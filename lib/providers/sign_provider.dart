import 'package:coconut_vault/model/common/vault_list_item_base.dart';

/// 서명 과정에서 사용하는 Provider
class SignProvider {
  int? _walletId;
  String? _unsignedPsbtBase64;
  String? _recipientAddress;
  VaultListItemBase? _vaultListItem;
  int? _sendingAmount;

  int? get walletId => _walletId;
  String? get unsignedPsbtBase64 => _unsignedPsbtBase64;
  VaultListItemBase? get vaultListItem => _vaultListItem;
  String? get recipientAddress => _recipientAddress;
  int? get sendingAmount => _sendingAmount;

  // psbt_scanner
  void setVaultListItem(VaultListItemBase vaultListItemBase) {
    _vaultListItem = vaultListItemBase;
  }

  // psbt_scanner
  void saveUnsignedPsbt(String psbtBase64) {
    _unsignedPsbtBase64 = psbtBase64;
  }

  // psbt_confirmation
  void saveRecipientAddress(String address) {
    _recipientAddress = address;
  }

  // psbt_confirmation
  void saveSendingAmount(int amount) {
    _sendingAmount = amount;
  }

  // psbt_confirmation
  void resetRecipientAddress() {
    _recipientAddress = null;
  }

  // psbt_confirmation
  void resetSendingAmount() {
    _sendingAmount = null;
  }
}
