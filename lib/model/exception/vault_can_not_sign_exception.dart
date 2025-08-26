import 'package:coconut_vault/localization/strings.g.dart';

class VaultSigningNotAllowedException implements Exception {
  static String defaultErrorMessage = t.errors.cannot_sign_error;
  final String message;

  VaultSigningNotAllowedException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'VaultSigningNotAllowedException: $message';
}
