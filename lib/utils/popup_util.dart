import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool> showResetFailureRetryPopup(BuildContext context, Object error, {BuildContext? navigatorContext}) async {
  final dialogContext = navigatorContext ?? context;
  if (!context.mounted || !dialogContext.mounted) return false;
  final retry = await showDialog<bool>(
    context: dialogContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.reset_failed,
          description: error.toString(),
          leftButtonText: t.cancel,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.retry,
          rightButtonColor: CoconutColors.black,
          onTapLeft: () => Navigator.pop(dialogContext, false),
          onTapRight: () => Navigator.pop(dialogContext, true),
        ),
      );
    },
  );
  return retry == true;
}

Future<void> showInfoPopup(BuildContext context, String title, String description, {String? buttonText}) async {
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return CoconutPopup(
        languageCode: context.read<VisibilityProvider>().appLanguage.code,
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
        title: title,
        description: description,
        rightButtonText: buttonText ?? t.confirm,
        onTapRight: () {
          Navigator.pop(context);
        },
      );
    },
  );
}
