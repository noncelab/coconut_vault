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
    required this.walletId,
    this.autoLoadMnemonic = true,
    this.isEmbedded = false,
    this.onAuthCanceled,
    this.onNextButtonPressed,
  });

  final int walletId;
  final bool autoLoadMnemonic;
  final bool isEmbedded;
  final VoidCallback? onAuthCanceled;
  final VoidCallback? onNextButtonPressed;

  @override
  State<MnemonicViewScreen> createState() => MnemonicViewScreenState();
}

class MnemonicViewScreenState extends State<MnemonicViewScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();
  late WalletProvider _walletProvider;
  Uint8List _mnemonic = Uint8List(0);
  bool _isLoading = true;
  bool _usePassphrase = false;
  String _passphrase = '';
  bool _passphraseObscured = false;

  String get passphrase => _usePassphrase ? _passphrase : '';

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _passphraseController.addListener(_handlePassphraseChanged);
    _passphraseFocusNode.addListener(_handlePassphraseFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.autoLoadMnemonic) {
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

  void _handlePassphraseFocusChanged() {
    if (!_passphraseFocusNode.hasFocus) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> setMnemonic() async {
    try {
      _mnemonic = await _walletProvider.getSecret(widget.walletId);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mnemonic.wipe();
    _passphrase = '';
    _passphraseController.removeListener(_handlePassphraseChanged);
    _passphraseController.text = '';
    _passphraseController.dispose();
    _passphraseFocusNode.removeListener(_handlePassphraseFocusChanged);
    _passphraseFocusNode.dispose();
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
              SingleChildScrollView(
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
                    ),
                  ),
                ),
              ),
              if (widget.onNextButtonPressed != null) ...[
                FixedBottomButton(
                  text: t.next,
                  isActive: _usePassphrase ? _passphrase.isNotEmpty : true,
                  backgroundColor: CoconutColors.black,
                  onButtonClicked: () {
                    /// TODO: Step2
                    debugPrint('step2 이동');
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
            });
          },
        ),
      ],
    );
  }

  Widget _buildPassphraseTextField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: CoconutTextField(
        focusNode: _passphraseFocusNode,
        controller: _passphraseController,
        placeholderText: t.seed_qr_confirmation_screen.passphrase_text_field_placeholder,
        padding: const EdgeInsets.all(16.0),
        onChanged: (_) {},
        maxLines: 1,
        isLengthVisible: false,
        obscureText: _passphraseObscured,
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
      ),
    );
  }
}
