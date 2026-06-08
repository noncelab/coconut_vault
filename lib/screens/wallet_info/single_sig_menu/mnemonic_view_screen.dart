import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/seed_invalidated_exception.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen({
    super.key,
    this.walletId,
    this.initialMnemonic,
    this.autoLoadMnemonic = true,
    this.isEmbedded = false,
    this.buildPassphraseToggle = false,
    this.requirePassphraseConfirmation = false,
    this.onAuthCanceled,
    this.onNextButtonPressed,
  }) : assert(walletId != null || initialMnemonic != null);

  final int? walletId;
  final Uint8List? initialMnemonic;
  final bool autoLoadMnemonic;
  final bool isEmbedded;
  final VoidCallback? onAuthCanceled;
  final VoidCallback? onNextButtonPressed;
  final bool buildPassphraseToggle;
  final bool requirePassphraseConfirmation;

  @override
  State<MnemonicViewScreen> createState() => MnemonicViewScreenState();
}

class MnemonicViewScreenState extends State<MnemonicViewScreen> with TickerProviderStateMixin {
  static const Duration _passphraseScrollDelay = Duration(milliseconds: 500);
  static const Duration _scrollDuration = Duration(milliseconds: 300);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _passphraseConfirmController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  final FocusNode _passphraseConfirmFocusNode = FocusNode();
  late WalletProvider _walletProvider;
  Uint8List _mnemonic = Uint8List(0);
  bool _isLoading = true;
  bool _usePassphrase = false;
  String _passphrase = '';
  String _passphraseConfirm = '';
  bool _passphraseObscured = false;

  Uint8List get mnemonic => Uint8List.fromList(_mnemonic);
  String get passphrase => _usePassphrase ? _passphrase : '';
  bool get _isPassphraseInputValid {
    if (!_usePassphrase) {
      return true;
    }

    if (_passphrase.isEmpty) {
      return false;
    }

    if (!widget.requirePassphraseConfirmation) {
      return true;
    }

    return _passphraseConfirm.isNotEmpty && _passphrase == _passphraseConfirm;
  }

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final initialMnemonic = widget.initialMnemonic;
    if (initialMnemonic != null) {
      _mnemonic = Uint8List.fromList(initialMnemonic);
      _isLoading = false;
    }
    _passphraseController.addListener(_handlePassphraseChanged);
    _passphraseConfirmController.addListener(_handlePassphraseConfirmChanged);
    _passphraseFocusNode.addListener(_handlePassphraseFocusChanged);
    _passphraseConfirmFocusNode.addListener(_handlePassphraseFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.autoLoadMnemonic || initialMnemonic != null) {
        return;
      }
      // getSecret하는 동안 생체인증 요청됨 - lifecycle event 호출됨
      setMnemonic();
    });
  }

  void _handlePassphraseChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _passphrase = _passphraseController.text;
    });
  }

  void _handlePassphraseConfirmChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _passphraseConfirm = _passphraseConfirmController.text;
    });
  }

  void _handlePassphraseFocusChanged() async {
    if (!_passphraseFocusNode.hasFocus && !_passphraseConfirmFocusNode.hasFocus) {
      return;
    }

    await Future<void>.delayed(_passphraseScrollDelay);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: _scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  void _unfocusPassphraseFields() {
    if (_passphraseFocusNode.hasFocus) {
      _passphraseFocusNode.unfocus();
    }

    if (_passphraseConfirmFocusNode.hasFocus) {
      _passphraseConfirmFocusNode.unfocus();
    }
  }

  Future<void> setMnemonic() async {
    final walletId = widget.walletId;
    if (walletId == null) {
      return;
    }

    try {
      _mnemonic = await _walletProvider.getSecret(walletId);
    } on UserCanceledAuthException catch (_) {
      if (!mounted) return;
      if (widget.isEmbedded) {
        widget.onAuthCanceled?.call();
        return;
      }
      showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
              languageCode: context.read<VisibilityProvider>().language,
              title: t.alert.auth_canceled_when_decrypt.title,
              description: t.alert.auth_canceled_when_decrypt.description_view_mnemonic,
              onTapRight: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
      );
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is SeedInvalidatedException) {
        message = e.message;
      }
      showDialog(
        context: context,
        builder:
            (context) => CoconutPopup(
              languageCode: context.read<VisibilityProvider>().language,
              title: t.mnemonic_view_screen.alert.failed_get_secret.title,
              description: message,
              onTapRight: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
      );
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _mnemonic.wipe();
    _passphrase = '';
    _passphraseConfirm = '';
    _passphraseController.removeListener(_handlePassphraseChanged);
    _passphraseController.text = '';
    _passphraseController.dispose();
    _passphraseConfirmController.removeListener(_handlePassphraseConfirmChanged);
    _passphraseConfirmController.text = '';
    _passphraseConfirmController.dispose();
    _passphraseFocusNode.removeListener(_handlePassphraseFocusChanged);
    _passphraseFocusNode.dispose();
    _passphraseConfirmFocusNode.removeListener(_handlePassphraseFocusChanged);
    _passphraseConfirmFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 앱바·상태바 제외한 본문 높이 기준 10%를 상단 여백으로 고정
          final bodyHeight = constraints.maxHeight;
          final topPadding = bodyHeight * 0.1;
          final contentMinHeight = bodyHeight - topPadding;

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _unfocusPassphraseFields,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: contentMinHeight),
                      child: Column(
                        children: [
                          MnemonicList(mnemonic: _mnemonic, isLoading: _isLoading),
                          if (context.select<VisibilityProvider, bool>(
                            (provider) => provider.isPassphraseUseEnabled,
                          )) ...[
                            CoconutLayout.spacing_600h,
                            if (widget.buildPassphraseToggle) ...[
                              // buildPassphraseToggle은 provider.isPassphraseUseEnabled값보다 우선순위가 낮습니다: 화면 표시 용
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: _buildPassphraseToggle(),
                              ),
                              if (_usePassphrase)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: _buildPassphraseTextField(),
                                ),
                              CoconutLayout.spacing_2500h,
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onNextButtonPressed != null) ...[
                FixedBottomButton(
                  text: t.next,
                  isActive: _isPassphraseInputValid,
                  backgroundColor: CoconutColors.black,
                  onButtonClicked: () {
                    widget.onNextButtonPressed?.call();
                  },
                ),
              ],
              const WarningWidget(visible: true),
            ],
          );
        },
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(context: context, title: t.view_mnemonic, backgroundColor: CoconutColors.white),
      body: body,
    );
  }

  Widget _buildPassphraseToggle() {
    return Row(
      children: [
        CoconutLayout.spacing_200w,
        Text(t.seed_qr_confirmation_screen.passphrase_toggle, style: CoconutTypography.body2_14_Bold),
        const Spacer(),
        CupertinoSwitch(
          value: _usePassphrase,
          activeTrackColor: CoconutColors.gray800,
          onChanged: (value) {
            setState(() {
              _usePassphrase = value;
              if (!value) {
                _passphraseController.clear();
                _passphraseConfirmController.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildPassphraseTextField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        children: [
          _buildPassphraseInputField(
            focusNode: _passphraseFocusNode,
            controller: _passphraseController,
            placeholderText: t.seed_qr_confirmation_screen.passphrase_text_field_placeholder,
          ),
          if (widget.requirePassphraseConfirmation)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildPassphraseInputField(
                focusNode: _passphraseConfirmFocusNode,
                controller: _passphraseConfirmController,
                placeholderText: t.mnemonic_generate_screen.passphrase_confirm_guide,
                isError: _passphraseConfirm.isNotEmpty && _passphrase != _passphraseConfirm,
                errorText: t.mnemonic_generate_screen.passphrase_not_matched,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassphraseInputField({
    required FocusNode focusNode,
    required TextEditingController controller,
    required String placeholderText,
    bool isError = false,
    String? errorText,
  }) {
    return CoconutTextField(
      focusNode: focusNode,
      controller: controller,
      placeholderText: placeholderText,
      padding: const EdgeInsets.all(16.0),
      onChanged: (_) {},
      maxLines: 1,
      isLengthVisible: false,
      obscureText: _passphraseObscured,
      isError: isError,
      errorText: errorText,
      suffix: SizedBox(
        width: 44,
        height: 44,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => setState(() => _passphraseObscured = !_passphraseObscured),
          child: Icon(
            _passphraseObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: CoconutColors.gray800,
            size: 18,
          ),
        ),
      ),
    );
  }
}
