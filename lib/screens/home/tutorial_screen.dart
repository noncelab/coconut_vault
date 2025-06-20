import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/external_links.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/utils/uri_launcher.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TutorialScreenStatus {
  entrance, // 앱 최초 실행
  modal, // 앱바의 튜토리얼 버튼을 이용한 진입
}

class TutorialScreen extends StatefulWidget {
  final TutorialScreenStatus screenStatus;
  const TutorialScreen({
    super.key,
    required this.screenStatus,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late String titleText;
  late String subtitleText;
  late String contentText;

  @override
  void initState() {
    super.initState();
    titleText = (widget.screenStatus == TutorialScreenStatus.entrance)
        ? t.tutorial_screen.title1
        : t.tutorial_screen.title2;
    subtitleText = (widget.screenStatus == TutorialScreenStatus.entrance)
        ? t.tutorial_screen.content
        : t.tutorial_screen.subtitle;
    contentText =
        (widget.screenStatus == TutorialScreenStatus.entrance) ? '' : t.tutorial_screen.content;
  }

  @override
  Widget build(BuildContext context) {
    List<String> splitTexts = (widget.screenStatus == TutorialScreenStatus.entrance)
        ? subtitleText.split('\n')
        : contentText.split('\n');
    return widget.screenStatus == TutorialScreenStatus.entrance
        ? Scaffold(
            backgroundColor: CoconutColors.white,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    top: 30,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.welcome),
                      style: TextButton.styleFrom(
                        foregroundColor: CoconutColors.gray800,
                      ),
                      child: Text(
                        t.skip,
                        style: CoconutTypography.body3_12.setColor(
                          CoconutColors.gray800,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          titleText,
                          style: CoconutTypography.heading3_21.merge(
                            const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Selector<ConnectivityProvider, bool>(
                            selector: (context, model) => model.isNetworkOn == true,
                            builder: (context, networkOn, _) {
                              if (networkOn) {
                                // 네트워크 연결 상태일 때
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 26),
                                    _browserImage(),
                                    const SizedBox(height: 30),
                                    ShrinkAnimationButton(
                                      onPressed: () => launchURL(
                                        COCONUT_TUTORIAL_URL,
                                        defaultMode: false,
                                      ),
                                      defaultColor: CoconutColors.gray800,
                                      pressedColor: CoconutColors.borderGray,
                                      borderRadius: 12,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          t.view_tutorial,
                                          style: CoconutTypography.body3_12.merge(
                                            const TextStyle(
                                                color: CoconutColors.white,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              /// 네트워크 연결 되지 않은 상태일 때
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  _splitTextWidget(splitTexts),
                                  const SizedBox(height: 20),
                                  _browserImage(),
                                ],
                              );
                            })
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.transparent,
            appBar: CoconutAppBar.build(title: '', context: context, isBottom: true),
            body: SafeArea(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 80,
                    ),
                    Text(
                      titleText,
                      style: CoconutTypography.heading3_21.merge(
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(subtitleText),
                    const SizedBox(height: 20),
                    _browserImage(),
                    const SizedBox(height: 20),
                    _splitTextWidget(splitTexts),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _splitTextWidget(List<String> splitTexts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          splitTexts[0],
          style: CoconutTypography.body2_14.setColor(
            CoconutColors.gray800,
          ),
        ),
        Text(
          splitTexts[1],
          style: CoconutTypography.body2_14_Bold.setColor(
            CoconutColors.gray800,
          ),
        ),
      ],
    );
  }

  Widget _browserImage() {
    return Image.asset(
      'assets/png/browser_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
      width: 222,
      fit: BoxFit.fitWidth,
    );
  }
}
