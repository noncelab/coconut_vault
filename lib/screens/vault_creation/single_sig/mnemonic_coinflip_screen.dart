import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
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
    CustomDialogs.showCustomAlertDialog(
      context,
      title: t.alert.stop_creating_mnemonic.title,
      message: t.alert.stop_creating_mnemonic.description,
      cancelButtonText: t.cancel,
      confirmButtonText: t.stop,
      confirmButtonColor: CoconutColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
      },
    );
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
      WordsLengthSelection(
          onSelected: _onLengthSelected, onShowStopDialog: _showStopGeneratingMnemonicDialog),
      PassphraseSelection(
          onSelected: _onPassphraseSelected, onShowStopDialog: _showStopGeneratingMnemonicDialog),
      FlipCoin(
        wordsCount: _selectedWordsCount,
        usePassphrase: _usePassphrase,
        onReset: _onReset,
        onShowStopDialog: _showStopGeneratingMnemonicDialog,
      )
    ];

    return Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CustomAppBar.build(
          title: t.mnemonic_coin_flip_screen.title,
          context: context,
          onBackPressed: _showStopGeneratingMnemonicDialog,
          hasRightIcon: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: screens[_step],
          ),
        ));
  }
}

class FlipCoin extends StatefulWidget {
  final int wordsCount;
  final bool usePassphrase;
  final Function() onReset;
  final VoidCallback onShowStopDialog;

  const FlipCoin({
    super.key,
    required this.wordsCount,
    required this.usePassphrase,
    required this.onReset,
    required this.onShowStopDialog,
  });

  @override
  State<FlipCoin> createState() => _FlipCoinState();
}

class _FlipCoinState extends State<FlipCoin> {
  late int stepCount; // 총 화면 단계
  int step = 0;
  String _mnemonic = '';
  String passphrase = '';
  final TextEditingController _passphraseController = TextEditingController();
  bool passphraseObscured = false;
  bool isNextButtonActive = false;
  int numberOfBits = 0;

  final List<int> _bits = [];
  late int _totalBits;
  int _currentIndex = 0;
  bool _showFullBits = false;

  @override
  void initState() {
    super.initState();
    _totalBits = widget.wordsCount == 12 ? 128 : 256;
    stepCount = widget.usePassphrase ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          widget.onShowStopDialog();
        },
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 12),
                  child: Selector<VisibilityProvider, bool>(
                      selector: (context, model) => model.isPassphraseUseEnabled,
                      builder: (context, isAdvancedUser, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HighLightedText(
                                widget.wordsCount == 12
                                    ? t.mnemonic_generate_screen.twelve
                                    : t.mnemonic_generate_screen.twenty_four,
                                color: CoconutColors.gray800),
                            Text(isAdvancedUser ? ', ${t.passphrase} ' : ''),
                            isAdvancedUser
                                ? widget.usePassphrase
                                    ? HighLightedText(t.mnemonic_coin_flip_screen.use,
                                        color: CoconutColors.gray800)
                                    : Row(
                                        children: [
                                          Text('${t.mnemonic_coin_flip_screen.use} '),
                                          HighLightedText(t.mnemonic_coin_flip_screen.do_not,
                                              color: CoconutColors.gray800),
                                        ],
                                      )
                                : Text(' ${t.mnemonic_coin_flip_screen.use}'),
                            GestureDetector(
                                onTap: _currentIndex != 0
                                    ? () => _showConfirmResetDialog(
                                        title: t.alert.reselect.title,
                                        message: t.alert.reselect.description,
                                        action: () {
                                          widget.onReset();
                                          Navigator.pop(context);
                                        })
                                    : widget.onReset,
                                child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: CoconutColors.borderGray)),
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: CoconutColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: CoconutColors.gray500.withOpacity(0.3),
                          spreadRadius: 4,
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: step == 0
                        ? Column(
                            children: [
                              Text('$_currentIndex / $_totalBits', style: Styles.h3),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: CoconutBorder.defaultRadius,
                                    onTap: _showAllBitsBottomSheet,
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1,
                                          color: CoconutColors.borderGray,
                                        ),
                                        borderRadius: CoconutBorder.defaultRadius,
                                        color: CoconutColors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 10,
                                        ),
                                        child: Text(t.view_all, style: Styles.caption),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildBitGrid(),
                              const SizedBox(height: 20),
                              _buildButtons(),
                            ],
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  child: CustomTextField(
                                    controller: _passphraseController,
                                    placeholder: t.mnemonic_coin_flip_screen.enter_passphrase,
                                    onChanged: (text) {
                                      setState(() {
                                        passphrase = text;
                                      });
                                    },
                                    maxLines: 1,
                                    obscureText: passphraseObscured,
                                    suffix: CupertinoButton(
                                      onPressed: () {
                                        setState(() {
                                          passphraseObscured = !passphraseObscured;
                                        });
                                      },
                                      child: passphraseObscured
                                          ? const Icon(
                                              CupertinoIcons.eye_slash,
                                              color: CoconutColors.gray800,
                                              size: 18,
                                            )
                                          : const Icon(
                                              CupertinoIcons.eye,
                                              color: CoconutColors.gray800,
                                              size: 18,
                                            ),
                                    ),
                                    maxLength: 100,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 4),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    '(${passphrase.length} / 100)',
                                    style: TextStyle(
                                        color: passphrase.length == 100
                                            ? CoconutColors.black.withOpacity(0.7)
                                            : CoconutColors.black.withOpacity(0.5),
                                        fontSize: 12,
                                        fontFamily: CustomFonts.text.getFontFamily),
                                  ),
                                ),
                              )
                            ],
                          )),
                if (step == 0 && stepCount == 1)
                  CompleteButton(
                      onPressed: () {
                        setState(() {
                          if (_generateMnemonicPhrase()) {
                            _showConfirmBottomSheet(t.bottom_sheet.mnemonic_backup);
                          }
                        });
                      },
                      label: t.complete,
                      disabled: _bits.length < _totalBits),
                if (step == 0 && stepCount == 2)
                  CompleteButton(
                      onPressed: () {
                        setState(() {
                          setState(() {
                            step = 1;
                          });
                        });
                      },
                      label: t.next,
                      disabled: _bits.length < _totalBits),
                if (widget.usePassphrase && step == 1)
                  CompleteButton(
                      onPressed: () {
                        setState(() {
                          if (_generateMnemonicPhrase()) {
                            _showConfirmBottomSheet(
                                t.bottom_sheet.mnemonic_backup_and_confirm_passphrase);
                          }
                        });
                      },
                      label: t.complete,
                      disabled: passphrase.isEmpty || _bits.length < _totalBits),
                const SizedBox(height: 80),
              ],
            )));
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
              width: 40,
              height: 50,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: CoconutColors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(8),
                color: index < currentBits.length
                    ? (currentBits[index] == 1
                        ? CoconutColors.black.withOpacity(0.06)
                        : CoconutColors.black.withOpacity(0.15))
                    : CoconutColors.white,
              ),
              child: Center(
                  child: Column(
                children: [
                  Text('${start + index + 1}',
                      style: Styles.caption.merge(TextStyle(
                          fontFamily: CustomFonts.number.getFontFamily,
                          color: CoconutColors.black.withOpacity(0.3)))),
                  Text(
                    index < currentBits.length ? '${currentBits[index]}' : '',
                    style: Styles.h3.merge(TextStyle(fontFamily: CustomFonts.number.getFontFamily)),
                  )
                ],
              )),
            );
          }),
        );
      }),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentIndex < _totalBits ? () => _addBit(1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  child: _buildCoin(t.mnemonic_coin_flip_screen.coin_head),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _currentIndex < _totalBits ? () => _addBit(0) : null,
                child: Ink(
                  child: _buildCoin(t.mnemonic_coin_flip_screen.coin_tail),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _removeLastBit,
              child: Text(t.delete_one,
                  style: Styles.subLabel
                      .merge(TextStyle(color: _bits.isEmpty ? CoconutColors.secondaryText : null))),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _showConfirmResetDialog,
              child: Text(t.delete_all,
                  style: Styles.subLabel
                      .merge(TextStyle(color: _bits.isEmpty ? CoconutColors.secondaryText : null))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoin(String label) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _bits.length == _totalBits
                    ? CoconutColors.borderLightGray
                    : CoconutColors.borderGray)),
        child: Text(label, style: Styles.body1));
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
    CustomDialogs.showCustomAlertDialog(
      context,
      title: title ?? t.delete_all,
      message: message ?? t.alert.erase_all_entered_so_far,
      cancelButtonText: t.cancel,
      confirmButtonText: t.confirm,
      confirmButtonColor: CoconutColors.warningText,
      onCancel: () => Navigator.pop(context),
      onConfirm: action ??
          () {
            _resetBits();
            Navigator.pop(context);
          },
    );
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

  void _showConfirmBottomSheet(String message) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: MnemonicConfirmationBottomSheet(
        onCancelPressed: () => Navigator.pop(context),
        onConfirmPressed: () {
          Provider.of<WalletCreationProvider>(context, listen: false)
              .setSecretAndPassphrase(_mnemonic, passphrase);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const VaultNameAndIconSetupScreen()));
        },
        onInactivePressed: () {
          CustomToast.showToast(context: context, text: t.toast.scroll_down);
        },
        mnemonic: _mnemonic,
        passphrase: widget.usePassphrase ? passphrase : null,
        topMessage: message,
      ),
    );
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
              style: Styles.caption.merge(TextStyle(
                  fontFamily: CustomFonts.number.getFontFamily,
                  color: CoconutColors.black.withOpacity(0.3))),
            ),
            Expanded(
              child: Text(
                bit == null ? '' : bit.toString(),
                style: Styles.h3.merge(
                  TextStyle(
                    fontFamily: CustomFonts.number.getFontFamily,
                    color: CoconutColors.black.withOpacity(0.7),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
