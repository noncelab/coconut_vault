import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/settings/language_bottom_sheet.dart';
import 'package:coconut_vault/screens/settings/unit_bottm_sheet.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/multi_button.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:provider/provider.dart';

import '../../widgets/bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CoconutAppBar.build(
        context: context,
        backgroundColor: Colors.transparent,
        height: 62,
        title: t.settings,
        isBottom: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _securityPart(context),
              CoconutLayout.spacing_1000h,
              Selector<WalletProvider, bool>(
                selector: (context, provider) => provider.vaultList.isNotEmpty,
                builder: (context, isNotEmpty, _) => isNotEmpty
                    ? Column(children: [_updatePart(context), CoconutLayout.spacing_1000h])
                    : Container(),
              ),
              _btcUnitPart(context),
              CoconutLayout.spacing_1000h,
              _languagePart(context),
              CoconutLayout.spacing_1000h,
              _advancedUserPart(context),
              CoconutLayout.spacing_1000h,
              _informationPart(context),
              SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom > 0
                      ? MediaQuery.of(context).viewPadding.bottom + Sizes.size12
                      : Sizes.size36)
            ],
          ),
        ),
      ),
    );
  }

  Widget _category(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: CoconutTypography.body1_16_Bold,
      ),
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
        Consumer<AuthProvider>(
          builder: (context, provider, child) {
            return MultiButton(children: [
              if (provider.isPinSet) ...{
                if (provider.canCheckBiometrics)
                  SingleButton(
                    buttonPosition: SingleButtonPosition.top,
                    title: t.settings_screen.use_biometric,
                    rightElement: CupertinoSwitch(
                      value: provider.hasBiometricsPermission ? provider.isBiometricEnabled : false,
                      activeColor: CoconutColors.black,
                      onChanged: (isOn) async {
                        if (isOn &&
                            await provider.authenticateWithBiometrics(
                                context: context, isSaved: true)) {
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
                  buttonPosition: provider.canCheckBiometrics
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

                    MyBottomSheet.showBottomSheet_90(
                      context: context,
                      child: const LoaderOverlay(
                        child: PinCheckScreen(
                          pinCheckContext: PinCheckContextEnum.pinChange,
                        ),
                      ),
                    );
                  },
                )
              } else ...{
                SingleButton(
                  buttonPosition: SingleButtonPosition.none,
                  title: t.settings_screen.set_password,
                  rightElement: CupertinoSwitch(
                    value: provider.hasBiometricsPermission ? provider.isBiometricEnabled : false,
                    activeColor: CoconutColors.black,
                    onChanged: (isOn) async {
                      /// 비밀번호 제거 기능은 제공하지 않음.
                      if (isOn) {
                        _showPinSettingScreen();
                      }
                    },
                  ),
                ),
              }
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedButton(
      {required String title, required VoidCallback onPressed, String? subtitle}) {
    return SingleButton(
      enableShrinkAnim: true,
      animationEndValue: 0.97,
      title: title,
      subtitle: subtitle,
      onPressed: onPressed,
    );
  }

  Widget _updatePart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.settings_screen.update),
        _buildAnimatedButton(
          title: t.settings_screen.prepare_update,
          onPressed: () async {
            final authProvider = context.read<AuthProvider>();
            if (await authProvider.isBiometricsAuthValid()) {
              Navigator.pushNamed(context, AppRoutes.prepareUpdate);
              return;
            }

            MyBottomSheet.showBottomSheet_90(
              context: context,
              child: CustomLoadingOverlay(
                child: PinCheckScreen(
                  pinCheckContext: PinCheckContextEnum.sensitiveAction,
                  onSuccess: () async {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.prepareUpdate);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _informationPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          }),
    ]);
  }

  Widget _btcUnitPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _category(t.unit),
      Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isBtcUnit,
          builder: (context, isBtcUnit, child) {
            return _buildAnimatedButton(
              title: t.bitcoin,
              subtitle: isBtcUnit ? t.btc : t.sats,
              onPressed: () async {
                MyBottomSheet.showBottomSheet_50(context: context, child: const UnitBottomSheet());
              },
            );
          }),
    ]);
  }

  Widget _advancedUserPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _category(t.advanced_user),
      Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isPassphraseUseEnabled,
          builder: (context, isPassphraseUseEnabled, child) {
            return SingleButton(
              buttonPosition: SingleButtonPosition.none,
              title: t.settings_screen.use_passphrase,
              rightElement: CupertinoSwitch(
                  value: isPassphraseUseEnabled,
                  activeColor: CoconutColors.black,
                  onChanged: (isOn) async {
                    await context.read<VisibilityProvider>().setAdvancedMode(isOn);
                  }),
            );
          }),
    ]);
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
                    MyBottomSheet.showBottomSheet_50(
                        context: context, child: const LanguageBottomSheet());
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
      default:
        return t.language.english;
    }
  }
}
