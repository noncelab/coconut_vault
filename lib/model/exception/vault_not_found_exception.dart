class VaultNotFoundException implements Exception {
  static String defaultErrorMessage = '해당 볼트를 찾을 수 없습니다.';
  final String message;

  VaultNotFoundException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'VaultNotFoundException: $message';
}
