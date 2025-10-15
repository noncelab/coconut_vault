import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:flutter/services.dart';

class VaultModeSelectionScreen extends StatefulWidget {
  final Function()? onComplete; // onComplete이 null일 경우 [설정 - 모드 변경]으로 진입
  const VaultModeSelectionScreen({super.key, this.onComplete});

  @override
  State<VaultModeSelectionScreen> createState() => _VaultModeSelectionScreenState();
}

class _VaultModeSelectionScreenState extends State<VaultModeSelectionScreen> {
  VaultMode? selectedVaultMode;
  final GlobalKey<CoconutShakeAnimationState> _deviceSecurityWarningShakeKey = GlobalKey<CoconutShakeAnimationState>();

  @override
  void initState() {
    super.initState();
    selectedVaultMode = context.read<PreferenceProvider>().getVaultMode();
  }

  bool _getActiveState(VaultMode vaultMode) {
    if (widget.onComplete != null) {
      return true;
    }
    return context.read<PreferenceProvider>().getVaultMode() != vaultMode;
  }

  Color _borderColor(VaultMode mode) {
    final bool inactive = widget.onComplete == null && !_getActiveState(mode);
    if (inactive) return CoconutColors.gray300;
    return selectedVaultMode == mode ? CoconutColors.black : CoconutColors.gray400;
  }

  Widget _buildModeCard({required VaultMode mode, required String title, required String description}) {
    return ShrinkAnimationButton(
      isActive: _getActiveState(mode),
      disabledColor: CoconutColors.gray200,
      border: Border.all(color: _borderColor(mode), width: 1.5),
      borderRadius: 12,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: CoconutTypography.heading4_18_Bold),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
                  },
                  child:
                      widget.onComplete == null && mode == context.read<PreferenceProvider>().getVaultMode()
                          ? SvgPicture.asset(
                            'assets/svg/check.svg',
                            key: const ValueKey('check-icon'),
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(CoconutColors.gray600, BlendMode.srcIn),
                          )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
            CoconutLayout.spacing_200h,
            Text(description, style: CoconutTypography.body2_14),
          ],
        ),
      ),
      onPressed: () {
        if (selectedVaultMode == mode) {
          setState(() {
            selectedVaultMode = null;
          });
          return;
        }

        setState(() {
          selectedVaultMode = mode;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.vault_mode_selection_screen.select_mode,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildModeCard(
                    mode: VaultMode.secureStorage,
                    title: t.vault_mode_selection_screen.secure_storage_mode,
                    description: t.vault_mode_selection_screen.secure_storage_mode_description,
                  ),
                  CoconutLayout.spacing_300h,
                  _buildModeCard(
                    mode: VaultMode.signingOnly,
                    title: t.vault_mode_selection_screen.signing_only_mode,
                    description: t.vault_mode_selection_screen.signing_only_mode_description,
                  ),
                ],
              ),
            ),
            FixedBottomButton(
              isActive:
                  selectedVaultMode != null &&
                  (widget.onComplete != null
                      ? selectedVaultMode != null
                      : selectedVaultMode != context.read<PreferenceProvider>().getVaultMode()),
              onButtonClicked: () async {
                if (selectedVaultMode == VaultMode.signingOnly) {
                  final shouldProceed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: true, // 외부 클릭 시 닫기 가능
                    builder: (BuildContext dialogContext) {
                      return Dialog(
                        backgroundColor: CoconutColors.white,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
                              child: Column(
                                children: [
                                  Text(
                                    t.vault_mode_selection_screen.device_password_setting_guide,
                                    style: CoconutTypography.body1_16_Bold,
                                  ),
                                  CoconutLayout.spacing_600h,
                                  ...List.generate(
                                    t.vault_mode_selection_screen.device_password_setting_guide_descriptions.length,
                                    (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: FutureBuilder<bool>(
                                          future:
                                              index == 0
                                                  ? context.read<AuthProvider>().isDeviceSecured()
                                                  : Future.value(true),
                                          builder: (context, snapshot) {
                                            final isDeviceSecured = snapshot.data ?? true;
                                            final shouldWarn = index == 0 && !isDeviceSecured;

                                            final rowWidget = Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${index + 1}.',
                                                  style: CoconutTypography.body2_14_Bold.copyWith(
                                                    color: shouldWarn ? CoconutColors.warningText : CoconutColors.black,
                                                  ),
                                                ),
                                                CoconutLayout.spacing_200w,
                                                Expanded(
                                                  child: Text(
                                                    t
                                                        .vault_mode_selection_screen
                                                        .device_password_setting_guide_descriptions[index],
                                                    style: CoconutTypography.body2_14_Bold.copyWith(
                                                      color:
                                                          shouldWarn ? CoconutColors.warningText : CoconutColors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );

                                            // index가 0이면서 경고 상태일 때만 ShakeAnimation 적용
                                            if (shouldWarn) {
                                              return CoconutShakeAnimation(
                                                key: _deviceSecurityWarningShakeKey,
                                                shakeOffset: 3,
                                                shakeAmount: 2,
                                                direction: Axis.horizontal,
                                                curve: Curves.linear,
                                                child: rowWidget,
                                              );
                                            }

                                            return rowWidget;
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  CoconutLayout.spacing_400h,
                                  ShrinkAnimationButton(
                                    onPressed: () async {
                                      // 기기 비밀번호 설정 여부 확인
                                      final isDeviceSecured = await context.read<AuthProvider>().isDeviceSecured();

                                      if (!isDeviceSecured) {
                                        // 기기 비밀번호가 설정되지 않았으면 shake만 실행하고 다이얼로그 유지
                                        _deviceSecurityWarningShakeKey.currentState?.shake();
                                        vibrateExtraLightDouble();
                                        return;
                                      }

                                      // 기기 비밀번호가 설정되어 있으면 진행
                                      if (!mounted) return;
                                      Navigator.pop(context, true);
                                    },
                                    borderRadius: 12,
                                    defaultColor: CoconutColors.black,
                                    pressedColor: CoconutColors.gray700,
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        t.vault_mode_selection_screen.device_password_setting_guide_understood,
                                        style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );

                  // 외부 클릭 또는 취소 시 (null 또는 false) 중단
                  if (shouldProceed != true || !mounted) return;
                }
                if (widget.onComplete != null) {
                  // 앱 최초 실행 시 widget.onComplete != null
                  context.read<ConnectivityProvider>().setHasSeenGuideTrue();
                  context.read<VisibilityProvider>().setHasSeenGuide().then((_) {
                    if (context.mounted) {
                      context.read<PreferenceProvider>().setVaultMode(selectedVaultMode!);
                      widget.onComplete!();
                    }
                    return;
                  });
                }

                if (context.read<AuthProvider>().isPinSet) {
                  // 앱 비밀번호 확인 먼저 수행
                  await _authenticateWithBiometricOrPin(context, PinCheckContextEnum.sensitiveAction, () {
                    // 비밀번호 일치 시 모드 변경 로직 수행
                    _changeVaultMode();
                  });
                } else {
                  // 비밀번호가 없는 상황
                  _changeVaultMode();
                }
              },
              text:
                  widget.onComplete != null
                      ? t.vault_mode_selection_screen.start
                      : t.vault_mode_selection_screen.change,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeVaultMode() async {
    // Signing Only Mode 로 변경된 경우
    // 비밀번호 확인 후 --> 호출 시점에 확인함
    // 비밀번호 설정 해제 --> <1>
    // 지갑삭제 --> <2>
    // 관련 shared pref 삭제 --> <3>

    // Secure Storage Mode 로 변경된 경우
    // 비밀번호 지정 --> <4>
    // 지갑 있는 경우 저장 --> <5>

    // 설정 - 모드 변경으로 진입(widget.onComplete가 null일 경우)

    if (!mounted) return;
    final currentVaultMode = context.read<PreferenceProvider>().getVaultMode();

    final secureStorageRepository = SecureStorageRepository();
    final sharedPrefsRepository = SharedPrefsRepository();

    switch (currentVaultMode) {
      case VaultMode.signingOnly:
        // 서명 전용 모드에서 안전 저장 모드로 바뀐 경우
        // 비밀번호 지정
        if (!mounted) return;
        await MyBottomSheet.showBottomSheet_90(
          context: context,
          child: PinSettingScreen(
            onComplete: () {
              if (!mounted) return;
              Navigator.pop(context); // PinSettingScreen 닫기
              context.read<PreferenceProvider>().setVaultMode(VaultMode.secureStorage);
              context.read<PreferenceProvider>().resetSigningModeEdgePanelPos();

              // 비밀번호 설정 완료, 지갑 있는 경우 저장
              final walletProvider = context.read<WalletProvider>();
              if (walletProvider.vaultList.isNotEmpty) {
                for (final vault in walletProvider.vaultList) {
                  if (vault.vaultType == WalletType.singleSignature) {
                    // 니모닉, 패프 가져올 방법 구체화 필요
                    // SingleSigWalletCreateDto(null, vault.name, vault.iconIndex, vault.colorIndex, vault.mnemonic, vault.passphrase);
                    // walletProvider.addSingleSigVault(singleSigWalletCreateDto);
                  } else {
                    // walletProvider.addMultiSigVault(multiSigWalletCreateDto);
                  }
                }
              }

              if (mounted) {
                setState(() {});
                _showModeChangeCompletePopup();
              }
            },
          ),
        );
        break;
      case VaultMode.secureStorage:
        // 안전 저장 모드에서 서명 전용 모드로 바뀐 경우
        // 먼저 경고 다이얼로그 표시

        // SecureStorage에서 시드 관련 데이터 모두 삭제
        // WalletProvider에 시드 관련 데이터는 남겨둠

        // <1> 비밀번호 설정 해제
        if (!mounted) return;
        context.read<AuthProvider>().setPinSet(false);
        // <2> 지갑삭제, 비밀번호 삭제
        await secureStorageRepository.deleteAll();

        // <3> 관련 shared pref 삭제
        await sharedPrefsRepository.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
        await sharedPrefsRepository.deleteSharedPrefsWithKey(SharedPrefsKeys.vaultListLength);

        if (mounted) {
          setState(() {});
          context.read<PreferenceProvider>().setVaultMode(VaultMode.signingOnly);
          _showModeChangeCompletePopup();
        }
        break;
      default:
        break;
    }
  }

  void _showModeChangeCompletePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.vault_mode_selection_screen.mode_change_complete,
          description:
              context.read<PreferenceProvider>().isSigningOnlyMode
                  ? t.vault_mode_selection_screen.mode_changed_description_signing_only
                  : t.vault_mode_selection_screen.mode_changed_description_secrue_storage,
          backgroundColor: CoconutColors.white,
          rightButtonText: t.confirm,
          rightButtonColor: CoconutColors.black,
          onTapRight: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _authenticateWithBiometricOrPin(
    BuildContext context,
    PinCheckContextEnum pinCheckContext,
    VoidCallback onSuccess,
  ) async {
    final authProvider = context.read<AuthProvider>();

    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onSuccess();
      return;
    }

    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            onSuccess();
          },
        ),
      ),
    );
  }
}
