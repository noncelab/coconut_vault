import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/check_list.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:provider/provider.dart';

class MnemonicGenerationScreen extends StatefulWidget {
  const MnemonicGenerationScreen({super.key});

  @override
  State<MnemonicGenerationScreen> createState() =>
      _MnemonicGenerationScreenState();
}

class _MnemonicGenerationScreenState extends State<MnemonicGenerationScreen> {
  late final int _totalStep;
  int _step = 0;
  int _selectedWordsCount = 0;
  bool _usePassphrase = false;
  String _mnemonicWords = '';
  String _passphrase = '';

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
    });
  }

  void _onFinished(String mnemonicWords, String passphrase, bool finished) {
    setState(() {
      _mnemonicWords =
          mnemonicWords.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      _passphrase = passphrase;
    });
  }

  void _showStopGeneratingMnemonicDialog() {
    CustomDialogs.showCustomAlertDialog(
      context,
      title: t.alert.stop_generating_mnemonic.title,
      message: t.alert.stop_generating_mnemonic.description,
      cancelButtonText: t.cancel,
      confirmButtonText: t.stop,
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
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: MnemonicConfirmationBottomSheet(
        onCancelPressed: () => Navigator.pop(context),
        onConfirmPressed: () {
          Provider.of<WalletCreationProvider>(context, listen: false)
              .setSecretAndPassphrase(_mnemonicWords, _passphrase);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const VaultNameAndIconSetupScreen()));
        },
        onInactivePressed: () {
          CustomToast.showToast(context: context, text: t.toast.scroll_down);
          vibrateMediumDouble();
        },
        mnemonic: _mnemonicWords,
        passphrase: _usePassphrase ? _passphrase : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Provider.of<WalletCreationProvider>(context, listen: false).resetAll();
    _totalStep = Provider.of<VisibilityProvider>(context, listen: false)
            .isPassphraseUseEnabled
        ? 2
        : 1;
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
        wordsCount: _selectedWordsCount,
        usePassphrase: _usePassphrase,
        onReset: _onReset,
        onFinished: _onFinished,
        onShowStopDialog: _showStopGeneratingMnemonicDialog,
        onShowConfirmBottomSheet: _showConfirmBottomSheet,
      ),
    ];

    return Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: t.mnemonic_generate_screen.title,
          context: context,
          onBackPressed: _showStopGeneratingMnemonicDialog,
          hasRightIcon: false,
        ),
        body: SafeArea(
          child: screens[_step],
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
      onPopInvokedWithResult: (didPop, _) {
        widget.onShowStopDialog();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            Text(t.mnemonic_generate_screen.select_word_length,
                style: Styles.body1Bold),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: t.mnemonic_generate_screen.twelve,
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
                    text: t.mnemonic_generate_screen.twenty_four,
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
      onPopInvokedWithResult: (didPop, _) {
        widget.onShowStopDialog();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            Text(t.mnemonic_generate_screen.use_passphrase,
                style: Styles.body1Bold),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: t.no,
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
                    text: t.yes,
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
  late WalletCreationProvider _walletCreationProvider;
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
    ChecklistItem(title: t.mnemonic_generate_screen.ensure_backup)
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
    _walletCreationProvider =
        Provider.of<WalletCreationProvider>(context, listen: false);
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
    bool gridviewColumnFlag = false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        widget.onShowStopDialog();
      },
      child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 12),
                  child: Selector<VisibilityProvider, bool>(
                      selector: (context, model) =>
                          model.isPassphraseUseEnabled,
                      builder: (context, isAdvancedUser, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            HighLightedText(
                                widget.wordsCount == 12
                                    ? t.mnemonic_generate_screen.twelve
                                    : t.mnemonic_generate_screen.twenty_four,
                                color: MyColors.darkgrey),
                            Text(isAdvancedUser ? ', ${t.passphrase} ' : ''),
                            isAdvancedUser
                                ? widget.usePassphrase
                                    ? HighLightedText(
                                        t.mnemonic_generate_screen.use,
                                        color: MyColors.darkgrey)
                                    : Row(
                                        children: [
                                          Text(
                                              '${t.mnemonic_generate_screen.use} '),
                                          HighLightedText(
                                              t.mnemonic_generate_screen.do_not,
                                              color: MyColors.darkgrey),
                                        ],
                                      )
                                : Text(' ${t.mnemonic_generate_screen.use}'),
                            GestureDetector(
                                onTap: widget.onReset,
                                child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: MyColors.borderGrey)),
                                    child: Text(
                                      t.re_select,
                                      style: Styles.caption,
                                    )))
                          ],
                        );
                      }),
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
                                //const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3, // Number of columns
                                    childAspectRatio:
                                        MediaQuery.of(context).size.height > 640
                                            ? 2.5
                                            : 2, // Aspect ratio for grid items
                                    crossAxisSpacing:
                                        0, // Space between columns
                                    mainAxisSpacing: 0, // Space between rows
                                  ),
                                  itemCount: mnemonic.split(' ').length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
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
                                            overflow: TextOverflow.visible,
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
                                      placeholder: t.mnemonic_generate_screen
                                          .enter_passphrase,
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
                  Text(t.mnemonic_generate_screen.backup_guide,
                      style: Styles.warning),
                if (step == 0 && stepCount == 2)
                  CompleteButton(
                      onPressed: () {
                        setState(() {
                          step = 1;
                        });
                      },
                      label: t.mnemonic_generate_screen.backup_complete,
                      disabled: false),
                if (step == 1)
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Text(
                      t.mnemonic_generate_screen.warning,
                      style: Styles.warning,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!widget.usePassphrase)
                  CompleteButton(
                      onPressed: () {
                        _walletCreationProvider.setSecretAndPassphrase(
                            mnemonic, passphrase);
                        widget.onFinished(mnemonic, passphrase, true);

                        widget.onShowConfirmBottomSheet();
                      },
                      label: t.mnemonic_generate_screen.backup_complete,
                      disabled: false),
                if (widget.usePassphrase && step == 1)
                  CompleteButton(
                      onPressed: () {
                        if (passphrase.isNotEmpty) {
                          _walletCreationProvider.setSecretAndPassphrase(
                              mnemonic, passphrase);
                          widget.onFinished(mnemonic, passphrase, true);
                          widget.onShowConfirmBottomSheet();
                        } else {
                          widget.onFinished(mnemonic, passphrase, false);
                        }
                      },
                      label: t.complete,
                      disabled: passphrase.isEmpty),
                const SizedBox(height: 40),
              ],
            )),
      ),
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
