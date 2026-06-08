import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/common/date_selector_bottom_sheet.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaprootCreationOverlays {
  TaprootCreationOverlays._();

  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String rightButtonText,
    String? leftButtonText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          title: title,
          description: description,
          leftButtonText: leftButtonText ?? t.cancel,
          rightButtonText: rightButtonText,
          onTapLeft: () => Navigator.pop(dialogContext, false),
          onTapRight: () => Navigator.pop(dialogContext, true),
        );
      },
    );
  }

  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String rightButtonText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          title: title,
          description: description,
          rightButtonText: rightButtonText,
          onTapRight: () => Navigator.pop(dialogContext),
        );
      },
    );
  }

  static Future<void> showDeviceAuthDialog({
    required BuildContext context,
    required String title,
    required String description,
    required void Function(BuildContext dialogContext) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: CoconutPopup(
            languageCode: context.read<VisibilityProvider>().language,
            title: title,
            description: description,
            rightButtonText: t.confirm,
            onTapRight: () => onConfirm(dialogContext),
          ),
        );
      },
    );
  }

  static Future<void> authenticateWithBiometricOrPin({
    required BuildContext context,
    required PinCheckContextEnum pinCheckContext,
    required VoidCallback onSuccess,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final isBiometricValid =
        pinCheckContext == PinCheckContextEnum.sensitiveAction
            ? await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()
            : await authProvider.isBiometricsAuthValid();

    if (isBiometricValid && context.mounted) {
      onSuccess();
      return;
    }

    if (!context.mounted) {
      return;
    }

    final pinCheckResult = await showPinCheckBottomSheet(context: context, pinCheckContext: pinCheckContext);
    if (pinCheckResult == true && context.mounted) {
      onSuccess();
    }
  }

  static Future<bool?> showPinCheckBottomSheet({
    required BuildContext context,
    required PinCheckContextEnum pinCheckContext,
  }) {
    return MyBottomSheet.showBottomSheet_90<bool>(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(pinCheckContext: pinCheckContext, onSuccess: () => Navigator.pop(context, true)),
      ),
    );
  }

  static void showTimelockDatePicker({
    required BuildContext context,
    required DateTime today,
    required DateTime? initialDateTime,
    required ValueChanged<DateTime> onDateTimeSelected,
  }) {
    DateSelectorBottomSheet.show(
      context: context,
      today: today,
      initialDateTime: initialDateTime,
      onDateTimeSelected: onDateTimeSelected,
    );
  }
}
