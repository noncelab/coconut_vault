import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/taproot_sync_qr_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text.dart';
import 'package:coconut_vault/widgets/tooltip_description.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaprootSyncQrScreen extends StatelessWidget {
  final int id;

  const TaprootSyncQrScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaprootSyncQrViewModel(Provider.of<WalletProvider>(context, listen: false), id),
      child: Consumer<TaprootSyncQrViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: CoconutColors.white,
            child: QrWithCopyTextScreen(
              title: t.taproot.sync_qr_screen.title,
              tooltipDescription: _buildQrDescription(),
              qrData: viewModel.qrData,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQrDescription() {
    return Container(
      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(children: [tooltipDescription(t.taproot.sync_qr_screen.description)]),
    );
  }
}
