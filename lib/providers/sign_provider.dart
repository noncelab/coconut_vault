import 'dart:collection';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';

/// 서명 과정에서 사용하는 Provider
class SignProvider {
  String? _unsignedPsbtBase64;
  VaultListItemBase? _vaultListItem;

  Psbt? _psbt;
  String? _recipientAddress;
  int? _sendingAmount;

  // for batch tx
  Map<String, double>? _recipientAmounts;

  // for multisig sign
  Map<String, String>? _unsignedInputsMap;
  Map<String, String>? _signedInputsMap;
  String? _signingPublicKey;

  String? _signedPsbtBase64;

  int? get walletId => _vaultListItem?.id;
  String? get unsignedPsbtBase64 => _unsignedPsbtBase64;
  VaultListItemBase? get vaultListItem => _vaultListItem;
  String? get walletName => _vaultListItem?.name;
  bool? get isMultisig => _vaultListItem?.vaultType == WalletType.multiSignature;

  Psbt? get psbt => _psbt;
  String? get recipientAddress => _recipientAddress;
  Map<String, double>? get recipientAmounts =>
      _recipientAmounts == null ? null : UnmodifiableMapView(_recipientAmounts!);

  Map<String, String>? get unsignedInputsMap => _unsignedInputsMap;
  Map<String, String>? get signedInputsMap => _signedInputsMap;
  String? get signingPublicKey => _signingPublicKey;

  int? get sendingAmount => _sendingAmount;

  String? get signedPsbtBase64 => _signedPsbtBase64;

  // 1. psbt_scanner
  void setVaultListItem(VaultListItemBase vaultListItemBase) {
    _vaultListItem = vaultListItemBase;
  }

  // 1. psbt_scanner
  void saveUnsignedPsbt(String psbtBase64) {
    _unsignedPsbtBase64 = psbtBase64;
    print('a!@#!@!@#!@# saveUnsignedPsbt $psbtBase64');
  }

  // 2. psbt_confirmation
  void savePsbt(Psbt psbt) {
    _psbt = psbt;
    print('a!@#!@!@#!@# savePsbt $psbt');
  }

  // 2. psbt_confirmation
  void saveRecipientAddress(String address) {
    _recipientAddress = address;
    print('a!@#!@!@#!@# saveRecipientAddress $address');
  }

  // 2. psbt_confirmation
  void saveRecipientAmounts(Map<String, double> recipientAmounts) {
    _recipientAmounts = recipientAmounts;
    print('a!@#!@!@#!@# saveRecipientAmounts $recipientAmounts');
  }

  // 2. psbt_confirmation
  void saveSendingAmount(int amount) {
    _sendingAmount = amount;
    print('a!@#!@!@#!@# saveSendingAmount $amount');
  }

  // 2. psbt_confirmation
  void resetPsbt() {
    _psbt = null;
    print('a!@#!@!@#!@# resetPsbt');
  }

  // 2. psbt_confirmation
  void resetRecipientAddress() {
    _recipientAddress = null;
    print('a!@#!@!@#!@# resetRecipientAddress');
  }

  // 2. psbt_confirmation
  void resetRecipientAmounts() {
    _recipientAmounts = null;
    print('a!@#!@!@#!@# resetRecipientAmounts');
  }

  // 2. psbt_confirmation
  void resetSendingAmount() {
    _sendingAmount = null;
    print('a!@#!@!@#!@# resetSendingAmount');
  }

  // 3-1. single_sig_sign
  // 3-2. multisig_sign
  void saveSignedPsbt(String psbtBase64) {
    _signedPsbtBase64 = psbtBase64;
    print('a!@#!@!@#!@# saveSignedPsbt $psbtBase64');
  }

  // 3-1. single_sig_sign
  // 3-2. multisig_sign
  void resetSignedPsbt() {
    _signedPsbtBase64 = null;
    print('a!@#!@!@#!@# resetSignedPsbt');
  }

  // 3-2. multisig_sign
  void saveUnsignedInputsMap(Map<String, String> inputsMap) {
    _unsignedInputsMap = inputsMap;
    print('a!@#!@!@#!@# saveUnsignedInputsMap $inputsMap');
  }

  // 3-2. multisig_sign
  void resetUnsignedInputsMap() {
    _unsignedInputsMap = null;
    print('a!@#!@!@#!@# resetUnsignedInputsMap');
  }

  // 3-2. multisig_sign
  void saveSignedInputsMap(Map<String, String> signedInputsMap) {
    _signedInputsMap = signedInputsMap;
    print('a!@#!@!@#!@# saveSignedInputsMap $signedInputsMap');
  }

  // 3-2. multisig_sign
  void resetSignedInputsMap() {
    _signedInputsMap = null;
    print('a!@#!@!@#!@# resetSignedInputsMap');
  }

  // 3-2. multisig_sign
  void saveSigningPublicKey(String publicKey) {
    _signingPublicKey = publicKey;
    print('a!@#!@!@#!@# saveSigningPublicKey $publicKey');
  }

  // 3-2. multisig_sign
  void resetSigningPublicKey() {
    _signingPublicKey = null;
    print('a!@#!@!@#!@# resetSigningPublicKey');
  }

  void resetAll() {
    print('a!@#!@!@#!@# resetAll');
    _unsignedPsbtBase64 =
        _vaultListItem =
            _psbt =
                _recipientAddress =
                    _recipientAmounts =
                        _sendingAmount =
                            _signedPsbtBase64 = _unsignedInputsMap = _signedInputsMap = _signingPublicKey = null;
  }
}
