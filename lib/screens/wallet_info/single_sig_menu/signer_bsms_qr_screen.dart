import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/multisig_signer_bsms_export_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignerBsmsQrScreen extends StatefulWidget {
  final int id;

  const SignerBsmsQrScreen({super.key, required this.id});

  @override
  State<SignerBsmsQrScreen> createState() => _SignerBsmsQrScreenState();
}

class _SignerBsmsQrScreenState extends State<SignerBsmsQrScreen> {
  late MultisigSignerBsmsExportViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultisigSignerBsmsExportViewModel>(
      create: (_) => _viewModel,
      child: Consumer<MultisigSignerBsmsExportViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              QrWithCopyTextScreen(
                title: viewModel.name,
                qrData: viewModel.qrData,
                tooltipDescription: _buildDescription(),
                textRichText: _getCopyTextRichText(),
              ),
              Visibility(
                visible: viewModel.isLoading,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(color: CoconutColors.gray150),
                  child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescription() {
    return CustomTooltip.buildInfoTooltip(
      context,
      richText: RichText(
        text: TextSpan(
          style: CoconutTypography.body2_14.setColor(CoconutColors.black),
          children: _getTooltipRichText(),
        ),
      ),
    );
  }

  List<TextSpan> _getTooltipRichText() {
    final basicStyle = CoconutTypography.body2_14.setColor(CoconutColors.black);

    return [
      TextSpan(text: t.signer_bsms_screen.guide1_1, style: basicStyle),
      const TextSpan(text: ' '),
      TextSpan(text: t.signer_bsms_screen.guide1_2, style: basicStyle),
    ];
  }

  RichText _getCopyTextRichText() {
    final basicStyle = CoconutTypography.body2_14.setColor(CoconutColors.black);
    final bsms = _viewModel.bsms;
    if (bsms == null) return RichText(text: TextSpan(text: '', style: basicStyle));
    return RichText(
      text: TextSpan(
        text: "${bsms.version}\n${bsms.secretToken}\n[",
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.normal,
          fontSize: 12,
          height: 1.4,
          letterSpacing: 0.5,
          color: CoconutColors.black,
        ),
        children: <TextSpan>[
          TextSpan(text: bsms.signer!.masterFingerPrint, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '/${bsms.signer!.path}]${bsms.signer!.extendedPublicKey.serialize()}\n'),
          TextSpan(text: bsms.signer!.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MultisigSignerBsmsExportViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewModel.errorMessage.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return CoconutPopup(
              languageCode: context.read<VisibilityProvider>().language,
              title: t.multisig_signer_bsms_export_screen.fail_bsms,
              description: _viewModel.errorMessage,
              leftButtonText: t.cancel,
              rightButtonText: t.confirm,
              onTapRight: () => Navigator.pop(context),
            );
          },
        );
      }
    });
  }
}
