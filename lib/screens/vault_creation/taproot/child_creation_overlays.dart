import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_overlays.dart';
import 'package:flutter/material.dart';

class ChildCreationOverlays {
  ChildCreationOverlays._();

  static Future<bool?> showCurrentVaultConfirmDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_dialog_title,
      description: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_dialog_description,
      rightButtonText: t.taproot.child_creation_screen.step3.single_sig_select_from_vault_dialog_action,
    );
  }

  static Future<bool?> showChildWalletResetDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.child_creation_screen.step4.return_dialog_title,
      description: t.taproot.child_creation_screen.step4.return_dialog_description,
      rightButtonText: t.confirm,
    );
  }

  static Future<void> showDuplicateWalletDialog(BuildContext context, String name) {
    return TaprootCreationOverlays.showInfoDialog(
      context: context,
      title: t.alert.same_wallet.title,
      description: t.alert.same_wallet.description(name: name),
      rightButtonText: t.confirm,
    );
  }

  static Future<void> showDeviceAuthDialog({
    required BuildContext context,
    required void Function(BuildContext dialogContext) onConfirm,
  }) {
    return TaprootCreationOverlays.showDeviceAuthDialog(
      context: context,
      title: t.taproot.child_creation_screen.step3.device_auth_dialog_title,
      description: t.taproot.child_creation_screen.step3.device_auth_dialog_description,
      onConfirm: onConfirm,
    );
  }

  static Future<void> authenticateWithBiometricOrPin({
    required BuildContext context,
    required PinCheckContextEnum pinCheckContext,
    required VoidCallback onSuccess,
  }) {
    return TaprootCreationOverlays.authenticateWithBiometricOrPin(
      context: context,
      pinCheckContext: pinCheckContext,
      onSuccess: onSuccess,
    );
  }
}
