import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/icon_path.dart';
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
import 'package:coconut_vault/screens/common/select_external_wallet_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_check_screen.dart';
import 'package:coconut_vault/screens/airgap/multisig_psbt_qr_code_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/coconut/transaction_util.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/assignable_pill_button.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:coconut_vault/widgets/tooltip/error_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// TAPROOT: MultisigSignScreen을 복사하여 Taproot(P2TR) 서명에 맞게 수정.
//   - 멀티시그 BSMS QR 가져오기 흐름(_showDialogForImportMultisig 등)은 Taproot에 해당 없음 → 제거
//   - 서명자(signer) 모델이 MultisigSigner -> TaprootParticipant 로 변경됨
//   - canSign(서명 가능/불가능) 상태에 따라 서명 버튼 노출/비활성화 처리 추가
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
  bool _isCupertinoLoadingShown = false;
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

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == BitcoinUnit.btc ? BitcoinUnit.sats : BitcoinUnit.btc;
    });
  }

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
      // TAPROOT: Taproot는 signer별 innerVaultId가 없으므로 지갑 id를 사용.
      //   participant 단위 passphrase 인증이 필요한 경우 PassphraseCheckScreen의 Taproot 대응 필요.
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

  Future<void> _signByInnerWallet(int index) async {
    if (!_viewModel.isSigningOnlyMode) {
      // 안전 저장 모드
      await _addSignatureToPsbtInStorageMode(index);
    } else {
      // 서명 전용 모드
      await _addSignatureToPsbtInSigningOnlyMode(index);
    }
  }

  Future<void> _addSignatureToPsbtInStorageMode(int index) async {
    Seed? seed;
    if (_viewModel.getHasPassphrase(index)) {
      seed = await _authenticateWithPassphrase(context: context, index: index);

      if (seed == null) {
        return;
      }
    } else {
      final authenticateResult = await _authenticateWithoutPassphrase();
      if (authenticateResult != true) {
        return;
      }
      try {
        // TAPROOT: participant의 seed를 secure storage(extendedPublicKey 키)에서 조회
        seed = Seed.fromMnemonic(await _viewModel.getSecret(index));
      } on UserCanceledAuthException catch (_) {
        return;
      } catch (e) {
        if (!mounted) return;
        showAlertDialog(context: context, content: t.errors.sign_error(error: e));
        return;
      }
    }

    await _addSignatureToPsbt(index, seed);
    seed.wipe();
  }

  /// @param index: signer index
  Future<void> _addSignatureToPsbt(int index, Seed seed) async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.sign(index, seed);
      await _checkCompletedAndGoNext();
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

  Future<void> _addSignatureToPsbtInSigningOnlyMode(int index) async {
    try {
      setState(() {
        _showLoading = true;
      });

      await _viewModel.signPsbtInSigningOnlyMode(index);
      await _checkCompletedAndGoNext();
    } on UserCanceledAuthException catch (_) {
      return;
    } on SeedInvalidatedException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
              languageCode: context.read<VisibilityProvider>().language,
              title: t.exceptions.seed_invalidated.title,
              description: e.message,
              onTapRight: () {
                Navigator.pop(context);
              },
            ),
      );
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

  Future<bool> _checkCompletedAndGoNext({bool shouldPopBeforeNavigate = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
      Navigator.pushReplacementNamed(context, AppRoutes.signedTransaction);
      return true;
    }
    return false;
  }

  // TAPROOT: 멀티시그 BSMS(다중서명 지갑 정보) QR 가져오기 흐름은 Taproot에 해당 없음.
  //   기존 _showDialogForImportMultisig / _showMultisigBsmsQrCodeBottomSheet 제거.

  void _showPsbtQrCodeBottomSheet(HardwareWalletType hwwType, {int? signerIndex}) {
    // TAPROOT: signer 모델이 TaprootParticipant 이므로 keyStore 대신 masterFingerprint 직접 사용
    final masterFingerprint = signerIndex != null ? _viewModel.signers[signerIndex].masterFingerprint : null;
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: PsbtQrCodeViewScreen(
        multisigName: _viewModel.walletName,
        index: signerIndex,
        signedRawTx: _viewModel.psbtForSigning,
        hardwareWalletType: hwwType,
        masterFingerprint: masterFingerprint,
        onNextPressed:
            signerIndex == null
                ? null
                : () async {
                  Navigator.pop(context); // 현재 다이얼로그 닫기

                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  _showPsbtScannerBottomSheet(signerIndex: signerIndex);
                },
      ),
    );
  }

  /// signerIndex == null : 화면 하단 'QR 스캔하기' 버튼을 누른 경우
  /// signerIndex != null : SignerList 중 하나를 눌러 서명하기 진행하는 경우
  void _showPsbtScannerBottomSheet({int? signerIndex}) {
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: PsbtScannerScreen(
          id: _viewModel.vaultId,
          hardwareWalletType: HardwareWalletType.coconutVault,
          onMultisigPsbtScanned: (String scannedData) async {
            try {
              bool isRawTxHexString = isRawTransactionHexString(scannedData);
              if (isRawTxHexString) {
                _viewModel.validateRawSignedTransaction(scannedData);
                _viewModel.saveSignedRawTxHex(scannedData);
              } else {
                _viewModel.onScannedPsbt(scannedData, isOverwrite: signerIndex == null);
              }

              bool navigated = false;
              navigated = await _checkCompletedAndGoNext(shouldPopBeforeNavigate: true);

              // 서명이 모두 완료되어 화면 전환이 일어난 경우에는 추가 pop을 하지 않는다.
              if (navigated) {
                return;
              }

              if (!mounted) return;
              Navigator.pop(context);

              // 바텀시트가 닫힌 후 서명 정보 업데이트 완료 안내
              if (signerIndex == null && mounted) {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CoconutPopup(
                      languageCode: context.read<VisibilityProvider>().language,
                      title: t.multisig_sign_screen.dialog.signature_update.title,
                      description: t.multisig_sign_screen.dialog.signature_update.description,
                      onTapRight: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }
            } on FormatException catch (e) {
              if (!mounted) return;
              await showInfoPopup(
                context,
                signerIndex != null
                    ? t.multisig_sign_screen.dialog.signature_failed.title
                    : t.multisig_sign_screen.dialog.signature_update_failed.title,
                e.message,
              );
              if (mounted) {
                Navigator.of(context).pop(); // close this bottom sheet
              }
              return;
            }
          },
        ),
      ),
    );
  }

  Future<HardwareWalletType?> _showHardwareSelectionBottomSheet({int? index, bool isFromBottomButton = false}) async {
    // 하단의 'QR 스캔하기'로 들어온 경우 index는 null

    HardwareWalletType? hwwType;

    final iconSourceList = [
      kCoconutVaultIconPath,
      kKeystoneIconPath,
      kSeedSignerIconPath,
      kJadeIconPath,
      kColdCardIconPath,
      kKruxIconPath,
    ];

    final externalWalletButtonList = [
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.coconut_vault, iconSource: iconSourceList[0]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.keystone3pro, iconSource: iconSourceList[1]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.seed_signer, iconSource: iconSourceList[2]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.jade, iconSource: iconSourceList[3]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.cold_card, iconSource: iconSourceList[4]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_signer.krux, iconSource: iconSourceList[5]),
    ];
    await MyBottomSheet.showDraggableBottomSheet<HardwareWalletType?>(
      context: context,
      showDragHandle: false,
      maxChildSize: 0.45,
      minChildSize: 0.2,
      initialChildSize: 0.45,
      childBuilder:
          (context) => SelectExternalWalletBottomSheet(
            title:
                index == null
                    ? t.multisig_sign_screen.select_signer_hardware_wallet
                    : t.multi_sig_setting_screen.add_signer.title,
            externalWalletButtonList: externalWalletButtonList,
            showConfirmDialog: !isFromBottomButton,
            selectedIndex: null,
            onSelected: (selectedIndex) {
              hwwType = HardwareWalletTypeExtension.getHardwareWalletTypeByIconPath(iconSourceList[selectedIndex]);
            },
          ),
    );
    return hwwType;
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
                            CoconutLayout.spacing_1300h,
                            // TAPROOT: 서명 불가능한 지갑/PSBT 조합이면 안내 문구 노출 (요구사항 2-2, 2-4)
                            if (viewModel.exceptionMessage?.isNotEmpty != true)
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
                      if (viewModel.isInitialized && viewModel.signType == TaprootSignType.musig2KeyPath) _buildBottomButtons(),
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

  @override
  void dispose() {
    super.dispose();
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

              final buttonText =
                  '$mfp - ${isSignerApproved
                      ? t.sign_completion
                      : isInnerWallet
                      ? t.sign
                      : t.add_sign}';

              return AssignablePillButton(
                width: MediaQuery.sizeOf(context).width * 0.9,
                isAssigned: isSignerApproved,
                iconWidget: iconWidget,
                text: buttonText,
                activeColor: const Color(0xFF88C125),
                onPressed: () async {
                  if (_viewModel.exceptionMessage?.isNotEmpty == true) return;
                  if (isSignerApproved) {
                    return;
                  }

                  // TAPROOT: 서명 불가능한 지갑/PSBT 조합이면 서명 진행 차단 (요구사항 2-2, 2-4)
                  if (_viewModel.canSign != true) {
                    return;
                  }

                  // TAPROOT: seed가 저장되어 있으면 내부 지갑으로 바로 서명
                  if (isInnerWallet) {
                    _signByInnerWallet(index);
                    return;
                  }

                  // TAPROOT: seed가 저장되어 있지 않은 participant는 외부 하드웨어 QR 흐름으로 처리
                  //   (멀티시그 BSMS 가져오기 흐름은 제거하고 PSBT QR 내보내기/스캔만 사용)
                  final hwwType = await _showHardwareSelectionBottomSheet(index: index);
                  if (hwwType == null) return;

                  setState(() {
                    _cupertinoLoadingMessage = t.multisig_sign_screen.loading_overlay;
                    _isCupertinoLoadingShown = true;
                  });

                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    setState(() {
                      _isCupertinoLoadingShown = false;
                    });
                  }
                  _showPsbtQrCodeBottomSheet(hwwType, signerIndex: index);
                },
              );
            },
          ),
          CoconutLayout.spacing_500h,
        ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    // TAPROOT: Selector 타입을 TaprootSignViewModel로 변경
    return Selector<TaprootSignViewModel, bool>(
      selector: (_, viewModel) => viewModel.isSignatureCompleted,
      builder: (context, isSignatureComplete, child) {
        return FixedBottomTweenButton(
          leftButtonClicked: () async {
            final hwwType = await _showHardwareSelectionBottomSheet(isFromBottomButton: true);
            if (hwwType != null) {
              _showPsbtQrCodeBottomSheet(hwwType);
            }
          },
          rightButtonClicked: () async {
            final hwwType = await _showHardwareSelectionBottomSheet(isFromBottomButton: true);
            if (hwwType != null) {
              _showPsbtScannerBottomSheet();
            }
          },
          leftText: t.export_qr,
          rightText: t.scan_qr,
          leftButtonBackgroundColor: CoconutColors.white,
          rightButtonBackgroundColor: CoconutColors.white,
          leftButtonTextColor: CoconutColors.black,
          rightButtonTextColor: CoconutColors.black,
          leftButtonBorderColor: CoconutColors.gray400,
          rightButtonBorderColor: CoconutColors.gray400,
          leftButtonPressedBackgroundColor: CoconutColors.gray200,
          rightButtonPressedBackgroundColor: CoconutColors.gray200,
        );
      },
    );
  }
}
