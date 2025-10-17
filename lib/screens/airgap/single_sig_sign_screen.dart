import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/single_sig_sign_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/passphrase_check_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SingleSigSignScreen extends StatefulWidget {
  const SingleSigSignScreen({super.key});

  @override
  State<SingleSigSignScreen> createState() => _SingleSigSignScreenState();
}

class _SingleSigSignScreenState extends State<SingleSigSignScreen> {
  late SingleSigSignViewModel _viewModel;
  late BitcoinUnit _currentUnit;

  bool _showLoading = false;
  bool _isProgressCompleted = false;
  bool _showFullAddress = false;

  @override
  void initState() {
    super.initState();
    _currentUnit = context.read<VisibilityProvider>().currentUnit;
    _viewModel = SingleSigSignViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<SignProvider>(context, listen: false),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_viewModel.isAlreadySigned) {
        _viewModel.updateSignState();
      }
    });
  }

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == BitcoinUnit.btc ? BitcoinUnit.sats : BitcoinUnit.btc;
    });
  }

  /// PassphraseCheckScreen 내부에서 인증까지 완료함
  Future<String?> _authenticateWithPassphrase({required BuildContext context}) async {
    return await MyBottomSheet.showBottomSheet_ratio(
      ratio: 0.5,
      context: context,
      child: PassphraseCheckScreen(id: _viewModel.walletId),
    );
  }

  Future<bool?> _authenticateWithoutPassphrase() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid()) {
      return true;
    }

    if (!mounted) return false;
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

  Future<void> _sign() async {
    Uint8List validPassphrase = utf8.encode('');
    if (_viewModel.hasPassphrase) {
      validPassphrase = utf8.encode(await _authenticateWithPassphrase(context: context) ?? '');

      if (validPassphrase.isEmpty) {
        return;
      }
    } else {
      final authenticateResult = await _authenticateWithoutPassphrase();
      if (authenticateResult != true) {
        return;
      }
    }

    await _addSignatureToPsbt(validPassphrase);
    validPassphrase.wipe();
  }

  Future<void> _addSignatureToPsbt(Uint8List passphrase) async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.sign(passphrase: passphrase);
    } catch (error) {
      if (mounted) {
        showAlertDialog(context: context, content: t.errors.sign_error(error: error));
      }
    } finally {
      setState(() {
        _showLoading = false;
      });
    }
  }

  void _askIfSureToQuit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.exit_sign.title,
          description: t.alert.exit_sign.description,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapLeft: () => Navigator.pop(context),
          onTapRight: () {
            _viewModel.resetSignProvider();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SingleSigSignViewModel>(
      create: (_) => _viewModel,
      child: Consumer<SingleSigSignViewModel>(
        builder:
            (context, viewModel, child) => Scaffold(
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(
                title: t.sign,
                context: context,
                onBackPressed: () {
                  viewModel.resetSignProvider();
                  Navigator.pop(context);
                },
                backgroundColor: CoconutColors.white,
              ),
              body: SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 보낼 수량
                          Padding(
                            padding: const EdgeInsets.only(top: 36, left: 16, right: 16),
                            child: Text(
                              viewModel.isSignerApproved
                                  ? (viewModel.isAlreadySigned ? t.single_sig_sign_screen.text : t.sign_completed)
                                  : t.one_sign_guide,
                              style: CoconutTypography.heading4_18_Bold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          CoconutLayout.spacing_600h,
                          _buildSendInfo(),
                          CoconutLayout.spacing_1400h,
                          _buildSignerList(),
                          CoconutLayout.spacing_2500h,
                        ],
                      ),
                    ),
                    _buildBottomButtons(),
                    _buildProgressIndicator(),
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
            ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: _viewModel.isSignerApproved ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          if (value == 1.0) {
            _isProgressCompleted = true;
          } else {
            _isProgressCompleted = false;
          }
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: CoconutColors.black.withValues(alpha: 0.06),
            borderRadius:
                _isProgressCompleted
                    ? BorderRadius.zero
                    : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
            valueColor: const AlwaysStoppedAnimation<Color>(CoconutColors.black),
          );
        },
      ),
    );
  }

  Widget _buildSendInfo() {
    final addressPostfix =
        _viewModel.recipientCount > 1 ? '\n${t.extra_count(count: _viewModel.recipientCount - 1)}' : '';
    final address =
        _showFullAddress
            ? _viewModel.firstRecipientAddress
            : '${_viewModel.firstRecipientAddress.substring(0, 6)}...${_viewModel.firstRecipientAddress.substring(_viewModel.firstRecipientAddress.length - 6)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          color: CoconutColors.black.withValues(alpha: 0.03),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              InformationItemCard(
                label: t.recipient,
                value: ['$address$addressPostfix'],
                isNumber: true,
                onPressed: () {
                  setState(() {
                    _showFullAddress = !_showFullAddress;
                  });
                },
              ),
              const Divider(color: CoconutColors.borderLightGray, height: 1),
              InformationItemCard(
                label: t.send_amount,
                value: [_currentUnit.displayBitcoinAmount(_viewModel.sendingAmount, withUnit: true)],
                isNumber: true,
                onPressed: _toggleUnit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignerList() {
    final colorIndex = _viewModel.walletColorIndex;
    final iconIndex = _viewModel.walletIconIndex;
    final name =
        _viewModel.walletName.length > 6 ? '${_viewModel.walletName.substring(0, 6)}...' : _viewModel.walletName;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return ShrinkAnimationButton(
              onPressed: () {
                if (_viewModel.isSignerApproved) {
                  return;
                }
                _sign();
              },
              defaultColor:
                  _viewModel.isSignerApproved
                      ? CoconutColors.backgroundColorPaletteLight[colorIndex]
                      : CoconutColors.white,
              pressedColor:
                  _viewModel.isSignerApproved
                      ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                      : CoconutColors.gray150,
              borderRadius: 100,
              borderWidth: 1,
              border: Border.all(
                color:
                    _viewModel.isSignerApproved
                        ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                        : CoconutColors.gray300,
                width: 1,
              ),
              child: SizedBox(
                width: 210,
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CoconutLayout.spacing_400w,
                    SvgPicture.asset(
                      CustomIcons.getPathByIndex(iconIndex),
                      colorFilter: ColorFilter.mode(CoconutColors.colorPalette[colorIndex], BlendMode.srcIn),
                      width: 14.0,
                    ),
                    CoconutLayout.spacing_300w,
                    MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: Text(
                        '$name - ${_viewModel.isSignerApproved ? t.sign_completion : t.sign}',
                        style: CoconutTypography.body1_16,
                      ),
                    ),
                    CoconutLayout.spacing_400w,
                  ],
                ),
              ),
            );
          },
        ),
        CoconutLayout.spacing_500h,
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Selector<SingleSigSignViewModel, bool>(
      selector: (_, viewModel) => viewModel.isSignerApproved,
      builder: (context, isSignatureComplete, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: 50,
                      child: ShrinkAnimationButton(
                        defaultColor: CoconutColors.gray300,
                        pressedColor: CoconutColors.gray200,
                        onPressed: _askIfSureToQuit,
                        borderRadius: CoconutStyles.radius_200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(t.abort, style: CoconutTypography.body2_14_Bold, textAlign: TextAlign.center),
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
                      height: 50,
                      child: ShrinkAnimationButton(
                        isActive: isSignatureComplete,
                        disabledColor: CoconutColors.gray150,
                        defaultColor: CoconutColors.black,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.signedTransaction);
                        },
                        pressedColor: CoconutColors.gray400,
                        borderRadius: CoconutStyles.radius_200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
