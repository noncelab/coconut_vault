import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_confirmation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/card/send_transaction_flow_card.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:coconut_vault/widgets/send_amount_header.dart';
import 'package:coconut_vault/widgets/send_output_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:provider/provider.dart';

class PsbtConfirmationScreen extends StatefulWidget {
  const PsbtConfirmationScreen({super.key});

  @override
  State<PsbtConfirmationScreen> createState() => _PsbtConfirmationScreenState();
}

class _PsbtConfirmationScreenState extends State<PsbtConfirmationScreen> {
  late PsbtConfirmationViewModel _viewModel;
  late BitcoinUnit _currentUnit;
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel = PsbtConfirmationViewModel(
      Provider.of<SignProvider>(context, listen: false),
      Provider.of<VisibilityProvider>(context, listen: false),
    );
    _currentUnit = context.read<VisibilityProvider>().isBtcUnit ? BitcoinUnit.btc : BitcoinUnit.sats;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _viewModel.setTxInfo();
      } catch (e) {
        if (mounted) {
          showAlertDialog(
            context: context,
            content: t.errors.psbt_parsing_error(error: e),
            onConfirmPressed: () {
              Navigator.pop(context);
            },
          );
        }
      } finally {
        if (mounted) {
          setState(() => _showLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PsbtConfirmationViewModel>(
      create: (_) => _viewModel,
      child: Consumer<PsbtConfirmationViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.psbt_confirmation_screen.title,
              context: context,
              onBackPressed: () {
                viewModel.resetSignProvider();
                Navigator.pop(context);
              },
              isBottom: true,
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        CustomTooltip.buildInfoTooltip(
                          context,
                          richText: RichText(
                            text: TextSpan(style: CoconutTypography.body3_12, children: _getTooltipRichText()),
                          ),
                        ),
                        SendAmountHeader(
                          amountText: _currentUnit.displayBitcoinAmount(viewModel.sendingAmount),
                          unitText: _currentUnit.symbol,
                          satoshiAmount: viewModel.sendingAmount ?? 0,
                          totalCostAmountText: _currentUnit.displayBitcoinAmount(viewModel.totalAmount),
                          onTap: _toggleUnit,
                        ),
                        CoconutLayout.spacing_300h,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTransactionFlowCard(viewModel),
                        ),
                        CoconutLayout.spacing_500h,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildOutputDetailCard(viewModel),
                        ),
                        if (viewModel.isSendingToMyAddress) ...[
                          const SizedBox(height: 20),
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                            child: Text(
                              t.psbt_confirmation_screen.self_sending,
                              textAlign: TextAlign.center,
                              style: CoconutTypography.body3_12.setColor(CoconutColors.gray800),
                            ),
                          ),
                        ],
                        if (viewModel.hasWarning) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: CoconutPadding.widgetContainer,
                            decoration: BoxDecoration(
                              borderRadius: CoconutBorder.defaultRadius,
                              color: CoconutColors.black.withValues(alpha: 0.3),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                              child: Text(t.psbt_confirmation_screen.warning, textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                        CoconutLayout.spacing_2500h,
                      ],
                    ),
                  ),
                  FixedBottomButton(
                    text: t.next,
                    isActive: !_showLoading && viewModel.totalAmount != null,
                    onButtonClicked: () {
                      Navigator.pushNamed(context, viewModel.nextScreen);
                    },
                  ),
                  Visibility(
                    visible: _showLoading,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                      child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
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

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == BitcoinUnit.btc ? BitcoinUnit.sats : BitcoinUnit.btc;
    });
  }

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: t.psbt_confirmation_screen.guide,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }

  Widget _buildTransactionFlowCard(PsbtConfirmationViewModel viewModel) {
    final List<int?> inputAmounts = viewModel.inputs;

    final externalOutputAmounts =
        viewModel.outputs
            .where((output) => !viewModel.isChangeOutput(output))
            .map((output) => output.outAmount!)
            .toList();
    final changeOutputAmounts =
        viewModel.outputs.where(viewModel.isChangeOutput).map((output) => output.outAmount!).toList();

    return SendTransactionFlowCard(
      inputAmounts: inputAmounts,
      externalOutputAmounts: externalOutputAmounts,
      changeOutputAmounts: changeOutputAmounts,
      fee: viewModel.estimatedFee,
      currentUnit: _currentUnit,
    );
  }

  Widget _buildOutputDetailCard(PsbtConfirmationViewModel viewModel) {
    final detailItems = <OutputDetailItem>[];
    int outputIndex = 0;
    for (final output in viewModel.outputs) {
      final isChange = viewModel.isChangeOutput(output);
      if (!isChange) {
        outputIndex += 1;
      }
      detailItems.add(
        OutputDetailItem(
          label: isChange ? t.change : t.psbt_confirmation_screen.flow_output_title(index: outputIndex),
          address: output.outAddress,
          amountSats: output.outAmount!,
          isChange: isChange,
        ),
      );
    }

    return SendOutputDetailCard(items: detailItems, currentUnit: _currentUnit);
  }
}

// Future<String> addSignatureToPsbt(WalletBase vault, String data) async {
//   final addSignatureToPsbtHandler =
//       IsolateHandler<List<dynamic>, String>(addSignatureToPsbtIsolate);
//   try {
//     await addSignatureToPsbtHandler.initialize(
//         initialType: InitializeType.addSign);

//     String signedPsbt = await addSignatureToPsbtHandler.run([vault, data]);
//     Logger.log(signedPsbt);
//     return signedPsbt;
//   } catch (e) {
//     Logger.log('[addSignatureToPsbtIsolate] ${e.toString()}');
//     throw (e.toString());
//   } finally {
//     addSignatureToPsbtHandler.dispose();
//   }
// }
