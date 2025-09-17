import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/utils/wallet_utils.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class MnemonicImportScreen extends StatefulWidget {
  const MnemonicImportScreen({super.key});

  @override
  State<MnemonicImportScreen> createState() => _MnemonicImportScreenState();
}

class _MnemonicImportScreenState extends State<MnemonicImportScreen> {
  // Constants
  static const int _defaultWordCount = 12;
  static const int _maxWordCount = 24;
  static const int _wordsPerLine = 3;
  static const int _maxLines = 8;
  static const Duration _scrollDuration = Duration(milliseconds: 300);
  static const Duration _passphraseScrollDelay = Duration(milliseconds: 500);

  // Providers
  late WalletProvider _walletProvider;
  late WalletCreationProvider _walletCreationProvider;

  // State variables
  bool _usePassphrase = false;
  String _passphrase = '';
  bool _passphraseObscured = false;
  bool? _isMnemonicValid;
  bool _isSuggestionWordsVisible = false;
  bool _isDropdownVisible = false;
  String? _errorMessage;
  List<String> _suggestionWords = [];
  List<int> _invalidMnemonicIndexes = [];
  int _wordCount = _defaultWordCount;

  // Controllers and nodes
  List<WordSuggestableController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  final TextEditingController _passphraseController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // UI related
  final List<double> _scrollOffsets = [];
  final GlobalKey _mnemonicInputLineGlobalKey = GlobalKey();
  Size _mnemonicInputLineSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false)
      ..resetAll();

    _initializeTextFields();
    _requestInitialFocus();
    _setupPostFrameCallbacks();
  }

  void _requestInitialFocus() {
    Future.microtask(() => _focusNodes[0].requestFocus());
  }

  void _setupPostFrameCallbacks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addFocusListeners();
      _initializeMnemonicInputLine();
      _initializeScrollOffsets();
    });
  }

  void _initializeMnemonicInputLine() {
    final mnemonicInputLineRenderBox =
        _mnemonicInputLineGlobalKey.currentContext?.findRenderObject() as RenderBox;
    _mnemonicInputLineSize = mnemonicInputLineRenderBox.size;
  }

  void _initializeScrollOffsets() {
    _scrollOffsets.clear();
    for (int i = 0; i < _maxLines; i++) {
      if (i == 0) {
        _scrollOffsets.add(0);
      }
      _scrollOffsets.add((_mnemonicInputLineSize.height + 8) * (i + 1));
    }
  }

  void _addFocusListeners() {
    _addMnemonicFieldListeners();
    _addPassphraseListener();
  }

  void _addMnemonicFieldListeners() {
    for (var i = 0; i < _wordCount; i++) {
      _focusNodes[i].addListener(() => _onMnemonicFieldFocusChanged(i));
    }
  }

  void _onMnemonicFieldFocusChanged(int index) {
    _validateMnemonic(checkPrefixMatch: false);
    final hasFocus = _focusNodes[index].hasFocus;

    if (!hasFocus) {
      _handleFieldLostFocus(index);
    } else {
      _handleFieldGainedFocus(index);
    }
  }

  void _handleFieldLostFocus(int index) {
    _controllers[index].clearSuggestion();

    if (!_focusNodes.any((node) => node.hasFocus)) {
      _hideSuggestionPanel();
    }
  }

  void _handleFieldGainedFocus(int index) {
    _controllers[index].clearSuggestion();
    _queryCurrentWord();

    if (_isCompleteMnemonicWord(_controllers[index].text)) {
      _hideSuggestionPanel();
      return;
    }

    _forceCursorToEnd(index);
    _updateSuggestionVisibility(index);
  }

  void _forceCursorToEnd(int index) {
    _controllers[index].selection = TextSelection.collapsed(
      offset: _controllers[index].text.length,
    );
  }

  void _updateSuggestionVisibility(int index) {
    final shouldShowSuggestions = _controllers[index].text.length >= 2;

    if (_isSuggestionWordsVisible != shouldShowSuggestions) {
      setState(() {
        _isSuggestionWordsVisible = shouldShowSuggestions;
      });
    }
  }

  void _hideSuggestionPanel() {
    if (_isSuggestionWordsVisible || _suggestionWords.isNotEmpty) {
      setState(() {
        _isSuggestionWordsVisible = false;
        _suggestionWords = [];
      });
    } else {
      setState(() {});
    }
  }

  bool _isCompleteMnemonicWord(String text) {
    return WalletUtility.isInMnemonicWordList(text.trim());
  }

  void _addPassphraseListener() {
    _passphraseFocusNode.addListener(() async {
      await Future.delayed(_passphraseScrollDelay);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: _scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  void _initializeTextFields() {
    _disposeTextFields();
    _controllers = List.generate(_wordCount, (index) => WordSuggestableController());
    _focusNodes = List.generate(_wordCount, (index) => FocusNode());
  }

  void _disposeTextFields() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }

  void _changeWordCount(int newCount) async {
    await _hideKeyboard();
    final preservedTexts = _getPreservedTexts();

    setState(() {
      _wordCount = newCount;
      _initializeTextFields();
      _restorePreservedTexts(preservedTexts);
      _resetValidationState();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addFocusListeners();
      _validateMnemonic(checkPrefixMatch: false);
    });
  }

  Future<void> _hideKeyboard() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  List<String> _getPreservedTexts() {
    return _controllers.map((controller) => controller.text).toList();
  }

  void _restorePreservedTexts(List<String> preservedTexts) {
    if (preservedTexts.isNotEmpty) {
      for (int i = 0; i < preservedTexts.length && i < _controllers.length; i++) {
        _controllers[i].text = preservedTexts[i];
      }
    }
  }

  void _resetValidationState() {
    _isMnemonicValid = null;
    _errorMessage = null;
    _suggestionWords = [];
    _isSuggestionWordsVisible = false;
    _isDropdownVisible = false;
    _invalidMnemonicIndexes = [];
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
    _disposeTextFields();
    _passphraseController.dispose();
    _passphraseFocusNode.dispose();
    super.dispose();
  }

  void _handleSpaceInput() {
    if (!_isSuggestionWordsVisible) return;

    final controllerIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (controllerIndex == -1) return;

    _controllers[controllerIndex].replaceWithSuggestion(_controllers[controllerIndex].cursorOffset);
    _hideSuggestionPanel();

    if (_controllers[controllerIndex].text.isNotEmpty) {
      _focusNextField();
    }
  }

  void _validateMnemonic({bool checkPrefixMatch = true}) {
    final List<bool> isMnemonicValid = List.generate(_wordCount, (index) => false);

    for (int i = 0; i < _wordCount; i++) {
      final word = _controllers[i].text.trim();
      isMnemonicValid[i] =
          WalletUtility.isInMnemonicWordList(word) ||
          (checkPrefixMatch ? _hasPrefixMatch(word) : false);
    }

    _updateInvalidIndexes(isMnemonicValid);
    _updateValidationState();
  }

  void _updateInvalidIndexes(List<bool> isMnemonicValid) {
    _invalidMnemonicIndexes = [
      for (int i = 0; i < isMnemonicValid.length; i++)
        if (!isMnemonicValid[i] && _controllers[i].text.isNotEmpty) i,
    ];
  }

  void _updateValidationState() {
    if (_invalidMnemonicIndexes.isNotEmpty) {
      setState(() {
        _isMnemonicValid = false;
        _errorMessage = t.errors.invalid_word_error(
          filter: _invalidMnemonicIndexes.map((e) => _controllers[e].text).toList(),
        );
      });
      return;
    }

    setState(() {
      if (_controllers.every((controller) => controller.text.isNotEmpty)) {
        _isMnemonicValid = isValidMnemonic(
          _controllers.map((controller) => controller.text).join(' '),
        );
      }
      _errorMessage = null;
    });
  }

  void _focusNextField() {
    final int currentIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (currentIndex == -1 || _controllers[currentIndex].text.isEmpty) return;

    if (currentIndex == _wordCount - 1) {
      FocusScope.of(context).unfocus();
      return;
    }

    final int nextIndex = currentIndex + 1;
    if (nextIndex < _focusNodes.length) {
      _focusNodes[nextIndex].requestFocus();
    }

    _validateMnemonic(checkPrefixMatch: false);
  }

  void _applySuggestionWord(String newWord) {
    final controllerIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (controllerIndex == -1) return;

    _controllers[controllerIndex].text = newWord.trim();
    _forceCursorToEnd(controllerIndex);
    _hideSuggestionPanel();
    _focusNextField();
  }

  void _queryCurrentWord() {
    if (!_focusNodes.any((node) => node.hasFocus)) {
      _hideSuggestionPanel();
      return;
    }

    final controllerIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (controllerIndex == -1) return;

    final text = _controllers[controllerIndex].text;
    final sel = _controllers[controllerIndex].selection;
    final pos = sel.baseOffset;
    if (pos < 0 || pos > text.length) return;

    final word = _extractCurrentWord(text, pos);
    if (word.length >= 2) {
      _updateSuggestions(word, controllerIndex);
    } else {
      setState(() {
        _suggestionWords = [];
      });
    }
  }

  String _extractCurrentWord(String text, int pos) {
    int start = pos;
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    int end = pos;
    while (end < text.length && text[end] != ' ') {
      end++;
    }
    return text.substring(start, end).trim();
  }

  void _updateSuggestions(String word, int controllerIndex) {
    try {
      String query = word.toLowerCase();
      _suggestionWords = _getFilteredSuggestions(query);

      setState(() {
        _isSuggestionWordsVisible =
            _suggestionWords.isNotEmpty && _focusNodes.any((node) => node.hasFocus);
      });

      if (_suggestionWords.isNotEmpty) {
        _controllers[controllerIndex].updateSuggestion(
          _controllers[controllerIndex].selection.baseOffset,
          _suggestionWords.first,
        );
      }
    } catch (_) {}
  }

  List<String> _getFilteredSuggestions(String query) {
    return wordList.where((item) => item.toLowerCase().startsWith(query)).toList()..sort((a, b) {
      final itemA = a.toLowerCase();
      final itemB = b.toLowerCase();
      final startsWithA = itemA.startsWith(query);
      final startsWithB = itemB.startsWith(query);

      if (startsWithA && !startsWithB) return -1;
      if (!startsWithA && startsWithB) return 1;
      return itemA.compareTo(itemB);
    });
  }

  bool _hasPrefixMatch(String prefix) {
    return wordList.any((word) => word.startsWith(prefix.toLowerCase()));
  }

  void _showStopImportingMnemonicDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => CoconutPopup(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.15,
            ),
            title: t.alert.stop_importing_mnemonic.title,
            description: t.alert.stop_importing_mnemonic.description,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonColor: CoconutColors.gray900,
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.gray900,
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
    );
  }

  Future<void> _handleBackNavigation() async {
    await _hideKeyboard();
    if (_canPopWithoutDialog()) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    } else {
      _showStopImportingMnemonicDialog();
    }
  }

  bool _canPopWithoutDialog() {
    return _controllers.every((controller) => controller.text.isEmpty) &&
        _passphrase.isEmpty &&
        mounted;
  }

  void _handleNextButton() {
    final String secret = _buildMnemonicSecret();
    final String passphrase = _usePassphrase ? _passphrase : '';

    if (_walletProvider.isSeedDuplicated(secret, passphrase)) {
      CoconutToast.showToast(
        context: context,
        text: t.toast.mnemonic_already_added,
        isVisibleIcon: true,
      );
      return;
    }

    _walletCreationProvider.setSecretAndPassphrase(secret, passphrase);
    Navigator.pushNamed(context, AppRoutes.mnemonicConfirmation);
  }

  String _buildMnemonicSecret() {
    return _controllers
        .map((controller) => controller.text)
        .join(' ')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _shouldShowSuggestionWords(int lineIndex) {
    final groups = _buildLineGroups();
    if (lineIndex < 0 || lineIndex >= groups.length) return false;

    final group = groups[lineIndex];
    return group.any(
      (index) =>
          _focusNodes[index].hasFocus &&
          _controllers[index].text.length >= 2 &&
          _suggestionWords.isNotEmpty,
    );
  }

  List<List<int>> _buildLineGroups() {
    return [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [9, 10, 11],
      [12, 13, 14],
      [15, 16, 17],
      [18, 19, 20],
      [21, 22, 23],
    ];
  }

  void _setDropdownVisible(bool value) {
    if (_isDropdownVisible != value) {
      setState(() {
        _isDropdownVisible = value;
      });
    }
  }

  void _handleOnEditComplete() {
    _handleSpaceInput();
    _validateMnemonic(checkPrefixMatch: false);
  }

  void _clearAll() async {
    _clearAllControllers();
    _resetAllState();
    _clearPassphrase();
  }

  void _clearAllControllers() {
    for (var controller in _controllers) {
      controller.clearSuggestion();
      controller.text = '';
    }
  }

  void _resetAllState() {
    setState(() {
      _passphrase = '';
      _isMnemonicValid = null;
      _errorMessage = null;
      _suggestionWords = [];
      _isSuggestionWordsVisible = false;
      _isDropdownVisible = false;
      _invalidMnemonicIndexes = [];
    });
  }

  void _clearPassphrase() {
    _passphraseController.clear();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => CoconutPopup(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(dialogContext).size.width * 0.15,
            ),
            title: t.alert.erase_all_entered_mnemonic.title,
            centerDescription: true,
            description: t.alert.erase_all_entered_mnemonic.description,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            leftButtonColor: CoconutColors.gray900,
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.gray900,
            onTapLeft: () => Navigator.pop(context),
            onTapRight: () => _handleClearAllConfirm(),
          ),
    );
  }

  void _handleClearAllConfirm() {
    _clearAll();
    Navigator.pop(context);
    _preventFocusRestoration();
  }

  void _preventFocusRestoration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleGlobalTap,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            await _handleBackNavigation();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: CoconutColors.white,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  void _handleGlobalTap() {
    if (_isDropdownVisible) {
      setState(() {
        _isDropdownVisible = false;
      });
    }
    if (_focusNodes.any((node) => node.hasFocus) || _passphraseFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return CoconutAppBar.build(
      title: t.mnemonic_import_screen.title,
      context: context,
      onBackPressed: _handleBackNavigation,
      actionButtonList: [
        IconButton(
          onPressed: () {
            if (_controllers.any((controller) => controller.text.isNotEmpty)) {
              _showClearAllDialog();
            }
          },
          icon: SvgPicture.asset('assets/svg/eraser.svg', width: 18, height: 18),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              CoconutLayout.spacing_400h,
              _buildWordCountSelector(),
              Expanded(child: _buildMnemonicInputSection()),
            ],
          ),
          if (!_isSuggestionWordsVisible) _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildWordCountSelector() {
    return Align(
      alignment: Alignment.centerRight,
      child: CupertinoButton(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 18),
        minSize: 0,
        onPressed: () {
          setState(() {
            _isDropdownVisible = !_isDropdownVisible;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _wordCount == _maxWordCount
                  ? t.mnemonic_import_screen.words_24
                  : t.mnemonic_import_screen.words_12,
              style: CoconutTypography.body2_14,
            ),
            CoconutLayout.spacing_200w,
            SvgPicture.asset('assets/svg/arrow-down.svg'),
          ],
        ),
      ),
    );
  }

  Widget _buildMnemonicInputSection() {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildMnemonicLines(),
              CoconutLayout.spacing_700h,
              _buildPassphraseToggle(),
              if (_usePassphrase) _buildPassphraseTextField(),
              CoconutLayout.spacing_2000h,
            ],
          ),
        ),
        if (_isDropdownVisible) _buildDropdownMenu(),
      ],
    );
  }

  List<Widget> _buildMnemonicLines() {
    final lineCount = _wordCount == _maxWordCount ? 8 : 4;
    return [
      for (var i = 0; i < lineCount; i++) ...[
        _buildMnemonicTextFieldLine(i),
        _buildSuggestionSection(i),
        CoconutLayout.spacing_200h,
      ],
    ];
  }

  Widget _buildSuggestionSection(int lineIndex) {
    return Visibility(
      visible: _shouldShowSuggestionWords(lineIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoconutLayout.spacing_200h,
          Text(
            t.mnemonic_import_screen.recommended_words,
            style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.gray800),
          ),
          CoconutLayout.spacing_150h,
          _buildSuggestionButtons(),
        ],
      ),
    );
  }

  Widget _buildSuggestionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _suggestionWords.map((word) => _buildSuggestionButton(word)).toList(),
    );
  }

  Widget _buildSuggestionButton(String word) {
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray200,
      border: Border.all(color: CoconutColors.gray400),
      borderRadius: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(word),
      ),
      onPressed: () => _applySuggestionWord(word),
    );
  }

  Widget _buildBottomButton() {
    return FixedBottomButton(
      showGradient: true,
      text: t.next,
      onButtonClicked: _handleNextButton,
      isActive: _isNextButtonActive(),
      backgroundColor: CoconutColors.black,
      isVisibleAboveKeyboard: false,
      subWidget: _buildErrorSubWidget(),
    );
  }

  bool _isNextButtonActive() {
    return _controllers.any((controller) => controller.text.isNotEmpty) &&
        _isMnemonicValid == true &&
        (_usePassphrase ? _passphrase.isNotEmpty : true);
  }

  Widget? _buildErrorSubWidget() {
    if ((_isMnemonicValid == false &&
            _controllers.every((controller) => controller.text.isNotEmpty)) ||
        _errorMessage != null) {
      return Text(
        _errorMessage ?? t.errors.invalid_mnemonic_phrase,
        style: CoconutTypography.body2_14.setColor(CoconutColors.hotPink),
      );
    }
    return null;
  }

  Widget _buildMnemonicTextFieldLine(int line) {
    return Row(
      key: line == 0 ? _mnemonicInputLineGlobalKey : null,
      children: [
        for (int i = 0; i < _wordsPerLine; i++) ...[
          if (i > 0) CoconutLayout.spacing_200w,
          Expanded(child: _buildMnemonicField(line * _wordsPerLine + i)),
        ],
      ],
    );
  }

  Widget _buildMnemonicField(int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleMnemonicFieldTap(index),
      child: Container(
        decoration: _buildFieldDecoration(index),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              (index + 1).toString().padLeft(2, '0'),
              style: CoconutTypography.body2_14.setColor(CoconutColors.gray500),
            ),
            CoconutLayout.spacing_50h,
            _buildMnemonicTextField(index),
          ],
        ),
      ),
    );
  }

  void _handleMnemonicFieldTap(int index) {
    if (!_focusNodes[index].hasFocus) {
      _focusNodes[index].requestFocus();
    }
    _forceCursorToEnd(index);
    _setDropdownVisible(false);
  }

  BoxDecoration _buildFieldDecoration(int index) {
    return BoxDecoration(
      border: Border.all(
        color:
            _invalidMnemonicIndexes.contains(index)
                ? CoconutColors.hotPink.withValues(alpha: 0.7)
                : CoconutColors.black.withValues(alpha: 0.08),
      ),
      borderRadius: BorderRadius.circular(24),
      color: CoconutColors.white,
    );
  }

  Widget _buildMnemonicTextField(int index) {
    return CoconutTextField(
      textAlign: TextAlign.center,
      key: ValueKey('mnemonic_field_${_wordCount}_$index'),
      isVisibleBorder: false,
      focusNode: _focusNodes[index],
      controller: _controllers[index],
      enableInteractiveSelection: false,
      textInputFormatter: [FilteringTextInputFormatter.allow(RegExp(r'[a-z ]'))],
      onEditingComplete: _handleOnEditComplete,
      onChanged: (text) => _handleMnemonicTextChanged(text, index),
      maxLines: 1,
      activeColor: CoconutColors.black,
      errorText: _errorMessage ?? t.errors.invalid_mnemonic_phrase,
      padding: EdgeInsets.zero,
    );
  }

  void _handleMnemonicTextChanged(String text, int index) {
    if (_handleSpaceInputInText(text, index)) return;

    _convertToLowerCase(text, index);
    _queryCurrentWord();
    _scrollToSuggestionsIfNeeded(index);
  }

  bool _handleSpaceInputInText(String text, int index) {
    final sel = _controllers[index].selection;
    final int insertPos = sel.baseOffset - 1;

    if (insertPos >= 0 && insertPos < text.length && text[insertPos] == ' ') {
      if (_isSpaceInMiddleOfWord(text, insertPos)) {
        _removeSpaceAndMaintainCursor(text, index, insertPos);
        return true;
      }

      if (_controllers[index].hasSuggestion && _suggestionWords.isNotEmpty) {
        _confirmSuggestionAndMoveToNext(index);
        return true;
      } else {
        _removeSpaceAndMoveToNext(text, index, insertPos);
        return true;
      }
    }
    return false;
  }

  bool _isSpaceInMiddleOfWord(String text, int insertPos) {
    final bool isAtEnd = insertPos == text.length - 1;
    final bool nextIsSpace = !isAtEnd && text[insertPos + 1] == ' ';
    return !(isAtEnd || nextIsSpace);
  }

  void _removeSpaceAndMaintainCursor(String text, int index, int insertPos) {
    final String without = text.substring(0, insertPos) + text.substring(insertPos + 1);
    _controllers[index].value = _controllers[index].value.copyWith(
      text: without,
      selection: TextSelection.collapsed(offset: insertPos),
      composing: TextRange.empty,
    );
  }

  void _confirmSuggestionAndMoveToNext(int index) {
    _controllers[index].replaceWithSuggestion(_controllers[index].selection.baseOffset);
    setState(() {
      _isSuggestionWordsVisible = false;
      _suggestionWords = [];
      _controllers[index].clearSuggestion();
    });
    _focusNextField();
  }

  void _removeSpaceAndMoveToNext(String text, int index, int insertPos) {
    final String without = text.substring(0, insertPos) + text.substring(insertPos + 1);
    _controllers[index].value = _controllers[index].value.copyWith(
      text: without,
      selection: TextSelection.collapsed(offset: insertPos),
      composing: TextRange.empty,
    );
    _validateMnemonic();
    if (!_invalidMnemonicIndexes.contains(index)) {
      _focusNextField();
    }
  }

  void _convertToLowerCase(String text, int index) {
    if (text != text.toLowerCase()) {
      final sel = _controllers[index].selection;
      _controllers[index].value = _controllers[index].value.copyWith(
        text: text.toLowerCase(),
        selection: sel,
        composing: TextRange.empty,
      );
    }
  }

  void _scrollToSuggestionsIfNeeded(int index) {
    if (_shouldShowSuggestionWords(index ~/ _wordsPerLine)) {
      _scrollController.animateTo(
        _scrollOffsets[index ~/ _wordsPerLine],
        duration: _scrollDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPassphraseToggle() {
    return Selector<VisibilityProvider, bool>(
      selector: (context, provider) => provider.isPassphraseUseEnabled,
      builder: (context, isAdvancedUser, child) {
        if (isAdvancedUser) {
          return _buildPassphraseToggleRow();
        }
        return _buildAdvancedModeNotice();
      },
    );
  }

  Widget _buildPassphraseToggleRow() {
    return Row(
      children: [
        Text(t.mnemonic_import_screen.use_passphrase, style: CoconutTypography.body2_14_Bold),
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

  Widget _buildAdvancedModeNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CoconutColors.black.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Text(t.mnemonic_import_screen.need_advanced_mode),
          GestureDetector(
            onTap: () {
              MyBottomSheet.showBottomSheet_90(context: context, child: const SettingsScreen());
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
  }

  Widget _buildPassphraseTextField() {
    return Column(
      children: [
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
              suffix: _buildPassphraseVisibilityToggle(),
              maxLength: 100,
            ),
          ),
        ),
        _buildPassphraseLengthIndicator(),
      ],
    );
  }

  Widget _buildPassphraseVisibilityToggle() {
    return CupertinoButton(
      onPressed: () {
        setState(() {
          _passphraseObscured = !_passphraseObscured;
        });
      },
      child:
          _passphraseObscured
              ? const Icon(CupertinoIcons.eye_slash, color: CoconutColors.gray800, size: 18)
              : const Icon(CupertinoIcons.eye, color: CoconutColors.gray800, size: 18),
    );
  }

  Widget _buildPassphraseLengthIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Align(
        alignment: Alignment.topRight,
        child: Text(
          '(${_passphrase.length} / 100)',
          style: CoconutTypography.body3_12.setColor(
            _passphrase.length == 100
                ? CoconutColors.black.withValues(alpha: 0.7)
                : CoconutColors.black.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Positioned(
      top: 0,
      right: 16,
      child: Visibility(
        visible: _isDropdownVisible,
        child: CoconutPulldownMenu(
          shadowColor: CoconutColors.gray300,
          dividerColor: CoconutColors.gray200,
          entries: [
            CoconutPulldownMenuItem(title: t.mnemonic_import_screen.words_12),
            CoconutPulldownMenuItem(title: t.mnemonic_import_screen.words_24),
          ],
          dividerHeight: 1,
          onSelected: _handleWordCountSelection,
        ),
      ),
    );
  }

  void _handleWordCountSelection(int index, String selectedText) {
    setState(() {
      _isDropdownVisible = false;
      if (index == 0 && _wordCount != _defaultWordCount) {
        _changeWordCount(_defaultWordCount);
      } else if (index == 1 && _wordCount != _maxWordCount) {
        _changeWordCount(_maxWordCount);
      }
    });
  }
}

class WordSuggestableController extends TextEditingController {
  int cursorOffset;
  String suggestionWord;

  WordSuggestableController({this.cursorOffset = 0, this.suggestionWord = ''});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle defaultStyle = style ?? CoconutTypography.body2_14;
    final TextStyle suggestSuffixStyle = CoconutTypography.body2_14.copyWith(
      color: CoconutColors.gray400,
    );

    List<TextSpan> children = [];
    final String text = this.text;

    if (cursorOffset <= text.length) {
      // 커서 위치에서 현재 단어의 시작점 찾기
      int wordStart = cursorOffset;
      while (wordStart > 0 && text[wordStart - 1] != ' ') {
        wordStart--;
      }

      // 커서 위치에서 현재 단어의 끝점 찾기
      int wordEnd = cursorOffset;
      while (wordEnd < text.length && text[wordEnd] != ' ') {
        wordEnd++;
      }

      final String currentWord = text.substring(wordStart, wordEnd);

      // suggestionWord가 현재 단어로 시작하는지 확인
      if (suggestionWord.toLowerCase().startsWith(currentWord.toLowerCase()) &&
          currentWord.isNotEmpty) {
        // 커서 이전 텍스트
        if (wordStart > 0) {
          children.add(TextSpan(text: text.substring(0, wordStart)));
        }

        // 현재 입력된 부분 (기본 스타일)
        children.add(TextSpan(text: currentWord, style: defaultStyle));

        // 제안 단어의 나머지 부분 (회색 스타일)
        final String suggestionSuffix = suggestionWord.substring(currentWord.length);
        children.add(TextSpan(text: suggestionSuffix, style: suggestSuffixStyle));

        // 커서 이후 텍스트
        if (wordEnd < text.length) {
          children.add(TextSpan(text: text.substring(wordEnd)));
        }
      } else {
        // suggestionWord가 적용되지 않는 경우 원본 텍스트 그대로
        children.add(TextSpan(text: text));
      }
    } else {
      // suggestionWord가 없는 경우 원본 텍스트 그대로
      children.add(TextSpan(text: text));
    }

    return TextSpan(style: defaultStyle, children: children);
  }

  // 추천 단어 업데이트
  void updateSuggestion(int? offset, String? suggestion) {
    cursorOffset = offset ?? 0;
    suggestionWord = suggestion ?? '';
    notifyListeners();
  }

  // 스페이스바 입력 시 추천 단어로 교체
  void replaceWithSuggestion(int offset) {
    if (!hasSuggestion) return;

    // 추천 단어로 교체하고 공백 추가
    final newText = suggestionWord;

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    // 추천 단어 초기화
    clearSuggestion();
  }

  // 추천 단어 제거
  void clearSuggestion() {
    suggestionWord = '';
    notifyListeners();
  }

  // 추천 단어가 있는지 확인
  bool get hasSuggestion => suggestionWord.isNotEmpty;
}
