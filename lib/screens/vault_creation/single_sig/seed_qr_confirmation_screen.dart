import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SeedQrConfirmationScreen extends StatefulWidget {
  final Uint8List scannedData;

  const SeedQrConfirmationScreen({
    super.key,
    required this.scannedData, // 필수 매개변수로 설정
  });

  @override
  State<SeedQrConfirmationScreen> createState() => _SeedQrConfirmationScreenState();
}

class _SeedQrConfirmationScreenState extends State<SeedQrConfirmationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passphraseController = TextEditingController();
  final FocusNode _passphraseFocusNode = FocusNode();

  late WalletProvider _walletProvider;
  late WalletCreationProvider _walletCreationProvider;

  bool _usePassphrase = false;
  String _passphrase = '';
  bool _passphraseObscured = false;

  late VoidCallback _passphraseListener;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false)..resetAll();
  }

  @override
  void dispose() {
    _usePassphrase = false;
    _passphrase = '';

    _passphraseController.removeListener(_passphraseListener);
    _passphraseController.text = '';
    _passphraseController.dispose();

    _passphraseFocusNode.dispose();
    super.dispose();
  }

  void _initListeners() {
    _passphraseListener = () {
      if (mounted) {
        setState(() {
          _passphrase = _passphraseController.text;
        });
      }
    };

    _passphraseController.addListener(_passphraseListener);

    _passphraseFocusNode.addListener(() {
      if (_passphraseFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            const extraPadding = 250.0; // 추가 여백
            final targetScroll = _scrollController.position.maxScrollExtent + extraPadding;

            _scrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          backgroundColor: CoconutColors.white,
          context: context,
          title: t.seed_qr_confirmation_screen.title,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  color: CoconutColors.white,
                  child: Column(
                    children: [
                      MnemonicList(mnemonic: widget.scannedData),
                      CoconutLayout.spacing_600h,
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildPassphraseToggle()),
                      if (_usePassphrase)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildPassphraseTextField(),
                        ),
                      CoconutLayout.spacing_2500h,
                    ],
                  ),
                ),
              ),
              FixedBottomButton(
                text: t.next,
                isActive: _usePassphrase ? _passphrase.isNotEmpty : true,
                backgroundColor: CoconutColors.black,
                onButtonClicked: _handleNextButton,
                gradientPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 140),
              ),
              const WarningWidget(visible: true),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNextButton() {
    _passphraseFocusNode.unfocus();

    final secret = widget.scannedData;

    final passphrase = utf8.encode(_usePassphrase ? _passphrase : '');

    if (_walletProvider.isSeedDuplicated(secret, passphrase)) {
      CoconutToast.showToast(context: context, text: t.toast.mnemonic_already_added, isVisibleIcon: true);
      return;
    }

    _walletCreationProvider.setSecretAndPassphrase(Uint8List.fromList(secret), Uint8List.fromList(passphrase));
    Navigator.pushNamed(context, AppRoutes.vaultNameSetup);
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
      child: SizedBox(
        child: CoconutTextField(
          focusNode: _passphraseFocusNode,
          controller: _passphraseController,
          placeholderText: t.seed_qr_confirmation_screen.passphrase_text_field_placeholder,
          onChanged: (_) {},
          maxLines: 1,
          isLengthVisible: false,
          obscureText: _passphraseObscured,
          suffix: CupertinoButton(
            onPressed: () {
              setState(() {
                _passphraseObscured = !_passphraseObscured;
              });
            },
            child:
                _passphraseObscured
                    ? const Icon(CupertinoIcons.eye_slash, color: CoconutColors.gray800, size: 18)
                    : const Icon(CupertinoIcons.eye, color: CoconutColors.gray800, size: 18),
          ),
          maxLength: 100,
        ),
      ),
    );
  }
}
