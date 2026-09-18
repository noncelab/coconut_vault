import 'package:coconut_vault/app_lite.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLiteRoutes', () {
    // 라이트 버전에 등록되는 라우트는 이 목록과 정확히 일치해야 합니다.
    // 라우트 추가/제거 시 이 목록을 함께 갱신하세요.
    final expectedRoutes = <String>{
      AppRoutes.vaultList,
      AppRoutes.vaultTypeSelection,
      AppRoutes.signerAssignment,
      AppRoutes.vaultCreationOptions,
      AppRoutes.mnemonicVerify,
      AppRoutes.mnemonicImport,
      AppRoutes.seedQrImport,
      AppRoutes.mnemonicConfirmation,
      AppRoutes.mnemonicView,
      AppRoutes.singleSigSetupInfo,
      AppRoutes.multisigSetupInfo,
      AppRoutes.multisigBsmsView,
      AppRoutes.viewXpub,
      AppRoutes.mnemonicWordList,
      AppRoutes.addressList,
      AppRoutes.multisigCreationOptions,
      AppRoutes.multisigQuorumSelection,
      AppRoutes.coordinatorBsmsConfigScanner,
      AppRoutes.bsmsPaste,
      AppRoutes.signerBsmsScanner,
      AppRoutes.psbtScanner,
      AppRoutes.psbtConfirmation,
      AppRoutes.signedTransaction,
      AppRoutes.syncToWallet,
      AppRoutes.multisigSignerBsmsExport,
      AppRoutes.vaultExportOptions,
      AppRoutes.backupWalletData,
      AppRoutes.multisigSign,
      AppRoutes.singleSigSign,
      AppRoutes.securitySelfCheck,
      AppRoutes.mnemonicAutoGen,
      AppRoutes.mnemonicCoinflip,
      AppRoutes.mnemonicDiceRoll,
      AppRoutes.appInfo,
      AppRoutes.welcome,
      AppRoutes.developer,
    };

    test('허용된 라우트만 등록된다', () {
      final routes = buildLiteRoutes(onWelcomeComplete: () {});
      expect(routes.keys.toSet(), equals(expectedRoutes));
    });
  });
}
