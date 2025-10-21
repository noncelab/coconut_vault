import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class PassphraseCheckScreen extends StatefulWidget {
  const PassphraseCheckScreen({super.key, required this.id});
  final int id;

  @override
  State<PassphraseCheckScreen> createState() => _PassphraseCheckScreen();
}

class _PassphraseCheckScreen extends State<PassphraseCheckScreen> {
  final ValueNotifier<String> _passphraseTextNotifier = ValueNotifier<String>('');
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passphraseTextNotifier.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: GestureDetector(
        onTap: _closeKeyboard,
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            context: context,
            title: t.passphrase_input_screen.title,
            backgroundColor: CoconutColors.white,
            isBottom: true,
          ),
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: _buildPassphraseInput())),
                  if (_showError) ...[
                    Text(
                      t.passphrase_input_screen.passphrase_error,
                      style: CoconutTypography.body3_12.setColor(CoconutColors.hotPink),
                    ),
                    CoconutLayout.spacing_300h,
                  ],
                  ValueListenableBuilder<String>(
                    valueListenable: _passphraseTextNotifier,
                    builder: (context, value, child) {
                      return CoconutButton(
                        onPressed: _handleSubmit,
                        isActive: _inputController.text.isNotEmpty && !_isSubmitting,
                        width: double.infinity,
                        height: 52,
                        text: t.confirm,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassphraseInput() {
    return ValueListenableBuilder<String>(
      valueListenable: _passphraseTextNotifier,
      builder: (context, value, child) {
        return CoconutTextField(
          textAlign: TextAlign.left,
          backgroundColor: CoconutColors.white,
          cursorColor: CoconutColors.black,
          activeColor: CoconutColors.black,
          placeholderColor: CoconutColors.gray350,
          controller: _inputController,
          focusNode: _inputFocusNode,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onChanged: (text) {
            _passphraseTextNotifier.value = text;
          },
          isError: false,
          isLengthVisible: false,
          maxLength: 100,
          placeholderText: t.passphrase_input_screen.enter_passphrase,
          suffix:
              _inputController.text.isNotEmpty
                  ? IconButton(
                    iconSize: 14,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _inputController.text = '';
                    },
                    icon: SvgPicture.asset(
                      'assets/svg/text-field-clear.svg',
                      colorFilter: const ColorFilter.mode(CoconutColors.gray900, BlendMode.srcIn),
                    ),
                  )
                  : null,
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      if (_showError) {
        _showError = false;
      }
    });

    _closeKeyboard();
    final isBiometricsAuthValid = await context.read<AuthProvider>().isBiometricsAuthValidToAvoidDoubleAuth();
    if (!isBiometricsAuthValid) {
      final pinCheckResult = await _showPinCheckScreen();
      if (pinCheckResult != true) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    if (!mounted) return;

    CustomDialogs.showLoadingDialog(context, t.verify_passphrase_screen.loading_description);
    Seed? result = await _verifyPassphrase(utf8.encode(_inputController.text));

    if (!mounted) return;
    Navigator.pop(context); // hide loading dialog

    if (result != null) {
      Navigator.pop(context, result);
    } else {
      setState(() {
        _showError = true;
      });
      Vibration.vibrate(duration: 100);
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<bool?> _showPinCheckScreen() async {
    return await MyBottomSheet.showBottomSheet_90<bool>(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onSuccess: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    );
  }

  Future<Seed?> _verifyPassphrase(Uint8List passphrase) async {
    final walletProvider = context.read<WalletProvider>();
    final secret = await walletProvider.getSecret(widget.id);
    final result = await compute(WalletIsolates.verifyPassphrase, {
      'mnemonic': secret,
      'passphrase': passphrase,
      'valutListItem': walletProvider.getVaultById(widget.id),
    });

    if (result['success'] == true) {
      return Seed.fromMnemonic(secret, passphrase: passphrase);
    }

    return null;
  }
}
