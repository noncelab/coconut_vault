import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
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
  String? _savedMfp;
  String? _recoveredMfp;
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
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: CustomLoadingOverlay(
        child: Builder(
          builder: (overlayContext) {
            return Scaffold(
              backgroundColor: CoconutColors.white,
              appBar: CoconutAppBar.build(context: context, title: t.verify_passphrase_screen.title, isBottom: true),
              body: SafeArea(
                child: Stack(
                  children: [
                    _buildContentArea(),
                    FixedBottomButton(
                      text: t.verify_passphrase_screen.start_verification,
                      isActive: _isButtonActive,
                      onButtonClicked: () => _verifyPassphrase(overlayContext),
                      showGradient: false,
                    ),
                  ],
                ),
              ),
            );
          },
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
        height: double.infinity,
        color: CoconutColors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                t.verify_passphrase_screen.description,
                style: CoconutTypography.body1_16_Bold,
                softWrap: true,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildPassphraseInput(),
              const SizedBox(height: 40),
              if (_isPassphraseVerified && !_isVerificationResultSuccess) _buildVerificationFailureCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassphraseInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                _passphraseObscured
                    ? t.passphrase_textfield.passphrase_visible
                    : t.passphrase_textfield.passphrase_hidden,
                style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.black),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _passphraseObscured = !_passphraseObscured),
              icon: Icon(
                _passphraseObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: CoconutColors.gray800,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
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
          placeholderText: t.verify_passphrase_screen.enter_passphrase,
          suffix: _buildClearButton(),
        ),
      ],
    );
  }

  Widget? _buildClearButton() {
    if (_controller.text.isEmpty) return null;

    return IconButton(
      highlightColor: CoconutColors.gray200,
      iconSize: 14,
      padding: EdgeInsets.zero,
      onPressed: _controller.clear,
      icon: SvgPicture.asset(
        'assets/svg/text-field-clear.svg',
        colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildVerificationFailureCard() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/svg/triangle-warning.svg', width: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.verify_passphrase_screen.result_title_failure,
                  style: CoconutTypography.heading4_18_Bold,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.verify_passphrase_screen.result_description_failure, style: CoconutTypography.body2_14),
          const SizedBox(height: 16),
          const Divider(color: CoconutColors.gray350, height: 1),
          const SizedBox(height: 16),
          _buildResultRow(
            title: t.verify_passphrase_screen.saved_mfp,
            value: _savedMfp ?? '',
            valueColor: CoconutColors.black,
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            title: t.verify_passphrase_screen.recovered_mfp,
            value: _recoveredMfp ?? '',
            valueColor: CoconutColors.hotPink,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required String title,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CoconutTypography.body2_14.setColor(CoconutColors.gray850)),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: CoconutTypography.body2_14_Number.copyWith(
                color: valueColor,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
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

  void _hideLoaderAndShowErrorPopup(BuildContext overlayContext, String title, String description) {
    if (!mounted) return;
    overlayContext.loaderOverlay.hide();

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

  Future<void> _verifyPassphrase(BuildContext overlayContext) async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);
      _closeKeyboard();

      final authResult = await _authenticateWithBiometricOrPin();
      if (!authResult || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));

      overlayContext.loaderOverlay.show();

      await Future.delayed(const Duration(milliseconds: 100));

      final walletProvider = context.read<WalletProvider>();
      Uint8List? mnemonic;

      try {
        mnemonic = await walletProvider.getSecret(widget.vaultId);
      } on UserCanceledAuthException catch (_) {
        _hideLoaderAndShowErrorPopup(
          overlayContext,
          t.alert.auth_canceled_when_decrypt.title,
          t.alert.auth_canceled_when_decrypt.description_passphrase_verify,
        );
        return;
      } catch (e) {
        _hideLoaderAndShowErrorPopup(overlayContext, t.passphrase_check_screen.alert.failed.title, e.toString());
        return;
      }

      final passphrase = utf8.encode(_controller.text);
      final vaultListItem = walletProvider.getVaultById(widget.vaultId);

      final result = await compute(WalletIsolates.verifyPassphrase, {
        'mnemonic': mnemonic,
        'passphrase': passphrase,
        'valutListItem': vaultListItem,
      });

      mnemonic.wipe();

      if (!mounted) {
        if (passphrase.isNotEmpty) passphrase.wipe();
        return;
      }

      if (result['success']) {
        vibrateLight();

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          overlayContext.loaderOverlay.hide();
          widget.onVerificationSuccess(passphrase);
        }
      } else {
        vibrateLightDouble();
        if (passphrase.isNotEmpty) passphrase.wipe();

        overlayContext.loaderOverlay.hide();

        setState(() {
          _previousInput = _controller.text;
          _isPassphraseVerified = true;
          _isVerificationResultSuccess = false;
          _savedMfp = result['savedMfp'];
          _recoveredMfp = result['recoveredMfp'];
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
