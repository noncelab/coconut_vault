import 'package:coconut_vault/localization/strings.g.dart';

class VaultNotFoundException implements Exception {
  static String defaultErrorMessage = t.errors.vault_not_found_error;
  final String message;

  VaultNotFoundException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'VaultNotFoundException: $message';
}
