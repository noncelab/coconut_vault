import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_bottom_sheet.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/utils/wallet_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MnemonicImport extends StatefulWidget {
  const MnemonicImport({super.key});

  @override
  State<MnemonicImport> createState() => _MnemonicImportState();
}

class _MnemonicImportState extends State<MnemonicImport> {
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
    CustomDialogs.showCustomAlertDialog(
      context,
      title: t.alert.stop_importing_mnemonic.title,
      message: t.alert.stop_importing_mnemonic.description,
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.buildWithNext(
              title: t.mnemonic_import_screen.title,
              context: context,
              onBackPressed: _handleBackNavigation,
              onNextPressed: _handleNextButton,
              isActive: _usePassphrase
                  ? _inputText.isNotEmpty && _isMnemonicValid == true && _passphrase.isNotEmpty
                  : _inputText.isNotEmpty && _isMnemonicValid == true,
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
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
              ),
            ),
          ),
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

    final String passphrase = _usePassphrase ? _passphrase.trim() : '';

    if (_walletProvider.isSeedDuplicated(secret, passphrase)) {
      CustomToast.showToast(context: context, text: t.toast.mnemonic_already_added);
      return;
    }

    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: MnemonicConfirmationBottomSheet(
        onCancelPressed: () => Navigator.pop(context),
        onConfirmPressed: () {
          _walletCreationProvider.setSecretAndPassphrase(secret, passphrase);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const VaultNameAndIconSetupScreen()));
        },
        onInactivePressed: () {
          CustomToast.showToast(context: context, text: t.toast.scroll_down);
          vibrateMediumDouble();
        },
        mnemonic: secret,
        passphrase: _usePassphrase ? _passphrase : null,
      ),
    );
  }

  Widget _buildMnemonicTextField() {
    return CustomTextField(
      focusNode: _mnemonicFocusNode,
      controller: _mnemonicController,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z ]'))],
      placeholder: t.mnemonic_import_screen.put_spaces_between_words,
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
      valid: _isMnemonicValid,
      errorMessage: _errorMessage ?? t.errors.invalid_mnemonic_phrase,
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
            child: CustomTextField(
              controller: _passphraseController,
              placeholder: t.mnemonic_import_screen.enter_passphrase,
              onChanged: (text) {},
              valid: _passphrase.length <= 100,
              maxLines: 1,
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
