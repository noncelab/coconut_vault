import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';

class MultisigAddKeyOptionBottomSheet extends StatelessWidget {
  final MultisigSigner signer;
  const MultisigAddKeyOptionBottomSheet({super.key, required this.signer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        customTitle: Text(t.multi_sig_setting_screen.add_key_option, style: CoconutTypography.body1_16_Bold),
        context: context,
        isBottom: true,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CoconutLayout.spacing_300h,
              ShrinkAnimationButton(
                border: Border.all(color: CoconutColors.gray300, width: 1),
                borderRadius: 12,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.mnemonicImport, arguments: {'externalSigner': signer});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                  child: Text(
                    t.multi_sig_setting_screen.input_mnemonic_word,
                    style: CoconutTypography.body1_16_Bold,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              CoconutLayout.spacing_300h,
              ShrinkAnimationButton(
                border: Border.all(color: CoconutColors.gray300, width: 1),
                borderRadius: 12,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.seedQrImport, arguments: {'externalSigner': signer});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                  child: Text(
                    t.multi_sig_setting_screen.scan_seed_qr,
                    style: CoconutTypography.body1_16_Bold,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
