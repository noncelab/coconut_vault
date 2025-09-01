import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/wallet_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MnemonicImportScreen extends StatefulWidget {
  const MnemonicImportScreen({super.key});

  @override
  State<MnemonicImportScreen> createState() => _MnemonicImportScreenState();
}

class _MnemonicImportScreenState extends State<MnemonicImportScreen> {
  late WalletProvider _walletProvider;
  late WalletCreationProvider _walletCreationProvider;
  String _inputText = '';
  bool _usePassphrase = false;
  String _passphrase = '';
  //String _passphraseConfirm = '';
  bool _passphraseObscured = false;
  // 니모닉이 유효한지 확인을 한 상황이면 true
  bool? _isMnemonicValid;
  String? _errorMessage;

  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final FocusNode _mnemonicFocusNode = FocusNode();
  final FocusNode _passphraseFocusNode = FocusNode();
  // final TextEditingController _passphraseConfirmController =
  //     TextEditingController();
  // final FocusNode _fcnodePassphrase = FocusNode();

  @override
  void initState() {
    super.initState();
    _initListeners();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false)
      ..resetAll();
    Future.microtask(() => _mnemonicFocusNode.requestFocus());
  }

  void _initListeners() {
    _passphraseController.addListener(() {
      setState(() {
        _passphrase = _passphraseController.text;
      });
    });
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    _passphraseController.dispose();
    _mnemonicFocusNode.dispose();
    _passphraseFocusNode.dispose();
    // _passphraseConfirmController.dispose();
    // _fcnodePassphrase.dispose();

    super.dispose();
  }

  void _validateMnemonic() {
    final String normalizedInputText = _inputText.trim().replaceAll(RegExp(r'\s+'), ' ');
    final List<String> words = normalizedInputText.split(' ');

    if (_inputText.trim().isEmpty) return _resetValidation();

    final List<String> invalidWords = words
        .where((word) => !WalletUtility.isInMnemonicWordList(word) && !_hasPrefixMatch(word))
        .toList();

    if (invalidWords.isNotEmpty) {
      setState(() {
        _isMnemonicValid = false;
        _errorMessage = t.errors.invalid_word_error(filter: invalidWords);
      });
      return;
    }

    if (!_isValidMnemonicLength(words)) return _resetValidation();

    setState(() {
      _isMnemonicValid = isValidMnemonic(normalizedInputText);
      _errorMessage = null;
    });
  }

  void _resetValidation() => setState(() {
        _isMnemonicValid = null;
        _errorMessage = null;
      });

  bool _isValidMnemonicLength(List<String> words) {
    final validLengths = [12, 15, 18, 21, 24];
    return validLengths.contains(words.length);
  }

  bool _hasPrefixMatch(String prefix) {
    return wordList.any((word) => word.startsWith(prefix.toLowerCase()));
  }

  void _showStopImportingMnemonicDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: t.alert.stop_importing_mnemonic.title,
            titleTextStyle: CoconutTypography.body1_16_Bold,
            description: t.alert.stop_importing_mnemonic.description,
            descriptionTextStyle: CoconutTypography.body2_14,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonTextStyle: CoconutTypography.body2_14.merge(
              const TextStyle(
                color: CoconutColors.gray900,
                fontWeight: FontWeight.w500,
              ),
            ),
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.gray900,
            rightButtonTextStyle: CoconutTypography.body2_14.merge(
              const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.mnemonic_import_screen.title,
          context: context,
          onBackPressed: _handleBackNavigation,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: <Widget>[
                        Text(t.mnemonic_import_screen.enter_mnemonic_phrase,
                            style: CoconutTypography.body1_16_Bold),
                        const SizedBox(height: 30),
                        _buildMnemonicTextField(),
                        const SizedBox(height: 30),
                        _buildPassphraseToggle(),
                        if (_usePassphrase) _buildPassphraseTextField(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                // TODO: check 버튼 너비가 다른 요소에 비해 더 넓은 것 같음
                FixedBottomButton(
                    text: t.next,
                    onButtonClicked: _handleNextButton,
                    isActive: _usePassphrase
                        ? _inputText.isNotEmpty &&
                            _isMnemonicValid == true &&
                            _passphrase.isNotEmpty
                        : _inputText.isNotEmpty && _isMnemonicValid == true,
                    backgroundColor: CoconutColors.black,
                    isVisibleAboveKeyboard: false),
                // TODO: isolate
                Visibility(
                  visible: false,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(color: CoconutColors.black.withOpacity(0.3)),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: CoconutColors.gray800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (_inputText.isEmpty && _passphrase.isEmpty && mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } else {
      _showStopImportingMnemonicDialog();
    }
  }

  void _handleNextButton() {
    final String secret = _inputText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final String passphrase = _usePassphrase ? _passphrase : '';

    if (_walletProvider.isSeedDuplicated(secret, passphrase)) {
      CoconutToast.showToast(
          context: context, text: t.toast.mnemonic_already_added, isVisibleIcon: true);
      return;
    }
    _walletCreationProvider.setSecretAndPassphrase(secret, passphrase);
    Navigator.pushNamed(context, AppRoutes.mnemonicConfirmation);
  }

  Widget _buildMnemonicTextField() {
    return CoconutTextField(
      focusNode: _mnemonicFocusNode,
      controller: _mnemonicController,
      textInputFormatter: [FilteringTextInputFormatter.allow(RegExp(r'[a-z ]'))],
      placeholderText: t.mnemonic_import_screen.put_spaces_between_words,
      onChanged: (text) {
        _inputText = text.toLowerCase();
        setState(() {
          _mnemonicController.value = _mnemonicController.value.copyWith(
            text: _inputText,
            selection: TextSelection.collapsed(
              offset: _mnemonicController.selection.baseOffset.clamp(0, _inputText.length),
            ),
          );
        });
        _validateMnemonic();
      },
      maxLines: 5,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      isError: _isMnemonicValid == false,
      errorText: _errorMessage ?? t.errors.invalid_mnemonic_phrase,
    );
  }

  Widget _buildPassphraseToggle() {
    return Selector<VisibilityProvider, bool>(
        selector: (context, provider) => provider.isPassphraseUseEnabled,
        builder: (context, isAdvancedUser, child) {
          if (isAdvancedUser) {
            return Row(
              children: [
                Text(t.mnemonic_import_screen.use_passphrase,
                    style: CoconutTypography.body2_14_Bold),
                const Spacer(),
                CupertinoSwitch(
                  value: _usePassphrase,
                  activeColor: CoconutColors.gray800,
                  onChanged: (value) {
                    setState(() {
                      _usePassphrase = value;
                    });
                  },
                ),
              ],
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: CoconutColors.black.withOpacity(0.06),
            ),
            child: Column(
              children: [
                Text(t.mnemonic_import_screen.need_advanced_mode),
                GestureDetector(
                  onTap: () {
                    MyBottomSheet.showBottomSheet_90(
                        context: context, child: const SettingsScreen());
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      t.mnemonic_import_screen.open_settings,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: CoconutColors.black,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildPassphraseTextField() {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            child: CoconutTextField(
              focusNode: _passphraseFocusNode,
              controller: _passphraseController,
              placeholderText: t.mnemonic_import_screen.enter_passphrase,
              onChanged: (_) {},
              isError: _passphrase.length > 100,
              maxLines: 1,
              isLengthVisible: false,
              obscureText: _passphraseObscured,
              suffix: CupertinoButton(
                onPressed: () {
                  setState(() {
                    _passphraseObscured = !_passphraseObscured;
                  });
                },
                child: _passphraseObscured
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
          )),
      Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: Align(
          alignment: Alignment.topRight,
          child: Text(
            '(${_passphrase.length} / 100)',
            style: CoconutTypography.body3_12.setColor(
              _passphrase.length == 100
                  ? CoconutColors.black.withOpacity(0.7)
                  : CoconutColors.black.withOpacity(0.5),
            ),
          ),
        ),
      )
    ]);
  }
}
