import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/screens/vault_creation/mnemonic_confirm_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/check_list.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:provider/provider.dart';

class MnemonicGenerateScreen extends StatefulWidget {
  const MnemonicGenerateScreen({super.key});

  @override
  State<MnemonicGenerateScreen> createState() => _MnemonicGenerateScreenState();
}

class _MnemonicGenerateScreenState extends State<MnemonicGenerateScreen> {
  int step = 0;
  int selectedWordsCount = 0;
  bool usePassphrase = false;
  String mnemonicWords = '';
  String passphrase = '';
  bool finished = false;

  @override
  void initState() {
    super.initState();
  }

  void _onLengthSelected(int wordsCount) {
    setState(() {
      selectedWordsCount = wordsCount;
      step = 1;
    });
  }

  void _onPassphraseSelected(bool selected) {
    setState(() {
      usePassphrase = selected;
      step = 2;
    });
  }

  void _onReset() {
    setState(() {
      step = 0;
      selectedWordsCount = 0;
      usePassphrase = false;
      finished = false;
    });
  }

  void _onFinished(String mnemonicWords, String passphrase, bool finished) {
    setState(() {
      this.mnemonicWords = mnemonicWords;
      this.passphrase = passphrase;
      this.finished = finished;
    });
  }

  void _showStopGeneratingMnemonicDialog() {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: '니모닉 생성 중단',
      message: '정말 니모닉 생성을 그만하시겠어요?',
      cancelButtonText: '취소',
      confirmButtonText: '그만하기',
      confirmButtonColor: MyColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
        );
      },
    );
  }

  void _showConfirmBottomSheet() {
    MyBottomSheet.showBottomSheet(
      title: '',
      context: context,
      titlePadding: const EdgeInsets.only(bottom: 20),
      child: MnemonicConfirm(
        onCancelPressed: () => Navigator.pop(context),
        onConfirmPressed: () =>
            Navigator.pushNamed(context, '/vault-name-setup'),
        onInactivePressed: () {
          CustomToast.showToast(context: context, text: "스크롤을 내려서 모두 확인해주세요");
        },
        mnemonic:
            mnemonicWords.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
        passphrase: usePassphrase ? passphrase : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WordsLengthSelection(
          onSelected: _onLengthSelected,
          onShowStopDialog: _showStopGeneratingMnemonicDialog),
      PassphraseSelection(
          onSelected: _onPassphraseSelected,
          onShowStopDialog: _showStopGeneratingMnemonicDialog),
      MnemonicWords(
        wordsCount: selectedWordsCount,
        usePassphrase: usePassphrase,
        onReset: _onReset,
        onFinished: _onFinished,
        onShowStopDialog: _showStopGeneratingMnemonicDialog,
        onShowConfirmBottomSheet: _showConfirmBottomSheet,
      ),
    ];

    return Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: '새 니모닉 문구',
          context: context,
          onBackPressed: _showStopGeneratingMnemonicDialog,
          hasRightIcon: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: screens[step],
          ),
        ));
  }
}

class WordsLengthSelection extends StatefulWidget {
  final void Function(int) onSelected;
  final VoidCallback onShowStopDialog;

  const WordsLengthSelection({
    super.key,
    required this.onSelected,
    required this.onShowStopDialog,
  });

  @override
  State<WordsLengthSelection> createState() => _WordsLengthSelectionState();
}

class _WordsLengthSelectionState extends State<WordsLengthSelection> {
  int selectedWordsCount = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        widget.onShowStopDialog();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            const Text('단어 수를 고르세요', style: Styles.body1Bold),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: '12 단어',
                    onTap: () {
                      setState(() {
                        selectedWordsCount = 12;
                      });
                      widget.onSelected(selectedWordsCount);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: '24 단어',
                    onTap: () {
                      setState(() {
                        selectedWordsCount = 24;
                      });
                      widget.onSelected(selectedWordsCount);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PassphraseSelection extends StatefulWidget {
  final void Function(bool) onSelected;
  final VoidCallback onShowStopDialog;

  const PassphraseSelection({
    super.key,
    required this.onSelected,
    required this.onShowStopDialog,
  });

  @override
  State<PassphraseSelection> createState() => _PassphraseSelectionState();
}

class _PassphraseSelectionState extends State<PassphraseSelection> {
  bool? selected;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        widget.onShowStopDialog();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            const Text('패스프레이즈를 사용하실 건가요?', style: Styles.body1Bold),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: '아니요',
                    onTap: () {
                      setState(() {
                        selected = false;
                      });
                      widget.onSelected(false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: '네',
                    onTap: () {
                      setState(() {
                        selected = true;
                      });
                      widget.onSelected(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MnemonicWords extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;
  final Function(String, String, bool) onFinished;
  final VoidCallback onShowStopDialog;
  final VoidCallback onShowConfirmBottomSheet;

  const MnemonicWords({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
    required this.onFinished,
    required this.onShowStopDialog,
    required this.onShowConfirmBottomSheet,
  });

  @override
  State<MnemonicWords> createState() => _MnemonicWordsState();
}

class _MnemonicWordsState extends State<MnemonicWords> {
  late int stepCount; // 총 화면 단계
  int step = 0;
  String mnemonic = '';
  String passphrase = '';
  final TextEditingController _passphraseController = TextEditingController();
  bool passphraseObscured = false;
  bool isNextButtonActive = false;
  bool isValid = true;
  String errorMessage = '';

  final List<ChecklistItem> checklistItem = [
    ChecklistItem(title: '니모닉을 틀림없이 백업했습니다.')
  ];

  void _generateMnemonicPhrase() {
    Seed randomSeed = Seed.random(mnemonicLength: widget.wordsCount);

    setState(() {
      mnemonic = randomSeed.mnemonic;
    });
  }

  @override
  void initState() {
    super.initState();
    stepCount = widget.usePassphrase ? 2 : 1;
    _generateMnemonicPhrase();
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultModel = Provider.of<VaultModel>(context, listen: false);

    bool gridviewColumnFlag = false;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        widget.onShowStopDialog();
      },
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HighLightedText(widget.wordsCount.toString(),
                        color: MyColors.darkgrey),
                    const Text(' 단어, 패스프레이즈 '),
                    widget.usePassphrase
                        ? const HighLightedText('사용', color: MyColors.darkgrey)
                        : const Row(
                            children: [
                              Text('사용 '),
                              HighLightedText('안함', color: MyColors.darkgrey),
                            ],
                          ),
                    GestureDetector(
                        onTap: widget.onReset,
                        child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: MyColors.borderGrey)),
                            child: const Text(
                              '다시 고르기',
                              style: Styles.caption,
                            )))
                  ],
                ),
              ),
              if (widget.usePassphrase)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NumberWidget(
                          number: 1,
                          assetPath: 'assets/svg/number/one.svg',
                          selected: step == 0,
                          onSelected: () {
                            setState(() {
                              step = 0;
                            });
                          }),
                      const Text('•••'),
                      NumberWidget(
                          number: 2,
                          assetPath: 'assets/svg/number/two.svg',
                          selected: step == 1,
                          onSelected: () {
                            setState(() {
                              step = 1;
                            });
                          }),
                    ],
                  ),
                ),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: MyColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: step == 0
                      ? Container(
                          padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
                          child: Column(
                            children: [
                              GestureDetector(
                                  onTap: _generateMnemonicPhrase,
                                  child: const Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 24, 0),
                                    child: Row(children: [
                                      Spacer(),
                                      Icon(
                                        Icons.refresh_rounded,
                                        color: MyColors.borderGrey,
                                      )
                                    ]),
                                  )),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, // Number of columns
                                  childAspectRatio:
                                      2.5, // Aspect ratio for grid items
                                  crossAxisSpacing: 0, // Space between columns
                                  mainAxisSpacing: 0, // Space between rows
                                ),
                                itemCount: mnemonic.split(' ').length,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index % 3 == 0) {
                                    gridviewColumnFlag = !gridviewColumnFlag;
                                  }

                                  return Container(
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          (index + 1).toString(),
                                          style: Styles.body2.merge(
                                            TextStyle(
                                              fontFamily: CustomFonts
                                                  .number.getFontFamily,
                                              color: MyColors.darkgrey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          mnemonic.split(' ')[index],
                                          style: Styles.body2.merge(
                                            const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  child: CustomTextField(
                                    controller: _passphraseController,
                                    placeholder: "패스프레이즈를 입력해 주세요",
                                    onChanged: (text) {
                                      setState(() {
                                        passphrase = text;
                                      });

                                      if (!widget.usePassphrase) {
                                        widget.onFinished(
                                            mnemonic, text, false);
                                      }
                                    },
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
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, right: 4),
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
                            ],
                          ),
                        )),
              if (step == 0)
                const Text('안전한 장소에서 니모닉 문구를 백업해 주세요', style: Styles.warning),
              if (step == 0 && stepCount == 2)
                CompleteButton(
                    onPressed: () {
                      setState(() {
                        step = 1;
                      });
                    },
                    label: '백업 완료',
                    disabled: false),
              if (step == 1)
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: const Text(
                    '입력하신 패스프레이즈는 보관과 유출에 유의해 주세요',
                    style: Styles.warning,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!widget.usePassphrase)
                CompleteButton(
                    onPressed: () {
                      vaultModel.startImporting(mnemonic, passphrase);
                      widget.onFinished(mnemonic, passphrase, true);

                      widget.onShowConfirmBottomSheet();
                    },
                    label: '백업 완료',
                    disabled: false),
              if (widget.usePassphrase && step == 1)
                CompleteButton(
                    onPressed: () {
                      if (passphrase.isNotEmpty) {
                        vaultModel.startImporting(mnemonic, passphrase);
                        widget.onFinished(mnemonic, passphrase, true);
                        widget.onShowConfirmBottomSheet();
                      } else {
                        widget.onFinished(mnemonic, passphrase, false);
                      }
                    },
                    label: '완료',
                    disabled: passphrase.isEmpty)
            ],
          )),
    );
  }
}

class NumberWidget extends StatefulWidget {
  final int number;
  final String assetPath;
  final bool selected;
  final Function() onSelected;

  const NumberWidget(
      {super.key,
      required this.number,
      required this.assetPath,
      required this.selected,
      required this.onSelected});

  @override
  _NumberWidgetState createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<NumberWidget> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.selected ? MyColors.darkgrey : Colors.white;
    Color iconColor = widget.selected ? MyColors.white : MyColors.darkgrey;

    return GestureDetector(
      onTap: widget.onSelected,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: bgColor,
            border: Border.all(color: MyColors.darkgrey)),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: SvgPicture.asset(
          widget.assetPath,
          width: 12,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
