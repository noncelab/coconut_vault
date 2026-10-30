import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/multisig_signer_bsms_export_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:coconut_vault/widgets/qr_with_copy_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignerBsmsQrScreen extends StatefulWidget {
  final int id;
  final WalletApp app;

  const SignerBsmsQrScreen({super.key, required this.id, this.app = WalletApp.coconut});

  @override
  State<SignerBsmsQrScreen> createState() => _SignerBsmsQrScreenState();
}

class _SignerBsmsQrScreenState extends State<SignerBsmsQrScreen> {
  late MultisigSignerBsmsExportViewModel _viewModel;
  late final BcUrQrViewHandler? _sparrowQr;

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
                qrData: _sparrowQr != null ? null : _exportText,
                qrViewDataHandler: _sparrowQr,
                textData: _exportText,
                tooltipDescription: _buildDescription(),
                textRichText: widget.app == WalletApp.coconut ? _getCopyTextRichText() : null,
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

  String get _exportText => switch (widget.app) {
    WalletApp.coconut => _viewModel.qrData,
    WalletApp.bluewallet => _viewModel.blueWalletCosigner,
    WalletApp.nunchuk || WalletApp.sparrow => _viewModel.signerDescriptor,
  };

  String get _appGuide => switch (widget.app) {
    WalletApp.coconut => t.signer_bsms_screen.coconut_guide,
    WalletApp.nunchuk => t.signer_bsms_screen.nunchuk_guide,
    WalletApp.sparrow => t.signer_bsms_screen.sparrow_guide,
    WalletApp.bluewallet => t.signer_bsms_screen.bluewallet_guide,
  };

  Widget _buildDescription() {
    return CustomTooltip.buildInfoTooltip(
      context,
      richText: RichText(
        text: TextSpan(
          style: CoconutTypography.body2_14.setColor(CoconutColors.black),
          children: [TextSpan(text: _appGuide)],
        ),
      ),
    );
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
    _sparrowQr =
        widget.app == WalletApp.sparrow && _viewModel.bsms != null
            ? BcUrQrViewHandler(_viewModel.sparrowAccount, UrType.cryptoAccount)
            : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewModel.errorMessage.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return CoconutPopup(
              languageCode: context.read<VisibilityProvider>().appLanguage.code,
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
