import 'dart:typed_data';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

class WalletCreationProvider {
  /// multisig
  int? _requiredSignatureCount;
  int? _totalSignatureCount;
  List<MultisigSigner>? _signers;

  /// singleSig
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)
  MultisigSigner? _externalSigner; // 멀티시그 지갑에서 외부지갑 키 추가 시
  int? _multisigVaultIdOfExternalSigner; // 멀티시그 지갑에서 외부지갑 키 추가 시 호출한 화면의 vault id

  /// multisig
  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;
  List<MultisigSigner>? get signers => _signers != null ? List.unmodifiable(_signers!) : null;

  /// singleSig
  Uint8List get secret => _secret;
  Uint8List? get passphrase => _passphrase.isNotEmpty ? _passphrase : null;
  MultisigSigner? get externalSigner => _externalSigner;
  int? get multisigVaultIdOfExternalSigner => _multisigVaultIdOfExternalSigner;

  WalletType get walletType {
    if (_requiredSignatureCount != null &&
        _totalSignatureCount != null &&
        _signers != null &&
        _secret.isEmpty &&
        _passphrase.isEmpty) {
      return WalletType.multiSignature;
    }

    if (_requiredSignatureCount == null && _totalSignatureCount == null && _signers == null && _secret.isNotEmpty) {
      return WalletType.singleSignature;
    }

    throw Exception('Invalid Wallet Creation Provider Setting');
  }

  /// multisig
  void setQuorumRequirement(int requiredSignatureCount, int totalSignatureCount) {
    _requiredSignatureCount = requiredSignatureCount;
    _totalSignatureCount = totalSignatureCount;
  }

  /// multisig
  void setSigners(List<MultisigSigner> signers) {
    assert(MultisigUtils.isValidQuorum(_requiredSignatureCount!, _totalSignatureCount!));

    _signers = signers;
  }

  void setExternalSigner(MultisigSigner externalSigner) {
    _externalSigner = externalSigner;
  }

  void setMultisigVaultIdOfExternalSigner(int? vaultId) {
    _multisigVaultIdOfExternalSigner = vaultId;
  }

  /// SingleSig
  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? Uint8List(0);
  }

  /// SingleSig
  void resetSecretAndPassphrase() {
    _secret.wipe();
    _passphrase.wipe();
    _secret = Uint8List(0);
    _passphrase = Uint8List(0);
  }

  /// Multisig
  void resetSigner() {
    _signers = null;
  }

  void resetAll() {
    // singleSig
    resetSecretAndPassphrase();

    /// multisig
    _requiredSignatureCount =
        _totalSignatureCount = _signers = _externalSigner = _multisigVaultIdOfExternalSigner = null;
  }
}
