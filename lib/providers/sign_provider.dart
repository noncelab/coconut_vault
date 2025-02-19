import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';

/// 서명 과정에서 사용하는 Provider
class SignProvider {
  String? _unsignedPsbtBase64;
  VaultListItemBase? _vaultListItem;

  PSBT? _psbt;
  String? _recipientAddress;
  int? _sendingAmount;

  String? _signedPsbtBase64;

  int? get walletId => _vaultListItem?.id;
  String? get unsignedPsbtBase64 => _unsignedPsbtBase64;
  VaultListItemBase? get vaultListItem => _vaultListItem;
  String? get walletName => _vaultListItem?.name;
  bool? get isMultisig =>
      _vaultListItem?.vaultType == WalletType.multiSignature;

  PSBT? get psbt => _psbt;
  String? get recipientAddress => _recipientAddress;
  int? get sendingAmount => _sendingAmount;

  String? get signedPsbtBase64 => _signedPsbtBase64;

  // 1. psbt_scanner
  void setVaultListItem(VaultListItemBase vaultListItemBase) {
    _vaultListItem = vaultListItemBase;
  }

  // 1. psbt_scanner
  void saveUnsignedPsbt(String psbtBase64) {
    _unsignedPsbtBase64 = psbtBase64;
  }

  // 2. psbt_confirmation
  void savePsbt(PSBT psbt) {
    _psbt = psbt;
  }

  // 2. psbt_confirmation
  void saveRecipientAddress(String address) {
    _recipientAddress = address;
  }

  // 2. psbt_confirmation
  void saveSendingAmount(int amount) {
    _sendingAmount = amount;
  }

  // 2. psbt_confirmation
  void resetPsbt() {
    _psbt = null;
  }

  // 2. psbt_confirmation
  void resetRecipientAddress() {
    _recipientAddress = null;
  }

  // 2. psbt_confirmation
  void resetSendingAmount() {
    _sendingAmount = null;
  }

  // 3-1. single_sig_sign
  // 3-2. multisig_sign
  void saveSignedPsbt(String psbtBase64) {
    _signedPsbtBase64 = psbtBase64;
  }

  // 3-1. single_sig_sign
  // 3-2. multisig_sign
  void resetSignedPsbt() {
    _signedPsbtBase64 = null;
  }

  void resetAll() {
    _unsignedPsbtBase64 = _vaultListItem =
        _psbt = _recipientAddress = _sendingAmount = _signedPsbtBase64 = null;
  }
}
