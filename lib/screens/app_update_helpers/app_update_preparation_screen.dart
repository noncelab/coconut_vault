import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/create_backup_view_model.dart';
import 'package:coconut_vault/widgets/indicator/countdown_spinner.dart';
import 'package:coconut_vault/widgets/indicator/gradient_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

enum AppUpdateStep {
  initial,
  validateMnemonic,
  confirmUpdate,
  generateSafetyKey,
  saveWalletData,
  verifyBackupFile,
  completed,
}

class UpdateProcessText {
  String title;
  String subtitle;
  UpdateProcessText({required this.title, required this.subtitle});
}

class AppUpdatePreparationScreen extends StatefulWidget {
  const AppUpdatePreparationScreen({super.key});

  @override
  State<AppUpdatePreparationScreen> createState() =>
      _AppUpdatePreparationScreenState();
}

class _AppUpdatePreparationScreenState extends State<AppUpdatePreparationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _mnemonicInputController =
      TextEditingController();
  final _mnemonicInputFocusNode = FocusNode();

  bool _mnemonicErrorVisible = false;
  bool _nextButtonEnabled = true;
  final List<UpdateProcessText> _updateProcessTextList = [
    UpdateProcessText(
      title: t.prepare_update.generating_secure_key,
      subtitle: t.prepare_update.generating_secure_key_description,
    ),
    UpdateProcessText(
      title: t.prepare_update.saving_wallet_data,
      subtitle: t.prepare_update.waiting_message,
    ),
    UpdateProcessText(
      title: t.prepare_update.verifying_safe_storage,
      subtitle: t.prepare_update.update_recovery_info,
    ),
  ];

  late AnimationController _animationController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<Offset> _slideUpAnimation;
  late AnimationController _progressController;
  double _generatingUpdateProgress = 0.0;

  AppUpdateStep _currentStep = AppUpdateStep.initial;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressController = AnimationController(vsync: this);

    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _mnemonicInputController.addListener(() {
      if (_mnemonicInputController.text.length >= 3) {
        _validateMnemonic();
      } else {
        setState(() {
          _mnemonicErrorVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _mnemonicInputController.dispose();
    _mnemonicInputFocusNode.dispose();
    super.dispose();
  }

  bool _isInProgressStep() {
    final inProgressSteps = {
      AppUpdateStep.generateSafetyKey,
      AppUpdateStep.saveWalletData,
      AppUpdateStep.verifyBackupFile,
      AppUpdateStep.completed,
    };
    return inProgressSteps.contains(_currentStep);
  }

  void _onBackPressed() {
    if (!_isInProgressStep()) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: ChangeNotifierProvider(
        create: (_) => PrepareUpdateViewModel(),
        child: Consumer<PrepareUpdateViewModel>(
          builder: (context, viewModel, child) {
            return GestureDetector(
              onTap: () => _closeKeyboard(),
              child: Scaffold(
                appBar: !_isInProgressStep()
                    ? CoconutAppBar.build(
                        title: t.settings_screen.prepare_update,
                        context: context,
                        onBackPressed: _onBackPressed,
                        isLeadingVisible: !_isInProgressStep(),
                      )
                    : null,
                body: SafeArea(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CoconutLayout.defaultPadding,
                    ),
                    height: MediaQuery.sizeOf(context).height,
                    child: Stack(
                      children: [
                        _getBodyWidget(),
                        if (_currentStep == AppUpdateStep.initial ||
                            _currentStep == AppUpdateStep.confirmUpdate)
                          Positioned(
                              left: 0,
                              right: 0,
                              bottom: 40,
                              child: _buildNextButton()),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getBodyWidget() {
    switch (_currentStep) {
      case AppUpdateStep.initial:
        return _buildInitialWidget();
      case AppUpdateStep.validateMnemonic:
        return _buildValidateMnemonicWidget();
      case AppUpdateStep.confirmUpdate:
        return _buildConfirmUpdateWidget();
      case AppUpdateStep.completed:
        return _buildCompletedWidget();
      case AppUpdateStep.generateSafetyKey:
      case AppUpdateStep.saveWalletData:
      case AppUpdateStep.verifyBackupFile:
        return _buildUpdateProcessWidget();
    }
  }

  Widget _buildNextButton() {
    return Stack(
      children: [
        CoconutButton(
          onPressed: () => _onNextButtonPressed(),
          isActive: _nextButtonEnabled,
          disabledBackgroundColor: CoconutColors.gray400,
          width: double.infinity,
          text: _currentStep == AppUpdateStep.initial ? t.confirm : t.start,
        ),
        if (!_nextButtonEnabled)
          Positioned(
            right: 20,
            top: 12,
            bottom: 12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CountdownSpinner(
                startSeconds: 5,
                onCompleted: () {
                  if (!mounted) return;
                  setState(() {
                    _nextButtonEnabled = true;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  void _onNextButtonPressed() async {
    // AppUpdateStep.initial 상태에서는 validateMnemonic 전환,
    // AppUpdateStep.confirmUpdate 상태에서는 generateSafetyKey 전환
    // AppUpdateStep.confirmUpdate 전환직후 _nextButtonEnabled이 false로 설정되고 countdown 5초 후 _nextButtonEnabled이 true로 변경됨
    if (_currentStep == AppUpdateStep.initial) {
      setState(() {
        _currentStep = AppUpdateStep.validateMnemonic;
      });
    } else if (_currentStep == AppUpdateStep.confirmUpdate) {
      setState(() {
        _currentStep = AppUpdateStep.generateSafetyKey;
      });

      _startProgress();

      /// TODO: 아래 코드는 수정되어야 합니다.
      /// 백업 파일 생성 로직에 따라 맞게 수정되어야 합니다.
      await Future.delayed(const Duration(milliseconds: 5000));
      if (mounted) {
        setState(() {
          _currentStep = AppUpdateStep.saveWalletData;
        });
        _animationController.forward(from: 0);
      }

      await Future.delayed(const Duration(milliseconds: 5000));
      if (mounted) {
        setState(() {
          _currentStep = AppUpdateStep.verifyBackupFile;
        });
        _animationController.forward(from: 0);
      }
    }
  }

  // AppUpdateStep.initial 상태에서 보여지는 위젯
  Widget _buildInitialWidget() {
    return Center(
      child: Column(
        children: [
          CoconutLayout.spacing_1600h,
          Text(
            t.prepare_update.title,
            style: CoconutTypography.heading4_18_Bold,
          ),
          CoconutLayout.spacing_500h,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              t.prepare_update.description,
              style: CoconutTypography.body2_14,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // AppUpdateStep.validateMnemonic 상태에서 보여지는 위젯
  Widget _buildValidateMnemonicWidget() {
    return Center(
      child: Column(
        children: [
          CoconutLayout.spacing_1600h,
          Text(
            // TODO 지갑이름, value 삽입
            t.prepare_update
                .enter_nth_word_of_wallet(wallet_name: 'test', n: 10),
            style: CoconutTypography.heading4_18_Bold,
          ),
          CoconutLayout.spacing_1500h,
          _buildMnemonicTextField(),
        ],
      ),
    );
  }

  // AppUpdateStep.confirmUpdate 상태에서 보여지는 위젯
  Widget _buildConfirmUpdateWidget() {
    return Center(
      child: Column(
        children: [
          CoconutLayout.spacing_1600h,
          Text(
            t.prepare_update.update_preparing_title,
            style: CoconutTypography.heading4_18_Bold,
          ),
          CoconutLayout.spacing_500h,
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(CoconutStyles.radius_200),
                    color: CoconutColors.gray200,
                  ),
                  child: Text(
                    t.prepare_update.update_preparing_description[index],
                    style: CoconutTypography.body2_14,
                    textAlign: TextAlign.center,
                  ),
                );
              },
              separatorBuilder: (context, index) => CoconutLayout.spacing_300h,
              itemCount: t.prepare_update.update_preparing_description.length,
            ),
          ),
        ],
      ),
    );
  }

  // AppUpdateStep: generateSafetyKey, saveWalletData, verifyBackupFile 상태에서 보여지는 위젯
  Widget _buildUpdateProcessWidget() {
    int index = _currentStep == AppUpdateStep.generateSafetyKey
        ? 0
        : _currentStep == AppUpdateStep.saveWalletData
            ? 1
            : 2;
    int prevIndex = index - 1;
    return Stack(
      children: [
        if (index != 0)
          Positioned(
            left: 0,
            right: 0,
            top: 162,
            bottom: 0,
            child:
                // 이전 위젯 - Slide Out
                SlideTransition(
              position: _slideOutAnimation,
              child: _buildSlideAnimationTitleWidget(prevIndex),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 162,
          bottom: 0,
          child:
              // 현재 위젯 - Scale In
              AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final progress = Curves.easeOut.transform(
                _animationController.value.clamp(0.0, 1.0),
              );
              final scale = 0.7 + (progress * 0.3);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: progress,
                  child: child,
                ),
              );
            },
            child: _buildSlideAnimationTitleWidget(index),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 32,
          child: Center(
            child: Stack(
              alignment: Alignment.center, // 중앙 정렬
              children: [
                GradientCircularProgressIndicator(
                  radius: 90,
                  gradientColors: const [
                    Colors.white,
                    Color.fromARGB(255, 164, 214, 250),
                  ],
                  strokeWidth: 36.0,
                  progress: _generatingUpdateProgress,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (_generatingUpdateProgress * 100).toStringAsFixed(0),
                      style: CoconutTypography.heading1_32_Bold
                          .setColor(const Color(0xFF1E88E5))
                          .merge(const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    CoconutLayout.spacing_100w,
                    Text(
                      '%',
                      style: CoconutTypography.body1_16_Bold
                          .setColor(const Color(0xFF42A5F5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: CoconutButton(
              onPressed: () => _startProgress(), text: '임시 버튼 (재실행)'),
        ),
      ],
    );
  }

  // AppUpdateStep: generateSafetyKey, saveWalletData, verifyBackupFile 상태에서 보여지는 타이틀 위젯
  Widget _buildSlideAnimationTitleWidget(int index) {
    return Column(
      children: [
        Text(
          _updateProcessTextList[index].title,
          style: CoconutTypography.heading4_18_Bold,
          textAlign: TextAlign.center,
        ),
        CoconutLayout.spacing_300h,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _updateProcessTextList[index].subtitle,
            style: CoconutTypography.body2_14,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // AppUpdateStep.completed 상태에서 보여지는 위젯
  Widget _buildCompletedWidget() {
    final updateInstructions = [
      t.prepare_update.step0,
      Platform.isAndroid
          ? t.prepare_update.step1_android
          : t.prepare_update.step1_ios,
      t.prepare_update.step2,
    ];
    return Center(
      child: Stack(
        // 임시 버튼 없애면 stack 제거
        children: [
          Column(
            children: [
              CoconutLayout.spacing_2500h,
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final progress = Curves.easeOut.transform(
                    _animationController.value.clamp(0.0, 1.0),
                  );
                  final scale = 0.7 + (progress * 0.3);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: progress,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      t.prepare_update.completed_title,
                      style: CoconutTypography.heading4_18_Bold,
                    ),
                    CoconutLayout.spacing_500h,
                    Text(
                      t.prepare_update.completed_description,
                      style: CoconutTypography.body2_14,
                    ),
                  ],
                ),
              ),
              CoconutLayout.spacing_800h,
              Expanded(
                child: SlideTransition(
                  position: _slideUpAnimation,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        width: MediaQuery.sizeOf(context).width,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(CoconutStyles.radius_200),
                          color: CoconutColors.gray200,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}.  ',
                              style: CoconutTypography.body2_14_Bold,
                            ),
                            Expanded(
                              child: Text(
                                updateInstructions[index],
                                style: CoconutTypography.body2_14_Bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        CoconutLayout.spacing_300h,
                    itemCount:
                        t.prepare_update.update_preparing_description.length,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: CoconutButton(
                onPressed: () {
                  setState(() {
                    _currentStep = AppUpdateStep.confirmUpdate;
                  });
                },
                text: '임시 버튼 (이전단계)'),
          ),
        ],
      ),
    );
  }

  void _startProgress() {
    if (_progressController.isAnimating) {
      _progressController.stop();
      return;
    }

    /// TODO 실제 업데이트 프로세스에 맞게 수정되어야 합니다.
    _progressController.duration = const Duration(seconds: 15);
    _progressController.forward(
        from: _progressController.value == 1 ? 0 : _generatingUpdateProgress);
    _progressController.addListener(() {
      setState(() {
        _generatingUpdateProgress = _progressController.value;
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // TODO: 백업 완료 체크 조건 추가
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) {
            setState(() {
              _currentStep = AppUpdateStep.completed;
            });
            _animationController.forward(from: 0);
          }
        });
      }
    });
  }

  void _validateMnemonic() async {
    if (_mnemonicInputController.text != 'mnemonic') {
      // Replace with actual validation
      setState(() {
        _mnemonicErrorVisible = true;
      });
      return;
    }

    setState(() {
      _mnemonicErrorVisible = false;
    });
    _closeKeyboard();
    context.loaderOverlay.show();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.loaderOverlay.hide();
      setState(() {
        _currentStep = AppUpdateStep.confirmUpdate;
        _nextButtonEnabled = false;
      });
    }
    _animationController.forward(from: 0);
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  CoconutTextField _buildMnemonicTextField() {
    return CoconutTextField(
      controller: _mnemonicInputController,
      focusNode: _mnemonicInputFocusNode,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onChanged: (text) {},
      isError: _mnemonicErrorVisible,
      isLengthVisible: false,
      errorText: t.prepare_update.incorrect_input_try_again,
      placeholderText: t.prepare_update.enter_word,
      suffix: Row(children: [
        IconButton(
          iconSize: 14,
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _mnemonicInputController.text = '';
            });
          },
          icon: SvgPicture.asset(
            'assets/svg/text-field-clear.svg',
            colorFilter:
                const ColorFilter.mode(CoconutColors.gray300, BlendMode.srcIn),
          ),
        ),
      ]),
    );
  }
}
