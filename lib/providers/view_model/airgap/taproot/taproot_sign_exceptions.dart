import 'package:coconut_vault/localization/strings.g.dart';

class UnsupportedTaprootPsbtException implements Exception {
  static String defaultErrorMessage = t.exceptions.unsupported_psbt_state;
  final String message;

  UnsupportedTaprootPsbtException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'UnsupportedTaprootPsbtException: $message';
}
