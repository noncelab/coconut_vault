import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_availability_checker.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class JailBreakDetectionScreen extends StatefulWidget {
  final bool hasSeenGuide;
  final VoidCallback onSkip;
  final VoidCallback? onReset;
  const JailBreakDetectionScreen({super.key, required this.hasSeenGuide, required this.onSkip, this.onReset});

  @override
  State<JailBreakDetectionScreen> createState() => _JailBreakDetectionScreenState();
}

class _JailBreakDetectionScreenState extends State<JailBreakDetectionScreen> {
  @override
  void initState() {
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
    return Consumer<VisibilityProvider>(
      builder: (context, visibilityProvider, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Scaffold(
            backgroundColor: CoconutColors.white,
            body: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CoconutLayout.spacing_1600h,
                              SvgPicture.asset('assets/svg/warning-hexagon.svg', width: 48, height: 48),
                              CoconutLayout.spacing_400h,
                              Text(
                                t.jail_break_detection_screen.title,
                                style: CoconutTypography.heading3_21_Bold,
                                textAlign: TextAlign.center,
                              ),
                              CoconutLayout.spacing_300h,
                              Text(
                                t.jail_break_detection_screen.description,
                                style: CoconutTypography.body1_16,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                t.jail_break_detection_screen.description2,
                                style: CoconutTypography.body1_16_Bold,
                                textAlign: TextAlign.center,
                              ),
                              CoconutLayout.spacing_900h,
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: CoconutColors.gray150,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.jail_break_detection_screen.jail_break_guide_title,
                                      style: CoconutTypography.body1_16_Bold,
                                    ),
                                    CoconutLayout.spacing_200h,
                                    Text(
                                      t.jail_break_detection_screen.jail_break_guide_description,
                                      style: CoconutTypography.body1_16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
    );
  }

  Future<void> _storeContinueAnywayPressed() async {
    SharedPrefsRepository sharedPrefs = SharedPrefsRepository();
    await sharedPrefs.setBool(SharedPrefsKeys.jailbreakDetectionIgnored, true);
    await sharedPrefs.setInt(SharedPrefsKeys.jailbreakDetectionIgnoredTime, DateTime.now().millisecondsSinceEpoch);
  }

  Widget _buildBottomButton() {
    // 첫 실행인 경우 [그래도 계속하시겠습니다] 버튼만 표시
    if (!widget.hasSeenGuide) {
      double bottom = MediaQuery.of(context).viewInsets.bottom + 16;
      return Positioned(
        bottom: bottom,
        left: 0,
        right: 0,
        child: Center(
          child: CoconutUnderlinedButton(
            padding: const EdgeInsets.all(8),
            text: t.jail_break_detection_screen.continue_anyway,
            textStyle: CoconutTypography.body1_16,
            onTap: () async {
              await _storeContinueAnywayPressed();
              widget.onSkip();
            },
          ),
        ),
      );
    }
    // 첫 실행이 아닌 경우 [그래도 계속하시겠습니다] 버튼과 [초기화하기] 버튼 표시
    return FixedBottomButton(
      subWidget: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CoconutUnderlinedButton(
          text: t.jail_break_detection_screen.continue_anyway,
          textStyle: CoconutTypography.body2_14,
          onTap: () async {
            await _storeContinueAnywayPressed();
            widget.onSkip();
          },
        ),
      ),
      isActive: true,
      onButtonClicked: () async {
        final result = await SecureZoneManager().deleteStoredData(context.read<AuthProvider>());
        if (!mounted || !result) return;
        widget.onReset?.call();
      },
      text: t.jail_break_detection_screen.delete_data,
    );
  }
}
