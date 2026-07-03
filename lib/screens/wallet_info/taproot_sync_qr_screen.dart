import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/taproot_sync_qr_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text.dart';
import 'package:coconut_vault/widgets/tooltip_description.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaprootSyncQrScreen extends StatelessWidget {
  final int id;

  const TaprootSyncQrScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaprootSyncQrViewModel(context.read<WalletProvider>(), id),
      child: Consumer<TaprootSyncQrViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: CoconutColors.white,
            child: QrWithCopyTextScreen(
              title: t.taproot.sync_qr_screen.title,
              tooltipDescription: _buildQrDescription(context),
              qrData: viewModel.qrData,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQrDescription(BuildContext context) {
    final language = Provider.of<VisibilityProvider>(context, listen: false).appLanguage.code;

    return CustomTooltip.buildInfoTooltip(
      context,
      richText: RichText(
        text: TextSpan(
          style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
          children: _getCoconutGuide(language),
        ),
      ),
    );
  }

  List<TextSpan> _getCoconutGuide(String language) {
    if (language == 'en') {
      return [
        em(t.taproot.sync_qr_screen.coconut_vault),
        const TextSpan(text: '\n1. '),
        TextSpan(text: t.select),
        em(t.taproot.sync_qr_screen.guide.coconut),
        const TextSpan(text: '\n2. '),
        TextSpan(text: t.taproot.sync_qr_screen.guide.inheritance),
        const TextSpan(text: '\n'),
        TextSpan(text: t.taproot.sync_qr_screen.guide.common),
      ];
    }
    return [
      em(t.taproot.sync_qr_screen.coconut_vault),
      const TextSpan(text: '\n1. '),
      em(t.taproot.sync_qr_screen.guide.coconut),
      TextSpan(text: t.select),
      const TextSpan(text: '\n2. '),
      TextSpan(text: t.taproot.sync_qr_screen.guide.inheritance),
      const TextSpan(text: '\n'),
      TextSpan(text: t.taproot.sync_qr_screen.guide.common),
    ];
  }
}
