import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/uri_launcher.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
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
        ? '튜토리얼을 참고하시면\n더욱 쉽게 사용할 수 있어요'
        : '도움이 필요하신가요?';
    subtitleText = (widget.screenStatus == TutorialScreenStatus.entrance)
        ? '인터넷 주소창에 입력해 주세요\ncoconut.onl'
        : '튜토리얼과 함께 사용해 보세요';
    contentText = (widget.screenStatus == TutorialScreenStatus.entrance)
        ? ''
        : '인터넷 주소창에 입력해 주세요\ncoconut.onl';
  }

  @override
  Widget build(BuildContext context) {
    List<String> splitTexts =
        (widget.screenStatus == TutorialScreenStatus.entrance)
            ? subtitleText.split('\n')
            : contentText.split('\n');
    return widget.screenStatus == TutorialScreenStatus.entrance
        ? Scaffold(
            backgroundColor: MyColors.white,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    top: 30,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/welcome'),
                      style: TextButton.styleFrom(
                        foregroundColor: MyColors.darkgrey,
                      ),
                      child: const Text(
                        '건너뛰기',
                        style: Styles.caption,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          titleText,
                          style: Styles.title5,
                          textAlign: TextAlign.center,
                        ),
                        Selector<AppModel, bool?>(
                            selector: (context, model) => model.isNetworkOn,
                            builder: (context, networkOn, _) {
                              if (networkOn!) {
                                // 네트워크 연결 상태일 때
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 26),
                                    _browserImage(),
                                    const SizedBox(height: 30),
                                    ShrinkAnimationButton(
                                      onPressed: () => launchURL(
                                        'https://noncelab.gitbook.io/coconut.onl',
                                        defaultMode: false,
                                      ),
                                      defaultColor: MyColors.darkgrey,
                                      pressedColor: MyColors.borderGrey,
                                      borderRadius: 12,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          '튜토리얼 보기',
                                          style: Styles.caption.merge(
                                            const TextStyle(
                                                color: MyColors.white,
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
            appBar: CustomAppBar.buildWithClose(title: '', context: context),
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
                      style: Styles.title5,
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
          style: Styles.body2.merge(
            const TextStyle(
              color: MyColors.darkgrey,
            ),
          ),
        ),
        Text(
          splitTexts[1],
          style: Styles.body2Bold.merge(
            const TextStyle(
              color: MyColors.darkgrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _browserImage() {
    return Image.asset(
      'assets/png/browser.png',
      width: 222,
      fit: BoxFit.fitWidth,
    );
  }
}
