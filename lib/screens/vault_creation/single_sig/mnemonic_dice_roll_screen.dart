import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class MnemonicDiceRollScreen extends StatefulWidget {
  const MnemonicDiceRollScreen({super.key});

  @override
  State<MnemonicDiceRollScreen> createState() => _MnemonicDiceRollScreenState();
}

class _MnemonicDiceRollScreenState extends State<MnemonicDiceRollScreen> {
  late final int _totalStep;
  int _step = 0;
  int _selectedWordsCount = 0;
  bool _usePassphrase = false;
  bool finished = false;

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
      finished = false;
    });
  }

  void _showStopGeneratingMnemonicDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
          );
        });
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
      DiceRoll(
        wordsCount: _selectedWordsCount,
        usePassphrase: _usePassphrase,
        onReset: _onReset,
      )
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
              title: t.mnemonic_dice_roll_screen.title,
              context: context,
              onBackPressed: _showStopGeneratingMnemonicDialog,
              backgroundColor: CoconutColors.white,
            ),
            body: SafeArea(
              child: screens[_step],
            )),
      ),
    );
  }
}

class DiceRoll extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;

  const DiceRoll({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
  });

  @override
  State<DiceRoll> createState() => _DiceRollState();
}

class _DiceRollState extends State<DiceRoll> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _passphraseConfirmController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final FocusNode _passphraseConfirmFocusNode = FocusNode();
  late int stepCount; // 총 화면 단계
  int step = 0;
  String _mnemonic = '';
  String _passphrase = '';
  String _passphraseConfirm = '';

  // dice roll 관련 변수
  int diceNumbers = 0;
  final List<int> _diceNumbers = [];
  final List<int> _bits = [];
  // late int _totalCount;
  int _currentIndex = 0;

  // 이안콜만 방식: 주사위 매핑
  final diceMapping = {
    1: [0, 1],
    2: [1, 0],
    3: [1, 1],
    4: [0],
    5: [1],
    6: [0, 0],
  };

  // passphrase 관련 변수
  bool passphraseObscured = false;
  bool isPassphraseConfirmVisible = false;

  bool isNextButtonActive = false;

  @override
  void initState() {
    super.initState();

    stepCount = widget.usePassphrase ? 2 : 1;
    _passphraseController.addListener(() {
      setState(() {
        _passphrase = _passphraseController.text;
      });
    });
    _passphraseConfirmController.addListener(() {
      setState(() {
        _passphraseConfirm = _passphraseConfirmController.text;
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
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _passphraseController.dispose();
    _passphraseFocusNode.dispose();
    _passphraseConfirmController.dispose();
    _passphraseConfirmFocusNode.dispose();
    super.dispose();
  }

  NextButtonState _getNextButtonState() {
    if (step == 0 && stepCount == 1) {
      // 패스프레이즈 사용 안함 - dice roll 화면
      return _bits.length >= (widget.wordsCount == 12 ? 128 : 256)
          ? NextButtonState.completeActive
          : NextButtonState.completeInactive;
    }

    if (step == 0 && stepCount == 2) {
      // 패스프레이즈 사용 - dice roll 화면
      return _bits.length >= (widget.wordsCount == 12 ? 128 : 256)
          ? NextButtonState.nextActive
          : NextButtonState.nextInactive;
    }

    // 패스프레이즈 입력 화면
    bool isActive = false;
    if (isPassphraseConfirmVisible) {
      // 패스프레이즈 확인 텍스트필드가 보이는 상태
      isActive = _passphrase.isNotEmpty &&
          _passphraseConfirm.isNotEmpty &&
          _passphrase == _passphraseConfirm;
    } else {
      // 패스프레이즈 확인 텍스트필드가 보이지 않는 상태
      isActive = _passphraseController.text.isNotEmpty;
      return isActive ? NextButtonState.nextActive : NextButtonState.nextInactive;
    }
    return isActive ? NextButtonState.completeActive : NextButtonState.completeInactive;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepIndicator(),
              step == 0 ? _buildDiceRollWidget() : _buildPassphraseInput(),
            ],
          ),
        ),
        _buildProgressBar(),
        FixedBottomTweenButton(
          showGradient: false,
          leftButtonRatio: 0.35,
          leftButtonClicked: () {
            _showAllBitsBottomSheet();
          },
          rightButtonClicked: () {
            _onNextButtonClicked();
          },
          isRightButtonActive: _bits.length >= (widget.wordsCount == 12 ? 128 : 256),
          leftText: t.view_all,
          rightText: _getNextButtonState().text,
        ),
      ],
    );
  }

  Widget _buildPassphraseInput() {
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        children: [
          Text(
            t.mnemonic_generate_screen.enter_passphrase,
            style: CoconutTypography.body1_16_Bold.setColor(
              step == 0 ? CoconutColors.warningText : CoconutColors.black,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
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

  Widget _buildDiceRollWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Opacity(
            opacity: _diceNumbers.isEmpty || _bits.length >= (widget.wordsCount == 12 ? 128 : 256)
                ? 1.0
                : 0.0,
            child: Text(
                _diceNumbers.isEmpty
                    ? t.mnemonic_dice_roll_screen.guide1
                    : t.mnemonic_dice_roll_screen.guide2,
                style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.gray800),
                textAlign: TextAlign.center),
          ),
          CoconutLayout.spacing_400h,
          _buildDiceGrid(),
          CoconutLayout.spacing_200h,
          CoconutLayout.spacing_1400h,
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Visibility(
        visible: step == 0,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
        child: Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Stack(
            children: [
              ClipRRect(
                child: Container(
                  height: 6,
                  color: CoconutColors.black.withOpacity(0.06),
                ),
              ),
              ClipRRect(
                borderRadius: _bits.length / (widget.wordsCount == 12 ? 128 : 256) == 1
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                        topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width *
                      (_bits.length / (widget.wordsCount == 12 ? 128 : 256)),
                  color: CoconutColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNextButtonClicked() {
    // 패프 사용안함 | Coinflip 화면
    if (step == 0 && stepCount == 1) {
      setState(() {
        if (_generateMnemonicPhrase()) {
          Provider.of<WalletCreationProvider>(context, listen: false)
              .setSecretAndPassphrase(_mnemonic, _passphrase);
          Navigator.pushNamed(context, AppRoutes.mnemonicManualEntropyConfirmation);
        }
      });
      return;
    }

    // 패프 사용함 | Coinflip 화면
    if (step == 0 && stepCount == 2) {
      setState(() {
        step = 1;
      });
      return;
    }

    // 패프 사용함 | 패프 입력 화면
    if (widget.usePassphrase && step == 1) {
      if (!isPassphraseConfirmVisible && _passphraseController.text.isNotEmpty) {
        // 패스프레이즈 입력 완료 | 패스프레이즈 확인 텍스트필드는 보이지 않을 때
        _passphraseFocusNode.unfocus();
        _passphraseConfirmFocusNode.unfocus();
        setState(() {
          _passphrase = _passphraseController.text;
          isPassphraseConfirmVisible = true;
        });
      } else if (_passphrase.isNotEmpty &&
          _passphraseConfirm.isNotEmpty &&
          _passphrase == _passphraseConfirm &&
          _generateMnemonicPhrase()) {
        // 패스프레이즈 입력 완료 | dice roll 데이터로 니모닉 생성 시도 성공
        Provider.of<WalletCreationProvider>(context, listen: false)
            .setSecretAndPassphrase(_mnemonic, _passphrase);
        _passphraseFocusNode.unfocus();
        _passphraseConfirmFocusNode.unfocus();

        Navigator.pushNamed(context, AppRoutes.mnemonicManualEntropyConfirmation);
      }
    }
  }

  Widget _buildStepIndicator() {
    return Visibility(
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      visible: widget.usePassphrase,
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
    );
  }

  Widget _buildDiceGrid() {
    const int gridElements = 10;
    int start;
    int end;
    List<int> currentRolls;

    // 현재 인덱스가 마지막 그룹에 있는지 확인
    // if (_currentIndex >= _totalCount ~/ gridElements * gridElements &&
    //     _currentIndex < _totalCount) {
    //   start = _totalCount ~/ gridElements * gridElements;
    //   end = _totalCount;
    // } else {
    start = _currentIndex ~/ gridElements * gridElements;
    end = start + gridElements;
    currentRolls = _diceNumbers.sublist(start, _currentIndex);
    // }

    currentRolls = _diceNumbers.sublist(start, _currentIndex);

    return Column(
      children: List.generate(2, (rowIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (colIndex) {
            int index = rowIndex * 5 + colIndex;
            int slotNumber = start + index + 1; // 슬롯 번호 (51, 52, 53, ...)
            bool hasData = index < currentRolls.length && slotNumber <= _bits.length; // 실제 데이터가 있는지

            return Container(
              width: 50,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: CoconutColors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(12),
                color: CoconutColors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$slotNumber',
                    style: CoconutTypography.body3_12_Number.setColor(
                      CoconutColors.black.withOpacity(0.3),
                    ),
                  ),
                  CoconutLayout.spacing_200h,
                  Text(
                    hasData ? '${currentRolls[index]}' : '',
                    style: CoconutTypography.heading4_18_NumberBold.setColor(
                      hasData ? CoconutColors.black : CoconutColors.white,
                    ),
                  )
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildButtons() {
    final List<int> diceNumbers = [-100, 1, 2, 3, -1, 4, 5, 6];
    //2x3 그리드로 그리기
    final List<Widget> buttons = diceNumbers.map((diceNumber) {
      if (diceNumber == -100) {
        // delete all
        return _buildDeleteButton(
          buttonText: t.delete_all,
          onButtonPressed: () => _showConfirmResetDialog(
              title: t.delete_all, message: t.alert.erase_all_entered_so_far, action: _resetBits),
        );
      }
      if (diceNumber == -1) {
        // delete one
        return _buildDeleteButton(
          buttonText: t.delete_one,
          onButtonPressed: () => _deleteRoll(),
        );
      }
      return _buildNumberButton(
        buttonText: diceNumber.toString(),
        onButtonPressed: () => _addRoll(diceNumber),
      );
    }).toList();

    return SizedBox(
      width: 282 + 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(2, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (colIndex) {
              return buttons[rowIndex * 4 + colIndex];
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDeleteButton({required String buttonText, required VoidCallback onButtonPressed}) {
    return ShrinkAnimationButton(
      onPressed: onButtonPressed,
      borderRadius: 12,
      child: SizedBox(
        width: 100,
        height: 40,
        child: Center(
            child: Text(
          buttonText,
          style: CoconutTypography.body3_12.setColor(
            _diceNumbers.isEmpty
                ? CoconutColors.secondaryText
                : CoconutColors.black.withOpacity(0.7),
          ),
        )),
      ),
    );
  }

  Widget _buildNumberButton({
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    const double boxWidth = 282 + 30;
    const double buttonWidth = boxWidth / 4 - 12;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ShrinkAnimationButton(
        onPressed: onButtonPressed,
        borderRadius: 12,
        child: Container(
          width: buttonWidth,
          height: buttonWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CoconutColors.black,
              width: 1,
            ),
          ),
          child: Center(
              child: SvgPicture.asset(
            'assets/svg/dice/$buttonText.svg',
            width: 44,
            height: 44,
          )),
        ),
      ),
    );
  }

  void _addRoll(int number) async {
    setState(() {
      _diceNumbers.add(number);
      _bits.addAll(diceMapping[number] ?? []);
      _currentIndex++;
    });
  }

  void _deleteRoll() async {
    if (_currentIndex == 0) return;

    setState(() {
      final removedNumber = _diceNumbers.removeLast();
      _bits.removeRange(_bits.length - (diceMapping[removedNumber]?.length ?? 0), _bits.length);
      _currentIndex--;
    });
  }

  void _resetBits() {
    setState(() {
      _diceNumbers.clear();
      _bits.clear();
      _currentIndex = 0;
    });
  }

  void _showConfirmResetDialog({String? title, String? message, VoidCallback? action}) {
    if (_currentIndex == 0) return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: title ?? t.delete_all,
            description: message ?? t.alert.erase_all_entered_so_far,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonColor: CoconutColors.black.withOpacity(0.7),
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.warningText,
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              _resetBits();
              Navigator.pop(context);
            },
          );
        });
  }

  bool _generateMnemonicPhrase() {
    try {
      setState(() {
        int bitsToUse = (_bits.length / 32).floor() * 32;
        int start = _bits.length - bitsToUse;
        Logger.log('diceRolls: ${_diceNumbers.join()}');
        Logger.log('bits sublist: ${_bits.sublist(start).join()}');
        _mnemonic =
            Seed.fromBinaryEntropy(_bits.sublist(start).map((int bit) => bit.toString()).join())
                .mnemonic
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'\s+'), ' ');
      });
      return true;
    } catch (e) {
      Logger.log('error: $e');
      return false;
    }
  }

  void _showAllBitsBottomSheet() {
    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      minChildSize: 0.5,
      childBuilder: (scrollController) => BinaryGrid(
          totalBits: _bits.length,
          bits: _diceNumbers,
          wordsCount: widget.wordsCount,
          scrollController: scrollController),
    );
  }
}

class BinaryGrid extends StatelessWidget {
  final int totalBits;
  final List<int> bits;
  final ScrollController scrollController;
  final int wordsCount;

  const BinaryGrid(
      {super.key,
      required this.totalBits,
      required this.bits,
      required this.wordsCount,
      required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('${t.view_all}(${bits.length}/${wordsCount == 12 ? 128 : 256})',
                style: CoconutTypography.body2_14_Bold),
            CoconutLayout.spacing_200h,
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: GridView.count(
                  controller: scrollController,
                  scrollDirection: Axis.vertical,
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  padding: const EdgeInsets.only(bottom: 30),
                  children: List.generate(bits.length, (index) {
                    return _buildGridItem(index < bits.length ? bits[index] : null, index);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(int? bit, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CoconutColors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (index + 1).toString(),
              style: CoconutTypography.body3_12_Number.setColor(
                CoconutColors.black.withOpacity(0.3),
              ),
            ),
            Expanded(
              child: Text(
                bit == null ? '' : bit.toString(),
                style: CoconutTypography.heading4_18_NumberBold.setColor(
                  CoconutColors.black.withOpacity(0.7),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
