import 'dart:typed_data';

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
import 'package:coconut_vault/providers/view_model/airgap/multisig_sign_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/airgap/multisig_info_qr_code_screen.dart';
import 'package:coconut_vault/screens/airgap/psbt_scanner_screen.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/common/select_external_wallet_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/passphrase_check_screen.dart';
import 'package:coconut_vault/screens/airgap/multisig_psbt_qr_code_screen.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
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
  bool _showFullAddress = false;
  bool _isCupertinoLoadingShown = false;
  String _cupertinoLoadingMessage = '';

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
      await _checkAndShowCreatingQrCode();
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
      await _checkAndShowCreatingQrCode();
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

  Future<bool> _checkAndShowCreatingQrCode() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted && _viewModel.isSignatureComplete) {
      _viewModel.saveSignedPsbt();

      Navigator.pop(context);
      setState(() {
        _cupertinoLoadingMessage = t.multisig_sign_screen.creating_qr_code;
        _isCupertinoLoadingShown = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isCupertinoLoadingShown = false;
        });
        Navigator.pushReplacementNamed(context, AppRoutes.signedTransaction);
        return true;
      }
    }
    return false;
  }

  void _showDialogToMultisigInfoQrCode(int index, HardwareWalletType hwwType, String multisigInfoQrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.multisig_sign_screen.dialog.preparation.title(name: hwwType.displayName),
          description: t.multisig_sign_screen.dialog.preparation.description(name: hwwType.displayName),
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
        onNextPressed: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          _showPsbtQrCodeBottomSheet(index, hwwType);
        },
      ),
    );
  }

  void _showPsbtQrCodeBottomSheet(int index, HardwareWalletType hwwType) {
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: PsbtQrCodeViewScreen(
        multisigName: _viewModel.walletName,
        keyIndex: '${index + 1}',
        signedRawTx: _viewModel.psbtForSigning,
        hardwareWalletType: hwwType,
        onNextPressed: () async {
          Navigator.pop(context); // 현재 다이얼로그 닫기

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          _showPsbtScannerBottomSheet(index, hwwType);
        },
      ),
    );
  }

  void _showPsbtScannerBottomSheet(int? index, HardwareWalletType hwwType) {
    MyBottomSheet.showBottomSheet_95(
      context: context,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: PsbtScannerScreen(
          id: _viewModel.vaultId,
          hardwareWalletType: hwwType,
          onMultisigSignCompleted: (psbtBase64) async {
            final signingPublicKey = _viewModel.signingPublicKey;
            int? signerIndex = index;
            final signedPsbt = Psbt.parse(psbtBase64);
            bool canSign = false;

            // PSBT inputs의 derivationPathList에서 masterFingerprint와 publicKey를 추출하여 signedInputsMap 생성
            if (signedPsbt.inputs.isNotEmpty) {
              final input = signedPsbt.inputs[0];
              if (input.partialSig != null && input.partialSig!.isNotEmpty) {
                for (var sig in input.partialSig!) {
                  final pubKey = sig.publicKey;
                  if (index != null) {
                    canSign = signingPublicKey == pubKey;
                  } else {
                    final pubKey = sig.publicKey;
                    final mfp =
                        _viewModel.unsignedPubkeyMap?.entries
                            .firstWhere(
                              (e) => e.value == pubKey.toString(),
                              orElse: () => const MapEntry<String, String>('', ''),
                            )
                            .key;
                    signerIndex = _viewModel.signers.indexWhere((signer) => signer.keyStore.masterFingerprint == mfp);
                    canSign = signerIndex != -1;
                  }
                }
              }
            }
            if (!canSign) {
              await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CoconutPopup(
                    title: t.multisig_sign_screen.dialog.sign_error.title,
                    description: t.multisig_sign_screen.dialog.sign_error.description,
                    onTapRight: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
              return;
            }

            _viewModel.addSignSignature(psbtBase64);

            _viewModel.updateSignState(signerIndex);

            final navigated = await _checkAndShowCreatingQrCode();

            // 서명이 모두 완료되어 _checkAndShowCreatingQrCode 안에서 화면 전환이 일어난 경우
            // (Navigator.pushReplacementNamed 호출)에는 추가 pop을 하지 않는다.
            if (navigated) {
              return;
            }

            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<HardwareWalletType?> _showHardwareSelectionBottomSheet({int? index}) async {
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
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.coconut_vault, iconSource: iconSourceList[0]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.keystone3pro, iconSource: iconSourceList[1]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.seed_signer, iconSource: iconSourceList[2]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.jade, iconSource: iconSourceList[3]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.cold_card, iconSource: iconSourceList[4]),
      ExternalWalletButton(name: t.multi_sig_setting_screen.add_icon.krux, iconSource: iconSourceList[5]),
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
                    : t.multi_sig_setting_screen.add_icon.title,
            externalWalletButtonList: externalWalletButtonList,
            selectedIndex: null,
            onSelected: (selectedIndex) {
              hwwType = HardwareWalletTypeExtension.getHardwareWalletTypeByIconPath(iconSourceList[selectedIndex]);
              if (hwwType != null && index != null) {
                _viewModel.updateSignerSource(index, hwwType!);
              }
            },
          ),
    );
    return hwwType;
  }

  // void _askIfSureToQuit() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return CoconutPopup(
  //         insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
  //         title: t.alert.exit_sign.title,
  //         description: t.alert.exit_sign.description,
  //         backgroundColor: CoconutColors.white,
  //         leftButtonText: t.no,
  //         leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
  //         rightButtonText: t.yes,
  //         rightButtonColor: CoconutColors.warningText,
  //         onTapLeft: () => Navigator.pop(context),
  //         onTapRight: () {
  //           _viewModel.resetAll();
  //           Navigator.popUntil(context, (route) => route.isFirst);
  //         },
  //       );
  //     },
  //   );
  // }

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
                            CoconutLayout.spacing_600h,
                            _buildSendInfo(),
                            CoconutLayout.spacing_1300h,
                            Text(
                              viewModel.isSignatureComplete
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
                      _buildBottomButtons(),
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
              final signer = _viewModel.signers[index];
              final isInnerWallet = signer.innerVaultId != null;
              final name = signer.name ?? t.external_wallet;
              final nameText = name.length > 6 ? '${name.substring(0, 6)}...' : name;
              // final colorIndex = _viewModel.signers[index].colorIndex ?? 0;
              final isSignerApproved = _viewModel.signersApproved[index];
              var hwwType = _viewModel.getSignerHwwType(index);

              return ShrinkAnimationButton(
                onPressed: () async {
                  if (isSignerApproved) {
                    return;
                  }

                  if (isInnerWallet) {
                    _sign(index);
                    return;
                  }

                  hwwType ??= await _showHardwareSelectionBottomSheet(index: index);

                  Uint8List? publicKey;

                  try {
                    // ExtendedPublicKey에서 HDWallet을 생성하여 derivation 수행
                    final extXpub = signer.keyStore.extendedPublicKey;
                    // derivationPath에서 index 값을 추출
                    final addressIndex = int.parse(
                      _viewModel.unsignedInputsMap?[signer.keyStore.masterFingerprint]?.split('/').last ?? '0',
                    );

                    HDWallet wallet = HDWallet.fromPublicKey(extXpub.publicKey, extXpub.chainCode);
                    wallet = wallet.derive(0).derive(addressIndex);
                    publicKey = wallet.publicKey;
                  } catch (e) {
                    // derive가 실패하면 원본 extended public key의 publicKey 사용
                    publicKey = signer.keyStore.extendedPublicKey.publicKey;
                  }
                  final publicKeyHex = Codec.encodeHex(publicKey);
                  _viewModel.saveSigningPublicKey(publicKeyHex);
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
                  switch (hwwType) {
                    case HardwareWalletType.krux:
                    case HardwareWalletType.keystone3Pro:
                      final multisigInfoQrData = _viewModel.getMultisigInfoQrData(hwwType!);
                      if (multisigInfoQrData == null) {
                        return;
                      }
                      _showDialogToMultisigInfoQrCode(index, hwwType!, multisigInfoQrData);
                      break;
                    case HardwareWalletType.coconutVault:
                    case HardwareWalletType.seedSigner:
                    case HardwareWalletType.jade:
                    case HardwareWalletType.coldcard:
                      _showPsbtQrCodeBottomSheet(index, hwwType!);
                      break;
                    default:
                      return;
                  }
                },
                defaultColor: isSignerApproved ? const Color(0xFF88C125).withAlpha(16) : CoconutColors.white,
                pressedColor: isSignerApproved ? const Color(0xFF88C125).withAlpha(70) : CoconutColors.gray150,
                borderRadius: 100,
                borderWidth: 1,
                border: Border.all(color: isSignerApproved ? const Color(0xFF88C125) : CoconutColors.gray200, width: 1),
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: SvgPicture.asset(
                          isSignerApproved
                              ? 'assets/svg/check-circle-green.svg'
                              : 'assets/svg/check-circle-outlined.svg',
                          width: 24.0,
                          key: ValueKey<bool>(isSignerApproved),
                        ),
                      ),
                      CoconutLayout.spacing_300w,
                      Flexible(
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                          child: Text(
                            '${isInnerWallet ? nameText : signer.keyStore.masterFingerprint} - ${isSignerApproved
                                ? t.sign_completion
                                : isInnerWallet
                                ? t.sign
                                : t.add_sign}',
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
        return FixedBottomTweenButton(
          leftButtonClicked: () {
            showDialog(
              context: context,
              builder:
                  (context) => CoconutPopup(
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
          rightButtonClicked: () async {
            final hwwType = await _showHardwareSelectionBottomSheet();
            if (hwwType != null) {
              _showPsbtScannerBottomSheet(null, hwwType);
            }
          },
          leftText: t.abort_sign,
          rightText: t.scan_qr,
          leftButtonBackgroundColor: CoconutColors.white,
          rightButtonBackgroundColor: CoconutColors.white,
          leftButtonTextColor: CoconutColors.black,
          rightButtonTextColor: CoconutColors.black,
          leftButtonBorderColor: CoconutColors.gray400,
          rightButtonBorderColor: CoconutColors.gray400,
        );
        // return Align(
        //   alignment: Alignment.bottomCenter,
        //   child: Padding(
        //     padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        //     child: SizedBox(
        //       width: MediaQuery.sizeOf(context).width,
        //       child: Row(
        //         children: [
        //           Flexible(
        //             flex: 1,
        //             child: SizedBox(
        //               width: MediaQuery.sizeOf(context).width,
        //               height: 50,
        //               child: ShrinkAnimationButton(
        //                 defaultColor: CoconutColors.gray300,
        //                 onPressed: _askIfSureToQuit,
        //                 borderRadius: CoconutStyles.radius_200,
        //                 child: Padding(
        //                   padding: const EdgeInsets.symmetric(vertical: 12),
        //                   child: FittedBox(
        //                     fit: BoxFit.scaleDown,
        //                     alignment: Alignment.center,
        //                     child: Text(t.abort, style: CoconutTypography.body2_14_Bold, textAlign: TextAlign.center),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //           CoconutLayout.spacing_200w,
        //           Flexible(
        //             flex: 2,
        //             child: SizedBox(
        //               width: MediaQuery.sizeOf(context).width,
        //               height: 50,
        //               child: ShrinkAnimationButton(
        //                 isActive: isSignatureComplete,
        //                 disabledColor: CoconutColors.gray150,
        //                 defaultColor: CoconutColors.black,
        //                 onPressed: () {
        //                   _viewModel.saveSignedPsbt();
        //                   Navigator.pushNamed(context, AppRoutes.signedTransaction);
        //                 },
        //                 pressedColor: CoconutColors.gray400,
        //                 borderRadius: CoconutStyles.radius_200,
        //                 child: Padding(
        //                   padding: const EdgeInsets.symmetric(vertical: 12),
        //                   child: FittedBox(
        //                     fit: BoxFit.scaleDown,
        //                     alignment: Alignment.center,
        //                     child: Text(
        //                       t.next,
        //                       style: CoconutTypography.body2_14_Bold.setColor(
        //                         isSignatureComplete ? CoconutColors.white : CoconutColors.gray350,
        //                       ),
        //                       textAlign: TextAlign.center,
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // );
      },
    );
  }
}
