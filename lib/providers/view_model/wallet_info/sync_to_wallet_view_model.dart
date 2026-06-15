import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/enums/wallet_export_format_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/services/blockchain_commons/account_descriptor/legacy_account_descriptor.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/utils/conversion_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

enum QrType { single, animated }

class WalletToSyncViewModel extends ChangeNotifier {
  final int _vaultId;
  final WalletProvider _walletProvider;
  final List<String> options = [t.coconut, 'BC UR', t.descriptor];

  late List<QrData> qrDatas;
  int _selectedOption = 0;

  late String derivationPath;
  late int _currentAccountIndex;
  late UrType urType;

  int get currentAccountIndex => _currentAccountIndex;

  WalletToSyncViewModel(this._vaultId, this._walletProvider) {
    _initVaultData();
  }

  void _initVaultData() {
    final vault = _walletProvider.getVaultById(_vaultId);

    if (vault is TaprootVaultListItem) {
      derivationPath = '';
      _currentAccountIndex = 0;
      qrDatas = [QrData(type: QrType.single, data: vault.getWalletSyncString())];
      return;
    }

    if (vault is SingleSigVaultListItem) {
      final singlesigVault = vault.coconutVault as SingleSignatureVault;
      derivationPath = singlesigVault.derivationPath;

      final pathParts = derivationPath.split('/');
      _currentAccountIndex =
          pathParts.isNotEmpty ? (int.tryParse(pathParts.last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) : 0;
    } else {
      derivationPath = '';
      _currentAccountIndex = 0;
    }

    final isSingleSig = vault.vaultType == WalletType.singleSignature;
    urType = isSingleSig ? UrType.cryptoAccount : UrType.cryptoOutput;

    // descriptor
    final String rawDescriptor =
        isSingleSig
            ? (vault.coconutVault as SingleSignatureVault).descriptor
            : (vault.coconutVault as MultisignatureVault).descriptor;

    qrDatas = [
      QrData(type: QrType.single, data: vault.getWalletSyncString()),
      QrData(type: QrType.animated, data: _getLegacyAccountDescriptor(vault)),
      QrData(type: QrType.single, data: _parseDescriptor(rawDescriptor, isSingleSig)),
    ];
  }

  Future<void> updateAccount(int newAccount, {Uint8List? passphrase}) async {
    Logger.log('1. Provider 업데이트 요청 시작: Account $newAccount');
    await _walletProvider.updateSingleSigAccount(_vaultId, newAccount, passphrase: passphrase);

    Logger.log('2. Provider 업데이트 완료. 뷰모델 데이터 재초기화 진행');
    _initVaultData();

    Logger.log('3. 데이터 재초기화 완료. UI 갱신(notifyListeners) 호출');
    notifyListeners();
  }

  Uint8List _getLegacyAccountDescriptor(VaultListItemBase vault) {
    if (vault.vaultType == WalletType.singleSignature) {
      final coconutVault = vault.coconutVault as SingleSignatureVault;
      return LegacyAccountDescriptor.buildSingleSigCbor(
        masterFingerprint: coconutVault.keyStore.masterFingerprint,
        parentFingerprint: coconutVault.keyStore.extendedPublicKey.parentFingerprint,
        pubkey33: coconutVault.keyStore.extendedPublicKey.publicKey,
        chainCode32: coconutVault.keyStore.extendedPublicKey.chainCode,
        coinType: NetworkType.currentNetworkType.isTestnet ? 1 : 0,
        account: _currentAccountIndex,
      );
    } else if (vault.vaultType == WalletType.multiSignature) {
      final multisigListItem = vault as MultisigVaultListItem;
      final coconutVault = vault.coconutVault as MultisignatureVault;
      int signerIndex = 0;

      return LegacyAccountDescriptor.buildMultisigCbor(
        requiredSignature: coconutVault.requiredSignature,
        coinType: NetworkType.currentNetworkType.isTestnet ? 1 : 0,
        cosigners:
            coconutVault.keyStoreList.map((keyStore) {
              var signer = multisigListItem.signers[signerIndex++];
              return Cosigner(
                label: signer.name ?? signer.memo ?? '',
                masterFingerprintHex: keyStore.masterFingerprint,
                parentFingerprintHex: keyStore.extendedPublicKey.parentFingerprint,
                pubkey33: keyStore.extendedPublicKey.publicKey,
                chainCode32: keyStore.extendedPublicKey.chainCode,
              );
            }).toList(),
      );
    }

    return Uint8List(0);
  }

  QrData get qrData => qrDatas[_selectedOption];
  String get qrDataString => _convertQrDataToString(qrData.data);

  void setFormatOption(SyncOption syncOption) {
    if (qrDatas.length == 1) {
      _selectedOption = 0;
      notifyListeners();
      return;
    }

    switch (syncOption.format) {
      case WalletExportFormatEnum.coconut:
        _selectedOption = 0;
        break;
      case WalletExportFormatEnum.bcUr:
        _selectedOption = 1;
        break;
      case WalletExportFormatEnum.descriptor:
        _selectedOption = 2;
        break;
    }
    notifyListeners();
  }

  String _convertQrDataToString(dynamic qrData) {
    if (qrData is Uint8List) {
      return ConversionUtil.bytesToHex(qrData).toUpperCase();
    }
    return qrData.toString();
  }

  /// 블루월렛, 넌척 등의 지갑들이 path + expubkey 조합의 keyspec만 인식함에 따른 조치
  String _parseDescriptor(String descriptor, bool isSingleSigVault) {
    if (!isSingleSigVault) return descriptor;

    try {
      var result = descriptor;

      if (result.contains('(') && result.contains(')')) {
        result = result.substring(result.indexOf('(') + 1, result.indexOf(')'));
      }

      if (result.contains('/<0;1>')) {
        result = result.substring(0, result.indexOf('/<0;1>'));
      } else if (result.contains(']') && result.split(']')[1].contains('/')) {
        result = '${result.split(']')[0]}]${result.split(']')[1].split('/').first}';
      }

      return result;
    } catch (e) {
      Logger.error(e);
      return descriptor;
    }
  }
}

class QrData {
  final QrType type;
  final dynamic data;

  QrData({required this.type, required this.data});
}
