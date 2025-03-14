import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/multisig_sign_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/airgap/multisig_signer_qr_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/utils/unit_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
// 서명 가져오기 때 사용했던 화면
//import 'package:coconut_vault/screens/airgap/multisig_signer_scan_bottom_sheet.dart';

class MultisigSignScreen extends StatefulWidget {
  const MultisigSignScreen({
    super.key,
  });

  @override
  State<MultisigSignScreen> createState() => _MultisigSignScreenState();
}

class _MultisigSignScreenState extends State<MultisigSignScreen> {
  late MultisigSignViewModel _viewModel;
  late int _requiredSignatureCount;
  bool _showLoading = false;
  bool _isProgressCompleted = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MultisigSignViewModel(
        Provider.of<WalletProvider>(context, listen: false),
        Provider.of<SignProvider>(context, listen: false));
    _requiredSignatureCount = _viewModel.requiredSignatureCount;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _viewModel.initPsbtSignState();
    });
  }

  void _signStep1(bool isKeyInsideVault, int index) {
    if (isKeyInsideVault) {
      MyBottomSheet.showBottomSheet_90(
        context: context,
        child: CustomLoadingOverlay(
          child: PinCheckScreen(
            pinCheckContext: PinCheckContextEnum.sensitiveAction,
            isDeleteScreen: true,
            onComplete: () {
              Navigator.pop(context);
              _signStep2(index);
            },
          ),
        ),
      );
    } else {
      _showQrBottomSheet(index);
    }
  }

  /// @param index: signer index
  void _signStep2(int index) async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.sign(index);
      _viewModel.updateSignState(index);
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

  void _showQrBottomSheet(int index) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: SignerQrBottomSheet(
        multisigName: _viewModel.walletName,
        keyIndex: '${index + 1}',
        signedRawTx: _viewModel.psbtForSigning,
      ),
    );
  }

  void _askIfSureToQuit() {
    CustomDialogs.showCustomAlertDialog(context,
        title: t.alert.exit_sign.title,
        message: t.alert.exit_sign.description,
        confirmButtonText: t.quit,
        confirmButtonColor: MyColors.warningText,
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          _viewModel.resetAll();
          Navigator.popUntil(context, (route) => route.isFirst);
        });
  }

  void _askIfSureToGoBack() {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: t.alert.stop_sign.title,
      message: t.alert.stop_sign.description,
      confirmButtonText: t.quit,
      confirmButtonColor: MyColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        _viewModel.reset();
        Navigator.pop(context); // 1) close dialog
        Navigator.pop(context); // 2) go back
      },
    );
  }

  void _onBackPressed() {
    if (_viewModel.signersApproved
        .where((bool isApproved) => isApproved)
        .isNotEmpty) {
      _askIfSureToGoBack();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: ChangeNotifierProvider<MultisigSignViewModel>(
        create: (_) => _viewModel,
        child: Consumer<MultisigSignViewModel>(
          builder: (context, viewModel, child) => Scaffold(
            backgroundColor: MyColors.lightgrey,
            appBar: CustomAppBar.buildWithNext(
                title: t.sign,
                context: context,
                onBackPressed: _onBackPressed,
                onNextPressed: () {
                  _viewModel.saveSignedPsbt();
                  Navigator.pushNamed(context, AppRoutes.signedTransaction);
                },
                isActive: viewModel.isSignatureComplete,
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
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          viewModel.isSignatureComplete
                              ? t.sign_completed
                              : '${viewModel.remainingSignatures}개의 서명이 필요합니다',
                          style: Styles.body2Bold,
                        ),
                      ),
                      // 보낼 주소
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 32, left: 20, right: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                ),
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
                          itemCount: viewModel.signers.length,
                          itemBuilder: (context, index) {
                            final signer = viewModel.signers[index];
                            final length = viewModel.signers.length - 1;
                            final isInnerWallet = signer.innerVaultId != null;
                            final name = signer.name ?? t.external_wallet;
                            final memo = signer.memo ?? '';
                            final iconIndex = signer.iconIndex ?? 0;
                            final colorIndex =
                                viewModel.signers[index].colorIndex ?? 0;

                            return Container(
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(index == 0 ? 19 : 0),
                                  topRight:
                                      Radius.circular(index == 0 ? 19 : 0),
                                  bottomLeft:
                                      Radius.circular(index == length ? 19 : 0),
                                  bottomRight:
                                      Radius.circular(index == length ? 19 : 0),
                                ),
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
                                      bottom: index == length ? 22 : 18,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                              '${t.multisig.nth_key(index: index + 1)} -',
                                              style: Styles.body1),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(
                                                  isInnerWallet ? 10 : 12),
                                              decoration: BoxDecoration(
                                                color: isInnerWallet
                                                    ? BackgroundColorPalette[
                                                        colorIndex]
                                                    : MyColors.grey236,
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              child: SvgPicture.asset(
                                                isInnerWallet
                                                    ? CustomIcons
                                                        .getPathByIndex(
                                                            iconIndex)
                                                    : 'assets/svg/download.svg',
                                                colorFilter: ColorFilter.mode(
                                                  isInnerWallet
                                                      ? ColorPalette[colorIndex]
                                                      : MyColors.black,
                                                  BlendMode.srcIn,
                                                ),
                                                width: isInnerWallet ? 20 : 15,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: Styles.body2),
                                                if (memo.isNotEmpty) ...{
                                                  Text(
                                                    memo,
                                                    style: Styles.caption2
                                                        .copyWith(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                }
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        if (viewModel
                                            .signersApproved[index]) ...{
                                          Row(
                                            children: [
                                              Text(
                                                t.sign_completion,
                                                style: Styles.body1Bold
                                                    .copyWith(
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
                                        } else if (_requiredSignatureCount >
                                            viewModel.signersApproved
                                                .where((item) => item)
                                                .length) ...{
                                          GestureDetector(
                                            onTap: () {
                                              _signStep1(isInnerWallet, index);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
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
                                  if (index < length) ...{
                                    const Divider(
                                        color: MyColors.divider, height: 1),
                                  }
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      // 종료, 서명 업데이트 버튼
                      CupertinoButton(
                          padding: const EdgeInsets.only(bottom: 50),
                          onPressed: _askIfSureToQuit,
                          child: Text(
                            t.stop_sign,
                            style: Styles.tertiaryButtonText,
                          )),
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // '서명 가져오기' 버튼이 있었는데 제거함
  // void _showScannerBottomSheet() {
  //   MyBottomSheet.showBottomSheet_90(
  //     context: context,
  //     child: SignerScanBottomSheet(
  //       onScanComplete: (signedRawTx) {
  //         _vaultModel.signedRawTx = signedRawTx;
  //         _checkSignedPsbt(signedRawTx);
  //         setState(() {});
  //       },
  //     ),
  //   );
  // }
}
