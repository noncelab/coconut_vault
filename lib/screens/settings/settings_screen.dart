import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/styles.dart';
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
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        toolbarHeight: 62,
        title: Text(t.settings),
        titleTextStyle:
            Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
        toolbarTextStyle: Styles.appbarTitle,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close,
            color: MyColors.black,
            size: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _securityPart(context),
              CoconutLayout.spacing_1000h,
              Selector<WalletProvider, bool>(
                selector: (context, provider) => provider.vaultList.isNotEmpty,
                builder: (context, isNotEmpty, _) => isNotEmpty
                    ? Column(children: [
                        _updatePart(context),
                        CoconutLayout.spacing_1000h
                      ])
                    : Container(),
              ),
              _advancedUserPart(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _securityPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(t.security, style: CoconutTypography.body1_16_Bold),
        ),
        Consumer<AuthProvider>(
          builder: (context, provider, child) {
            return ButtonGroup(buttons: [
              if (provider.isPinSet) ...{
                if (provider.canCheckBiometrics)
                  SingleButton(
                    title: t.settings_screen.use_biometric,
                    rightElement: CupertinoSwitch(
                      value: provider.hasBiometricsPermission
                          ? provider.isBiometricEnabled
                          : false,
                      activeColor: MyColors.primary,
                      onChanged: (isOn) async {
                        if (isOn &&
                            await provider.authenticateWithBiometrics(context,
                                isSaved: true)) {
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
                  title: t.settings_screen.change_password,
                  onPressed: () async {
                    MyBottomSheet.showBottomSheet_90(
                      context: context,
                      child: const LoaderOverlay(
                        child: PinCheckScreen(
                          pinCheckContext: PinCheckContextEnum.change,
                        ),
                      ),
                    );
                  },
                )
              } else ...{
                SingleButton(
                  title: t.settings_screen.set_password,
                  rightElement: CupertinoSwitch(
                    value: provider.isPinSet,
                    activeColor: MyColors.primary,
                    onChanged: (value) {
                      MyBottomSheet.showBottomSheet_90(
                        context: context,
                        child: const PinSettingScreen(),
                      );
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
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            t.settings_screen.update,
            style: CoconutTypography.body1_16_Bold,
          ),
        ),
        ButtonGroup(
          buttons: [
            SingleButton(
              title: t.settings_screen.prepare_update,
              onPressed: () async {
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: CustomLoadingOverlay(
                    child: PinCheckScreen(
                      pinCheckContext: PinCheckContextEnum.sensitiveAction,
                      isDeleteScreen: true,
                      onComplete: () async {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.prepareUpdate);
                      },
                    ),
                  ),
                );
              },
            ),
            // 임시 메뉴
            SingleButton(
              title: '복원하기',
              onPressed: () async {
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: CustomLoadingOverlay(
                    child: PinCheckScreen(
                      pinCheckContext: PinCheckContextEnum.sensitiveAction,
                      isDeleteScreen: true,
                      onComplete: () async {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.restorationInfo);
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

  Widget _advancedUserPart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            t.settings_screen.advanced_user,
            style: CoconutTypography.body1_16_Bold,
          ),
        ),
        ButtonGroup(
          buttons: [
            SingleButton(
              title: t.settings_screen.use_passphrase,
              rightElement: CupertinoSwitch(
                value: true,
                activeColor: MyColors.primary,
                onChanged: (isOn) async {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
