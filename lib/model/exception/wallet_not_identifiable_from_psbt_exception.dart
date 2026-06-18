import 'package:coconut_vault/localization/strings.g.dart';

class WalletNotIdentifiableFromPsbtException implements Exception {
  static String defaultErrorMessage = t.errors.extended_public_key_not_found_error;
  final String message;

  WalletNotIdentifiableFromPsbtException({String? message}) : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'DirectWalletSelectionRequiredException: $message';
}
