import 'package:coconut_vault/services/secure_storage_service.dart';

/// 앱 진입 시 잠금 해제를 위해 PIN 번호 입력 횟수를 제한하기 위한 보조 함수들
class PinAttemptService {
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, String>> loadLockoutDuration() async {
    final lockoutEndTimeString =
        await _storageService.read(key: 'lockout_end_time');
    final totalAttemptTimes =
        await _storageService.read(key: 'total_pin_attempt');
    final attemptTime = await _storageService.read(key: 'pin_attempt');

    return {
      'lockoutEndTime': lockoutEndTimeString ?? '',
      'totalAttemptString': totalAttemptTimes ?? '0',
      'attemptString': attemptTime ?? '0',
    };
  }

  Future<void> setLockoutDuration(int minutes, {int totalAttempt = 0}) async {
    final lockoutEndTime = DateTime.now().add(Duration(minutes: minutes));
    final attemptTimes = (totalAttempt).toString();
    await _storageService.write(
        key: 'lockout_end_time',
        value: minutes != 0 ? lockoutEndTime.toIso8601String() : '');
    await _storageService.write(key: 'total_pin_attempt', value: attemptTimes);
  }

  Future<String> loadPinAttemptTimes() async {
    final attemptTimes = await _storageService.read(key: 'pin_attempt') ?? '0';
    return attemptTimes;
  }

  Future<void> setPinAttemptTimes(int time) async {
    final attemptTimes = time.toString();
    await _storageService.write(
      key: 'pin_attempt',
      value: attemptTimes,
    );
  }
}
