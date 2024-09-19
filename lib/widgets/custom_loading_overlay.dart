import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/styles.dart';

class CustomLoadingOverlay extends StatelessWidget {
  final Widget child;

  const CustomLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      useDefaultLoading: false,
      overlayWidgetBuilder: (_) {
        return const Center(
          child: CircularProgressIndicator(
            color: MyColors.darkgrey,
          ),
        );
      },
      child: child,
    );
  }
}
