import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/entropy_base/base_entropy_widget.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';

class MnemonicCoinflipScreen extends BaseMnemonicEntropyScreen {
  const MnemonicCoinflipScreen({super.key, required super.entropyType});

  @override
  State<MnemonicCoinflipScreen> createState() => _MnemonicDiceRollScreenState();
}

class _MnemonicDiceRollScreenState extends BaseMnemonicEntropyScreenState<MnemonicCoinflipScreen> {
  @override
  String get screenTitle => t.mnemonic_dice_roll_screen.title;
  @override
  Widget buildEntropyWidget() {
    return CoinFlip(
      wordsCount: selectedWordsCount,
      usePassphrase: usePassphrase,
      onReset: onReset,
      entropyType: EntropyType.manual,
    );
  }
}

class CoinFlip extends BaseEntropyWidget {
  const CoinFlip({
    super.key,
    required super.wordsCount,
    required super.usePassphrase,
    required super.onReset,
    required super.entropyType,
  });

  @override
  State<CoinFlip> createState() => _CoinFlipState();
}

class _CoinFlipState extends BaseEntropyWidgetState<CoinFlip> {
  // coinflip 관련 변수
  int numberOfBits = 0;
  final List<int> _bits = [];
  late int _totalBits;
  int _currentIndex = 0;
  bool _showFullBits = false;

  @override
  List<int> get currentBits => _bits;

  @override
  String get leftButtonText => t.view_all;

  @override
  String get rightButtonText => t.next;

  @override
  bool get isRightButtonActiveImpl {
    if (step == 0) {
      return _bits.length >= (widget.wordsCount == 12 ? 128 : 256);
    } else if (step == 1) {
      return isPassphraseValid;
    }
    return false;
  }

  @override
  void onNavigateToNext() {
    Navigator.pushNamed(context, AppRoutes.mnemonicConfirmation, arguments: {'calledFrom': AppRoutes.mnemonicCoinflip});
  }

  @override
  void initState() {
    super.initState();
    _totalBits = widget.wordsCount == 12 ? 128 : 256;
  }

  @override
  Widget buildEntropyContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CoconutLayout.spacing_200h,
          Opacity(
            opacity: _bits.isNotEmpty ? 0.0 : 1.0,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                t.mnemonic_coin_flip_screen.guide,
                style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.gray800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          CoconutLayout.spacing_200h,
          _buildBitGrid(),
          CoconutLayout.spacing_200h,
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text('$_currentIndex/$_totalBits', style: CoconutTypography.heading4_18_Bold),
          ),
          CoconutLayout.spacing_1400h,
          _buildCoinflipButtons(),
        ],
      ),
    );
  }

  Widget _buildCoinflipButtons() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                _buildTextButton(t.delete_all, showConfirmResetDialog),
                _buildTextButton(t.delete_one, removeLastEntropyData),
              ],
            ),
          ),
          CoconutLayout.spacing_300w,
          _buildCoinButton(
            t.mnemonic_coin_flip_screen.coin_head,
            () => _currentIndex < _totalBits ? addEntropyData(1) : null,
          ),
          CoconutLayout.spacing_100w,
          _buildCoinButton(
            t.mnemonic_coin_flip_screen.coin_tail,
            () => _currentIndex < _totalBits ? addEntropyData(0) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return ShrinkAnimationButton(
      onPressed: onPressed,
      pressedColor: CoconutColors.gray200,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Center(
            child: Text(
              text,
              style: CoconutTypography.body2_14.setColor(
                _bits.isEmpty ? CoconutColors.secondaryText : CoconutColors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
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
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                text,
                style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
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

  String listToBinaryString(List<int> list) {
    return list.map((int bit) => bit.toString()).join();
  }

  @override
  void showAllBitsBottomSheet() {
    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      minChildSize: 0.5,
      childBuilder:
          (scrollController) => BinaryGrid(totalCount: _totalBits, inputs: _bits, scrollController: scrollController),
    );
  }

  @override
  void addEntropyData(data) async {
    if (_currentIndex == _totalBits) return;

    setState(() {
      _bits.add(data);
      _currentIndex++;
    });

    if (_currentIndex % 8 == 0 && _currentIndex < _totalBits) {
      setState(() {
        _showFullBits = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (_currentIndex < _totalBits) {
        _showFullBits = false;
        setState(() {});
      }
    }
  }

  @override
  void removeLastEntropyData() {
    if (_currentIndex == 0) return;
    setState(() {
      _bits.removeLast();
      _currentIndex--;
    });
  }

  @override
  void resetEntropyData() {
    setState(() {
      _bits.clear();
      _currentIndex = 0;
      _showFullBits = false;
    });
  }
}
