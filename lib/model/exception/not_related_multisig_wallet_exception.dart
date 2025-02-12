import 'package:coconut_vault/localization/strings.g.dart';

class NotRelatedMultisigWalletException implements Exception {
  static String defaultErrorMessage =
      t.errors.not_related_multisig_wallet_error;
  final String message;

  NotRelatedMultisigWalletException({String? message})
      : message = message ?? defaultErrorMessage;

  @override
  String toString() => 'MyFunctionException: $message';
}
