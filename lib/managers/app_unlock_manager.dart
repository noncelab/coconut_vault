import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';

/// 앱 진입 시 잠금 해제를 위해 PIN 번호 입력 횟수를 제한하기 위한 보조 함수들
class AppUnlockManager {
  final SharedPrefsRepository _sharedPrefs = SharedPrefsRepository();

  static String lockoutEndTimeKey = SharedPrefsKeys.kLockoutEndDateTime;
  static String totalAttemptKey = SharedPrefsKeys.kTotalPinInputAttemptCount;
  static String attemptKey = SharedPrefsKeys.kPinInputAttemptCount;

  Map<String, String> loadLockoutDuration() {
    final lockoutEndDateTimeString = _sharedPrefs.getString(lockoutEndTimeKey);
    final totalAttemptCount = _sharedPrefs.getString(totalAttemptKey);
    final attemptCount = _sharedPrefs.getString(attemptKey);

    return {
      lockoutEndTimeKey: lockoutEndDateTimeString,
      totalAttemptKey: totalAttemptCount.isEmpty ? '0' : totalAttemptCount,
      attemptKey: attemptCount.isEmpty ? '0' : attemptCount,
    };
  }

  // TODO: 딜레이 발생 이유
  Future<void> setLockoutDuration(int minutes,
      {int totalAttemptCount = 0}) async {
    final lockoutEndTime = DateTime.now().add(Duration(minutes: minutes));
    final attemptCount = totalAttemptCount.toString();
    await _sharedPrefs.setString(lockoutEndTimeKey,
        minutes != 0 ? lockoutEndTime.toIso8601String() : '');
    await _sharedPrefs.setString(totalAttemptKey, attemptCount);
  }

  String loadPinInputAttemptCount() {
    final attemptCount = _sharedPrefs.getString(attemptKey);
    return attemptCount.isEmpty ? '0' : attemptCount;
  }

  Future<void> setPinInputAttemptCount(int numberOfTimes) async {
    final attemptCount = numberOfTimes.toString();
    await _sharedPrefs.setString(attemptKey, attemptCount);
  }
}
