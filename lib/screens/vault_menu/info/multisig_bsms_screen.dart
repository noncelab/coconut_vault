import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/multisig_bsms_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultisigBsmsScreen extends StatelessWidget {
  final int id;

  const MultisigBsmsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MultisigBsmsViewModel(Provider.of<WalletProvider>(context, listen: false), id),
      child: Consumer<MultisigBsmsViewModel>(
        builder: (context, viewModel, child) {
          final qrWidth = MediaQuery.of(context).size.width * 0.76;

          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.multi_sig_bsms_screen.title,
              context: context,
              isBottom: false,
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Description
                  _buildDescriptionBsms(viewModel),
                  CoconutLayout.spacing_300h,
                  Center(
                    child: Container(
                      width: qrWidth,
                      decoration: CoconutBoxDecoration.shadowBoxDecoration,
                      child: QrImageView(data: viewModel.qrData),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionBsms(MultisigBsmsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _description(t.multi_sig_bsms_screen.guide.text1),
          const SizedBox(height: 4),
          if (viewModel.outsideWalletIdList.isEmpty) ...[
            _description(t.multi_sig_bsms_screen.guide.text2),
            const SizedBox(height: 4),
            _description(t.multi_sig_bsms_screen.guide.text3),
          ] else ...{
            _description(
              t.multi_sig_bsms_screen.guide.text4(gen: viewModel.generateOutsideWalletDescription(isAnd: true)),
            ),
            const SizedBox(height: 4),
            _description(t.multi_sig_bsms_screen.guide.text5(gen: viewModel.generateOutsideWalletDescription())),
          },
        ],
      ),
    );
  }

  Widget _description(String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text('•', style: CoconutTypography.body2_14),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: CoconutTypography.body2_14.setColor(CoconutColors.black),
              children: _parseDescription(description),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _parseDescription(String description) {
    // ** 로 감싸져 있는 문구 볼트체 적용
    List<TextSpan> spans = [];
    description.split("**").asMap().forEach((index, part) {
      spans.add(
        TextSpan(text: part, style: index.isEven ? CoconutTypography.body2_14 : CoconutTypography.body2_14_Bold),
      );
    });
    return spans;
  }
}
