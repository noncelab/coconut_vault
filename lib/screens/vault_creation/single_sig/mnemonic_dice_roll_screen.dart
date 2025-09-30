import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/entropy_base/base_entropy_widget.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MnemonicDiceRollScreen extends BaseMnemonicEntropyScreen {
  const MnemonicDiceRollScreen({super.key, required super.entropyType});

  @override
  State<MnemonicDiceRollScreen> createState() => _MnemonicDiceRollScreenState();
}

class _MnemonicDiceRollScreenState extends BaseMnemonicEntropyScreenState<MnemonicDiceRollScreen> {
  @override
  String get screenTitle => t.mnemonic_dice_roll_screen.title;
  @override
  Widget buildEntropyWidget([ValueNotifier<bool>? notifier, ValueNotifier<int>? stepNotifier]) {
    return DiceRoll(
      wordsCount: selectedWordsCount,
      usePassphrase: usePassphrase,
      onReset: onReset,
      entropyType: EntropyType.manual,
    );
  }
}

class DiceRoll extends BaseEntropyWidget {
  const DiceRoll({
    super.key,
    required super.wordsCount,
    required super.usePassphrase,
    required super.onReset,
    required super.entropyType,
  });

  @override
  State<DiceRoll> createState() => _DiceRollState();
}

class _DiceRollState extends BaseEntropyWidgetState<DiceRoll> {
  List<int> _bits = [];
  // dice roll 관련 변수
  int diceNumbers = 0;

  final List<int> _diceNumbers = [];

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

  @override
  List<int> get currentBits => _bits;

  @override
  String get leftButtonText => t.view_all;

  @override
  String get rightButtonText => t.next;

  @override
  void onNavigateToNext() {
    Navigator.pushNamed(context, AppRoutes.mnemonicConfirmation);
  }

  @override
  bool get isRightButtonActive => _bits.length >= (widget.wordsCount == 12 ? 128 : 256);

  @override
  Widget buildEntropyContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CoconutLayout.spacing_200h,
          Opacity(
            opacity: _diceNumbers.isEmpty || _bits.length >= (widget.wordsCount == 12 ? 128 : 256) ? 1 : 0,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(
                _diceNumbers.isEmpty ? t.mnemonic_dice_roll_screen.guide1 : t.mnemonic_dice_roll_screen.guide2,
                style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.gray800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          CoconutLayout.spacing_200h,
          _buildDiceGrid(),
          CoconutLayout.spacing_1400h,
          _buildButtons(),
          CoconutLayout.spacing_2500h,
        ],
      ),
    );
  }

  Widget _buildDiceGrid() {
    const int gridElements = 10;
    int start;
    List<int> currentRolls;

    start = _currentIndex ~/ gridElements * gridElements;
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
                border: Border.all(color: CoconutColors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(12),
                color: CoconutColors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$slotNumber',
                    style: CoconutTypography.body3_12_Number.setColor(CoconutColors.black.withValues(alpha: 0.3)),
                  ),
                  CoconutLayout.spacing_200h,
                  Text(
                    hasData ? '${currentRolls[index]}' : '',
                    style: CoconutTypography.heading4_18_NumberBold.setColor(
                      hasData ? CoconutColors.black : CoconutColors.white,
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

  Widget _buildButtons() {
    final List<int> diceNumbers = [-100, 1, 2, 3, -1, 4, 5, 6];
    //2x3 그리드로 그리기
    final List<Widget> buttons =
        diceNumbers.map((diceNumber) {
          if (diceNumber == -100) {
            // delete all
            return _buildDeleteButton(buttonText: t.delete_all, onButtonPressed: showConfirmResetDialog);
          }
          if (diceNumber == -1) {
            // delete one
            return _buildDeleteButton(buttonText: t.delete_one, onButtonPressed: removeLastEntropyData);
          }
          return _buildNumberButton(
            buttonText: diceNumber.toString(),
            onButtonPressed: () => addEntropyData(diceNumber),
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text(
              buttonText,
              style: CoconutTypography.body2_14.setColor(
                _diceNumbers.isEmpty ? CoconutColors.secondaryText : CoconutColors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton({required String buttonText, required VoidCallback onButtonPressed}) {
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
            border: Border.all(color: CoconutColors.black, width: 1),
          ),
          child: Center(child: SvgPicture.asset('assets/svg/dice/$buttonText.svg', width: 44, height: 44)),
        ),
      ),
    );
  }

  @override
  void addEntropyData(data) {
    setState(() {
      _diceNumbers.add(data);
      _bits.addAll(diceMapping[data] ?? []);
      _currentIndex++;
    });
  }

  @override
  void removeLastEntropyData() {
    if (_currentIndex == 0) return;
    setState(() {
      final removedNumber = _diceNumbers.removeLast();
      _bits.removeRange(_bits.length - (diceMapping[removedNumber]?.length ?? 0), _bits.length);
      _currentIndex--;
    });
  }

  @override
  void resetEntropyData() {
    setState(() {
      _diceNumbers.clear();
      _bits.clear();
      _currentIndex = 0;
    });
  }

  @override
  void showAllBitsBottomSheet() {
    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      minChildSize: 0.5,
      childBuilder:
          (scrollController) => BinaryGrid(
            totalCount: _diceNumbers.length,
            inputs: _diceNumbers,
            scrollController: scrollController,
            showProgress: false,
          ),
    );
  }
}
