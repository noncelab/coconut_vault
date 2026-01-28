import 'package:coconut_vault/constants/multisig.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';

class MultisigUtils {
  // 2 <= n <= kMultisigMaxCount, 1 <= m <= n
  static bool isValidQuorum(int m, int n) {
    return m > 0 && m <= n && n > 1 && n <= kMultisigMaxTotalCount;
  }

  // recommended requiredCount 계산합니다.
  static int calculateRecommendedRequiredCount(int totalCount) {
    return totalCount ~/ 2 + 1;
  }

  // m-of-n에 따라 카테고리를 반환합니다.
  static MultisigCategory classifyPolicy(int m, int n) {
    if (m <= 0 || n <= 1 || m > n) {
      throw ArgumentError('Invalid quorum $m-of-$n');
    }

    if (m == 1) {
      return MultisigCategory.lossTolerant;
    }

    if (m == n) {
      return MultisigCategory.highestSecurity;
    }

    if (n == 3 && m == 2) {
      return MultisigCategory.balanced;
    }

    if (n >= 4 && m == n - 1) {
      return MultisigCategory.highSecurity;
    }

    return MultisigCategory.balanced;
  }

  static String buildQuorumCategoryText(MultisigCategory category) {
    switch (category) {
      case MultisigCategory.lossTolerant:
        return t.multisig_quorum_selection_screen.quorum_category.loss_tolerant;
      case MultisigCategory.balanced:
        return t.multisig_quorum_selection_screen.quorum_category.balanced;
      case MultisigCategory.highSecurity:
      case MultisigCategory.highestSecurity:
        return t.multisig_quorum_selection_screen.quorum_category.high_security;
    }
  }

  // 카테고리에 따라 문구를 반환합니다.
  static String buildQuorumMessage(MultisigCategory category, int m) {
    switch (category) {
      case MultisigCategory.lossTolerant:
        return t.multisig_quorum_selection_screen.quorum_message.loss_tolerant;
      case MultisigCategory.balanced:
        return t.multisig_quorum_selection_screen.quorum_message.balanced(m: m);
      case MultisigCategory.highSecurity:
        return t.multisig_quorum_selection_screen.quorum_message.high_security(m: m);
      case MultisigCategory.highestSecurity:
        return t.multisig_quorum_selection_screen.quorum_message.highest_security;
    }
  }
}
