import 'package:coconut_vault/services/shared_preferences_service.dart';

/// 앱 진입 시 잠금 해제를 위해 PIN 번호 입력 횟수를 제한하기 위한 보조 함수들
class PinAttemptService {
  final SharedPrefsService _sharedPrefs = SharedPrefsService();
  static String kLockoutEndTime = 'LOCKOUT_END_TIME';
  static String kTotalPinAttempt = 'TOTAL_PIN_ATTEMPT';
  static String kPinAttempt = 'PIN_ATTEMPT';

  Map<String, String> loadLockoutDuration() {
    final lockoutEndTimeString = _sharedPrefs.getString(kLockoutEndTime);
    final totalAttemptTimes = _sharedPrefs.getString(kTotalPinAttempt);
    final attemptTime = _sharedPrefs.getString(kPinAttempt);

    return {
      'lockoutEndTime': lockoutEndTimeString,
      'totalAttemptString': totalAttemptTimes.isEmpty ? '0' : totalAttemptTimes,
      'attemptString': attemptTime.isEmpty ? '0' : attemptTime,
    };
  }

  // TODO: 딜레이 발생 이유
  Future<void> setLockoutDuration(int minutes, {int totalAttempt = 0}) async {
    final lockoutEndTime = DateTime.now().add(Duration(minutes: minutes));
    final attemptTimes = (totalAttempt).toString();
    await _sharedPrefs.setString(
        kLockoutEndTime, minutes != 0 ? lockoutEndTime.toIso8601String() : '');
    await _sharedPrefs.setString(kTotalPinAttempt, attemptTimes);
  }

  String loadPinAttemptTimes() {
    final attemptTimes = _sharedPrefs.getString(kPinAttempt);
    return attemptTimes.isEmpty ? '0' : attemptTimes;
  }

  Future<void> setPinAttemptTimes(int time) async {
    final attemptTimes = time.toString();
    await _sharedPrefs.setString(kPinAttempt, attemptTimes);
  }
}
