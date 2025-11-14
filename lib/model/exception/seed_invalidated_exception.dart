import 'package:coconut_vault/localization/strings.g.dart';

/// [서명 전용 모드] 지갑을 추가 후, 앱을 백그라운드에 두고 기기 암호를 해제했다가 재설정 후 돌아와
/// 니모닉 보기 또는 서명 시 이 예외가 발생합니다.
/// [안전 저장 모드] iOS는 앱 실행 시 security precheck 후 PIN 점검 단계에서 기기 암호 해제 여부를 미리 알 수 있고,
/// AOS는 홈화면 진입 후 이 예외가 발생하면 기기 암호가 해제됐다가 재설정 됐음을 알 수 있습니다.
class SeedInvalidatedException implements Exception {
  static String defaultErrorMessage = t.exceptions.seed_invalidated.description;
  final String message;

  SeedInvalidatedException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'SeedInvalidatedException: $message';
}
