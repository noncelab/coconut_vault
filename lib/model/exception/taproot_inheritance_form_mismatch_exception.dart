import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/localization/strings.g.dart';

enum TaprootInheritanceFormMismatch { needsLegacyWallet, needsWalletUpdate }

class TaprootInheritanceFormMismatchException implements Exception {
  final TaprootInheritanceFormMismatch mismatch;
  final String message;

  TaprootInheritanceFormMismatchException({required this.mismatch, required String walletName})
    : message = _message(mismatch, walletName);

  static String _message(TaprootInheritanceFormMismatch mismatch, String walletName) {
    switch (mismatch) {
      case TaprootInheritanceFormMismatch.needsLegacyWallet:
        const version = kLastLegacyInheritanceVersion;
        return version == null
            ? t.errors.cannot_sign_error
            : t.exceptions.taproot_inheritance_needs_legacy_wallet(name: walletName, version: version);
      case TaprootInheritanceFormMismatch.needsWalletUpdate:
        const version = kMinWalletVersionForInheritance;
        return version == null
            ? t.errors.cannot_sign_error
            : t.exceptions.taproot_inheritance_needs_wallet_update(name: walletName, version: version);
    }
  }

  @override
  String toString() => 'TaprootInheritanceFormMismatchException: $message';
}
