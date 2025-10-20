import 'package:coconut_vault/localization/strings.g.dart';

class ExtendedPublicKeyNotFoundException implements Exception {
  static String defaultErrorMessage = t.errors.extended_public_key_not_found_error;
  final String message;

  ExtendedPublicKeyNotFoundException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'ExtendedPublicKeyNotFoundException: $message';
}
