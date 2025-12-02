import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/coordinator_bsms_qr_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text.dart';
import 'package:coconut_vault/widgets/tooltip_description.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoordinatorBsmsQrScreen extends StatelessWidget {
  final int id;

  const CoordinatorBsmsQrScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CoordinatorBsmsQrViewModel(Provider.of<WalletProvider>(context, listen: false), id),
      child: Consumer<CoordinatorBsmsQrViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: CoconutColors.white,
            child: QrWithCopyTextScreen(
              title: t.multi_sig_setting_screen.export_menu.share_bsms,
              tooltipDescription: _buildDescriptionBsms(viewModel),
              qrData: viewModel.qrData,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionBsms(CoordinatorBsmsQrViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          tooltipDescription(t.coordinator_bsms_qr_screen.guide.text1),
          const SizedBox(height: 4),
          tooltipDescription(t.coordinator_bsms_qr_screen.guide.text2),
        ],
      ),
    );
  }
}
