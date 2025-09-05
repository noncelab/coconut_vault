import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomDialogs {
  static void showLoadingDialog(
    BuildContext context,
    String text,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    CoconutLayout.spacing_800h,
                    SizedBox(
                      width: 70,
                      child: Lottie.asset(
                        'assets/lottie/loading-gray.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    CoconutLayout.spacing_500h,
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            textAlign: TextAlign.center, text, style: CoconutTypography.body2_14)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
