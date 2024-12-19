class MultisigUtils {
  // totalCount는 최대 3까지만 가능합니다.
  static bool validateQuoramRequirement(int requiredCount, int totalCount) {
    return requiredCount > 0 &&
        requiredCount <= totalCount &&
        totalCount > 1 &&
        totalCount <= 3;
  }
}
