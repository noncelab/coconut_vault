import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
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
        titleTextStyle: CoconutTypography.body1_16,
        toolbarTextStyle: CoconutTypography.heading4_18,
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
              // TODO: 복원 기능 테스트를 위해 임시 주석 처리
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
                      activeColor: CoconutColors.black,
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
          ],
        ),
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
              color: CoconutColors.black,
              fontSize: 16,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.bold,
            )),
      ),
      Consumer<VisibilityProvider>(builder: (context, provider, child) {
        return ButtonGroup(buttons: [
          SingleButton(
            title: t.settings_screen.use_passphrase,
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
