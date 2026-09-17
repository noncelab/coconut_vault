import 'package:coconut_vault/app_shell.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/routes/common_routes.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:flutter/material.dart';

export 'routes/common_routes.dart' show buildCommonRoutes;
export 'utils/route_util.dart' show buildScreenWithArguments;

/// 기존 라이트 진입점과의 호환성을 유지하는 래퍼.
class CoconutVaultLiteApp extends StatelessWidget {
  const CoconutVaultLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultApp(
      isLiteBuild: true,
      routesBuilder: (onWelcomeComplete) => buildLiteRoutes(onWelcomeComplete: onWelcomeComplete),
      fallbackRoutesBuilder: _buildLiteFallbackRoutes,
    );
  }
}

/// 라이트 버전 라우트 테이블.
///
/// `test/app_lite_routes_test.dart`에서 호환성을 위해 유지됩니다.
/// 실제 라우트는 [buildCommonRoutes]에 `onWelcomeComplete`를 전달해 생성합니다.
Map<String, WidgetBuilder> buildLiteRoutes({required VoidCallback onWelcomeComplete}) {
  return buildCommonRoutes(onWelcomeComplete: onWelcomeComplete);
}

Map<String, WidgetBuilder> _buildLiteFallbackRoutes(
  VoidCallback onWelcomeComplete,
  VoidCallback onModeSelectionComplete,
) => {AppRoutes.welcome: (context) => WelcomeScreen(onComplete: onWelcomeComplete)};
