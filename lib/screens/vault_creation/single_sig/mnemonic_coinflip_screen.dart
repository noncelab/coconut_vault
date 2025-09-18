import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_tween_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
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
      FlipCoin(
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
              title: t.mnemonic_coin_flip_screen.title,
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

class FlipCoin extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;

  const FlipCoin({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
  });

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
  String _mnemonic = '';
  String _passphrase = '';
  String _passphraseConfirm = '';

  // coinflip 관련 변수
  int numberOfBits = 0;
  final List<int> _bits = [];
  late int _totalBits;
  int _currentIndex = 0;
  bool _showFullBits = false;

  // passphrase 관련 변수
  bool passphraseObscured = false;
  bool isPassphraseConfirmVisible = false;

  bool isNextButtonActive = false;

  @override
  void initState() {
    super.initState();
    _totalBits = widget.wordsCount == 12 ? 128 : 256;
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
      // 패스프레이즈 사용 안함 - coinflip 화면
      return _bits.length >= _totalBits
          ? NextButtonState.completeActive
          : NextButtonState.completeInactive;
    }

    if (step == 0 && stepCount == 2) {
      // 패스프레이즈 사용 - coinflip 화면
      return _bits.length >= _totalBits ? NextButtonState.nextActive : NextButtonState.nextInactive;
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
              _buildProgressBar(),
              _buildStepIndicator(),
              step == 0 ? _buildCoinflipWidget() : _buildPassphraseInput(),
            ],
          ),
        ),
        FixedBottomTweenButton(
          showGradient: false,
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

  Widget _buildCoinflipWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Text('$_currentIndex/$_totalBits', style: CoconutTypography.heading4_18_Bold),
          CoconutLayout.spacing_800h,
          _buildBitGrid(),
          CoconutLayout.spacing_1300h,
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Visibility(
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
              borderRadius: _currentIndex / _totalBits == 1
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
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
    );
  }

  void _onNextButtonClicked() {
    // 패프 사용안함 | Coinflip 화면
    if (step == 0 && stepCount == 1) {
      setState(() {
        if (_generateMnemonicPhrase()) {
          Provider.of<WalletCreationProvider>(context, listen: false)
              .setSecretAndPassphrase(_mnemonic, _passphrase);
          Navigator.pushNamed(context, AppRoutes.mnemonicCoinflipConfirmation);
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
        // 패스프레이즈 입력 완료 | coinflip 데이터로 니모닉 생성 시도 성공
        Provider.of<WalletCreationProvider>(context, listen: false)
            .setSecretAndPassphrase(_mnemonic, _passphrase);
        _passphraseFocusNode.unfocus();
        _passphraseConfirmFocusNode.unfocus();

        Navigator.pushNamed(context, AppRoutes.mnemonicCoinflipConfirmation);
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
                border: Border.all(color: CoconutColors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(12),
                color: CoconutColors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${start + index + 1}',
                    style: CoconutTypography.body3_12_Number.setColor(
                      CoconutColors.black.withOpacity(0.3),
                    ),
                  ),
                  CoconutLayout.spacing_200h,
                  Text(
                    index < currentBits.length ? '${currentBits[index]}' : '',
                    style: CoconutTypography.heading4_18_NumberBold.setColor(
                      index < currentBits.length ? CoconutColors.black : CoconutColors.white,
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
    return SizedBox(
      width: 224, // GridView의 item이 보이는 총 너비
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              ShrinkAnimationButton(
                onPressed: () => _currentIndex < _totalBits ? _addBit(1) : null,
                borderRadius: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 45),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoconutColors.black,
                      width: 1,
                    ),
                  ),
                  child: Text(t.mnemonic_coin_flip_screen.coin_head),
                ),
              ),
              CoconutLayout.spacing_200h,
              ShrinkAnimationButton(
                onPressed: _showConfirmResetDialog,
                pressedColor: CoconutColors.gray200,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    t.delete_all,
                    style: CoconutTypography.body3_12.setColor(
                      _bits.isEmpty
                          ? CoconutColors.secondaryText
                          : CoconutColors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              ShrinkAnimationButton(
                onPressed: () => _currentIndex < _totalBits ? _addBit(0) : null,
                borderRadius: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 45),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoconutColors.black,
                      width: 1,
                    ),
                  ),
                  child: Text(t.mnemonic_coin_flip_screen.coin_tail),
                ),
              ),
              CoconutLayout.spacing_200h,
              ShrinkAnimationButton(
                onPressed: _removeLastBit,
                pressedColor: CoconutColors.gray200,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    t.delete_one,
                    style: CoconutTypography.body3_12.setColor(
                      _bits.isEmpty
                          ? CoconutColors.secondaryText
                          : CoconutColors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  String listToBinaryString(List<int> list) {
    return list.map((int bit) => bit.toString()).join();
  }

  bool _generateMnemonicPhrase() {
    try {
      final mnemonic = Seed.fromBinaryEntropy(listToBinaryString(_bits)).mnemonic;
      setState(() {
        _mnemonic = mnemonic.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showAllBitsBottomSheet() {
    MyBottomSheet.showBottomSheet(
        title: '${t.view_all}(${_bits.length}/$_totalBits)',
        context: context,
        child: BinaryGrid(totalBits: _totalBits, bits: _bits));
  }
}

class BinaryGrid extends StatelessWidget {
  final int totalBits;
  final List<int> bits;

  const BinaryGrid({super.key, required this.totalBits, required this.bits});

  Future<List<int>> _loadBits() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return bits;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: MediaQuery.of(context).size.height * 0.7, // BottomSheet 높이 제한
      child: FutureBuilder<List<int>>(
        future: _loadBits(),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: CoconutColors.gray800,
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return GridView.count(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              padding: const EdgeInsets.only(bottom: 30),
              children: List.generate(totalBits, (index) {
                return _buildGridItem(null, index);
              }),
            );
          }

          List<int> loadedBits = snapshot.data!;

          return GridView.count(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            crossAxisCount: 8,
            mainAxisSpacing: 4,
            padding: const EdgeInsets.only(bottom: 30),
            children: List.generate(totalBits, (index) {
              return _buildGridItem(index < loadedBits.length ? loadedBits[index] : null, index);
            }),
          );
        },
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
