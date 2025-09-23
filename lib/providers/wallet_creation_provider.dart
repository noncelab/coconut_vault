import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/enums/wallet_enums.dart';
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
  Uint8List _passphrase = utf8.encode(''); // utf8.encode(passphraseString)

  /// multisig
  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;
  List<MultisigSigner>? get signers => _signers != null ? List.unmodifiable(_signers!) : null;

  /// singleSig
  Uint8List get secret => _secret;
  String? get passphrase => _passphrase != Uint8List(0) ? utf8.decode(_passphrase) : null;

  WalletType get walletType {
    if (_requiredSignatureCount != null &&
        _totalSignatureCount != null &&
        _signers != null &&
        _secret.isEmpty &&
        _passphrase.isEmpty) {
      return WalletType.multiSignature;
    }

    if (_requiredSignatureCount == null &&
        _totalSignatureCount == null &&
        _signers == null &&
        _secret.isNotEmpty) {
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
    assert(
        MultisigUtils.validateQuorumRequirement(_requiredSignatureCount!, _totalSignatureCount!));

    _signers = signers;
  }

  /// SingleSig
  void setSecretAndPassphrase(Uint8List secret, Uint8List? passphrase) {
    _secret = secret;
    _passphrase = passphrase ?? utf8.encode('');
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
