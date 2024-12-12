import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/lower_case_text_input_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/vault_creation/mnemonic_confirm_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/utils/wallet_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:provider/provider.dart';

class MnemonicImport extends StatefulWidget {
  const MnemonicImport({super.key});

  @override
  State<MnemonicImport> createState() => _MnemonicImportState();
}

class _MnemonicImportState extends State<MnemonicImport> {
  String inputText = '';
  bool usePassphrase = false;
  String passphrase = '';
  String passphraseConfirm = '';
  bool passphraseObscured = false;
  // 니모닉이 유효한지 확인을 한 상황이면 true
  bool? isMnemonicValid;
  // bool passphraseConfirmObscured = false;
  bool isNextButtonActive = false;
  bool isValid = true;
  bool isFinishing = false;
  String? errorMessage;

  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  // final TextEditingController _passphraseConfirmController =
  //     TextEditingController();
  // final FocusNode _fcnodePassphrase = FocusNode();

  void validateInput() {
    if (inputText.trim().isEmpty) {
      if (isMnemonicValid != null) {
        setState(() {
          isMnemonicValid = null;
          errorMessage = null;
        });
      }
      return;
    }

    String normalizedInputText =
        inputText.trim().replaceAll(RegExp(r'\s+'), ' ');
    List<String> words = normalizedInputText.split(' ');
    List<String> filtered = [];

    for (int i = 0; i < words.length; i++) {
      // 유효 길이 미만의 마지막 입력 중인 단어는 유효성 체크에서 임시로 제외
      if (i == words.length - 1 &&
          !inputText.endsWith(' ') &&
          (i != 11 && i != 14 && i != 17 && i != 20 && i != 23)) {
        continue;
      }

      // bip-39에 없는 단어가 있으면, 목록에 추가
      if (!WalletUtility.isInMnemonicWordList(words[i])) {
        filtered.add(words[i]);
      }
    }

    if (filtered.isNotEmpty) {
      setState(() {
        isMnemonicValid = false;
        errorMessage = '잘못된 단어예요. $filtered';
      });
      return;
    } else {
      isMnemonicValid = null;
      errorMessage = null;
    }

    // 유효한 길이가 아닌 니모닉 문구는 검증하지 않음
    if (words.length < 12 ||
        (words.length > 12 && words.length < 15) ||
        (words.length > 15 && words.length < 18) ||
        (words.length > 18 && words.length < 21) ||
        (words.length > 21 && words.length < 24)) {
      if (isMnemonicValid != null) {
        setState(() {
          isMnemonicValid = null;
        });
      }
      return;
    }

    // 12자리 또는 24자리 일 때 검증
    inputText = inputText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    if (words.last.length < 3) {
      isMnemonicValid = null;
      errorMessage = null;
      return;
    }

    setState(() {
      isMnemonicValid = isValidMnemonic(inputText);
    });
  }

  void _initListeners() {
    _passphraseController.addListener(() {
      setState(() {
        passphrase = _passphraseController.text;
      });
    });
  }

  void _onBackPressed(BuildContext context) {
    if (inputText.isEmpty && passphrase.isEmpty) {
      final model = Provider.of<VaultModel>(context, listen: false);
      model.completeSinglesigImporting();
      isFinishing = true;
      Navigator.pop(context);
    } else {
      _showStopGeneratingMnemonicDialog();
    }
  }

  void _showStopGeneratingMnemonicDialog() {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: '복원 중단',
      message: '정말 복원하기를 그만하시겠어요?',
      cancelButtonText: '취소',
      confirmButtonText: '그만하기',
      confirmButtonColor: MyColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (Route<dynamic> route) => false);
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _initListeners();
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    _passphraseController.dispose();
    // _passphraseConfirmController.dispose();
    // _fcnodePassphrase.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!isFinishing) _onBackPressed(context);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: CustomAppBar.buildWithNext(
              title: '복원하기',
              context: context,
              onBackPressed: () {
                _onBackPressed(context);
              },
              onNextPressed: () {
                final model = Provider.of<VaultModel>(context, listen: false);

                if (model.isSeedDuplicated(
                    inputText
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'\s+'), ' '),
                    usePassphrase ? passphrase.trim() : '')) {
                  CustomToast.showToast(
                      context: context, text: "이미 추가되어 있는 니모닉이에요");
                  return;
                }

                model.startSinglesigImporting(
                    inputText
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'\s+'), ' '),
                    usePassphrase ? passphrase.trim() : '');

                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: MnemonicConfirm(
                    onCancelPressed: () => Navigator.pop(context),
                    onConfirmPressed: () =>
                        Navigator.pushNamed(context, '/vault-name-setup'),
                    onInactivePressed: () {
                      CustomToast.showToast(
                          context: context, text: "스크롤을 내려서 모두 확인해 주세요");
                      vibrateMediumDouble();
                    },
                    mnemonic: inputText
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'\s+'), ' '),
                    passphrase: usePassphrase ? passphrase : null,
                  ),
                );
              },
              isActive: usePassphrase
                  ? inputText.isNotEmpty &&
                      isMnemonicValid == true &&
                      passphrase.isNotEmpty
                  : inputText.isNotEmpty && isMnemonicValid == true,
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: Column(
                      children: <Widget>[
                        const Text('니모닉 문구를 입력해 주세요', style: Styles.body1Bold),
                        const SizedBox(height: 30),
                        CustomTextField(
                            controller: _mnemonicController,
                            inputFormatter: [
                              LowerCaseTextInputFormatter(),
                            ],
                            placeholder: "단어 사이에 띄어쓰기를 넣어주세요",
                            onChanged: (text) {
                              inputText = text.toLowerCase();
                              setState(() {
                                _mnemonicController.value =
                                    _mnemonicController.value.copyWith(
                                  text: inputText,
                                  selection: TextSelection.collapsed(
                                    offset: _mnemonicController
                                        .selection.baseOffset
                                        .clamp(0, inputText.length),
                                  ),
                                );
                              });
                              validateInput();
                            },
                            maxLines: 5,
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                            valid: isMnemonicValid,
                            errorMessage: errorMessage ?? '잘못된 니모닉 문구예요'),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const Text('패스프레이즈 사용', style: Styles.body2Bold),
                            const Spacer(),
                            CupertinoSwitch(
                              value: usePassphrase,
                              activeColor: MyColors.darkgrey,
                              onChanged: (value) {
                                setState(() {
                                  usePassphrase = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (usePassphrase)
                          Column(children: [
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  child: CustomTextField(
                                    controller: _passphraseController,
                                    placeholder: "패스프레이즈를 입력해 주세요",
                                    onChanged: (text) {},
                                    valid: passphrase.length <= 100,
                                    maxLines: 1,
                                    obscureText: passphraseObscured,
                                    suffix: CupertinoButton(
                                      onPressed: () {
                                        setState(() {
                                          passphraseObscured =
                                              !passphraseObscured;
                                        });
                                      },
                                      child: passphraseObscured
                                          ? const Icon(
                                              CupertinoIcons.eye_slash,
                                              color: MyColors.darkgrey,
                                              size: 18,
                                            )
                                          : const Icon(
                                              CupertinoIcons.eye,
                                              color: MyColors.darkgrey,
                                              size: 18,
                                            ),
                                    ),
                                    maxLength: 100,
                                  ),
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 4),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  '(${passphrase.length} / 100)',
                                  style: TextStyle(
                                      color: passphrase.length == 100
                                          ? MyColors.transparentBlack
                                          : MyColors.transparentBlack_50,
                                      fontSize: 12,
                                      fontFamily:
                                          CustomFonts.text.getFontFamily),
                                ),
                              ),
                            )
                          ]),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // TODO: isolate
          Visibility(
            visible: false,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration:
                  const BoxDecoration(color: MyColors.transparentBlack_30),
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.darkgrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
