class MultisigUtils {
  // totalCount는 최대 3까지만 가능합니다.
  static bool validateQuorumRequirement(int requiredCount, int totalCount,
      {bool isP2trMuSig2 = false}) {
    if (isP2trMuSig2) {
      return requiredCount == totalCount && totalCount >= 3 && totalCount <= 10;
    } else {
      return requiredCount > 0 && requiredCount <= totalCount && totalCount > 1 && totalCount <= 3;
    }
  }
}
