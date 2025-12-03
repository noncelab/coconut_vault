import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/widgets/entropy_base/base_entropy_widget.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';

class MnemonicAutoGenScreen extends BaseMnemonicEntropyScreen {
  const MnemonicAutoGenScreen({super.key, required super.entropyType});

  @override
  State<MnemonicAutoGenScreen> createState() => _MnemonicAutoGenScreenState();
}

class _MnemonicAutoGenScreenState extends BaseMnemonicEntropyScreenState<MnemonicAutoGenScreen> with RouteAware {
  final GlobalKey<BaseEntropyWidgetState<GeneratedWords>> _generatedWordsKey =
      GlobalKey<BaseEntropyWidgetState<GeneratedWords>>();
  @override
  String get screenTitle => t.mnemonic_dice_roll_screen.title;

  @override
  Widget buildEntropyWidget() {
    return GeneratedWords(
      key: _generatedWordsKey,
      wordsCount: selectedWordsCount,
      usePassphrase: usePassphrase,
      onReset: onReset,
      entropyType: EntropyType.auto,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 다른 화면으로 push 했다가, pop 으로 이 화면이 다시 보일 때 호출됨
  @override
  void didPopNext() {
    super.didPopNext();
    final walletCreationProvider = context.read<WalletCreationProvider>();
    // resetAll() 등으로 provider 의 secret 이 비어있다면,
    // 현재 화면 상태 기준으로 다시 입력해준다.
    if (walletCreationProvider.secret.isEmpty) {
      final state = _generatedWordsKey.currentState;
      if (state != null) {
        final mnemonic = state.mnemonic;
        final passphrase = state.passphrase;
        if (mnemonic != null && mnemonic.isNotEmpty) {
          walletCreationProvider.setSecretAndPassphrase(mnemonic, passphrase.isNotEmpty ? passphrase : null);
        }
      }
      // 니모닉 재생성
      _generatedWordsKey.currentState?.generateMnemonicWords();
      CoconutToast.showToast(isVisibleIcon: true, context: context, text: t.toast.mnemonic_has_been_regenerated);
    }
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
  bool get isRightButtonActiveImpl {
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
    Navigator.pushNamed(context, AppRoutes.mnemonicVerify, arguments: {'calledFrom': AppRoutes.mnemonicAutoGen});
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
