import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_confirmation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:flutter_svg/svg.dart';
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
    _viewModel = PsbtConfirmationViewModel(Provider.of<SignProvider>(context, listen: false));
    _currentUnit = context.read<VisibilityProvider>().currentUnit;
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
              });
        }
      } finally {
        if (mounted) {
          setState(
            () => _showLoading = false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PsbtConfirmationViewModel>(
      create: (_) => _viewModel,
      child: Consumer<PsbtConfirmationViewModel>(builder: (context, viewModel, child) {
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
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                        child: CoconutToolTip(
                          backgroundColor: CoconutColors.gray100,
                          borderColor: CoconutColors.gray400,
                          icon: SvgPicture.asset(
                            'assets/svg/circle-info.svg',
                            colorFilter: const ColorFilter.mode(
                              CoconutColors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          tooltipType: CoconutTooltipType.fixed,
                          richText: RichText(
                            text: TextSpan(
                              style: CoconutTypography.body3_12,
                              children: _getTooltipRichText(),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleUnit,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: Sizes.size40),
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                text: _currentUnit.displayBitcoinAmount(viewModel.sendingAmount),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: ' ${_currentUnit.symbol}',
                                      style: CoconutTypography.heading4_18_Number),
                                ],
                              ),
                              style: CoconutTypography.heading1_32_Number.merge(
                                const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28.0),
                            color: CoconutColors.black.withOpacity(0.03),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                InformationItemCard(
                                  label: t.recipient,
                                  value: viewModel.recipientAddress,
                                  isNumber: true,
                                ),
                                const Divider(
                                  color: CoconutColors.borderLightGray,
                                  height: 1,
                                ),
                                InformationItemCard(
                                  label: t.estimated_fee,
                                  value: [
                                    _currentUnit.displayBitcoinAmount(viewModel.estimatedFee,
                                        withUnit: true)
                                  ],
                                  isNumber: true,
                                ),
                                const Divider(
                                  color: CoconutColors.borderLightGray,
                                  height: 1,
                                ),
                                InformationItemCard(
                                  label: t.total_amount,
                                  value: [
                                    _currentUnit.displayBitcoinAmount(viewModel.totalAmount,
                                        withUnit: true)
                                  ],
                                  isNumber: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (viewModel.isSendingToMyAddress) ...[
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          t.psbt_confirmation_screen.self_sending,
                          textAlign: TextAlign.center,
                          style: CoconutTypography.body3_12.setColor(
                            CoconutColors.gray800,
                          ),
                        ),
                      ],
                      if (viewModel.hasWarning) ...[
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          padding: CoconutPadding.widgetContainer,
                          decoration: BoxDecoration(
                              borderRadius: CoconutBorder.defaultRadius,
                              color: CoconutColors.black.withOpacity(0.3)),
                          child: Text(
                            t.psbt_confirmation_screen.warning,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FixedBottomButton(
                  text: t.next,
                  isActive: !_showLoading && viewModel.totalAmount != null,
                  onButtonClicked: () {
                    Navigator.pushNamed(
                      context,
                      viewModel.isMultisig ? AppRoutes.multisigSign : AppRoutes.singleSigSign,
                    );
                  },
                ),
                Visibility(
                  visible: _showLoading,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(color: CoconutColors.black.withOpacity(0.3)),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: CoconutColors.gray800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
        text: '[3] ',
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.psbt_confirmation_screen.guide,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
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
