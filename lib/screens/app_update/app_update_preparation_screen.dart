import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/app_update_step_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/app_update_preparation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/indicator/countdown_spinner.dart';
import 'package:coconut_vault/widgets/indicator/percent_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class UpdateProcessText {
  String title;
  String subtitle;

  UpdateProcessText({required this.title, required this.subtitle});
}

class AppUpdatePreparationScreen extends StatefulWidget {
  const AppUpdatePreparationScreen({super.key});

  @override
  State<AppUpdatePreparationScreen> createState() => _AppUpdatePreparationScreenState();
}

class _AppUpdatePreparationScreenState extends State<AppUpdatePreparationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _mnemonicWordInputController = TextEditingController();
  final _mnemonicInputFocusNode = FocusNode();

  bool _mnemonicErrorVisible = false;
  bool _nextButtonEnabled = true;

  AppUpdateStep _currentStep = AppUpdateStep.initial;
  bool get _isInProgressStep {
    final inFileEncryptionSteps = {
      AppUpdateStep.generateSafetyKey,
      AppUpdateStep.saveWalletData,
      AppUpdateStep.verifyBackupFile,
      AppUpdateStep.completed,
    };
    return inFileEncryptionSteps.contains(_currentStep);
  }

  final List<UpdateProcessText> _updateProcessTextList = [
    UpdateProcessText(
      // 키 생성
      title: t.prepare_update.generating_secure_key,
      subtitle: t.prepare_update.generating_secure_key_description,
    ),
    UpdateProcessText(
      // 지갑 데이터 저장
      title: t.prepare_update.saving_wallet_data,
      subtitle: t.prepare_update.waiting_message,
    ),
    UpdateProcessText(
      // 저장 확인
      title: t.prepare_update.verifying_safe_storage,
      subtitle: t.prepare_update.update_recovery_info,
    ),
  ];

  late AnimationController _animationController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<Offset> _slideUpAnimation;
  late AnimationController _progressController;

  bool _hasAddedListener = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _mnemonicWordInputController.dispose();
    _mnemonicInputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppUpdatePreparationViewModel(
        Provider.of<WalletProvider>(context, listen: false),
      ),
      child: Consumer<AppUpdatePreparationViewModel>(
        builder: (context, viewModel, child) {
          if (!_hasAddedListener) {
            _mnemonicWordInputController.addListener(() {
              _handleMnemonicWordInput(context);
            });
            _mnemonicInputFocusNode.addListener(() {
              _handleMnemonicWordInput(context);
            });
            _hasAddedListener = true;
          }
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _onBackPressed();
              }
            },
            child: GestureDetector(
              onTap: _closeKeyboard,
              child: Scaffold(
                backgroundColor: CoconutColors.white,
                appBar: !_isInProgressStep
                    ? CoconutAppBar.build(
                        title: t.settings_screen.prepare_update,
                        context: context,
                        onBackPressed: _onBackPressed,
                        isLeadingVisible: !_isInProgressStep,
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
                        _buildBodyWidget(),
                        if (_currentStep == AppUpdateStep.initial ||
                            _currentStep == AppUpdateStep.confirmUpdate)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 40,
                            child: _buildNextButton(viewModel),
                          ),
                        if (!viewModel.isMnemonicLoaded)
                          // 뒤로가기는 가능해야 하기 때문에 loaderOverlay를 사용하지 않고 별도 구현
                          Container(
                            width: MediaQuery.sizeOf(context).width,
                            height: MediaQuery.sizeOf(context).height,
                            color: Colors.white.withOpacity(0.5),
                            child: const Center(
                              child: CoconutCircularIndicator(),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMnemonicWordInput(BuildContext context) {
    try {
      final viewModel = context.read<AppUpdatePreparationViewModel>();
      if (!viewModel.isMnemonicLoaded || _mnemonicWordInputController.text.isEmpty) {
        setState(() {
          _mnemonicErrorVisible = false;
        });
        return;
      }

      if (!_mnemonicInputFocusNode.hasFocus) {
        if (!viewModel.isWordMatched(
          _mnemonicWordInputController.text,
        )) {
          setState(() {
            _mnemonicErrorVisible = true;
          });
          return;
        }
      }

      if (_mnemonicWordInputController.text.length >= viewModel.mnemonicWordLength) {
        if (!viewModel.isWordMatched(
          _mnemonicWordInputController.text,
        )) {
          setState(() {
            _mnemonicErrorVisible = true;
          });
        } else {
          if (viewModel.isMnemonicValidationFinished) {
            _goToConfirmUpdateStep();
            return;
          }
          setState(() {
            _mnemonicErrorVisible = false;
            _mnemonicWordInputController.clear();
          });
        }
      } else {
        setState(() {
          _mnemonicErrorVisible = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _goToConfirmUpdateStep() async {
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

  void _onBackPressed() {
    if (!_isInProgressStep) {
      Navigator.pop(context);
    }
  }

  Widget _buildBodyWidget() {
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

  Widget _buildNextButton(AppUpdatePreparationViewModel viewModel) {
    return Stack(
      children: [
        CoconutButton(
          onPressed: () => _onNextButtonPressed(viewModel),
          isActive: _nextButtonEnabled && viewModel.isMnemonicLoaded,
          disabledBackgroundColor: CoconutColors.gray400,
          width: double.infinity,
          height: 52,
          text: _currentStep == AppUpdateStep.initial ? t.confirm : t.start,
        ),
        if (!_nextButtonEnabled)
          Positioned(
            right: 24,
            top: 12,
            bottom: 12,
            child: SizedBox(
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

  void _onNextButtonPressed(AppUpdatePreparationViewModel viewModel) async {
    // AppUpdateStep.initial 상태에서는 validateMnemonic 전환,
    // AppUpdateStep.confirmUpdate 상태에서는 generateSafetyKey 전환
    // AppUpdateStep.confirmUpdate 전환직후 _nextButtonEnabled이 false로 설정되고 countdown 5초 후 _nextButtonEnabled이 true로 변경됨
    if (_currentStep == AppUpdateStep.initial) {
      setState(() {
        _openKeyboard();
        _currentStep = AppUpdateStep.validateMnemonic;
      });
    } else if (_currentStep == AppUpdateStep.confirmUpdate) {
      setState(() {
        _currentStep = AppUpdateStep.generateSafetyKey;
      });
      _startFileEncryptionProgress(viewModel);
      _animationController.forward(from: 0);
    }
  }

  // AppUpdateStep.initial 상태에서 보여지는 위젯
  Widget _buildInitialWidget() {
    return Center(
      child: Column(
        children: [
          Container(
            height: CoconutLayout.spacing_2500h.height! - kToolbarHeight,
          ),
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
    return Selector<AppUpdatePreparationViewModel, Tuple2<String, int>>(
        selector: (context, viewModel) => Tuple2(viewModel.walletName, viewModel.mnemonicWordIndex),
        builder: (context, data, _) {
          final walletName = data.item1;
          final mnemonicWordIndex = data.item2;

          return Center(
            child: Column(
              children: [
                Container(
                  height: CoconutLayout.spacing_2500h.height! - kToolbarHeight,
                ),
                Text(
                  t.prepare_update.enter_nth_word_of_wallet(
                    wallet_name: walletName,
                    n: mnemonicWordIndex,
                  ),
                  style: CoconutTypography.heading4_18_Bold,
                ),
                CoconutLayout.spacing_1500h,
                CoconutTextField(
                  textInputFormatter: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                  controller: _mnemonicWordInputController,
                  focusNode: _mnemonicInputFocusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onChanged: (text) {},
                  isError: _mnemonicErrorVisible,
                  isLengthVisible: false,
                  errorText: t.prepare_update.incorrect_input_try_again,
                  placeholderText: t.prepare_update.enter_word,
                  suffix: _mnemonicWordInputController.text.isNotEmpty
                      ? IconButton(
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _mnemonicWordInputController.text = '';
                            });
                          },
                          icon: SvgPicture.asset(
                            'assets/svg/text-field-clear.svg',
                            colorFilter:
                                const ColorFilter.mode(CoconutColors.gray900, BlendMode.srcIn),
                          ),
                        )
                      : null,
                )
              ],
            ),
          );
        });
  }

  // AppUpdateStep.confirmUpdate 상태에서 보여지는 위젯
  Widget _buildConfirmUpdateWidget() {
    return Center(
      child: Column(
        children: [
          Container(
            height: CoconutLayout.spacing_2500h.height! - kToolbarHeight,
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CoconutStyles.radius_200),
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
            top: CoconutLayout.spacing_2500h.height!,
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
          top: CoconutLayout.spacing_2500h.height!,
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
          bottom: 0,
          child: Center(
            child: Stack(
              alignment: Alignment.center, // 중앙 정렬
              children: [
                PercentProgressIndicator(
                  textColor: const Color(0xFF1E88E5),
                  progressController: _progressController,
                ),
              ],
            ),
          ),
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
      Platform.isAndroid ? t.prepare_update.step1_android : t.prepare_update.step1_ios,
      t.prepare_update.step2,
    ];
    return Center(
      child: Column(
        children: [
          Container(
            height: CoconutLayout.spacing_2500h.height!,
          ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(CoconutStyles.radius_200),
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
                separatorBuilder: (context, index) => CoconutLayout.spacing_300h,
                itemCount: t.prepare_update.update_preparing_description.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startFileEncryptionProgress(AppUpdatePreparationViewModel viewModel) {
    if (_progressController.isAnimating) {
      _progressController.stop();
      return;
    }

    // 백업파일 생성 프로세스 시작
    viewModel.createBackupData();

    _progressController.addListener(() {
      setState(() {});
    });

    // viewModel에서 변경 감지 후 progressBar를 움직이도록
    viewModel.addListener(() {
      if (_currentStep == AppUpdateStep.completed) {
        return;
      }
      final progress = viewModel.backupProgress;
      debugPrint('progress: $progress');
      if (progress == 40 || progress == 80 || progress == 100) {
        // Progress animation 시작

        const duration = Duration(
          milliseconds: 5000,
        );

        _progressController
            .animateTo(
          progress / 100,
          duration: duration,
        )
            .then((_) {
          if (progress == 40) {
            debugPrint('createBackupData 완료, _saveEncryptedBackupWithData 호출');
            if (_currentStep != AppUpdateStep.saveWalletData) {
              setState(() {
                _currentStep = AppUpdateStep.saveWalletData;
              });
              _animationController.forward(from: 0);
            }
          } else if (progress == 80) {
            debugPrint('encryptAndSave 완료, deleteAllWallets 호출');
            if (_currentStep != AppUpdateStep.verifyBackupFile) {
              setState(() {
                _currentStep = AppUpdateStep.verifyBackupFile;
              });
              _animationController.forward(from: 0);
            }
          } else if (progress == 100) {
            debugPrint('deleteAllWallets 완료, 프로세스 종료(1.5초 대기)');
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                setState(() {
                  _currentStep = AppUpdateStep.completed;
                });
                _animationController.forward(from: 0);
              }
            });
          }
          viewModel.setProgressReached(progress);
        });
      }
    });
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _openKeyboard() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_mnemonicInputFocusNode);
    });
  }
}
