import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_step_widgets.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_overlays.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_scanner_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';

class ParentCreationOverlays {
  ParentCreationOverlays._();

  static Future<bool?> showCurrentVaultConfirmDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_dialog_title,
      description: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_dialog_description,
      rightButtonText: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_dialog_action,
    );
  }

  static Future<bool?> showCreateChildWalletConfirmDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_2.create_dialog_title,
      description: t.taproot.parent_creation_screen.step_2.create_dialog_description,
      rightButtonText: t.taproot.parent_creation_screen.step_1.single_sig_select_from_vault_dialog_action,
    );
  }

  static Future<void> showSameChildWalletAsParentDialog(BuildContext context, {required String description}) {
    return TaprootCreationOverlays.showInfoDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_2.same_child_wallet_as_parent_dialog_title,
      description: description,
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

  static Future<bool?> showSameParentWalletDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_1.same_parent_wallet_dialog_title,
      description: t.taproot.parent_creation_screen.step_1.same_parent_wallet_dialog_description,
      rightButtonText: t.confirm,
    );
  }

  static Future<void> showParentScanErrorDialog({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return TaprootCreationOverlays.showInfoDialog(
      context: context,
      title: title,
      description: description,
      rightButtonText: t.rescan,
    );
  }

  static Future<bool?> showParentWalletResetDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_2.return_dialog_title,
      description: t.taproot.parent_creation_screen.step_2.return_dialog_description,
      rightButtonText: t.confirm,
    );
  }

  static Future<bool?> showChildWalletResetDialog(BuildContext context) {
    return TaprootCreationOverlays.showConfirmDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_2.child_wallet_reset_dialog_title,
      description: t.taproot.parent_creation_screen.step_2.child_wallet_reset_dialog_description,
      rightButtonText: t.confirm,
    );
  }

  static Future<void> showDeviceAuthDialog({
    required BuildContext context,
    required void Function(BuildContext dialogContext) onConfirm,
  }) {
    return TaprootCreationOverlays.showDeviceAuthDialog(
      context: context,
      title: t.taproot.parent_creation_screen.step_1.device_auth_dialog_title,
      description: t.taproot.parent_creation_screen.step_1.device_auth_dialog_description,
      onConfirm: onConfirm,
    );
  }

  static Future<void> authenticateWithBiometricOrPin({
    required BuildContext context,
    required PinCheckContextEnum pinCheckContext,
    required VoidCallback onSuccess,
  }) async {
    await TaprootCreationOverlays.authenticateWithBiometricOrPin(
      context: context,
      pinCheckContext: pinCheckContext,
      onSuccess: onSuccess,
    );
  }

  static void showMultisigParentExportBottomSheet(BuildContext context, {required String? qrData}) {
    MyBottomSheet.showBottomSheet_ratio(
      context: context,
      ratio: 0.8,
      showDragHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            CoconutLayout.spacing_700h,
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                '${t.taproot.parent_creation_screen.step_1.multisig_qr_title_1}\n'
                '${t.taproot.parent_creation_screen.step_1.multisig_qr_title_2}',
                style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.black),
                textAlign: TextAlign.center,
              ),
            ),
            CoconutLayout.spacing_2100h,
            ParentMultisigParentExportQr(qrData: qrData),
          ],
        ),
      ),
    );
  }

  static Future<TaprootVault?> showMultisigParentScannerBottomSheet(BuildContext context) {
    final guideText = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Text(
        '${t.taproot.parent_creation_screen.step_1.multisig_scanner_title_1}\n'
        '${t.taproot.parent_creation_screen.step_1.multisig_scanner_title_2}',
        style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.white),
        textAlign: TextAlign.center,
      ),
    );

    return MyBottomSheet.showDraggableScrollableSheet<TaprootVault>(
      context: context,
      topWidget: true,
      physics: const ClampingScrollPhysics(),
      enableSingleChildScroll: false,
      hideAppBar: true,
      child: Scaffold(
        appBar: CoconutAppBar.build(
          context: context,
          backgroundColor: Colors.transparent,
          title: t.taproot.parent_creation_screen.title,
        ),
        body: TaprootScannerScreen(
          useCloseButton: true,
          topGuideWidget: Positioned(top: 80, left: 24, right: 24, child: guideText),
        ),
      ),
    );
  }

  static void showTimelockDatePicker({
    required BuildContext context,
    required DateTime today,
    required DateTime? initialDateTime,
    required ValueChanged<DateTime> onDateTimeSelected,
  }) {
    TaprootCreationOverlays.showTimelockDatePicker(
      context: context,
      today: today,
      initialDateTime: initialDateTime,
      onDateTimeSelected: onDateTimeSelected,
    );
  }
}
