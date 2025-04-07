import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/single_sig_sign_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/unit_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SingleSigSignScreen extends StatefulWidget {
  const SingleSigSignScreen({
    super.key,
  });

  @override
  State<SingleSigSignScreen> createState() => _SingleSigSignScreenState();
}

class _SingleSigSignScreenState extends State<SingleSigSignScreen> {
  late SingleSigSignViewModel _viewModel;

  bool _showLoading = false;
  bool _isProgressCompleted = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SingleSigSignViewModel(
        Provider.of<WalletProvider>(context, listen: false),
        Provider.of<SignProvider>(context, listen: false));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_viewModel.isAlreadySigned) {
        _viewModel.updateSignState();
      }
    });
  }

  void _signStep1() {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          isDeleteScreen: true,
          onComplete: () {
            Navigator.pop(context);
            _signStep2();
          },
        ),
      ),
    );
  }

  void _signStep2() async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.sign();
      _viewModel.updateSignState();
    } catch (_) {
      if (mounted) {
        showAlertDialog(
            context: context, content: t.errors.sign_error(error: _));
      }
    } finally {
      setState(() {
        _showLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SingleSigSignViewModel>(
      create: (_) => _viewModel,
      child: Consumer<SingleSigSignViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          backgroundColor: MyColors.lightgrey,
          appBar: CustomAppBar.buildWithNext(
              title: t.sign,
              context: context,
              onBackPressed: () {
                viewModel.resetSignProvider();
                Navigator.pop(context);
              },
              onNextPressed: () {
                Navigator.pushNamed(context, AppRoutes.signedTransaction);
              },
              isActive: viewModel.requiredSignatureCount ==
                  viewModel.signersApproved
                      .where((bool isApproved) => isApproved)
                      .length,
              backgroundColor: MyColors.lightgrey,
              hasBackdropFilter: false),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // progress
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: viewModel.signersApproved
                                .where((item) => item)
                                .length /
                            viewModel.requiredSignatureCount,
                      ),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, child) {
                        if (value == 1.0) {
                          _isProgressCompleted = true;
                        } else {
                          _isProgressCompleted = false;
                        }
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: MyColors.transparentBlack_06,
                            borderRadius: _isProgressCompleted
                                ? BorderRadius.zero
                                : const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6)),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                MyColors.black),
                          ),
                        );
                      },
                    ),
                    // 보낼 수량
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        viewModel.requiredSignatureCount <=
                                viewModel.signersApproved
                                    .where((item) => item)
                                    .length
                            ? (viewModel.isAlreadySigned
                                ? t.single_sig_sign_screen.text
                                : t.sign_completed)
                            : t.sign_required(
                                count: viewModel.requiredSignatureCount -
                                    viewModel.signersApproved
                                        .where((item) => item)
                                        .length),
                        style: Styles.body2Bold,
                      ),
                    ),
                    // 보낼 주소
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 32, left: 25, right: 25),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.recipient,
                                style: Styles.body2
                                    .copyWith(color: MyColors.grey57),
                              ),
                              Text(
                                textAlign: TextAlign.end,
                                TextUtils.truncateNameMax25(
                                        viewModel.firstRecipientAddress) +
                                    (viewModel.recipientCount > 1
                                        ? '\n${t.extra_count(count: viewModel.recipientCount - 1)}'
                                        : ''),
                                style: Styles.body1,
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.send_amount,
                                style: Styles.body2
                                    .copyWith(color: MyColors.grey57),
                              ),
                              Text(
                                '${satoshiToBitcoinString(viewModel.sendingAmount)} ${t.btc}',
                                style: Styles.balance2.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Signer List
                    Container(
                      margin:
                          const EdgeInsets.only(top: 32, left: 20, right: 20),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: MyBorder.defaultRadius,
                              color: MyColors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: index == 0 ? 22 : 18,
                                    bottom: index == 1 ? 22 : 18,
                                  ),
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: BackgroundColorPalette[
                                                  viewModel.walletColorIndex],
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            child: SvgPicture.asset(
                                              CustomIcons.getPathByIndex(
                                                  viewModel.walletIconIndex),
                                              colorFilter: ColorFilter.mode(
                                                ColorPalette[
                                                    viewModel.walletColorIndex],
                                                BlendMode.srcIn,
                                              ),
                                              width: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(viewModel.walletName,
                                                  style: Styles.body2),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      if (viewModel.isApproved(index)) ...{
                                        Row(
                                          children: [
                                            Text(
                                              t.sign_completion,
                                              style: Styles.body1Bold.copyWith(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                            const SizedBox(width: 4),
                                            SvgPicture.asset(
                                              'assets/svg/circle-check.svg',
                                              width: 12,
                                            ),
                                          ],
                                        ),
                                      } else ...{
                                        GestureDetector(
                                          onTap: _signStep1,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: MyColors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                  color: MyColors.black19,
                                                  width: 1),
                                            ),
                                            child: Center(
                                              child: Text(
                                                t.signature,
                                                style: Styles.caption.copyWith(
                                                    color: MyColors
                                                        .black19), // 텍스트 색상도 검정으로 변경
                                              ),
                                            ),
                                          ),
                                        ),
                                      },
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: _showLoading,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                        color: MyColors.transparentBlack_30),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: MyColors.darkgrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
