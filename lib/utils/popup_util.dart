import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showInfoPopup(BuildContext context, String title, String description) async {
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return CoconutPopup(
        languageCode: context.read<VisibilityProvider>().language,
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
        title: title,
        description: description,
        rightButtonText: t.confirm,
        onTapRight: () {
          Navigator.pop(context);
        },
      );
    },
  );
}
