import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/settings/unit_bottm_sheet.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                _advancedUserPart(context),
                SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom > 0
                        ? MediaQuery.of(context).viewPadding.bottom
                        : Sizes.size16)
              ],
            ),
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
            return ButtonGroup(buttons: [
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

  Widget _updatePart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _category(t.settings_screen.update),
        ButtonGroup(
          buttons: [
            SingleButton(
              buttonPosition: SingleButtonPosition.none,
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
                      onComplete: () async {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.prepareUpdate);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _btcUnitPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _category(t.unit),
      Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isBtcUnit,
          builder: (context, isBtcUnit, child) {
            return ButtonGroup(buttons: [
              SingleButton(
                title: t.bitcoin_kr,
                subtitle: isBtcUnit ? t.btc : t.sats,
                onPressed: () async {
                  MyBottomSheet.showBottomSheet_50(
                      context: context, child: const UnitBottomSheet());
                },
              ),
            ]);
          }),
    ]);
  }

  Widget _advancedUserPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _category(t.advanced_user),
      Selector<VisibilityProvider, bool>(
          selector: (_, viewModel) => viewModel.isPassphraseUseEnabled,
          builder: (context, isPassphraseUseEnabled, child) {
            return ButtonGroup(buttons: [
              SingleButton(
                buttonPosition: SingleButtonPosition.none,
                title: t.settings_screen.use_passphrase,
                rightElement: CupertinoSwitch(
                    value: isPassphraseUseEnabled,
                    activeColor: CoconutColors.black,
                    onChanged: (isOn) async {
                      await context.read<VisibilityProvider>().setAdvancedMode(isOn);
                    }),
              )
            ]);
          }),
    ]);
  }
}
