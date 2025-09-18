import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/check_list.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class MnemonicGenerationScreen extends StatefulWidget {
  const MnemonicGenerationScreen({super.key});

  @override
  State<MnemonicGenerationScreen> createState() => _MnemonicGenerationScreenState();
}

class _MnemonicGenerationScreenState extends State<MnemonicGenerationScreen> {
  late final int _totalStep;
  int _step = 0;
  int _selectedWordsCount = 0;
  bool _usePassphrase = false;

  final ValueNotifier<bool> _regenerateNotifier = ValueNotifier<bool>(false);

  void _onRegenerate() {
    _regenerateNotifier.value = true;
  }

  void _onLengthSelected(int wordsCount) {
    setState(() {
      _selectedWordsCount = wordsCount;
      _step = _totalStep == 2 ? 1 : 2;
    });
  }

  void _onPassphraseSelected(bool selected) {
    setState(() {
      _usePassphrase = selected;
      _step = 2;
    });
  }

  void _onReset() {
    setState(() {
      _step = 0;
      _selectedWordsCount = 0;
      _usePassphrase = false;
    });
  }

  void _showStopGeneratingMnemonicDialog() {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return CoconutPopup(
              insetPadding:
                  EdgeInsets.symmetric(horizontal: MediaQuery.of(dialogContext).size.width * 0.15),
              title: t.alert.stop_generating_mnemonic.title,
              description: t.alert.stop_generating_mnemonic.description,
              backgroundColor: CoconutColors.white,
              rightButtonText: t.alert.stop_generating_mnemonic.confirm,
              rightButtonColor: CoconutColors.gray900,
              leftButtonText: t.alert.stop_generating_mnemonic.reselect,
              leftButtonColor: CoconutColors.gray900,
              onTapLeft: () {
                Navigator.pop(context);
                _onReset();
              },
              onTapRight: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                Navigator.pop(context);
              });
        });
  }

  void _onNavigateToNext() {
    Navigator.pushNamed(context, AppRoutes.mnemonicVerify);
  }

  @override
  void initState() {
    super.initState();
    Provider.of<WalletCreationProvider>(context, listen: false).resetAll();
    _totalStep =
        Provider.of<VisibilityProvider>(context, listen: false).isPassphraseUseEnabled ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WordsLengthSelection(onSelected: _onLengthSelected),
      PassphraseSelection(onSelected: _onPassphraseSelected),
      MnemonicWords(
        wordsCount: _selectedWordsCount,
        usePassphrase: _usePassphrase,
        onReset: _onReset,
        onNavigateToNext: _onNavigateToNext,
        regenerateNotifier: _regenerateNotifier,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showStopGeneratingMnemonicDialog();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            title: t.mnemonic_generate_screen.title,
            context: context,
            onBackPressed: _showStopGeneratingMnemonicDialog,
            backgroundColor: CoconutColors.white,
            actionButtonList: [
              if (_step == 2)
                IconButton(
                  onPressed: _onRegenerate,
                  icon: SvgPicture.asset('assets/svg/refresh.svg', width: 18, height: 18),
                ),
            ],
          ),
          body: SafeArea(
            child: screens[_step],
          ),
        ),
      ),
    );
  }
}

class WordsLengthSelection extends StatefulWidget {
  final void Function(int) onSelected;

  const WordsLengthSelection({
    super.key,
    required this.onSelected,
  });

  @override
  State<WordsLengthSelection> createState() => _WordsLengthSelectionState();
}

class _WordsLengthSelectionState extends State<WordsLengthSelection> {
  int selectedWordsCount = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
      child: Column(
        children: [
          Text(
            t.mnemonic_generate_screen.select_word_length,
            style: CoconutTypography.body1_16_Bold,
          ),
          CoconutLayout.spacing_800h,
          Row(
            children: [
              _buildWordCountButton(t.mnemonic_generate_screen.twelve),
              CoconutLayout.spacing_200w,
              _buildWordCountButton(t.mnemonic_generate_screen.twenty_four),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCountButton(String text) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withOpacity(0.15),
      child: Container(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(child: Text(text, style: CoconutTypography.body1_16_Bold))),
      onPressed: () {
        setState(() {
          selectedWordsCount = text == t.mnemonic_generate_screen.twelve ? 12 : 24;
        });
        widget.onSelected(selectedWordsCount);
      },
    );
  }
}

class PassphraseSelection extends StatefulWidget {
  final void Function(bool) onSelected;

  const PassphraseSelection({
    super.key,
    required this.onSelected,
  });

  @override
  State<PassphraseSelection> createState() => _PassphraseSelectionState();
}

class _PassphraseSelectionState extends State<PassphraseSelection> {
  bool usePassphrase = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
      child: Column(
        children: [
          Text(
            t.mnemonic_generate_screen.use_passphrase,
            style: CoconutTypography.body1_16_Bold,
          ),
          CoconutLayout.spacing_800h,
          Row(
            children: [
              _buildPassphraseUseButton(t.no),
              CoconutLayout.spacing_200w,
              _buildPassphraseUseButton(t.yes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassphraseUseButton(String text) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withOpacity(0.15),
      child: Container(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(child: Text(text, style: CoconutTypography.body1_16_Bold))),
      onPressed: () {
        setState(() {
          usePassphrase = text == t.no ? false : true;
        });
        widget.onSelected(usePassphrase);
      },
    );
  }
}

enum MnemonicWordsFrom {
  coinflip,
  generation,
}

class MnemonicWords extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;
  final MnemonicWordsFrom from;
  final VoidCallback onNavigateToNext;
  final ValueNotifier<bool>? regenerateNotifier;

  const MnemonicWords({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
    required this.onNavigateToNext,
    this.from = MnemonicWordsFrom.generation,
    this.regenerateNotifier,
  });

  @override
  State<MnemonicWords> createState() => _MnemonicWordsState();
}

class _MnemonicWordsState extends State<MnemonicWords> {
  late WalletCreationProvider _walletCreationProvider;
  late int stepCount; // 총 화면 단계
  int step = 0;
  String mnemonic = '';
  String passphrase = '';
  String passphraseConfirm = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _passphraseConfirmController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final FocusNode _passphraseConfirmFocusNode = FocusNode();
  bool passphraseObscured = false;
  bool isValid = true;
  bool isPassphraseConfirmVisible = false;
  bool isPassphraseNotMached = false;
  bool hasScrolledToBottom = false; // 니모닉 리스트를 끝까지 확인했는지 추적
  String errorMessage = '';

  final List<ChecklistItem> checklistItem = [
    ChecklistItem(title: t.mnemonic_generate_screen.ensure_backup)
  ];

  void _generateMnemonicPhrase() {
    Seed randomSeed = Seed.random(mnemonicLength: widget.wordsCount);

    setState(() {
      mnemonic = randomSeed.mnemonic;
      hasScrolledToBottom = mnemonic.split(' ').length == 12;
    });
  }

  NextButtonState _getNextButtonState() {
    if (!widget.usePassphrase) {
      // 패스프레이즈 사용 안함 - 항상 '다음' 버튼
      return NextButtonState.nextActive;
    }

    if (step == 1) {
      // 패스프레이즈 입력 화면
      bool isActive = false;
      if (isPassphraseConfirmVisible) {
        // 패스프레이즈 확인 텍스트필드가 보이는 상태
        isActive = passphrase.isNotEmpty &&
            passphraseConfirm.isNotEmpty &&
            passphrase == passphraseConfirm;
      } else {
        // 패스프레이즈 확인 텍스트필드가 보이지 않는 상태
        isActive = _passphraseController.text.isNotEmpty;
        return isActive ? NextButtonState.nextActive : NextButtonState.nextInactive;
      }
      return isActive ? NextButtonState.completeActive : NextButtonState.completeInactive;
    } else {
      // 니모닉 생성 화면 - 항상 '다음' 버튼
      return NextButtonState.nextActive;
    }
  }

  @override
  void initState() {
    super.initState();
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);
    stepCount = widget.usePassphrase ? 2 : 1;
    if (widget.from == MnemonicWordsFrom.generation) {
      _generateMnemonicPhrase();
    }
    if (widget.from == MnemonicWordsFrom.coinflip) {
      mnemonic = _walletCreationProvider.secret!;
    }

    widget.regenerateNotifier?.addListener(_onRegenerateRequested);

    // 스크롤 리스너 추가
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        // 스크롤이 끝에 가까워지면 확인 완료로 표시
        if (currentScroll >= maxScroll - 50) {
          if (!hasScrolledToBottom) {
            setState(() {
              hasScrolledToBottom = true;
            });
          }
        }
      }
    });
    _passphraseController.addListener(() {
      if (_passphraseConfirmController.text.isNotEmpty) {
        setState(() {
          passphrase = _passphraseController.text;
        });
      } else {
        setState(() {}); // clear text 아이콘 보이기 위함
      }
    });
    _passphraseConfirmController.addListener(() {
      setState(() {
        passphraseConfirm = _passphraseConfirmController.text;
        // isPassphraseNotMached 조건 체크
        if (passphrase.isNotEmpty &&
            passphraseConfirm.isNotEmpty &&
            passphrase != passphraseConfirm) {
          isPassphraseNotMached = true;
        } else {
          isPassphraseNotMached = false;
        }
      });
    });

    _passphraseConfirmFocusNode.addListener(() {
      if (_passphraseConfirmFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 300));
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      } else {
        // passphraseConfirm 입력이 멈춘 후 (포커스를 잃은 후) 매칭 여부 체크
        if (passphrase.isNotEmpty &&
            passphraseConfirm.isNotEmpty &&
            passphrase != passphraseConfirm) {
          setState(() {
            isPassphraseNotMached = true;
          });
        }
      }
    });
  }

  void _onRegenerateRequested() {
    if (widget.regenerateNotifier?.value == true) {
      _generateMnemonicPhrase();
      widget.regenerateNotifier?.value = false;
    }
  }

  @override
  void dispose() {
    widget.regenerateNotifier?.removeListener(_onRegenerateRequested);

    _scrollController.dispose();
    _passphraseController.dispose();
    _passphraseConfirmController.dispose();
    _passphraseFocusNode.dispose();
    _passphraseConfirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                color: CoconutColors.white,
                child: Column(
                  children: [
                    _buildStepIndicator(),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                      ),
                      child: Text(
                        step == 0
                            ? t.mnemonic_generate_screen.backup_guide
                            : isPassphraseNotMached
                                ? t.mnemonic_generate_screen.passphrase_not_matched
                                : t.mnemonic_generate_screen.enter_passphrase,
                        style: CoconutTypography.body1_16_Bold.setColor(
                          step == 0
                              ? CoconutColors.warningText
                              : isPassphraseNotMached
                                  ? CoconutColors.warningText
                                  : CoconutColors.black,
                        ),
                      ),
                    ),
                    step == 0
                        ? MnemonicList(mnemonic: mnemonic, isLoading: mnemonic.isEmpty)
                        : _buildPassphraseInput(),
                    const SizedBox(height: 100),
                  ],
                )),
          ),
          FixedBottomButton(
            isActive: _getNextButtonState().isActive,
            text: _getNextButtonState().text,
            backgroundColor: CoconutColors.black,
            onButtonClicked: () {
              if (widget.from == MnemonicWordsFrom.coinflip) {
                widget.onNavigateToNext();
                return;
              }
              if (step == 0 && stepCount == 2) {
                if (hasScrolledToBottom) {
                  // 니모닉 리스트를 끝까지 확인했다면 다음 단계로
                  setState(() {
                    step = 1;
                  });
                } else {
                  // 아직 끝까지 확인하지 않았다면 스크롤을 하단으로 이동
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              }
              if (!widget.usePassphrase) {
                if (!hasScrolledToBottom) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  return;
                }
                _walletCreationProvider.setSecretAndPassphrase(mnemonic, passphrase);
                _passphraseFocusNode.unfocus();
                _passphraseConfirmFocusNode.unfocus();
                widget.onNavigateToNext();
              }
              if (widget.usePassphrase && step == 1) {
                if (!isPassphraseConfirmVisible && _passphraseController.text.isNotEmpty) {
                  _passphraseFocusNode.unfocus();
                  _passphraseConfirmFocusNode.unfocus();
                  setState(() {
                    passphrase = _passphraseController.text;
                    isPassphraseConfirmVisible = true;
                  });
                } else if (passphrase.isNotEmpty &&
                    passphraseConfirm.isNotEmpty &&
                    passphrase == passphraseConfirm) {
                  _walletCreationProvider.setSecretAndPassphrase(mnemonic, passphrase);
                  _passphraseFocusNode.unfocus();
                  _passphraseConfirmFocusNode.unfocus();
                  widget.onNavigateToNext();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Visibility(
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      visible: widget.usePassphrase,
      child: Container(
        padding: const EdgeInsets.only(
          top: 16,
        ),
        child: Stack(
          children: [
            const SizedBox(
              height: 50,
              width: 120,
              child: Center(
                child: DottedDivider(
                  height: 2.0,
                  width: 100,
                  dashWidth: 2.0,
                  dashSpace: 4.0,
                  color: CoconutColors.gray400,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: NumberWidget(
                  number: 1,
                  selected: step == 0,
                  onSelected: () {
                    setState(() {
                      step = 0;
                    });
                  }),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: NumberWidget(
                  number: 2,
                  selected: step == 1,
                  onSelected: () {
                    setState(() {
                      step = 1;
                    });
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassphraseInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              child: CoconutTextField(
                focusNode: _passphraseFocusNode,
                controller: _passphraseController,
                placeholderText: t.mnemonic_generate_screen.memorable_passphrase_guide,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                  if (_passphraseController.text.isNotEmpty) {
                    setState(() {
                      isPassphraseConfirmVisible = true;
                    });
                  }
                },
                onChanged: (_) {},
                maxLines: 1,
                obscureText: passphraseObscured,
                suffix: Row(
                  children: [
                    if (_passphraseController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _passphraseController.text = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            'assets/svg/text-field-clear.svg',
                            colorFilter:
                                const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          passphraseObscured = !passphraseObscured;
                        });
                      },
                      child: passphraseObscured
                          ? Container(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 8,
                                bottom: 8,
                                left: 8,
                              ),
                              child: const Icon(
                                CupertinoIcons.eye_slash,
                                color: CoconutColors.gray800,
                                size: 18,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 8,
                                bottom: 8,
                                left: 8,
                              ),
                              child: const Icon(
                                CupertinoIcons.eye,
                                color: CoconutColors.gray800,
                                size: 18,
                              ),
                            ),
                    ),
                  ],
                ),
                maxLength: 100,
              ),
            ),
          ),
          if (isPassphraseConfirmVisible)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                child: CoconutTextField(
                  focusNode: _passphraseConfirmFocusNode,
                  controller: _passphraseConfirmController,
                  placeholderText: t.mnemonic_generate_screen.passphrase_confirm_guide,
                  onChanged: (_) {},
                  maxLines: 1,
                  suffix: Row(
                    children: [
                      if (_passphraseConfirmController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _passphraseConfirmController.text = '';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/svg/text-field-clear.svg',
                              colorFilter:
                                  const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                            ),
                          ),
                        ),
                    ],
                  ),
                  maxLength: 100,
                ),
              ),
            ),
          CoconutLayout.spacing_2500h,
        ],
      ),
    );
  }
}

class NumberWidget extends StatefulWidget {
  final int number;
  final bool selected;
  final Function() onSelected;

  const NumberWidget(
      {super.key, required this.number, required this.selected, required this.onSelected});

  @override
  State<NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<NumberWidget> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = CoconutColors.gray800;
    Color iconColor = CoconutColors.white;
    bool isFirst = widget.number == 1;
    return GestureDetector(
      onTap: widget.onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
            EdgeInsets.only(left: isFirst ? 8 : 16, right: isFirst ? 16 : 8, top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: widget.selected ? bgColor : CoconutColors.gray400,
            border: widget.selected ? Border.all(color: CoconutColors.gray800) : null,
            shape: BoxShape.circle,
          ),
          width: widget.selected ? 28 : 12,
          child: widget.selected
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(widget.selected ? 8 : 6),
                    child: Text(
                      widget.number.toString(),
                      style: CoconutTypography.body3_12_Number.setColor(iconColor),
                    ),
                  ),
                )
              : Container(),
        ),
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  final double height;
  final double width;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const DottedDivider({
    super.key,
    this.height = 1.0,
    this.width = double.infinity,
    this.dashWidth = 2.0,
    this.dashSpace = 2.0,
    this.color = CoconutColors.gray500,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: CustomPaint(
        size: Size(width, height),
        painter: DottedLinePainter(
          dashWidth: dashWidth,
          dashSpace: dashSpace,
          color: color,
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double dashWidth;
  final double dashSpace;
  final Color color;

  DottedLinePainter({
    required this.dashWidth,
    required this.dashSpace,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

enum NextButtonState {
  completeActive, // '완료' + 활성화
  completeInactive, // '완료' + 비활성화
  nextActive, // '다음' + 활성화
  nextInactive // '다음' + 비활성화
}

extension NextButtonStateExtension on NextButtonState {
  String get text {
    switch (this) {
      case NextButtonState.completeActive:
      case NextButtonState.completeInactive:
        return t.complete;
      case NextButtonState.nextActive:
      case NextButtonState.nextInactive:
        return t.next;
    }
  }

  bool get isActive {
    switch (this) {
      case NextButtonState.completeActive:
      case NextButtonState.nextActive:
        return true;
      case NextButtonState.completeInactive:
      case NextButtonState.nextInactive:
        return false;
    }
  }
}
