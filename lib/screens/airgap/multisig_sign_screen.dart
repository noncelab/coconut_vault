import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/multisig_sign_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/airgap/multisig_signer_qr_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_menu/info/passphrase_check_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
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
  late BitcoinUnit _currentUnit;
  bool _showLoading = false;
  bool _isProgressCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentUnit = context.read<VisibilityProvider>().currentUnit;
    _viewModel = MultisigSignViewModel(Provider.of<WalletProvider>(context, listen: false),
        Provider.of<SignProvider>(context, listen: false));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _viewModel.initPsbtSignState();
    });
  }

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == BitcoinUnit.btc ? BitcoinUnit.sats : BitcoinUnit.btc;
    });
  }

  /// PassphraseCheckScreen 내부에서 인증까지 완료함
  Future<String?> _authenticateWithPassphrase({
    required BuildContext context,
    required int index,
  }) async {
    return await MyBottomSheet.showBottomSheet_ratio(
      ratio: 0.5,
      context: context,
      child: PassphraseCheckScreen(id: _viewModel.getInnerVaultId(index)),
    );
  }

  Future<bool?> _authenticateWithoutPassphrase() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid()) {
      return true;
    }

    return await MyBottomSheet.showBottomSheet_90<bool>(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onSuccess: () {
            Navigator.pop(context, true);
            return true;
          },
        ),
      ),
    );
  }

  Future<void> _sign(bool isKeyInsideVault, int index) async {
    if (isKeyInsideVault) {
      String? validPassphrase;
      if (_viewModel.getHasPassphrase(index)) {
        validPassphrase = await _authenticateWithPassphrase(context: context, index: index);

        if (validPassphrase == null) {
          return;
        }
      } else {
        final authenticateResult = await _authenticateWithoutPassphrase();
        if (authenticateResult != true) {
          return;
        }
      }

      await _addSignatureToPsbt(index, validPassphrase ?? "");
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CoconutPopup(
              insetPadding:
                  EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
              title: t.move_to_qr_screen,
              titleTextStyle: CoconutTypography.body1_16_Bold,
              description: t.move_to_qr_screen_description,
              descriptionTextStyle: CoconutTypography.body2_14,
              backgroundColor: CoconutColors.white,
              rightButtonText: t.confirm,
              rightButtonColor: CoconutColors.black,
              rightButtonTextStyle: CoconutTypography.body2_14.merge(
                const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTapRight: () {
                Navigator.pop(context);
                _showQrBottomSheet(index);
              },
            );
          });
    }
  }

  /// @param index: signer index
  Future<void> _addSignatureToPsbt(int index, String passphrase) async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.sign(index, passphrase);
    } catch (_) {
      if (mounted) {
        showAlertDialog(context: context, content: t.errors.sign_error(error: _));
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
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: t.alert.exit_sign.title,
            titleTextStyle: CoconutTypography.body1_16_Bold,
            description: t.alert.exit_sign.description,
            descriptionTextStyle: CoconutTypography.body2_14,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonTextStyle: CoconutTypography.body2_14.merge(
              TextStyle(
                color: CoconutColors.black.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            rightButtonText: t.quit,
            rightButtonColor: CoconutColors.warningText,
            rightButtonTextStyle: CoconutTypography.body2_14.merge(
              const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              _viewModel.resetAll();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          );
        });
  }

  void _askIfSureToGoBack() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: t.alert.stop_sign.title,
            titleTextStyle: CoconutTypography.body1_16_Bold,
            description: t.alert.stop_sign.description,
            descriptionTextStyle: CoconutTypography.body2_14,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonTextStyle: CoconutTypography.body2_14.merge(
              TextStyle(
                color: CoconutColors.black.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            rightButtonText: t.quit,
            rightButtonColor: CoconutColors.warningText,
            rightButtonTextStyle: CoconutTypography.body2_14.merge(
              const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              _viewModel.reset();
              Navigator.pop(context); // 1) close dialog
              Navigator.pop(context); // 2) go back
            },
          );
        });
  }

  void _onBackPressed() {
    if (_viewModel.signersApproved.where((bool isApproved) => isApproved).isNotEmpty) {
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
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.sign,
              context: context,
              onBackPressed: _onBackPressed,
              backgroundColor: CoconutColors.white,
            ),
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
                          end: viewModel.signersApproved.where((item) => item).length /
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
                              backgroundColor: CoconutColors.black.withOpacity(0.06),
                              borderRadius: _isProgressCompleted
                                  ? BorderRadius.zero
                                  : const BorderRadius.only(
                                      topRight: Radius.circular(6),
                                      bottomRight: Radius.circular(6)),
                              valueColor: const AlwaysStoppedAnimation<Color>(CoconutColors.black),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: Text(
                          viewModel.isSignatureComplete
                              ? t.sign_completed
                              : t.sign_required_amount(n: viewModel.remainingSignatures),
                          style: CoconutTypography.heading4_18_Bold,
                        ),
                      ),
                      CoconutLayout.spacing_600h,
                      _buildSendInfo(),
                      CoconutLayout.spacing_1400h,
                      _buildSignerList(),
                    ],
                  ),
                  _buildBottomButtons(),
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSendInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CoconutColors.gray150,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.recipient,
                style: CoconutTypography.body2_14.setColor(CoconutColors.gray700),
              ),
              Text(
                textAlign: TextAlign.end,
                TextUtils.truncateNameMax25(_viewModel.firstRecipientAddress) +
                    (_viewModel.recipientCount > 1
                        ? '\n${t.extra_count(count: _viewModel.recipientCount - 1)}'
                        : ''),
                style: CoconutTypography.body1_16,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.send_amount,
                style: CoconutTypography.body2_14.setColor(CoconutColors.gray700),
              ),
              GestureDetector(
                onTap: _toggleUnit,
                child: Text(
                  _currentUnit.displayBitcoinAmount(_viewModel.sendingAmount, withUnit: true),
                  style: CoconutTypography.body1_16_Number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignerList() {
    return Column(
      children: [
        for (int index = 0; index < _viewModel.signers.length; index++) ...[
          LayoutBuilder(builder: (context, constraints) {
            final signer = _viewModel.signers[index];
            final isInnerWallet = signer.innerVaultId != null;
            final name = signer.name ?? t.external_wallet;
            final memo = signer.memo;
            final iconIndex = signer.iconIndex ?? 0;
            final colorIndex = _viewModel.signers[index].colorIndex ?? 0;
            final isSignerApproved = _viewModel.signersApproved[index];
            return ShrinkAnimationButton(
              onPressed: () {
                if (isSignerApproved) {
                  return;
                }
                _sign(isInnerWallet, index);
              },
              defaultColor: isSignerApproved
                  ? isInnerWallet
                      ? CoconutColors.backgroundColorPaletteLight[colorIndex]
                      : CoconutColors.backgroundColorPaletteLight[8]
                  : CoconutColors.white,
              pressedColor: isSignerApproved
                  ? isInnerWallet
                      ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                      : CoconutColors.backgroundColorPaletteLight[8].withAlpha(70)
                  : CoconutColors.gray150,
              borderRadius: 100,
              borderWidth: 1,
              border: Border.all(
                color: isSignerApproved
                    ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                    : CoconutColors.gray200,
                width: 1,
              ),
              child: Container(
                width: 210,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      isInnerWallet
                          ? CustomIcons.getPathByIndex(iconIndex)
                          : 'assets/svg/qr-code.svg',
                      colorFilter: ColorFilter.mode(
                        isInnerWallet
                            ? CoconutColors.colorPalette[colorIndex]
                            : CoconutColors.black,
                        BlendMode.srcIn,
                      ),
                      width: 14.0,
                    ),
                    CoconutLayout.spacing_300w,
                    Flexible(
                      child: Text(
                        t.multisig.nth_key_with_name(
                            name: isInnerWallet ? name : memo ?? t.external_wallet,
                            index: index + 1),
                        style: CoconutTypography.body1_16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          CoconutLayout.spacing_500h,
        ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Selector<MultisigSignViewModel, bool>(
        selector: (_, viewModel) => viewModel.isSignatureComplete,
        builder: (context, isSignatureComplete, child) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: ShrinkAnimationButton(
                          defaultColor: CoconutColors.gray300,
                          onPressed: _askIfSureToQuit,
                          borderRadius: CoconutStyles.radius_200,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              t.abort,
                              style: CoconutTypography.body2_14_Bold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    CoconutLayout.spacing_200w,
                    Flexible(
                      flex: 2,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: ShrinkAnimationButton(
                          isActive: isSignatureComplete,
                          disabledColor: CoconutColors.gray150,
                          defaultColor: CoconutColors.black,
                          onPressed: () {
                            _viewModel.saveSignedPsbt();
                            Navigator.pushNamed(context, AppRoutes.signedTransaction);
                          },
                          borderRadius: CoconutStyles.radius_200,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              t.next,
                              style: CoconutTypography.body2_14_Bold.setColor(
                                isSignatureComplete ? CoconutColors.white : CoconutColors.gray350,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
