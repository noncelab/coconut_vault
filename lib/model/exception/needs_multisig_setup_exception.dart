import 'package:coconut_vault/localization/strings.g.dart';

class NeedsMultisigSetupException implements Exception {
  final String message;

  NeedsMultisigSetupException({required String singleSigWalletName})
    : message = t.exceptions.needs_multisig_setup(name: singleSigWalletName);

  @override
  String toString() => 'NeedsMultisigSetupException: $message';
}
