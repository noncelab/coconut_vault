import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
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
              const SizedBox(
                height: 28,
              ),
              /*_informationPart(),
              const SizedBox(height: 32),*/
              _advancedUserPart(context)
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(t.security,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                color: MyColors.black,
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.bold,
              )),
        ),
        Consumer<AuthProvider>(builder: (context, provider, child) {
          return ButtonGroup(buttons: [
            if (provider.isPinSet) ...{
              if (provider.canCheckBiometrics)
                SingleButton(
                  title: t.settings_screen.use_biometric,
                  rightElement: CupertinoSwitch(
                    value: provider.hasBiometricsPermission
                        ? provider.isBiometricEnabled
                        : false,
                    activeColor: MyColors.black,
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
        }),
      ],
    );
  }

  Widget _advancedUserPart(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(t.advanced_user,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              color: MyColors.black,
              fontSize: 16,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.bold,
            )),
      ),
      Consumer<VisibilityProvider>(builder: (context, provider, child) {
        return ButtonGroup(buttons: [
          SingleButton(
            title: t.settings_screen.use_passphase,
            rightElement: CupertinoSwitch(
                value: provider.isPassphraseUseEnabled,
                activeColor: MyColors.black,
                onChanged: (isOn) async {
                  await provider.setAdvancedMode(isOn);
                }),
          )
        ]);
      }),
    ]);
  }
}
