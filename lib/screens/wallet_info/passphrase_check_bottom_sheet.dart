import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class PassphraseVerificationBottomSheet extends StatefulWidget {
  final int vaultId;
  final Function(Uint8List) onVerificationSuccess;

  const PassphraseVerificationBottomSheet({super.key, required this.vaultId, required this.onVerificationSuccess});

  @override
  State<PassphraseVerificationBottomSheet> createState() => _PassphraseVerificationBottomSheetState();
}

class _PassphraseVerificationBottomSheetState extends State<PassphraseVerificationBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isPassphraseVerified = false;
  bool _isVerificationResultSuccess = false;
  bool _isSubmitting = false;
  String? _previousInput;
  bool _passphraseObscured = false;

  // Getter
  bool get _isInputValid => _controller.text.isNotEmpty && _previousInput != _controller.text;
  bool get _isButtonActive => _isInputValid && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: CoconutBottomSheet(
        useIntrinsicHeight: true,
        appBar: CoconutAppBar.build(context: context, title: t.verify_passphrase_screen.title, isBottom: true),
        bottomMargin: 20,
        body: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight : 0, left: 20, right: 20, top: 8),
          child: _buildContentArea(),
        ),
      ),
    );
  }

  // MARK: - UI Components

  Widget _buildContentArea() {
    return GestureDetector(
      onTap: _closeKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        color: CoconutColors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              t.bottom_sheet.verify_passphrase.description,
              style: CoconutTypography.body2_14_Bold,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildPassphraseInput(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CoconutButton(
                text: t.confirm,
                isActive: _isButtonActive,
                onPressed: () => _verifyPassphrase(),
                backgroundColor: CoconutColors.black,
                foregroundColor: CoconutColors.white,
                disabledBackgroundColor: CoconutColors.gray150,
                disabledForegroundColor: CoconutColors.gray350,
                height: 50.0,
                textStyle: CoconutTypography.body1_16_Bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassphraseInput() {
    return Column(
      children: [
        const SizedBox(height: 8),
        CoconutTextField(
          textAlign: TextAlign.left,
          backgroundColor: CoconutColors.white,
          cursorColor: CoconutColors.black,
          activeColor: CoconutColors.black,
          placeholderColor: CoconutColors.gray400,
          controller: _controller,
          focusNode: _focusNode,
          obscureText: _passphraseObscured,
          textInputType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onChanged: (_) {},
          isError: _isPassphraseVerified && !_isVerificationResultSuccess,
          isLengthVisible: false,
          maxLength: 100,
          placeholderText: t.bottom_sheet.verify_passphrase.placeholder,
          suffix: _buildSuffixButtons(),
          errorText: t.bottom_sheet.verify_passphrase.passphrase_error_message,
        ),
      ],
    );
  }

  Widget _buildSuffixButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildPrivacyButton(), const SizedBox(width: 4), _buildClearButton(), const SizedBox(width: 8)],
    );
  }

  Widget _buildPrivacyButton() {
    return GestureDetector(
      onTap: () => setState(() => _passphraseObscured = !_passphraseObscured),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Icon(
          _passphraseObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
          color: CoconutColors.gray800,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _controller.clear,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: SvgPicture.asset(
          'assets/svg/text-field-clear.svg',
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            _isPassphraseVerified && !_isVerificationResultSuccess ? CoconutColors.hotPink : CoconutColors.gray900,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // MARK: - Logic & Actions

  Future<bool?> _showPinCheckScreen() async {
    return await MyBottomSheet.showBottomSheet_90<bool>(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
  }

  Future<bool> _authenticateWithBiometricOrPin() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()) return true;

    final pinCheckResult = await _showPinCheckScreen();
    return pinCheckResult == true;
  }

  void _hideLoaderAndShowErrorPopup(String title, String description) {
    if (!mounted) return;
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder:
          (ctx) => CoconutPopup(
            languageCode: ctx.read<VisibilityProvider>().language,
            title: title,
            description: description,
            onTapRight: () => Navigator.pop(ctx),
          ),
    );
    Vibration.vibrate(duration: 100);
  }

  Future<void> _verifyPassphrase() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);
      _closeKeyboard();

      final authResult = await _authenticateWithBiometricOrPin();
      if (!authResult || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 200));

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: CoconutColors.black.withValues(alpha: 0.2),
        builder: (context) => const PopScope(canPop: false, child: Center(child: CoconutCircularIndicator())),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final walletProvider = context.read<WalletProvider>();
      Uint8List? mnemonic;

      try {
        mnemonic = await walletProvider.getSecret(widget.vaultId);
      } on UserCanceledAuthException catch (_) {
        _hideLoaderAndShowErrorPopup(
          t.alert.auth_canceled_when_decrypt.title,
          t.alert.auth_canceled_when_decrypt.description_passphrase_verify,
        );
        return;
      } catch (e) {
        _hideLoaderAndShowErrorPopup(t.passphrase_check_screen.alert.failed.title, e.toString());
        return;
      }

      final passphrase = utf8.encode(_controller.text);
      final vaultListItem = walletProvider.getVaultById(widget.vaultId);

      final result = await compute(WalletIsolates.verifyPassphrase, {
        'mnemonic': mnemonic,
        'passphrase': passphrase,
        'vaultListItem': vaultListItem,
      });

      mnemonic.wipe();

      if (!mounted) {
        if (passphrase.isNotEmpty) passphrase.wipe();
        return;
      }

      if (result['success']) {
        vibrateLight();

        await Future.delayed(const Duration(milliseconds: 150));

        if (mounted) {
          Navigator.of(context).pop();
          widget.onVerificationSuccess(passphrase);
        }
      } else {
        vibrateLightDouble();
        if (passphrase.isNotEmpty) passphrase.wipe();

        Navigator.of(context).pop();

        setState(() {
          _previousInput = _controller.text;
          _isPassphraseVerified = true;
          _isVerificationResultSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
