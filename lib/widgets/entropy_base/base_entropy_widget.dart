import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/utils/conversion_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class BaseEntropyWidget extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;
  final EntropyType entropyType;
  final Uint8List? mnemonic;
  final ValueNotifier<int>? stepNotifier; // 니모닉 or 패스프레이즈 입력 단계

  const BaseEntropyWidget({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
    required this.entropyType,
    this.mnemonic,
    this.stepNotifier,
  });
}

abstract class BaseEntropyWidgetState<T extends BaseEntropyWidget> extends State<T> {
  // 공통 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _passphraseConfirmController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final FocusNode _passphraseConfirmFocusNode = FocusNode();

  // 공통 상태 변수
  late int stepCount;
  int step = 0;
  Uint8List _mnemonic = Uint8List(0);
  Uint8List _passphrase = Uint8List(0);
  Uint8List _passphraseConfirm = Uint8List(0);
  bool hasScrolledToBottom = false;
  bool isWarningVisible = true;

  // passphrase 관련 변수
  bool passphraseObscured = false;
  bool isPassphraseConfirmVisible = false;

  Uint8List? get mnemonic => _mnemonic;

  static final Set<String> validCharSet = {
    ...List.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i)), // a-z
    ...List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)), // A-Z
    ...List.generate(10, (i) => i.toString()), // 0-9
    '[', ']', '{', '}', '#', '%', '^', '*', '+', '=', '_', '\\', '|', '~',
    '<', '>', '-', '/', ':', ';', '(', ')', r'$', '&', '"', '`', '.', ',', '?', '!', '\'', '@',
  };

  String passphraseErrorMessage = '';

  @override
  void initState() {
    super.initState();
    stepCount = widget.usePassphrase ? 2 : 1;
    widget.stepNotifier?.value = 0; // 니모닉 입력 단계 0
    if (widget.entropyType == EntropyType.auto) {
      generateMnemonicWords();
    }

    _passphraseController.addListener(() {
      setState(() {
        invalidPassphraseList =
            _passphraseController.text.characters.where((char) => !validCharSet.contains(char)).toSet().toList();
        _passphrase = utf8.encode(_passphraseController.text);

        if (_passphrase.isNotEmpty && _passphraseConfirm.isNotEmpty && listEquals(_passphrase, _passphraseConfirm)) {
          passphraseErrorMessage = t.mnemonic_generate_screen.passphrase_warning(
            words: invalidPassphraseList.join(", "),
          );
        } else {
          passphraseErrorMessage = '';
        }
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
  }

  @override
  void dispose() {
    for (int i = 0; i < currentBits.length; i++) {
      currentBits[i] = 0;
    }
    _mnemonic.wipe();
    _passphrase.wipe();
    _passphraseConfirm.wipe();

    _passphraseController.dispose();
    _passphraseConfirmController.dispose();
    _passphraseFocusNode.dispose();
    _passphraseConfirmFocusNode.dispose();
    super.dispose();
  }

  bool _isPassphraseValid() {
    if (_passphrase.isEmpty) {
      passphraseErrorMessage = '';
      return false;
    }

    _checkIfInvalidCharactersIncluded();

    if (_passphraseConfirm.isEmpty) {
      return false;
    }

    if (!listEquals(_passphrase, _passphraseConfirm)) {
      passphraseErrorMessage = t.mnemonic_generate_screen.passphrase_not_matched;
      return false;
    }

    _checkIfInvalidCharactersIncluded();
    return true;
  }

  void _checkIfInvalidCharactersIncluded() {
    var invalidPassphraseList =
        _passphraseController.text.characters.where((char) => !validCharSet.contains(char)).toSet().toList();

    if (invalidPassphraseList.isEmpty) {
      passphraseErrorMessage = '';
    } else {
      passphraseErrorMessage = t.mnemonic_generate_screen.passphrase_warning(words: invalidPassphraseList.join(", "));
    }
  }

  // 공통 메서드
  Widget _buildPassphraseInput() {
    return EntropyPassphraseInput(
      passphraseController: _passphraseController,
      passphraseConfirmController: _passphraseConfirmController,
      passphraseFocusNode: _passphraseFocusNode,
      passphraseConfirmFocusNode: _passphraseConfirmFocusNode,
      passphraseObscured: passphraseObscured,
      // isPassphraseConfirmVisible: isPassphraseConfirmVisible,
      step: step,
      onPassphraseObscuredChanged: (obscured) {
        setState(() {
          passphraseObscured = obscured;
        });
      },
      onPassphraseConfirmVisibilityChanged: () {
        setState(() {
          isPassphraseConfirmVisible = true;
        });
      },
      onPassphraseClear: () {
        setState(() {
          _passphraseController.text = '';
        });
      },
      onPassphraseConfirmClear: () {
        setState(() {
          _passphraseConfirmController.text = '';
        });
      },
    );
  }

  Widget _buildStepIndicator() {
    return EntropyStepIndicator(
      usePassphrase: widget.usePassphrase,
      step: step,
      onStepSelected: (selectedStep) {
        setState(() {
          step = selectedStep;
        });
        widget.stepNotifier?.value = selectedStep;
      },
    );
  }

  void _onNextButtonClicked() {
    // 패스프레이즈 사용안함 | 엔트로피 화면
    if (step == 0 && stepCount == 1) {
      _checkDuplicateThenProceed();
      return;
    }

    // 패스프레이즈 사용함 | 엔트로피 화면
    if (step == 0 && stepCount == 2) {
      setState(() {
        step = 1;
      });
      widget.stepNotifier?.value = 1;
      return;
    }

    if (!widget.usePassphrase && step == 0) {
      if (widget.entropyType == EntropyType.auto) {
        _passphrase = utf8.encode(_passphraseController.text);
        Provider.of<WalletCreationProvider>(context, listen: false).setSecretAndPassphrase(_mnemonic, _passphrase);
      }
    }

    // 패스프레이즈 사용함 | 패스프레이즈 입력 화면
    if (widget.usePassphrase && step == 1) {
      // if (_passphrase.isNotEmpty && _passphraseConfirm.isNotEmpty && listEquals(_passphrase, _passphraseConfirm)) {}
      // if (!isPassphraseConfirmVisible && _passphraseController.text.isNotEmpty) {
      //   // 패스프레이즈 입력 완료 | 패스프레이즈 확인 텍스트필드는 보이지 않을 때
      //   _passphraseFocusNode.unfocus();
      //   _passphraseConfirmFocusNode.unfocus();
      //   setState(() {
      //     _passphrase = utf8.encode(_passphraseController.text);
      //     isPassphraseConfirmVisible = true;
      //   });
      // } else

      if (_passphrase.isNotEmpty && _passphraseConfirm.isNotEmpty && listEquals(_passphrase, _passphraseConfirm)) {
        // 패스프레이즈 입력 완료 | 엔트로피 데이터로 니모닉 생성 시도 성공
        _passphrase = utf8.encode(_passphraseController.text);

        if (widget.entropyType == EntropyType.manual) {
          _setMnemonicFromEntropy();
        }

        // print('setSecretAndPassphrase: $_mnemonic, $_passphrase');
        Provider.of<WalletCreationProvider>(context, listen: false).setSecretAndPassphrase(_mnemonic, _passphrase);
        _passphraseFocusNode.unfocus();
        _passphraseConfirmFocusNode.unfocus();

        _checkDuplicateThenProceed();
      }
    }
  }

  bool _setMnemonicFromEntropy() {
    try {
      setState(() {
        int bitsToUse = widget.wordsCount == 12 ? 128 : 256;
        int start = currentBits.length - bitsToUse;
        _mnemonic = Seed.fromEntropy(ConversionUtil.bitsToBytes(currentBits.sublist(start))).mnemonic;
      });
      return true;
    } catch (e) {
      Logger.log('error: $e');
      return false;
    }
  }

  void generateMnemonicWords() {
    setState(() {
      _mnemonic = Seed.random(mnemonicLength: widget.wordsCount).mnemonic;
      hasScrolledToBottom = widget.wordsCount == 12;
    });
  }

  void _checkDuplicateThenProceed() {
    if (widget.entropyType == EntropyType.manual) {
      _setMnemonicFromEntropy();
    }

    if (Provider.of<WalletProvider>(context, listen: false).isSeedDuplicated(_mnemonic, _passphrase)) {
      CoconutToast.showToast(context: context, text: t.toast.mnemonic_already_added, isVisibleIcon: true);
      return;
    }

    Provider.of<WalletCreationProvider>(context, listen: false).setSecretAndPassphrase(_mnemonic, _passphrase);
    onNavigateToNext();
  }

  // 추상 메서드 (각 구현체에서 정의)
  Widget buildEntropyContent();
  List<int> get currentBits;
  void addEntropyData(dynamic data);
  void removeLastEntropyData();
  void resetEntropyData();
  void showAllBitsBottomSheet();
  void onNavigateToNext();
  String get leftButtonText;
  String get rightButtonText;
  bool get isRightButtonActiveImpl; // 각 구현체에서 정의
  bool get isRightButtonActive {
    // WarningWidget이 보이는 조건일 때만 isWarningVisible 체크
    if (widget.entropyType == EntropyType.auto && step == 0) {
      return isRightButtonActiveImpl && !isWarningVisible;
    }
    // 그 외에는 isRightButtonActiveImpl만 체크
    return isRightButtonActiveImpl;
  }

  bool get isPassphraseValid => _isPassphraseValid();

  List<String> invalidPassphraseList = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildStepIndicator(), step == 0 ? buildEntropyContent() : _buildPassphraseInput()],
          ),
        ),
        if (widget.entropyType == EntropyType.manual) ...[_buildProgressBar()],
        leftButtonText.isNotEmpty
            ? EntropyBottomButtons(
              isRightButtonActive: isRightButtonActive,
              leftText: leftButtonText,
              rightText: rightButtonText,
              onLeftButtonPressed: showAllBitsBottomSheet,
              onRightButtonPressed: _onNextButtonClicked,
              subWidget: _buildButtonSubWidget(),
            )
            : FixedBottomButton(
              isActive: isRightButtonActive,
              text: rightButtonText,
              onButtonClicked: _onNextButtonClicked,
              subWidget: _buildButtonSubWidget(),
            ),
        if (widget.entropyType == EntropyType.auto && step == 0)
          WarningWidget(
            visible: isWarningVisible,
            onWarningDismissed: () {
              setState(() {
                isWarningVisible = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildButtonSubWidget() {
    // 패스프레이즈 주의 메시지 표시 위젯
    final emptyWidget = Container();
    return step == 0
        ? emptyWidget // 엔트로피 화면에서 보이지 않음
        : !widget.usePassphrase
        ? emptyWidget
        : passphraseErrorMessage.isEmpty
        ? emptyWidget
        : FittedBox(
          child: Text(
            passphraseErrorMessage,
            style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
            textAlign: TextAlign.center,
          ),
        );
  }

  Widget _buildProgressBar() {
    return EntropyProgressBar(
      visible: step == 0,
      total: widget.wordsCount == 12 ? 128 : 256,
      current: currentBits.length,
    );
  }

  void showConfirmResetDialog() {
    if (currentBits.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (BuildContext context) => CoconutPopup(
            title: t.delete_all,
            description: t.alert.erase_all_entered_so_far,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.no,
            rightButtonText: t.yes,
            rightButtonColor: CoconutColors.warningText,
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              resetEntropyData();
              Navigator.pop(context);
            },
          ),
    );
  }
}
