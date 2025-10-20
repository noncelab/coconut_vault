import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/main_route_guard.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/services/security_prechecker.dart';
import 'package:coconut_vault/utils/device_secure_checker.dart';
import 'package:coconut_vault/utils/device_secure_checker.dart' as DeviceSecureChecker;
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// devicePasswordRequired: 기기 비밀번호 필요 화면(앱 최초 실행, 진입 후 표시)
// devicePasswordChanged: 기기 비밀번호 변경 감지 화면(앱 진입 후 표시)
enum DevicePasswordDetectionScreenState { devicePasswordRequired, devicePasswordChanged }

class DevicePasswordDetectionScreen extends StatefulWidget {
  final DevicePasswordDetectionScreenState state;
  final VoidCallback onComplete;
  const DevicePasswordDetectionScreen({super.key, required this.state, required this.onComplete});

  @override
  State<DevicePasswordDetectionScreen> createState() => _DevicePasswordDetectionScreenState();
}

class _DevicePasswordDetectionScreenState extends State<DevicePasswordDetectionScreen> {
  bool isDeviceSecured = false;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 화면을 강제로 리빌드하여 최신 언어 설정을 적용
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainRouteGuard(
      onAppGoActive: () async {
        // 자동 화면 전환은 devicePasswordRequired와 devicePasswordTurnedOff 상태에서만 진행
        // devicePasswordTurnedOff 상태에서는 vaultList가 0이고, 볼트 핀 설정이 없을 때만 표시되어야 함
        // 만약 핀설정이 되어있으면 결국 devicePassword를 설정하더라도 아이폰에서는 devicePasswordChanged 상태로 전환하게 됨
        // -> 자동으로 볼트 초기화를 진행할 것인지?
        // (아이폰은 키체인이 무효화 되기 때문에 이 과정을 거치는데) 안드로이드는 어떻게 되는지 확인이 필요함, 안드로이드는 초기화가 필요 없을 수도 있음
        if (widget.state == DevicePasswordDetectionScreenState.devicePasswordRequired) {
          isDeviceSecured = await DeviceSecureChecker.isDeviceSecured();
          if (isDeviceSecured) {
            if (mounted) {
              widget.onComplete();
            }
          }
        }
      },
      onAppGoBackground: () {},
      onAppGoInactive: () {},
      child: Consumer<VisibilityProvider>(
        builder: (context, visibilityProvider, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Scaffold(
              backgroundColor: _getBackgroundColor(),
              body: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          children: [
                            Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: FittedBox(fit: BoxFit.scaleDown, child: _buildTitleTextWidget()),
                                  ),
                                  CoconutLayout.spacing_300h,
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.23),

                                    child: _buildDescriptionTextWidget(),
                                  ),
                                ],
                              ),
                            ),
                            CoconutLayout.spacing_800h,
                            Flexible(
                              flex: 1,
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 80), child: _buildImage()),
                            ),
                          ],
                        ),
                      ),
                      _buildBottomButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        return CoconutColors.white;
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        return CoconutColors.gray150;
    }
  }

  Widget _buildTitleTextWidget() {
    String titleText = '';
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        titleText = t.device_password_detection_screen.device_password_required;
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        titleText = t.device_password_detection_screen.device_password_changed_question;
    }
    return Text(titleText, style: CoconutTypography.heading3_21_Bold, textAlign: TextAlign.center);
  }

  Widget _buildDescriptionTextWidget() {
    Widget descriptionTextWidget;
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        descriptionTextWidget = Text(
          t.device_password_detection_screen.device_password_setting_guide,
          style: CoconutTypography.body1_16,
          textAlign: TextAlign.center,
        );
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        descriptionTextWidget = Column(
          children: [
            Text(
              t.device_password_detection_screen.device_password_changed_guide,
              style: CoconutTypography.body1_16_Bold,
              textAlign: TextAlign.center,
            ),
            CoconutLayout.spacing_200h,
            Text(
              t.device_password_detection_screen.reset_vault_to_use,
              style: CoconutTypography.body1_16_Bold,
              textAlign: TextAlign.center,
            ),
          ],
        );
    }

    return descriptionTextWidget;
  }

  Widget _buildImage() {
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        return Image.asset('assets/png/password-required.png', fit: BoxFit.fitWidth);
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        return Image.asset('assets/png/keychain-inaccessible.png', fit: BoxFit.fitWidth, width: 100);
    }
  }

  Widget _buildBottomButton() {
    return FixedBottomButton(
      showGradient: false,
      isActive: true,
      onButtonClicked: () async => _onButtonClicked(),
      text: _getButtonText(),
    );
  }

  String _getButtonText() {
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        return t.device_password_detection_screen.go_to_settings;
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        return t.device_password_detection_screen.reset_vault;
    }
  }

  void _onButtonClicked() async {
    switch (widget.state) {
      case DevicePasswordDetectionScreenState.devicePasswordRequired:
        await openSystemSecuritySettings(
          context,
          hasDialogShownForIos: true,
          title: t.device_password_detection_screen.ios_settings_dialog_title,
          description: t.device_password_detection_screen.ios_settings_dialog_description,
          buttonText: t.confirm,
        );
        break;
      case DevicePasswordDetectionScreenState.devicePasswordChanged:
        final result = await SecurityPrechecker().deleteStoredData();
        if (mounted && result) {
          widget.onComplete();
        }
        break;
    }
  }
}
