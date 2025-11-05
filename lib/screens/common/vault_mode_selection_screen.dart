import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/device_secure_checker.dart' as device_secure_checker;
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coconut_vault/utils/device_secure_checker.dart';

class VaultModeSelectionScreen extends StatefulWidget {
  final Function()? onComplete; // onComplete이 null일 경우 [설정 - 모드 변경]으로 진입
  const VaultModeSelectionScreen({super.key, this.onComplete});

  @override
  State<VaultModeSelectionScreen> createState() => _VaultModeSelectionScreenState();
}

class _VaultModeSelectionScreenState extends State<VaultModeSelectionScreen> {
  VaultMode? selectedVaultMode;
  bool _isConvertingToSecureStorageMode = false;

  @override
  void initState() {
    super.initState();
    selectedVaultMode = context.read<PreferenceProvider>().getVaultMode();
  }

  Color _borderColor(VaultMode mode) {
    return selectedVaultMode == mode ? CoconutColors.black : CoconutColors.gray400;
  }

  Widget _buildModeCard({required VaultMode mode, required String title, required String description}) {
    return ShrinkAnimationButton(
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
                          ? Container(
                            key: const ValueKey('current-using-container'),
                            decoration: BoxDecoration(
                              color: CoconutColors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(
                              t.vault_mode_selection_screen.current_using,
                              style: CoconutTypography.body3_12.setColor(CoconutColors.white),
                            ),
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
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
                  debugPrint(
                    'selectedVaultMode: ${await SecureStorageRepository().read(key: SecureStorageKeys.kVaultPin)}',
                  );
                  if (widget.onComplete != null) {
                    // 앱 최초 실행 시 widget.onComplete != null

                    if (!await device_secure_checker.isDeviceSecured()) {
                      // 기기 비밀번호 설정 안되어 있으면 설정 화면으로 이동
                      if (!context.mounted) return;
                      openSystemSecuritySettings(
                        context,
                        hasDialogShownForIos: true,
                        title: t.vault_mode_selection_screen.secure_use_guide_title,
                        description: t.vault_mode_selection_screen.secure_use_guide_description,
                        buttonText: t.device_password_detection_screen.go_to_settings,
                      );
                      return;
                    }

                    if (context.mounted) {
                      context.read<ConnectivityProvider>().setHasSeenGuideTrue();
                      await context.read<VisibilityProvider>().setHasSeenGuide();
                      if (context.mounted) {
                        bool isDone = await _setVaultMode(selectedVaultMode!);
                        if (!isDone) return;
                        widget.onComplete!();
                      }
                      return;
                    }
                  }

                  if (!context.mounted) return;
                  final shouldProceed = await showDialog<bool>(
                    context: context,
                    barrierColor: CoconutColors.black.withValues(alpha: 0.1),
                    builder: (BuildContext dialogContext) {
                      bool isSigningOnlyMode = selectedVaultMode == VaultMode.signingOnly;
                      bool isAndroid = Platform.isAndroid;
                      return WarningWidget(
                        title:
                            isSigningOnlyMode
                                ? t.vault_mode_selection_screen.signing_only_mode_warning_title
                                : t.vault_mode_selection_screen.secure_storage_mode_warning_title,
                        description: Column(
                          children: [
                            ...List.generate(
                              isSigningOnlyMode
                                  ? t.vault_mode_selection_screen.signing_only_mode_warning_descriptions.length
                                  : isAndroid
                                  ? t
                                      .vault_mode_selection_screen
                                      .secure_storage_mode_warning_descriptions_android
                                      .length
                                  : t.vault_mode_selection_screen.secure_storage_mode_warning_descriptions_ios.length,
                              (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}.',
                                        style: CoconutTypography.heading4_18_Bold.copyWith(color: CoconutColors.white),
                                      ),
                                      CoconutLayout.spacing_200w,
                                      Expanded(
                                        child: Text(
                                          isSigningOnlyMode
                                              ? t
                                                  .vault_mode_selection_screen
                                                  .signing_only_mode_warning_descriptions[index]
                                              : isAndroid
                                              ? t
                                                  .vault_mode_selection_screen
                                                  .secure_storage_mode_warning_descriptions_android[index]
                                              : t
                                                  .vault_mode_selection_screen
                                                  .secure_storage_mode_warning_descriptions_ios[index],
                                          style: CoconutTypography.heading4_18_Bold.copyWith(
                                            color: CoconutColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        buttonText: t.vault_mode_selection_screen.device_password_setting_guide_understood,
                        onWarningDismissed: () async {
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        },
                      );
                    },
                  );

                  // 외부 클릭 또는 취소 시 (null 또는 false) 중단
                  if (shouldProceed != true || !mounted) return;

                  if (!context.mounted) return;
                  if (context.read<AuthProvider>().isPinSet) {
                    // 앱 비밀번호 확인 먼저 수행
                    await _authenticateWithBiometricOrPin(context, PinCheckContextEnum.sensitiveAction, () async {
                      // 비밀번호 일치 시 모드 변경 로직 수행
                      await _changeVaultMode();
                    });
                  } else {
                    // 비밀번호가 없는 상황
                    await _changeVaultMode();
                  }
                },
                text:
                    widget.onComplete != null
                        ? t.vault_mode_selection_screen.start
                        : t.vault_mode_selection_screen.change,
              ),
              Visibility(
                visible: _isConvertingToSecureStorageMode,
                child: Container(
                  decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                  child: Center(
                    child: MessageActivityIndicator(
                      message:
                          Platform.isAndroid
                              ? t.vault_mode_selection_screen.converting_to_secure_storage_mode_aos
                              : t.vault_mode_selection_screen.converting_to_secure_storage_mode_ios,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeVaultMode() async {
    if (!mounted) return;
    final currentVaultMode = context.read<PreferenceProvider>().getVaultMode();
    switch (currentVaultMode) {
      case VaultMode.signingOnly:
        // 서명 전용 모드에서 안전 저장 모드로 바뀐 경우
        final preferenceProvider = context.read<PreferenceProvider>();
        final walletProvider = context.read<WalletProvider>();
        final visibilityProvider = context.read<VisibilityProvider>();
        final authProvider = context.read<AuthProvider>();

        // TODO: edgePanel 숨기기
        //final pos = preferenceProvider.signingModeEdgePanelPos;
        //await preferenceProvider.resetSigningModeEdgePanelPos();
        //assert(pos.$1 != null && pos.$2 != null);

        // 비밀번호 지정
        if (!mounted) return;
        final result = await MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen());
        if (result == true) {
          try {
            await authProvider.updateDeviceBiometricAvailability();

            if (walletProvider.vaultList.isNotEmpty) {
              setState(() {
                _isConvertingToSecureStorageMode = true;
              });
              await Future.delayed(const Duration(seconds: 4));
            }

            await walletProvider.updateIsSigningOnlyMode(false);
            await preferenceProvider.setVaultMode(VaultMode.secureStorage);
            visibilityProvider.updateIsSigningOnlyMode(false);

            if (mounted) {
              setState(() {});
              _showModeChangeCompletePopup();
            }
          } catch (e) {
            authProvider.resetPinData();

            // preferenceProvider.setSigningModeEdgePanelPos(pos.$1!, pos.$2!);
            if (!mounted) return;
            _showModeChangeFailedPopup(e.toString(), VaultMode.signingOnly);
          } finally {
            if (_isConvertingToSecureStorageMode) {
              setState(() {
                _isConvertingToSecureStorageMode = false;
              });
            }
          }
        }
        break;
      case VaultMode.secureStorage:
        try {
          final preferenceProvider = context.read<PreferenceProvider>();
          final walletProvider = context.read<WalletProvider>();
          final visibilityProvider = context.read<VisibilityProvider>();
          final authProvider = context.read<AuthProvider>();

          await walletProvider.updateIsSigningOnlyMode(true);
          await authProvider.setPinSet(false);
          visibilityProvider.updateIsSigningOnlyMode(true);
          await preferenceProvider.setVaultMode(VaultMode.signingOnly);

          if (!mounted) return;
          setState(() {});
          _showModeChangeCompletePopup();
        } catch (e) {
          if (!mounted) return;
          _showModeChangeFailedPopup(e.toString(), VaultMode.secureStorage);
        }
        break;
      default:
        break;
    }
  }

  /// 앱 첫 실행 후 선택 시 호출하는 함수
  Future<bool> _setVaultMode(VaultMode selectedMode) async {
    assert(widget.onComplete != null);

    bool isSigningOnlyMode = selectedMode == VaultMode.signingOnly;

    if (!isSigningOnlyMode) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        barrierColor: CoconutColors.black.withValues(alpha: 0.1),
        builder: (BuildContext dialogContext) {
          return WarningWidget(
            title: t.precautions,
            description: Column(
              children: [
                // 현재 보여줄 항목이 1개여서 index 출력도 하던 코드는 지움
                ...List.generate(
                  t.vault_mode_selection_screen.secure_storage_mode_precautions_when_first_setting.length,
                  (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        t.vault_mode_selection_screen.secure_storage_mode_precautions_when_first_setting[index],
                        style: CoconutTypography.heading4_18_Bold.copyWith(color: CoconutColors.white),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
            buttonText: t.vault_mode_selection_screen.device_password_setting_guide_understood,
            onWarningDismissed: () async {
              if (!mounted) return;
              Navigator.pop(context, true);
            },
          );
        },
      );

      if (shouldProceed != true || !mounted) return false;
    }

    context.read<PreferenceProvider>().setVaultMode(selectedMode);
    context.read<VisibilityProvider>().updateIsSigningOnlyMode(isSigningOnlyMode);

    return true;
  }

  void _showModeChangeFailedPopup(String errorMessage, VaultMode currentVaultMode) {
    final description =
        currentVaultMode == VaultMode.secureStorage
            ? t.vault_mode_selection_screen.signing_only_mode_conversion_failed
            : t.vault_mode_selection_screen.secure_storage_mode_conversion_failed;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.vault_mode_selection_screen.mode_change_failed_title,
          description: "$description\n error: $errorMessage",
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

  void _showModeChangeCompletePopup() {
    if (!mounted) return;
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
            Navigator.popUntil(context, (route) => route.isFirst);
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
