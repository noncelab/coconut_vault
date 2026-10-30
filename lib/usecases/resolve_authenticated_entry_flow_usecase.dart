import 'package:coconut_vault/app_entry_flow.dart';
import 'package:coconut_vault/providers/auth_provider.dart';

/// Called after the device security check, in full secure-storage mode.
class ResolveAuthenticatedEntryFlowUsecase {
  static Future<AppEntryFlow> execute({
    required AuthProvider authProvider,
    required bool isIos,
    required int walletCount,
    required Future<bool> Function() verifyIosKeychainValidity,
  }) async {
    await authProvider.ready;
    // Preserve the explicit permanent-lock recovery flow.
    if (authProvider.isPermanentlyLocked) return AppEntryFlow.pinCheck;

    // Disabling the device passcode can invalidate Keychain records and make
    // startup authentication fail. Show data recovery guidance before the
    // generic PIN error; never clear uncertain authentication state here.
    if (isIos && authProvider.isPinSet && !await verifyIosKeychainValidity()) {
      return AppEntryFlow.cannotAccessToSecureZone;
    }
    if (authProvider.authenticationUnavailable || walletCount > 0) return AppEntryFlow.pinCheck;
    return AppEntryFlow.vaultHome;
  }
}
