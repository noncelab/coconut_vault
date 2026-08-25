import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/coordinator_bsms_qr_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text_screen.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoordinatorBsmsQrScreen extends StatelessWidget {
  final int id;

  const CoordinatorBsmsQrScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => CoordinatorBsmsQrViewModel(
            Provider.of<WalletProvider>(context, listen: false),
            id,
            mode: CoordinatorViewMode.shareWithOtherVault,
          ),
      child: Consumer<CoordinatorBsmsQrViewModel>(
        builder: (context, viewModel, child) {
          return QrWithCopyTextScreen(
            title: t.multi_sig_setting_screen.export_menu.share_bsms,
            tooltipDescription: _buildDescriptionBsms(context),
            qrData: viewModel.qrData,
          );
        },
      ),
    );
  }

  Widget _buildDescriptionBsms(BuildContext context) {
    return CustomTooltip.buildInfoTooltip(
      context,
      showIcon: false,
      richText: RichText(
        text: TextSpan(
          style: CoconutTypography.body2_14.setColor(CoconutColors.black),
          children: [
            const TextSpan(text: '\u2022 ', style: CoconutTypography.body1_16),
            TextSpan(text: t.coordinator_bsms_qr_screen.guide.text1),
            const TextSpan(text: '\n\u2022 ', style: CoconutTypography.body1_16),
            TextSpan(text: t.coordinator_bsms_qr_screen.guide.text2),
          ],
        ),
      ),
    );
  }
}
