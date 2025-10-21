import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/screens/settings/language_bottom_sheet.dart';
import 'package:coconut_vault/screens/settings/unit_bottm_sheet.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/button/multi_button.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final ScrollController scrollController;
  const SettingsScreen({super.key, required this.scrollController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDraggableHeader(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: CoconutColors.white),
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                _securityPart(context),
                CoconutLayout.spacing_1000h,
                _btcUnitPart(context),
                CoconutLayout.spacing_1000h,
                _languagePart(context),
                CoconutLayout.spacing_1000h,
                Selector<PreferenceProvider, bool>(
                  selector: (context, preferenceProvider) => preferenceProvider.isSigningOnlyMode,
                  builder: (context, isSigningOnlyMode, child) {
                    if (isSigningOnlyMode) return const SizedBox.shrink();
                    return Column(children: [_advancedUserPart(context), CoconutLayout.spacing_1000h]);
                  },
                ),
                _informationPart(context),
                SizedBox(
                  height:
                      MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom + Sizes.size12
                          : Sizes.size36,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: CoconutColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: CoconutColors.black, size: 24),
                ),
                Expanded(child: Text(t.settings, style: CoconutTypography.body1_16_Bold, textAlign: TextAlign.center)),
                const SizedBox(width: 24), // Balance the close icon
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _category(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: CoconutTypography.body1_16_Bold),
    );
  }

  void _showPinSettingScreen() {
    MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen());
  }

  Widget _securityPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.security),
        Selector<PreferenceProvider, bool>(
          selector: (_, provider) => provider.isSigningOnlyMode,
          builder: (context, isSigningOnlyMode, child) {
            if (isSigningOnlyMode) {
              return _buildAnimatedButton(
                title: t.vault_mode_selection_screen.change_mode,
                subtitle: t.vault_mode_selection_screen.signing_only_mode,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.vaultModeSelection);
                },
              );
            }
            return Consumer<AuthProvider>(
              builder: (context, provider, child) {
                return MultiButton(
                  children: [
                    if (provider.isPinSet) ...{
                      if (provider.isBiometricSupportedByDevice)
                        SingleButton(
                          buttonPosition: SingleButtonPosition.top,
                          title: t.settings_screen.use_biometric,
                          description:
                              provider.isBiometricEnabled
                                  ? null
                                  : provider.availableBiometrics.isNotEmpty
                                  ? t.alert.secure_module_use_biometrics.description
                                  : null,
                          rightElement: CupertinoSwitch(
                            value: provider.isBiometricEnabled,
                            activeTrackColor: CoconutColors.black,
                            onChanged: (isOn) async {
                              assert(provider.isBiometricSupportedByDevice);

                              if (provider.availableBiometrics.isEmpty) {
                                if (Platform.isAndroid) {
                                  CoconutToast.showToast(
                                    context: context,
                                    text: t.settings_screen.toast.no_enrolled_biometrics,
                                    isVisibleIcon: true,
                                    seconds: 5,
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CoconutPopup(
                                        insetPadding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context).size.width * 0.15,
                                        ),
                                        title: t.settings_screen.dialog.need_biometrics_setting_title,
                                        description: t.settings_screen.dialog.need_biometrics_setting_desc,
                                        backgroundColor: CoconutColors.white,
                                        rightButtonText: t.settings_screen.dialog.btn_move_to_setting,
                                        rightButtonColor: CoconutColors.gray900,
                                        leftButtonText: t.cancel,
                                        leftButtonColor: CoconutColors.gray900,
                                        onTapLeft: () {
                                          Navigator.pop(context);
                                        },
                                        onTapRight: () {
                                          Navigator.pop(context);
                                          _openAppSettings();
                                        },
                                      );
                                    },
                                  );
                                }
                                return;
                              }

                              if (isOn && await provider.authenticateWithBiometrics(context: context, isSaved: true)) {
                                Logger.log('Biometric authentication success');
                                provider.saveIsBiometricEnabled(true);
                              } else {
                                Logger.log('Biometric authentication fail');
                                provider.saveIsBiometricEnabled(false);
                              }
                            },
                          ),
                        ),
                      SingleButton(
                        buttonPosition:
                            provider.isBiometricSupportedByDevice
                                ? SingleButtonPosition.bottom
                                : SingleButtonPosition.none,
                        title: t.settings_screen.change_password,
                        enableShrinkAnim: true,
                        animationEndValue: 0.97,
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          if (await authProvider.isBiometricsAuthValid()) {
                            _showPinSettingScreen();
                            return;
                          }

                          if (!context.mounted) return;
                          MyBottomSheet.showBottomSheet_90(
                            context: context,
                            child: const LoaderOverlay(
                              child: PinCheckScreen(pinCheckContext: PinCheckContextEnum.pinChange),
                            ),
                          );
                        },
                      ),
                    } else ...{
                      SingleButton(
                        buttonPosition: SingleButtonPosition.none,
                        title: t.settings_screen.set_password,
                        rightElement: CupertinoSwitch(
                          value: provider.isBiometricEnabled,
                          activeTrackColor: CoconutColors.black,
                          onChanged: (isOn) async {
                            /// 비밀번호 제거 기능은 제공하지 않음.
                            if (isOn) {
                              _showPinSettingScreen();
                            }
                          },
                        ),
                      ),
                    },
                    SingleButton(
                      buttonPosition: SingleButtonPosition.bottom,
                      enableShrinkAnim: true,
                      animationEndValue: 0.97,
                      title: t.vault_mode_selection_screen.change_mode,
                      subtitle:
                          context.read<PreferenceProvider>().isSigningOnlyMode
                              ? t.vault_mode_selection_screen.signing_only_mode
                              : t.vault_mode_selection_screen.secure_storage_mode,
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.vaultModeSelection);
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _openAppSettings() async {
    const url = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildAnimatedButton({required String title, required VoidCallback onPressed, String? subtitle}) {
    return SingleButton(
      enableShrinkAnim: true,
      animationEndValue: 0.97,
      title: title,
      subtitle: subtitle,
      onPressed: onPressed,
    );
  }

  Widget _informationPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.settings_screen.information),
        Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isPassphraseUseEnabled,
          builder: (context, isPassphraseUseEnabled, child) {
            return _buildAnimatedButton(
              title: t.view_app_info,
              onPressed: () async {
                Navigator.pushNamed(context, AppRoutes.appInfo);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _btcUnitPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.unit),
        Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isBtcUnit,
          builder: (context, isBtcUnit, child) {
            return _buildAnimatedButton(
              title: t.bitcoin,
              subtitle: isBtcUnit ? t.btc : t.sats,
              onPressed: () async {
                MyBottomSheet.showBottomSheet_ratio(
                  ratio: 0.5,
                  context: context,
                  child: const UnitBottomSheet(),
                  showDragHandle: true,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _advancedUserPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.advanced_user),
        Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isPassphraseUseEnabled,
          builder: (context, isPassphraseUseEnabled, child) {
            return SingleButton(
              buttonPosition: SingleButtonPosition.none,
              title: t.settings_screen.use_passphrase,
              rightElement: CupertinoSwitch(
                value: isPassphraseUseEnabled,
                activeTrackColor: CoconutColors.black,
                onChanged: (isOn) async {
                  if (!isOn) {
                    await context.read<VisibilityProvider>().setAdvancedMode(isOn);
                    return;
                  }

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CoconutPopup(
                          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
                          title: t.settings_screen.dialog.use_passphrase_title,
                          description: t.settings_screen.dialog.use_passphrase_description,
                          rightButtonText: t.settings_screen.dialog.use_passphrase_btn,
                          onTapRight: () async {
                            await context.read<VisibilityProvider>().setAdvancedMode(isOn);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _languagePart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(t.language.language, style: CoconutTypography.body1_16_Bold),
        ),
        Consumer<VisibilityProvider>(
          builder: (context, provider, child) {
            return Selector<VisibilityProvider, String>(
              selector: (_, provider) => provider.language,
              builder: (context, language, child) {
                return _buildAnimatedButton(
                  title: t.language.language,
                  subtitle: _getCurrentLanguageDisplayName(language),
                  onPressed: () async {
                    MyBottomSheet.showBottomSheet_ratio(
                      ratio: 0.5,
                      context: context,
                      child: const LanguageBottomSheet(),
                      showDragHandle: true,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _getCurrentLanguageDisplayName(String language) {
    switch (language) {
      case 'kr':
        return t.language.korean;
      case 'en':
        return t.language.english;
      case 'jp':
        return t.language.japanese;
      default:
        return t.language.english;
    }
  }
}
