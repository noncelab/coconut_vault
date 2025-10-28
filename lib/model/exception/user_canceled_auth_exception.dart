import 'package:coconut_vault/localization/strings.g.dart';

class UserCanceledAuthException implements Exception {
  static String defaultErrorMessage = t.errors.user_cancelled_auth;
  final String message;

  UserCanceledAuthException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'UserCancelledAuthException: $message';
}
