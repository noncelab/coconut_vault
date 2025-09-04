import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/multisig_signer_bsms_export_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultisigSignerBsmsExportScreen extends StatefulWidget {
  final int id;

  const MultisigSignerBsmsExportScreen({super.key, required this.id});

  @override
  State<MultisigSignerBsmsExportScreen> createState() => _MultisigSignerBsmsExportScreenState();
}

class _MultisigSignerBsmsExportScreenState extends State<MultisigSignerBsmsExportScreen> {
  late MultisigSignerBsmsExportViewModel _viewModel;
  bool _isDialogShown = false; // 다이얼로그가 두 번 호출 되는 현상 방지

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultisigSignerBsmsExportViewModel>(
      create: (_) => _viewModel = MultisigSignerBsmsExportViewModel(
          Provider.of<WalletProvider>(context, listen: false), widget.id),
      child: Consumer<MultisigSignerBsmsExportViewModel>(
        builder: (context, viewModel, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_viewModel.isSignerBsmsSetFailed && !_isDialogShown) {
              _isDialogShown = true;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoAlertDialog(
                        title: Text(t.errors.export_error),
                        content: Text(_viewModel.errorMessage),
                        actions: <CupertinoDialogAction>[
                          CupertinoDialogAction(
                            onPressed: () {
                              viewModel.setSignerBsmsStatus(false);
                              _isDialogShown = false;
                              Navigator.pop(context);
                            },
                            child: Text(t.confirm),
                          ),
                        ]);
                  });
            }
          });

          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: viewModel.name,
              context: context,
            ),
            body: SafeArea(
              child: Stack(children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomTooltip.buildInfoTooltip(context,
                          richText: RichText(
                            text: TextSpan(
                              style: CoconutTypography.body3_12,
                              children: _getTooltipRichText(),
                            ),
                          )),
                      CoconutLayout.spacing_800h,
                      Center(
                          child: Container(
                              width: MediaQuery.of(context).size.width * 0.76,
                              decoration: CoconutBoxDecoration.shadowBoxDecoration,
                              child: QrImageView(
                                data: viewModel.qrData,
                              ))),
                      CoconutLayout.spacing_800h,
                      Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.74,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t.signer_bsms_screen.export_info,
                              style: CoconutTypography.body2_14_Bold,
                            ),
                          ),
                          CoconutLayout.spacing_300h,
                          if (viewModel.bsms != null) SignerBsmsInfoCard(bsms: viewModel.bsms!)
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                Visibility(
                    visible: viewModel.isLoading,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(color: CoconutColors.gray150),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: CoconutColors.gray800,
                        ),
                      ),
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: t.signer_bsms_screen.guide1_1,
        style: CoconutTypography.body2_14_Bold.copyWith(
          height: 1.2,
          letterSpacing: 0.5,
          color: CoconutColors.black,
        ),
      ),
      TextSpan(
        text: t.signer_bsms_screen.guide1_2,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_bsms_screen.guide1_3,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_bsms_screen.guide1_4,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_bsms_screen.guide1_5,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.signer_bsms_screen.guide1_6,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }
}
