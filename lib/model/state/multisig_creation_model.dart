import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/utils/coconut/multisig_utils.dart';

class MultisigCreationModel {
  int? _requiredSignatureCount;
  int? _totalSignatureCount;
  List<MultisigSigner>? signers;

  int? get requiredSignatureCount => _requiredSignatureCount;
  int? get totalSignatureCount => _totalSignatureCount;

  void setQuoramRequirement(
      int requiredSignatureCount, int totalSignatureCount) {
    _requiredSignatureCount = requiredSignatureCount;
    _totalSignatureCount = totalSignatureCount;
  }

  void setSigners(List<MultisigSigner> signers) {
    assert(MultisigUtils.validateQuoramRequirement(
        _requiredSignatureCount!, _totalSignatureCount!));

    this.signers = signers;
  }

  void reset() {
    _requiredSignatureCount = _totalSignatureCount = signers = null;
  }
}
