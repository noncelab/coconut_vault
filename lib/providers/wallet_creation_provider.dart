import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/services/secure_memory.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

class WalletCreationProvider {
  /// multisig
  int? _requiredSignatureCount;
  int? _totalSignatureCount;
  List<MultisigSigner>? _signers;

  /// singleSig
  Uint8List _secret = Uint8List(0); // utf8.encode(mnemonicWordsString)
  Uint8List _passphrase = Uint8List(0); // utf8.encode(passphraseString)

  /// multisig
  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;
  List<MultisigSigner>? get signers => _signers != null ? List.unmodifiable(_signers!) : null;

  /// singleSig
  String? get secret => _secret != Uint8List(0) ? utf8.decode(_secret) : null;
  String? get passphrase => _passphrase != Uint8List(0) ? utf8.decode(_passphrase) : null;

  /// multisig
  void setQuorumRequirement(int requiredSignatureCount, int totalSignatureCount) {
    _requiredSignatureCount = requiredSignatureCount;
    _totalSignatureCount = totalSignatureCount;
  }

  /// multisig
  void setSigners(List<MultisigSigner> signers) {
    assert(
        MultisigUtils.validateQuorumRequirement(_requiredSignatureCount!, _totalSignatureCount!));

    _signers = signers;
  }

  /// SingleSig
  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? Uint8List(0);
  }

  /// SingleSig
  void resetSecretAndPassphrase() {
    SecureMemory.wipe(_secret);
    SecureMemory.wipe(_passphrase);
  }

  /// Multisig
  void resetSigner() {
    _signers = null;
  }

  void resetAll() {
    // singleSig
    SecureMemory.wipe(_secret);
    SecureMemory.wipe(_passphrase);

    /// multisig
    _requiredSignatureCount = _totalSignatureCount = _signers = null;
  }
}
