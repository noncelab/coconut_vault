import 'package:coconut_vault/app_bootstrap.dart';
import 'package:coconut_vault/app_lite.dart';

/// 라이트(서명 전용) 버전 엔트리포인트.
///
/// `flutter build --flavor liteMainnet -t lib/main_lite.dart`
/// 실제 초기화 로직은 [bootstrapApp]에서 공유되며, 이 파일은 thin entry point 역할만 합니다.
void main() => bootstrapApp(isLiteBuild: true, app: const CoconutVaultLiteApp());
