import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/account_descriptor/legacy_account_descriptor.dart';
import 'package:coconut_vault/utils/conversion_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

enum QrType { single, animated }

class WalletToSyncViewModel extends ChangeNotifier {
  final List<String> options = [t.coconut, 'BC UR', t.descriptor];
  late final List<QrData> qrDatas;
  int _selectedOption = 0;

  WalletToSyncViewModel(int vaultId, WalletProvider walletProvider) {
    final vault = walletProvider.getVaultById(vaultId);
    qrDatas = [
      QrData(type: QrType.single, data: vault.getWalletSyncString()),
      QrData(type: QrType.animated, data: _getLegacyAccountDescriptor(vault)),
      QrData(
          type: QrType.single,
          data: _parseDescriptor(
              vault.coconutVault.descriptor, vault.vaultType == WalletType.singleSignature)),
    ];
  }

  Uint8List _getLegacyAccountDescriptor(VaultListItemBase vault) {
    if (vault.vaultType == WalletType.singleSignature) {
      final coconutVault = vault.coconutVault as SingleSignatureVault;
      return LegacyAccountDescriptor.getLegacyAccountDescriptor(
          coconutVault.keyStore.masterFingerprint,
          coconutVault.keyStore.extendedPublicKey.parentFingerprint,
          coconutVault.keyStore.extendedPublicKey.publicKey,
          coconutVault.keyStore.extendedPublicKey.chainCode,
          NetworkType.currentNetworkType.isTestnet,
          true);
    } else if (vault.vaultType == WalletType.multiSignature) {
      throw 'Multisig Not Implemented yet';
    } else {
      throw 'Wrong vault type: ${vault.vaultType}';
    }
  }

  QrData get qrData => qrDatas[_selectedOption];
  String get qrDataString => _convertQrDataToString(qrData.data);

  void setSelectedOption(int option) {
    _selectedOption = option;
    notifyListeners();
  }

  String _convertQrDataToString(dynamic qrData) {
    if (qrData is String) {
      return qrData;
    } else if (qrData is Uint8List) {
      return ConversionUtil.bytesToHex(qrData).toUpperCase();
    }

    return qrData.toString();
  }

  /// 블루월렛, 넌척 등의 지갑들이 path + expubkey 조합의 keyspec만 인식함에 따른 조치
  String _parseDescriptor(String descriptor, bool isSingleSigVault) {
    try {
      var result = descriptor;

      if (isSingleSigVault) {
        if (result.contains('(') && result.contains(')')) {
          result = result.substring(result.indexOf('(') + 1, result.indexOf(')'));
        }

        /// /0/*, /1/*, 혹은 <0;1>/*, /*은 없을 수 있음
        if (result.contains('/<0;1>')) {
          result = result.substring(0, result.indexOf('/<0;1>'));
        } else if (result.split(']')[1].contains('/')) {
          result = '${result.split(']')[0]}]${result.split(']')[1].split('/').first}';
        }
      } else {
        /// TODO: 구현 필요
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
