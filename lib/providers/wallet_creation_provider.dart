import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

class WalletCreationProvider {
  /// multisig
  int? _requiredSignatureCount;
  int? _totalSignatureCount;
  List<MultisigSigner>? _signers;

  /// singleSig
  String? _secret;
  String? _passphrase;

  var _addressType;

  /// multisig
  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;
  List<MultisigSigner>? get signers => _signers != null ? List.unmodifiable(_signers!) : null;

  /// singleSig
  String? get secret => _secret;
  String? get passphrase => _passphrase;

  String? get addressType => _addressType;

  /// multisig
  void setQuorumRequirement(int requiredSignatureCount, int totalSignatureCount) {
    _requiredSignatureCount = requiredSignatureCount;
    _totalSignatureCount = totalSignatureCount;
  }

  void setAddressType(String addressType) {
    _addressType = addressType;
  }

  /// multisig
  void setSigners(List<MultisigSigner> signers) {
    assert(
        MultisigUtils.validateQuorumRequirement(_requiredSignatureCount!, _totalSignatureCount!));

    _signers = signers;
  }

  /// SingleSig
  void setSecretAndPassphrase(String secret, String? passphrase) {
    _secret = secret;
    _passphrase = passphrase;
  }

  /// SingleSig
  void resetSecretAndPassphrase() {
    _secret = _passphrase = null;
  }

  /// Multisig
  void resetSigner() {
    _signers = null;
  }

  void resetAll() {
    // singleSig
    _secret = _passphrase = null;

    /// multisig
    _requiredSignatureCount = _totalSignatureCount = _signers = null;
  }
}
