import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/taproot/taproot_sign_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_check_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_qr_code_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/providers/view_model/airgap/taproot/taproot_musig2_sign_session.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/assignable_pill_button.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:coconut_vault/widgets/tooltip/error_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class TaprootSignScreen extends StatefulWidget {
  const TaprootSignScreen({super.key});

  @override
  State<TaprootSignScreen> createState() => _TaprootSignScreenState();
}

class _TaprootSignScreenState extends State<TaprootSignScreen> {
  // TAPROOT: ViewModel 타입 변경
  late TaprootSignViewModel _viewModel;
  late BitcoinUnit _currentUnit;
  bool _showLoading = false;
  bool _showFullAddress = false;
  // MuSig2 First Signer 흐름에서 nonce 생성 시 획득한 Seed를 BottomSheet 닫힌 후 localSign 단계까지 보유.
  // ViewModel보다 생명주기가 짧은 State에 두어 화면 종료 시 dispose()에서 wipe() 보장.
  // step == localNonceCreated(재진입) 시에는 _getSeed() 재호출 없이 이 값을 재사용.
  Seed? _pendingSeed;
  bool _isCupertinoLoadingShown = false;
  bool _isFinalizeLoadingDialogShown = false;
  String _cupertinoLoadingMessage = '';

  @override
  void initState() {
    super.initState();
    _currentUnit = context.read<VisibilityProvider>().currentUnit;
    _viewModel = TaprootSignViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<SignProvider>(context, listen: false),
      Provider.of<PreferenceProvider>(context, listen: false).isSigningOnlyMode,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _viewModel.initPsbtSignState();
      } catch (e) {
        if (!mounted) return;
        showAlertDialog(
          context: context,
          content: e.toString(),
          onConfirmPressed: () {
            Navigator.pop(context);
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _pendingSeed?.wipe();
    _pendingSeed = null;
    super.dispose();
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
      // TAPROOT: Provider/Consumer 타입을 TaprootSignViewModel로 변경
      child: ChangeNotifierProvider<TaprootSignViewModel>(
        create: (_) => _viewModel,
        child: Consumer<TaprootSignViewModel>(
          builder:
              (context, viewModel, child) => Scaffold(
                backgroundColor: CoconutColors.white,
                appBar: CoconutAppBar.build(
                  title: t.sign,
                  context: context,
                  onBackPressed: _onBackPressed,
                  backgroundColor: CoconutColors.white,
                  actionButtonList: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/svg/leave.svg',
                          colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                        ),
                        highlightColor: CoconutColors.gray200,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => CoconutPopup(
                                  languageCode: context.read<VisibilityProvider>().language,
                                  title: t.alert.exit_sign.title,
                                  description: t.alert.exit_sign.description,
                                  backgroundColor: CoconutColors.white,
                                  leftButtonText: t.no,
                                  leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
                                  rightButtonText: t.yes,
                                  rightButtonColor: CoconutColors.warningText,
                                  onTapLeft: () => Navigator.pop(context),
                                  onTapRight: () {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  },
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CoconutLayout.spacing_600h,
                            if (viewModel.exceptionMessage?.isNotEmpty == true)
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width * 0.9,
                                child: ErrorTooltip(isShown: true, errorMessage: '${viewModel.exceptionMessage}'),
                              ),
                            _buildSendInfo(),
                            // MuSig2 가이드 문구
                            if (viewModel.isInitialized &&
                                viewModel.signType == TaprootSignType.musig2KeyPath &&
                                !viewModel.isMusig2Completed()) ...[
                              CoconutLayout.spacing_100h,
                              CustomTooltip.buildInfoTooltip(
                                context,
                                richText: RichText(
                                  text: TextSpan(
                                    style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
                                    children: _getMusig2GuideTextSpan(),
                                  ),
                                ),
                                backgroundColor: CoconutColors.white,
                                borderColor: CoconutColors.black,
                              ),
                            ] else
                              CoconutLayout.spacing_1300h,

                            if (viewModel.exceptionMessage?.isNotEmpty != true &&
                                !(viewModel.isInitialized && viewModel.signType == TaprootSignType.musig2KeyPath))
                              Text(
                                viewModel.isSignatureCompleted
                                    ? t.sign_completed
                                    : t.sign_required_amount(n: viewModel.remainingSignatures),
                                style: CoconutTypography.body1_16_Bold,
                                textAlign: TextAlign.center,
                              ),
                            CoconutLayout.spacing_600h,
                            _buildSignerList(),
                            CoconutLayout.spacing_2500h,
                          ],
                        ),
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
                      Visibility(
                        visible: _isCupertinoLoadingShown,
                        child: Container(
                          decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                          child: Center(
                            child: MessageActivityIndicator(
                              message: _cupertinoLoadingMessage,
                              isCupertinoIndicator: true,
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 45),
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

  Widget _buildSendInfo() {
    final addressPostfix =
        _viewModel.recipientCount > 1 ? '\n${t.extra_count(count: _viewModel.recipientCount - 1)}' : '';
    final address =
        _showFullAddress
            ? _viewModel.firstRecipientAddress
            : '${_viewModel.firstRecipientAddress.substring(0, 11)}...${_viewModel.firstRecipientAddress.substring(_viewModel.firstRecipientAddress.length - 8)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0), color: CoconutColors.gray150),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(t.recipient, style: CoconutTypography.body2_14.setColor(CoconutColors.gray700)),
                    ),
                    CoconutLayout.spacing_400w,
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _showFullAddress = !_showFullAddress;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(sizeFactor: animation, axisAlignment: 1.0, child: child),
                              );
                            },
                            child: Align(
                              key: ValueKey('$_showFullAddress$address'),
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$address$addressPostfix',
                                textAlign: TextAlign.end,
                                style: CoconutTypography.body2_14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                CoconutLayout.spacing_100h,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(t.send_amount, style: CoconutTypography.body2_14.setColor(CoconutColors.gray700)),
                    ),
                    CoconutLayout.spacing_400w,
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _toggleUnit();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _currentUnit.displayBitcoinAmount(_viewModel.sendingAmount, withUnit: true),
                            textAlign: TextAlign.end,
                            style: CoconutTypography.body2_14_Number,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignerList() {
    return Column(
      children: [
        for (int index = 0; index < _viewModel.signers.length; index++) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              // TAPROOT: signer 모델이 TaprootParticipant 로 변경됨
              final signer = _viewModel.signers[index];
              // TAPROOT: 내부 서명 가능 여부 = 이 지갑에 해당 participant의 seed가 저장되어 있는지
              final isInnerWallet = signer.isSeedStored;
              // TAPROOT: 이름 대신 masterFingerprint 노출 (외부 signer 이름 개념 없음)
              final mfp = signer.masterFingerprint;
              final isSignerApproved = _viewModel.signersApproved[index];

              final iconPath =
                  isSignerApproved ? 'assets/svg/check-circle-green.svg' : 'assets/svg/check-circle-outlined.svg';

              final iconColorFilter =
                  isSignerApproved ? null : const ColorFilter.mode(CoconutColors.gray300, BlendMode.srcIn);

              final iconWidget = AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
                },
                child: SvgPicture.asset(
                  iconPath,
                  width: 24.0,
                  colorFilter: iconColorFilter,
                  key: ValueKey<bool>(isSignerApproved),
                ),
              );

              final buttonText = '$mfp - ${_viewModel.getSignerButtonText(index, isSignerApproved, isInnerWallet)}';

              return AssignablePillButton(
                width: MediaQuery.sizeOf(context).width * 0.9,
                isAssigned: isSignerApproved,
                iconWidget: iconWidget,
                text: buttonText,
                activeColor: const Color(0xFF88C125),
                isDisabled: (!isInnerWallet && !isSignerApproved),
                onPressed: () async {
                  if (_viewModel.exceptionMessage?.isNotEmpty == true) return;
                  if (isSignerApproved) {
                    return;
                  }

                  // TAPROOT: 서명 불가능한 지갑/PSBT 조합이면 서명 진행 차단 (요구사항 2-2, 2-4)
                  if (_viewModel.canSign != true) {
                    return;
                  }

                  if (isInnerWallet) {
                    if (_viewModel.signType == TaprootSignType.musig2KeyPath) {
                      _runMusig2SignFlow(index);
                    } else {
                      _signByInnerWallet(index);
                    }
                    return;
                  }
                },
              );
            },
          ),
          CoconutLayout.spacing_500h,
        ],
      ],
    );
  }

  // MARK - getSeed

  /// PassphraseCheckScreen 내부에서 인증까지 완료함
  Future<Seed?> _authenticateWithPassphrase({required BuildContext context, required int index}) async {
    // Taproot 서명 시 특정 서명자의 seed가 필요하므로 targetXpub 전달
    final signers = _viewModel.signers;
    final String? targetXpub = index < signers.length ? signers[index].extendedPublicKey : null;
    if (targetXpub?.isNotEmpty != true) {
      throw StateError('targetXpub is empty');
    }

    return await MyBottomSheet.showBottomSheet_ratio(
      ratio: 0.5,
      context: context,
      child: PassphraseCheckScreen(
        id: _viewModel.vaultId,
        context: PassphraseCheckContext.sign,
        targetXpub: targetXpub,
      ),
    );
  }

  Future<bool?> _authenticateWithoutPassphrase() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()) {
      return true;
    }
    if (mounted) {
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

    return false;
  }

  void _askIfSureToGoBack() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().language,
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.stop_sign.title,
          description: t.alert.stop_sign.description,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapLeft: () => Navigator.pop(context),
          onTapRight: () {
            _viewModel.clearSignedResultInSignProvider();
            Navigator.pop(context); // 1) close dialog
            Navigator.pop(context); // 2) go back
          },
        );
      },
    );
  }

  Future<Seed?> _getSeedInSigningOnlyMode(int index) async {
    return await _viewModel.getSeedInSigningOnlyMode(index);
  }

  Future<Seed?> _getSeedInStorageMode(int index) async {
    if (_viewModel.getHasPassphrase(index)) {
      return await _authenticateWithPassphrase(context: context, index: index);
    } else {
      final authenticateResult = await _authenticateWithoutPassphrase();
      if (authenticateResult != true) return null;
      return Seed.fromMnemonic(await _viewModel.getSecret(index));
    }
  }

  Future<Seed?> _getSeed(int index) async {
    try {
      if (_viewModel.isSigningOnlyMode) {
        return await _getSeedInSigningOnlyMode(index);
      } else {
        return await _getSeedInStorageMode(index);
      }
    } on UserCanceledAuthException catch (_) {
      return null;
    } on SeedInvalidatedException catch (e) {
      if (!mounted) return null;
      showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
              languageCode: context.read<VisibilityProvider>().language,
              title: t.exceptions.seed_invalidated.title,
              description: e.message,
              onTapRight: () => Navigator.pop(context),
            ),
      );
      return null;
    }
  }

  // MARK - common

  void _onBackPressed() {
    if (_viewModel.signersApproved.where((bool isApproved) => isApproved).isNotEmpty) {
      _askIfSureToGoBack();
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> _checkCompletedAndGoNext({
    bool shouldPopBeforeNavigate = false,
    bool isMusig2SecondSigner = false,
  }) async {
    if (!_viewModel.isSignatureCompleted) return false;

    if (shouldPopBeforeNavigate) {
      if (mounted) {
        Navigator.pop(context);
      } else {
        return false;
      }
    }

    setState(() {
      _cupertinoLoadingMessage = t.multisig_sign_screen.creating_qr_code;
      _isCupertinoLoadingShown = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isCupertinoLoadingShown = false;
    });
    _viewModel.saveSignedResult();

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.signedTransaction,
        arguments:
            isMusig2SecondSigner ? {'tooltipText': t.taproot_sign_screen.musig2_sign.guide.first_sign_completed} : null,
      );
      return true;
    }
    return false;
  }

  // MARK - TaprootSignType singleKeyPath & scriptPath

  Future<void> _signByInnerWallet(int index) async {
    assert(_viewModel.signType != TaprootSignType.musig2KeyPath);

    final seed = await _getSeed(index);
    if (seed == null) return;

    try {
      setState(() => _showLoading = true);
      await _viewModel.sign(index, seed);
      await _checkCompletedAndGoNext();
    } catch (error) {
      if (mounted) {
        showAlertDialog(context: context, content: t.errors.sign_error(error: error));
      }
    } finally {
      setState(() => _showLoading = false);
      seed.wipe();
    }
  }

  /// MARK - TaprootSignType musig2
  Future<void> _runMusig2SignFlow(int index) async {
    assert(_viewModel.signType == TaprootSignType.musig2KeyPath);

    if (_viewModel.isMusig2FirstSigner(index)) {
      // First Signer 흐름: nonce 생성 → QR 공유 → remote nonce 수신 → partial sig → QR 공유 → aggregation
      await _runSignFlowAsFirstSigner(index);
    } else {
      // Second Signer 흐름: 첫 번째 폰 PSBT 수신 → nonce + partial sig 한 번에 → QR 공유
      await _runSignFlowAsSecondSigner(index);
    }
  }

  Future<void> _showMusig2PsbtQrCodeBottomSheet({
    required String qrData,
    required List<TextSpan> guideRichText,
    String? appBarTitle,
    required String buttonText,
    required void Function(NavigatorState navigator) onButtonPressed,
  }) async {
    final innerNavKey = GlobalKey<NavigatorState>();
    await MyBottomSheet.showBottomSheet_95(
      context: context,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (innerNavKey.currentState?.canPop() == true) {
            innerNavKey.currentState!.pop();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Navigator(
          key: innerNavKey,
          onGenerateRoute:
              (settings) => MaterialPageRoute(
                builder:
                    (innerContext) => PsbtQrCodeScreen(
                      qrData: qrData,
                      guideRichText: guideRichText,
                      appBarTitle: appBarTitle,
                      buttonText: buttonText,
                      onButtonPressed: () {
                        onButtonPressed(Navigator.of(innerContext));
                      },
                    ),
              ),
        ),
      ),
    );
  }

  /// 두 번째 Signer의 PSBT 스캔 콜백 핸들러
  Future<void> _handleSecondSignerPsbtScanned(String scannedData) async {
    assert(_pendingSeed != null, '_pendingSeed must be set in _runSignFlowAsFirstSigner');

    try {
      setState(() => _showLoading = true);
      _showFinalizeLoadingDialog();
      await _viewModel.musig2FirstSignerFinalize(scannedData, _pendingSeed!);
      _hideFinalizeLoadingDialog();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final title = e is FormatException ? t.taproot_sign_screen.exceptions.update_sign_fail : t.errors.sign_failed;
      if (mounted) {
        _hideFinalizeLoadingDialog();
        setState(() => _showLoading = false);
        await showAlertDialog(context: context, title: title, content: e is FormatException ? e.message : e.toString());
      }
    } finally {
      _hideFinalizeLoadingDialog();
      if (mounted) setState(() => _showLoading = false);
    }
  }

  void _showFinalizeLoadingDialog() {
    if (!mounted || _isFinalizeLoadingDialogShown) return;
    _isFinalizeLoadingDialogShown = true;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: CoconutColors.black.withValues(alpha: 0.3),
      builder: (_) => const PopScope(canPop: false, child: Center(child: CoconutCircularIndicator())),
    ).then((_) {
      _isFinalizeLoadingDialogShown = false;
    });
  }

  void _hideFinalizeLoadingDialog() {
    if (!mounted || !_isFinalizeLoadingDialogShown) return;
    Navigator.of(context, rootNavigator: true).pop();
    _isFinalizeLoadingDialogShown = false;
  }

  /// 두 번째 Signer의 PSBT 스캔 화면 생성
  /// INFO: 닫을 필요가 없는 화면에어서 왼상단에 닫기 버튼 안보임
  Widget _buildSecondSignerScanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: PsbtScannerScreen(
        id: _viewModel.vaultId,
        hardwareWalletType: HardwareWalletType.coconutVault,
        appBarTitle: t.taproot_sign_screen.musig2_sign.appbar_title.update_sign,
        tooltipRichText: [
          TextSpan(
            text: t.taproot_sign_screen.musig2_sign.guide.scan_other_signer_qr,
            style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
          ),
        ],
        onMultisigPsbtScanned: _handleSecondSignerPsbtScanned,
      ),
    );
  }

  /// MuSig2 First Signer: nonce 생성 → QR 공유 → 두 번째 폰 QR 스캔 → aggregation 완성
  Future<void> _runSignFlowAsFirstSigner(int index) async {
    final step = _viewModel.musig2SignSession!.firstSignerStep;
    assert(step == TaprootMusig2FirstSignerStep.none || step == TaprootMusig2FirstSignerStep.localNonceCreated);

    String? nonceAddedPsbt;
    try {
      // 2. nonce 생성 (PSBT에 자신의 nonce만 추가됨)
      if (step == TaprootMusig2FirstSignerStep.none) {
        final seed = await _getSeed(index);
        if (seed == null) return;
        _pendingSeed = seed;

        setState(() => _showLoading = true);
        nonceAddedPsbt = await _viewModel.musig2FirstSignerCreateNonce(index, seed);
        setState(() => _showLoading = false);
      } else {
        nonceAddedPsbt = _viewModel.musig2SignSession!.currentPsbt;
      }

      await _showMusig2PsbtQrCodeBottomSheet(
        qrData: nonceAddedPsbt,
        guideRichText: [TextSpan(text: t.taproot_sign_screen.musig2_sign.guide.scan_with_other_signer)],
        appBarTitle: t.taproot_sign_screen.musig2_sign.appbar_title.sign_with_other_signer,
        buttonText: t.next,
        onButtonPressed: (navigator) {
          navigator.push(MaterialPageRoute(builder: (_) => _buildSecondSignerScanner()));
        },
      );
      final isCompleted = await _checkCompletedAndGoNext();
      if (isCompleted) {
        _pendingSeed?.wipe();
        _pendingSeed = null;
      }
    } catch (error) {
      if (mounted) {
        showAlertDialog(context: context, content: t.errors.sign_error(error: error));
      }
    } finally {
      if (mounted) setState(() => _showLoading = false);
    }
  }

  /// MuSig2 Second Signer: 첫 번째 폰 QR(PSBT) 스캔 → nonce + partial sig 생성 → QR(PSBT) 공유 → 완성된 PSBT 수신
  Future<void> _runSignFlowAsSecondSigner(int index) async {
    final step = _viewModel.musig2SignSession!.secondSignerStep;
    assert(step == TaprootMusig2SecondSignerStep.remoteNonceCreated);
    Seed? seed;
    try {
      seed = await _getSeed(index);
      if (seed == null) return;

      setState(() => _showLoading = true);
      await _viewModel.musig2SecondSignerSign(seed);
      seed.wipe();
      seed = null;
      setState(() => _showLoading = false);
      await _checkCompletedAndGoNext(isMusig2SecondSigner: true);
    } catch (error) {
      if (mounted) {
        showAlertDialog(context: context, content: t.errors.sign_error(error: error));
      }
    } finally {
      seed?.wipe();
      if (mounted) setState(() => _showLoading = false);
    }
  }

  List<TextSpan> _getMusig2GuideTextSpan() {
    final session = _viewModel.musig2SignSession;
    if (session == null) return [];

    if (session.isFirstSigner) {
      if (session.firstSignerStep == TaprootMusig2FirstSignerStep.none) {
        return [TextSpan(text: t.taproot_sign_screen.musig2_sign.guide.please_bring_key)];
      } else {
        return [TextSpan(text: t.taproot_sign_screen.musig2_sign.guide.please_do_next)];
      }
    } else {
      return [TextSpan(text: t.taproot_sign_screen.musig2_sign.guide.please_sign)];
    }
  }

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == BitcoinUnit.btc ? BitcoinUnit.sats : BitcoinUnit.btc;
    });
  }
}
