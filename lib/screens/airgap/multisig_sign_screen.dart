import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/currency_enum.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/multisig_sign_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_info_qr_code_screen.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_check_screen.dart';
import 'package:coconut_vault/screens/airgap/multisig_psbt_qr_code_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/card/information_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultisigSignScreen extends StatefulWidget {
  const MultisigSignScreen({super.key});

  @override
  State<MultisigSignScreen> createState() => _MultisigSignScreenState();
}

class _MultisigSignScreenState extends State<MultisigSignScreen> {
  late MultisigSignViewModel _viewModel;
  late BitcoinUnit _currentUnit;
  bool _showLoading = false;
  bool _isProgressCompleted = false;
  bool _showFullAddress = false;

  @override
  void initState() {
    super.initState();
    _currentUnit = context.read<VisibilityProvider>().currentUnit;
    _viewModel = MultisigSignViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<SignProvider>(context, listen: false),
      Provider.of<PreferenceProvider>(context, listen: false).isSigningOnlyMode,
    );

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
  Future<Seed?> _authenticateWithPassphrase({required BuildContext context, required int index}) async {
    return await MyBottomSheet.showBottomSheet_ratio(
      ratio: 0.5,
      context: context,
      child: PassphraseCheckScreen(id: _viewModel.getInnerVaultId(index), context: PassphraseCheckContext.sign),
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

  Future<void> _sign(int index) async {
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
    } on UserCanceledAuthException catch (_) {
      return;
    } on SeedInvalidatedException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
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

  // TODO
  void _showDialogToMultisigInfoQrCode(int index, HardwareWalletType hwwType, String multisigInfoQrData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.multisig_sign_screen.dialog.title(name: hwwType.displayName),
          description: t.multisig_sign_screen.dialog.description(name: hwwType.displayName),
          backgroundColor: CoconutColors.white,
          leftButtonText: t.skip,
          rightButtonText: t.confirm,
          rightButtonColor: CoconutColors.black,
          onTapRight: () {
            Navigator.pop(context);
            // 하드월렛 추가 정보 QR 뷰 보여주기
            _showMultisigInfoQrCodeBottomSheet(index, hwwType, multisigInfoQrData);
          },
          onTapLeft: () {
            Navigator.pop(context);
            // PSBT QR 뷰 보여주기
            _showPsbtQrCodeBottomSheet(index, hwwType);
          },
        );
      },
    );
  }

  void _showMultisigInfoQrCodeBottomSheet(int index, HardwareWalletType hwwType, String multisigInfoQrData) {
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: MultisigQrCodeViewScreen(
        multisigName: _viewModel.walletName,
        keyIndex: '${index + 1}',
        signedRawTx: _viewModel.psbtForSigning,
        hardwareWalletType: hwwType,
        qrData: multisigInfoQrData,
      ),
    );
  }

  // TODO
  void _showPsbtQrCodeBottomSheet(int index, HardwareWalletType hwwType) {
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: PsbtQrCodeViewScreen(
        multisigName: _viewModel.walletName,
        keyIndex: '${index + 1}',
        signedRawTx: _viewModel.psbtForSigning,
        hardwareWalletType: hwwType,
      ),
    );
  }

  void _showHardwareSelectionBottomSheet() {
    // TODO: 하드웨어 선택 bottom sheet 보여주기
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
            _viewModel.resetAll();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
      },
    );
  }

  void _askIfSureToGoBack() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
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
            _viewModel.reset();
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
      child: ChangeNotifierProvider<MultisigSignViewModel>(
        create: (_) => _viewModel,
        child: Consumer<MultisigSignViewModel>(
          builder:
              (context, viewModel, child) => Scaffold(
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
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 36),
                              child: Text(
                                viewModel.isSignatureComplete
                                    ? t.sign_completed
                                    : t.sign_required_amount(n: viewModel.remainingSignatures),
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0.0,
          end: _viewModel.signersApproved.where((item) => item).length / _viewModel.requiredSignatureCount,
        ),
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
    return Column(
      children: [
        for (int index = 0; index < _viewModel.signers.length; index++) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final signer = _viewModel.signers[index];
              final isInnerWallet = signer.innerVaultId != null;
              final name = signer.name ?? t.external_wallet;
              final nameText = name.length > 6 ? '${name.substring(0, 6)}...' : name;
              final memo = signer.memo;
              final signerSource = signer.signerSource;
              final iconIndex = signer.iconIndex ?? 0;
              final colorIndex = _viewModel.signers[index].colorIndex ?? 0;
              final isSignerApproved = _viewModel.signersApproved[index];
              var hwwType = _viewModel.getSignerHwwType(index);

              return ShrinkAnimationButton(
                onPressed: () {
                  if (isSignerApproved) {
                    return;
                  }

                  if (isInnerWallet) {
                    _sign(index);
                    return;
                  }

                  // TODO:
                  // 외부에서 서명을 진행해야 하는 경우
                  if (hwwType == null) {
                    // 지정되어 있지 않으면 하드월렛 선택
                    _showHardwareSelectionBottomSheet();
                    // 화면 pop하면서 hww type 전달받기
                    hwwType ??= HardwareWalletType.vault;
                  }

                  switch (hwwType) {
                    case HardwareWalletType.krux:
                    case HardwareWalletType.keystone:
                      final multisigInfoQrData = _viewModel.getMultisigInfoQrData(index);
                      _showDialogToMultisigInfoQrCode(index, hwwType!, multisigInfoQrData);
                      break;
                    case HardwareWalletType.vault:
                    case HardwareWalletType.seesigner:
                    case HardwareWalletType.jade:
                    case HardwareWalletType.coldcard:
                      // TODO: 로딩 오버레이('다른 기기에서 서명을 시작합니다...') 2s 보여준 후
                      // t.multisig_sign_screen.loading_overlay 문구 사용
                      _showPsbtQrCodeBottomSheet(index, hwwType!);
                      break;
                    case null:
                      // TODO: Handle this case.
                      throw UnimplementedError();
                  }
                },
                defaultColor:
                    isSignerApproved
                        ? isInnerWallet
                            ? CoconutColors.backgroundColorPaletteLight[colorIndex]
                            : CoconutColors.backgroundColorPaletteLight[8]
                        : CoconutColors.white,
                pressedColor:
                    isSignerApproved
                        ? isInnerWallet
                            ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                            : CoconutColors.backgroundColorPaletteLight[8].withAlpha(70)
                        : CoconutColors.gray150,
                borderRadius: 100,
                borderWidth: 1,
                border: Border.all(
                  color:
                      isSignerApproved
                          ? isInnerWallet
                              ? CoconutColors.backgroundColorPaletteLight[colorIndex].withAlpha(70)
                              : CoconutColors.gray300
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
                        isInnerWallet ? CustomIcons.getPathByIndex(iconIndex) : 'assets/svg/qr-code.svg',
                        colorFilter: ColorFilter.mode(
                          isInnerWallet ? CoconutColors.colorPalette[colorIndex] : CoconutColors.black,
                          BlendMode.srcIn,
                        ),
                        width: 14.0,
                      ),
                      CoconutLayout.spacing_300w,
                      Flexible(
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                          child: Text(
                            '${isInnerWallet ? nameText : memo ?? t.external_wallet} - ${isSignerApproved ? t.sign_completion : t.sign}',
                            style: CoconutTypography.body1_16,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
                          _viewModel.saveSignedPsbt();
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
