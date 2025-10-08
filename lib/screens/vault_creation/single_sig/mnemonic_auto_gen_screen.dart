import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/widgets/entropy_base/base_entropy_widget.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MnemonicAutoGenScreen extends BaseMnemonicEntropyScreen {
  const MnemonicAutoGenScreen({super.key, required super.entropyType});

  @override
  State<MnemonicAutoGenScreen> createState() => _MnemonicAutoGenScreenState();
}

class _MnemonicAutoGenScreenState extends BaseMnemonicEntropyScreenState<MnemonicAutoGenScreen> {
  @override
  String get screenTitle => t.mnemonic_dice_roll_screen.title;

  @override
  Widget buildEntropyWidget() {
    return GeneratedWords(
      wordsCount: selectedWordsCount,
      usePassphrase: usePassphrase,
      onReset: onReset,
      entropyType: EntropyType.auto,
    );
  }
}

class GeneratedWords extends BaseEntropyWidget {
  final Uint8List? customMnemonic;

  const GeneratedWords({
    super.key,
    required super.wordsCount,
    required super.usePassphrase,
    required super.onReset,
    required super.entropyType,
    this.customMnemonic,
  });

  @override
  State<GeneratedWords> createState() => _GeneratedWordsState();
}

class _GeneratedWordsState extends BaseEntropyWidgetState<GeneratedWords> {
  bool isPassphraseNotMached = false;

  @override
  Widget buildEntropyContent() {
    final Uint8List? finalMnemonic = widget.customMnemonic ?? widget.mnemonic ?? mnemonic;

    return Column(
      children: [
        step == 0
            ? MnemonicList(mnemonic: finalMnemonic ?? Uint8List(0), isLoading: finalMnemonic?.isEmpty ?? true)
            : Container(),
        CoconutLayout.spacing_2500h,
      ],
    );
  }

  @override
  bool get isRightButtonActive => _isActive();

  bool _isActive() {
    if (step == 0 && hasScrolledToBottom) {
      return true;
    }

    if (step == 1 && isPassphraseValid) {
      return true;
    }

    return false;
  }

  @override
  String get leftButtonText => '';

  @override
  String get rightButtonText => t.next;

  @override
  void onNavigateToNext() {
    Navigator.pushNamed(context, AppRoutes.mnemonicVerify);
  }

  // 자동 생성되므로 엔트로피 데이터 추가 불필요
  @override
  List<int> get currentBits => [];

  @override
  void addEntropyData(data) {
    return;
  }

  @override
  void removeLastEntropyData() {
    return;
  }

  @override
  void resetEntropyData() {
    return;
  }

  @override
  void showAllBitsBottomSheet() {
    return;
  }
}
