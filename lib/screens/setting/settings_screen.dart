import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/providers/app_model.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/pin_setting_screen.dart';
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
                height: 40,
              ),
              /*_informationPart(),
              const SizedBox(height: 32),*/
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
        Consumer<AppModel>(builder: (context, appModel, child) {
          return ButtonGroup(buttons: [
            if (appModel.isPinEnabled) ...{
              if (appModel.canCheckBiometrics)
                SingleButton(
                  title: t.settings_screen.use_biometric,
                  rightElement: CupertinoSwitch(
                    value: appModel.hasBiometricsPermission
                        ? appModel.isBiometricEnabled
                        : false,
                    activeColor: MyColors.primary,
                    onChanged: (isOn) async {
                      if (isOn &&
                          await appModel.authenticateWithBiometrics(context,
                              isSave: true)) {
                        appModel.saveIsBiometricEnabled(true);
                      } else {
                        appModel.saveIsBiometricEnabled(false);
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
                        screenStatus: PinCheckScreenStatus.change,
                      ),
                    ),
                  );
                },
              )
            } else ...{
              SingleButton(
                title: t.settings_screen.set_password,
                rightElement: CupertinoSwitch(
                  value: appModel.isPinEnabled,
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
}
