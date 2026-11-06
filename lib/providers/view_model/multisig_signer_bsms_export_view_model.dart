import 'dart:convert';
import 'package:coconut_vault/enums/wallet_app.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/i_qr_view_data_handler.dart';

import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

class MultisigSignerBsmsExportViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  late String _qrData;
  late String _errorMessage;
  late bool _isLoading;
  late SingleSigVaultListItem _singleSigVaultListItem;
  Bsms? _bsms;
  final WalletApp app;
  IQrViewDataHandler? _qrViewDataHandler;

  MultisigSignerBsmsExportViewModel(this._walletProvider, id, {this.app = WalletApp.coconut}) {
    _qrData = '';
    _errorMessage = '';
    _isLoading = true;
    _singleSigVaultListItem = _walletProvider.getVaultById(id) as SingleSigVaultListItem;
    _setSignerBsms();
  }
  String get name => _singleSigVaultListItem.name;
  String get qrData => _qrData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  Bsms? get bsms => _bsms;
  bool get usesBsmsText => app == WalletApp.coconut;
  IQrViewDataHandler? get qrViewDataHandler => _qrViewDataHandler;
  String? get displayQrData => _qrViewDataHandler == null ? exportText : null;

  String get exportText => switch (app) {
    WalletApp.coconut => qrData,
    WalletApp.bluewallet => blueWalletCosigner,
    WalletApp.nunchuk || WalletApp.sparrow => signerDescriptor,
  };

  String get guideText => switch (app) {
    WalletApp.coconut => t.signer_bsms_screen.coconut_guide,
    WalletApp.nunchuk => t.signer_bsms_screen.nunchuk_guide,
    WalletApp.sparrow => t.signer_bsms_screen.sparrow_guide,
    WalletApp.bluewallet => t.signer_bsms_screen.bluewallet_guide,
  };

  /// Key origin expression for registering one signer, not a wallet descriptor.
  /// Reuse the BIP48 key from signer BSMS, never the singlesig BIP84 key.
  String get signerDescriptor {
    final signer = _bsms?.signer;
    if (signer == null) return '';
    final path = signer.path.startsWith('m/') ? signer.path.substring(2) : signer.path;
    return '[${signer.masterFingerPrint}/$path]${signer.extendedPublicKey.serialize(toXpub: true)}';
  }

  // BlueWallet MultisigCosigner.exportToJson uses these three fields.
  String get blueWalletCosigner {
    final signer = _bsms?.signer;
    if (signer == null) return '';
    return jsonEncode({
      'xfp': signer.masterFingerPrint,
      'xpub': signer.extendedPublicKey.serialize(toXpub: true),
      'path': signer.path.startsWith('m/') ? signer.path : 'm/${signer.path}',
    });
  }

  /// BCR-2020-015: one P2WSH cosigner, not an invented 1-of-1 wallet.
  /// Sparrow imports crypto-account via QRScanDialog / KeystoreController.
  Uint8List get sparrowAccount {
    final signer = _bsms!.signer!;
    final key = signer.extendedPublicKey;
    final path = signer.path.replaceFirst(RegExp(r'^m/'), '').split('/');
    final fingerprint = int.parse(signer.masterFingerPrint, radix: 16);
    final enc = CBOREncoder();
    enc.encodeMapSize(2);
    enc.encodeInteger(1);
    enc.encodeInteger(fingerprint);
    enc.encodeInteger(2);
    enc.encodeArraySize(1);
    for (final tag in [308, 401, 410, 303]) {
      enc.encodeTagAndValue(CBORTag.majorSemantic, tag);
    }
    enc.encodeMapSize(6);
    enc.encodeInteger(2);
    enc.encodeBool(false);
    enc.encodeInteger(3);
    enc.encodeBytes(key.publicKey);
    enc.encodeInteger(4);
    enc.encodeBytes(key.chainCode);
    enc.encodeInteger(5);
    enc.encodeTagAndValue(CBORTag.majorSemantic, 305);
    enc.encodeMapSize(2);
    enc.encodeInteger(1);
    enc.encodeInteger(0);
    enc.encodeInteger(2);
    enc.encodeInteger(int.parse(path[1].replaceAll(RegExp("['hH]"), '')));
    enc.encodeInteger(6);
    enc.encodeTagAndValue(CBORTag.majorSemantic, 304);
    enc.encodeMapSize(3);
    enc.encodeInteger(1);
    enc.encodeArraySize(path.length * 2);
    for (final component in path) {
      enc.encodeInteger(int.parse(component.replaceAll(RegExp("['hH]"), '')));
      enc.encodeBool(RegExp(r"['hH]$").hasMatch(component));
    }
    enc.encodeInteger(2);
    enc.encodeInteger(fingerprint);
    enc.encodeInteger(3);
    enc.encodeInteger(path.length);
    enc.encodeInteger(8);
    enc.encodeInteger(int.parse(key.parentFingerprint, radix: 16));
    return enc.getBytes();
  }

  VaultListItemBase get vaultListItem => _singleSigVaultListItem;

  Future<void> _setSignerBsms() async {
    try {
      _qrData = _singleSigVaultListItem.getSignerBsmsByAddressType(AddressType.p2wsh);
      _bsms = Bsms.parseSigner(_qrData);
      if (app == WalletApp.sparrow) {
        _qrViewDataHandler = BcUrQrViewHandler(sparrowAccount, UrType.cryptoAccount);
      }
    } catch (e) {
      Logger.error('setSignerBsms error: $e');
      _errorMessage = e.toString();
      _bsms = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
