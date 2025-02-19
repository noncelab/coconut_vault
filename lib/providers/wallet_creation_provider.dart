import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

class WalletCreationProvider {
  int? _requiredSignatureCount;
  int? _totalSignatureCount;
  List<MultisigSigner>? signers;

  String? _secret;
  String? _passphrase;

  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;

  String? get secret => _secret;
  String? get passphrase => _passphrase;

  void setQuorumRequirement(
      int requiredSignatureCount, int totalSignatureCount) {
    _requiredSignatureCount = requiredSignatureCount;
    _totalSignatureCount = totalSignatureCount;
  }

  void setSigners(List<MultisigSigner> signers) {
    assert(MultisigUtils.validateQuorumRequirement(
        _requiredSignatureCount!, _totalSignatureCount!));

    this.signers = signers;
  }

  void reset() {
    _requiredSignatureCount = _totalSignatureCount = signers = null;
  }

  /// SingleSig
  void setSecretAndPassphrase(String secret, String? passphrase) {
    _secret = secret;
    _passphrase = passphrase;
  }

  /// SingleSig
  void resetSecretAndPassphrase() {
    _secret = null;
    _passphrase = null;
  }
}
