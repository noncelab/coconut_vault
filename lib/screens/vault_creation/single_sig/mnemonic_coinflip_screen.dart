import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class MnemonicCoinflipScreen extends StatefulWidget {
  const MnemonicCoinflipScreen({super.key});

  @override
  State<MnemonicCoinflipScreen> createState() => _MnemonicCoinflipScreenState();
}

class _MnemonicCoinflipScreenState extends State<MnemonicCoinflipScreen> {
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
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.stop_generating_mnemonic.title,
          description: t.alert.stop_generating_mnemonic.description,
          backgroundColor: CoconutColors.white,
          rightButtonText: t.yes,
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
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Provider.of<WalletCreationProvider>(context, listen: false).resetAll();
    _totalStep = Provider.of<VisibilityProvider>(context, listen: false).isPassphraseUseEnabled ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WordsLengthSelection(onSelected: _onLengthSelected),
      PassphraseSelection(onSelected: _onPassphraseSelected),
      FlipCoin(wordsCount: _selectedWordsCount, usePassphrase: _usePassphrase, onReset: _onReset),
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
            title: t.mnemonic_coin_flip_screen.title,
            context: context,
            onBackPressed: _showStopGeneratingMnemonicDialog,
            backgroundColor: CoconutColors.white,
          ),
          body: SafeArea(child: screens[_step]),
        ),
      ),
    );
  }
}

class FlipCoin extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;

  const FlipCoin({super.key, required this.wordsCount, required this.usePassphrase, required this.onReset});

  @override
  State<FlipCoin> createState() => _FlipCoinState();
}

class _FlipCoinState extends State<FlipCoin> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _passphraseConfirmController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final FocusNode _passphraseConfirmFocusNode = FocusNode();
  late int stepCount; // 총 화면 단계
  int step = 0;

  Uint8List _mnemonic = Uint8List(0);
  Uint8List _passphrase = Uint8List(0);
  Uint8List _passphraseConfirm = Uint8List(0);

  // coinflip 관련 변수
  int numberOfBits = 0;
  final List<int> _bits = [];
  late int _totalBits;
  int _currentIndex = 0;
  bool _showFullBits = false;

  // passphrase 관련 변수
  bool passphraseObscured = false;
  bool isPassphraseConfirmVisible = false;
  List<String> invalidPassphraseList = [];
  bool isNextButtonActive = false;

  @override
  void initState() {
    super.initState();
    _totalBits = widget.wordsCount == 12 ? 128 : 256;
    stepCount = widget.usePassphrase ? 2 : 1;
    _passphraseController.addListener(() {
      setState(() {
        invalidPassphraseList =
            _passphraseController.text.characters
                .where((char) => !MnemonicWords.validCharSet.contains(char))
                .toSet()
                .toList();
        _passphrase = utf8.encode(_passphraseController.text);
      });
    });
    _passphraseConfirmController.addListener(() {
      setState(() {
        _passphraseConfirm = utf8.encode(_passphraseConfirmController.text);
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
    for (int i = 0; i < _bits.length; i++) {
      _bits[i] = 0;
    }
    _bits.clear();
    _mnemonic.wipe();
    _passphrase.wipe();
    _passphraseConfirm.wipe();

    _scrollController.dispose();
    _passphraseController.dispose();
    _passphraseFocusNode.dispose();
    _passphraseConfirmController.dispose();
    _passphraseConfirmFocusNode.dispose();
    super.dispose();
  }

  NextButtonState _getNextButtonState() {
    if (step == 0 && stepCount == 1) {
      // 패스프레이즈 사용 안함 - coinflip 화면
      return _bits.length >= _totalBits ? NextButtonState.completeActive : NextButtonState.completeInactive;
    }

    if (step == 0 && stepCount == 2) {
      // 패스프레이즈 사용 - coinflip 화면
      return _bits.length >= _totalBits ? NextButtonState.nextActive : NextButtonState.nextInactive;
    }

    // 패스프레이즈 입력 화면
    bool isActive = false;
    if (isPassphraseConfirmVisible) {
      // 패스프레이즈 확인 텍스트필드가 보이는 상태
      isActive = _passphrase.isNotEmpty && _passphraseConfirm.isNotEmpty && listEquals(_passphrase, _passphraseConfirm);
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
              step == 0 ? _buildCoinflipWidget() : _buildPassphraseInput(),
              CoconutLayout.spacing_2500h,
            ],
          ),
        ),
        _buildProgressBar(),
        FixedBottomTweenButton(
          showGradient: false,
          subWidget:
              invalidPassphraseList.isNotEmpty
                  ? Text(
                    t.mnemonic_generate_screen.passphrase_warning(words: invalidPassphraseList.join(", ")),
                    style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
                    textAlign: TextAlign.center,
                  )
                  : null,
          leftButtonRatio: 0.35,
          leftButtonClicked: () {
            _showAllBitsBottomSheet();
          },
          rightButtonClicked: () {
            _onNextButtonClicked();
          },
          isRightButtonActive: _getNextButtonState().isActive,
          leftText: t.view_all,
          rightText: _getNextButtonState().text,
        ),
      ],
    );
  }

  Widget _buildCoinflipButtons() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              _buildTextButton(t.delete_all, _showConfirmResetDialog),
              _buildTextButton(t.delete_one, _removeLastBit),
            ],
          ),
          CoconutLayout.spacing_300w,
          _buildCoinButton(t.mnemonic_coin_flip_screen.coin_head, () => _currentIndex < _totalBits ? _addBit(1) : null),
          CoconutLayout.spacing_100w,
          _buildCoinButton(t.mnemonic_coin_flip_screen.coin_tail, () => _currentIndex < _totalBits ? _addBit(0) : null),
        ],
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return ShrinkAnimationButton(
      onPressed: onPressed,
      pressedColor: CoconutColors.gray200,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(child: Text(text)),
      ),
    );
  }

  Widget _buildCoinButton(String text, VoidCallback onPressed) {
    return ShrinkAnimationButton(
      onPressed: onPressed,
      pressedColor: CoconutColors.gray150,
      borderRadius: 100,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 84, maxHeight: 84),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: CoconutColors.gray350),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: CoconutColors.gray300),
          ),
          child: Center(
            child: Text(
              text,
              style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
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
                enableSuggestions: true,
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
                            colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          passphraseObscured = !passphraseObscured;
                        });
                      },
                      child:
                          passphraseObscured
                              ? Container(
                                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8, left: 8),
                                child: const Icon(CupertinoIcons.eye_slash, color: CoconutColors.gray800, size: 18),
                              )
                              : Container(
                                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8, left: 8),
                                child: const Icon(CupertinoIcons.eye, color: CoconutColors.gray800, size: 18),
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
                  enableSuggestions: true,
                  obscureText: passphraseObscured,
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
                              colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
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

  Widget _buildCoinflipWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Opacity(
            opacity: _bits.isNotEmpty ? 0.0 : 1.0,
            child: Text(
              t.mnemonic_coin_flip_screen.guide,
              style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.gray800),
              textAlign: TextAlign.center,
            ),
          ),
          CoconutLayout.spacing_400h,
          _buildBitGrid(),
          CoconutLayout.spacing_200h,
          Text('$_currentIndex/$_totalBits', style: CoconutTypography.heading4_18_Bold),
          CoconutLayout.spacing_1400h,
          _buildCoinflipButtons(),
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
              ClipRRect(child: Container(height: 6, color: CoconutColors.black.withOpacity(0.06))),
              ClipRRect(
                borderRadius:
                    _currentIndex / _totalBits == 1
                        ? BorderRadius.zero
                        : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * (_currentIndex / _totalBits),
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
          Provider.of<WalletCreationProvider>(context, listen: false).setSecretAndPassphrase(_mnemonic, _passphrase);
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
          _passphrase = utf8.encode(_passphraseController.text);
          isPassphraseConfirmVisible = true;
        });
      } else if (_passphrase.isNotEmpty &&
          _passphraseConfirm.isNotEmpty &&
          listEquals(_passphrase, _passphraseConfirm) &&
          _generateMnemonicPhrase()) {
        // 패스프레이즈 입력 완료 | coinflip 데이터로 니모닉 생성 시도 성공
        Provider.of<WalletCreationProvider>(context, listen: false).setSecretAndPassphrase(_mnemonic, _passphrase);
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
              },
            ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBitGrid() {
    int start = _currentIndex + 1 == _totalBits ? _totalBits - 8 : _currentIndex ~/ 8 * 8;
    int end;
    List<int> currentBits;

    if (_showFullBits) {
      start = start - 8;
    }
    if (start == _totalBits) {
      start -= 8;
    }
    end = start + 8;
    currentBits = _bits.length >= end ? _bits.sublist(start, end) : _bits.sublist(start);

    return Column(
      children: List.generate(2, (rowIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (colIndex) {
            int index = rowIndex * 4 + colIndex;
            return Container(
              width: 50,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(12),
                color: CoconutColors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${start + index + 1}',
                    style: CoconutTypography.body3_12_Number.setColor(CoconutColors.black.withValues(alpha: 0.3)),
                  ),
                  CoconutLayout.spacing_200h,
                  Text(
                    index < currentBits.length ? '${currentBits[index]}' : '',
                    style: CoconutTypography.heading4_18_NumberBold.setColor(
                      index < currentBits.length ? CoconutColors.black : CoconutColors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  void _addBit(int bit) async {
    if (_currentIndex == _totalBits) return;

    setState(() {
      _bits.add(bit);
      _currentIndex++;
    });

    if (_currentIndex % 8 == 0 && _currentIndex < _totalBits) {
      setState(() {
        _showFullBits = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (_currentIndex < _totalBits) {
        _showFullBits = false;
        setState(() {});
      }
    }
  }

  void _removeLastBit() async {
    if (_currentIndex == 0) return;
    setState(() {
      _bits.removeLast();
      _currentIndex--;
    });
  }

  void _resetBits() {
    setState(() {
      _bits.clear();
      _currentIndex = 0;
      _showFullBits = false;
    });
  }

  void _showConfirmResetDialog({String? title, String? message, VoidCallback? action}) {
    if (_currentIndex == 0) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: title ?? t.delete_all,
          description: message ?? t.alert.erase_all_entered_so_far,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withOpacity(0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapLeft: () => Navigator.pop(context),
          onTapRight: () {
            _resetBits();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  String listToBinaryString(List<int> list) {
    return list.map((int bit) => bit.toString()).join();
  }

  bool _generateMnemonicPhrase() {
    try {
      setState(() {
        _mnemonic = Seed.fromEntropy(bitsToBytes(_bits)).mnemonic;
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // TODO: 유틸 함수로 만들지 확인 필요
  // Uint8List.fromList()
  Uint8List bitsToBytes(List<int> bits) {
    List<int> eightBits = [];
    if (bits.length < 8) {
      for (int i = 8 - bits.length; i > 0; i--) {
        eightBits.add(0);
      }
      eightBits.addAll(bits);
    } else {
      eightBits.addAll(bits);
    }
    Uint8List bytes = Uint8List(eightBits.length ~/ 8);
    for (int i = 0; i < eightBits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        byte = (byte << 1) | eightBits[i + j];
      }
      bytes[i ~/ 8] = byte;
    }
    return bytes;
  }

  void _showAllBitsBottomSheet() {
    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      minChildSize: 0.5,
      childBuilder:
          (scrollController) => BinaryGrid(totalBits: _totalBits, bits: _bits, scrollController: scrollController),
    );
  }
}

class BinaryGrid extends StatelessWidget {
  final int totalBits;
  final List<int> bits;
  final ScrollController scrollController;

  const BinaryGrid({super.key, required this.totalBits, required this.bits, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('${t.view_all}(${bits.length}/$totalBits)', style: CoconutTypography.body2_14_Bold),
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
                  children: List.generate(totalBits, (index) {
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
        border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (index + 1).toString(),
              style: CoconutTypography.body3_12_Number.setColor(CoconutColors.black.withValues(alpha: 0.3)),
            ),
            Expanded(
              child: Text(
                bit == null ? '' : bit.toString(),
                style: CoconutTypography.heading4_18_NumberBold.setColor(CoconutColors.black.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
