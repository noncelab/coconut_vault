import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class PassphraseVerificationScreen extends StatefulWidget {
  const PassphraseVerificationScreen({super.key, required this.id});
  final int id;

  @override
  State<PassphraseVerificationScreen> createState() => _PassphraseVerificationScreenState();
}

class _PassphraseVerificationScreenState extends State<PassphraseVerificationScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  late final AnimationController _progressController;
  final ValueNotifier<String> _passphraseTextNotifier = ValueNotifier<String>('');

  bool _isPassphraseVerified = false;
  bool _isVerificationResultSuccess = false;
  String? _savedMfp;
  String? _recoveredMfp;
  String? _extendedPublicKey;
  bool _isSubmitting = false;
  String? _previousInput;
  // 언어 전환이 가능하려면 obscureText가 true여야 함.
  // 사용자 의도대로 입력할 수 있도록 기본값을 false로 설정함.
  bool _passphraseObscured = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
    _inputFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _progressController.dispose();
    _passphraseTextNotifier.dispose();
    super.dispose();
  }

  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: GestureDetector(
        onTap: _closeKeyboard,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(title: t.verify_passphrase_screen.title, context: context),
          body: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: CoconutLayout.defaultPadding),
                      child: Column(
                        children: [
                          CoconutLayout.spacing_600h,
                          Text(
                            t.verify_passphrase_screen.description,
                            style: CoconutTypography.body1_16_Bold,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                          CoconutLayout.spacing_600h,
                          _buildPassphraseInput(),
                          CoconutLayout.spacing_1000h,
                          if (_isPassphraseVerified) _buildVerificationResultCard(),
                          CoconutLayout.spacing_2500h,
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: _passphraseTextNotifier,
                    builder: (_, value, child) {
                      return FixedBottomButton(
                        onButtonClicked: verifyPassphrase,
                        text: t.verify_passphrase_screen.start_verification,
                        textColor: CoconutColors.white,
                        isActive:
                            _previousInput != _inputController.text &&
                            _inputController.text.isNotEmpty &&
                            !_isSubmitting,
                        backgroundColor: CoconutColors.black,
                        showGradient: true,
                        gradientPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 140),
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

  Future<bool> _authenticateWithBiometricOrPin() async {
    final authProvider = context.read<AuthProvider>();
    if (await authProvider.isBiometricsAuthValid()) {
      return true;
    }

    final pinCheckResult = await _showPinCheckScreen();
    if (pinCheckResult == true) return true;
    return false;
  }

  Future<void> verifyPassphrase() async {
    if (_isSubmitting) return;
    try {
      setState(() {
        _isSubmitting = true;
      });

      _closeKeyboard();

      final authResult = await _authenticateWithBiometricOrPin();
      if (!authResult) return;
      if (!mounted) return;
      CustomDialogs.showLoadingDialog(context, t.verify_passphrase_screen.loading_description);
      _isPassphraseVerified = false;
      final walletProvider = context.read<WalletProvider>();
      final mnemonic = await walletProvider.getSecret(widget.id);
      final passphrase = utf8.encode(_inputController.text);
      final vaultListItem = walletProvider.getVaultById(widget.id);

      final result = await compute(WalletIsolates.verifyPassphrase, {
        'mnemonic': mnemonic,
        'passphrase': passphrase,
        'valutListItem': vaultListItem,
      });

      mnemonic.wipe();
      if (passphrase.isNotEmpty) {
        passphrase.wipe();
      }

      _previousInput = _inputController.text;

      if (result['success']) {
        vibrateLight();
      } else {
        vibrateLightDouble();
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      _isPassphraseVerified = true;
      _isVerificationResultSuccess = result['success'];
      _savedMfp = result['savedMfp'];
      _recoveredMfp = result['recoveredMfp'];
      _extendedPublicKey = result['extendedPublicKey'] as String?;
      setState(() {});
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildPassphraseInput() {
    return ValueListenableBuilder<String>(
      valueListenable: _passphraseTextNotifier,
      builder: (context, value, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CoconutLayout.spacing_200w,
                Text(
                  _passphraseObscured
                      ? t.passphrase_textfield.passphrase_visible
                      : t.passphrase_textfield.passphrase_hidden,
                  style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.black),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _passphraseObscured = !_passphraseObscured),
                  icon: Icon(
                    _passphraseObscured ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    color: CoconutColors.gray800,
                    size: 20,
                  ),
                ),
              ],
            ),
            CoconutTextField(
              textAlign: TextAlign.left,
              backgroundColor: CoconutColors.white,
              cursorColor: CoconutColors.black,
              activeColor: CoconutColors.black,
              placeholderColor: CoconutColors.gray350,
              controller: _inputController,
              focusNode: _inputFocusNode,
              obscureText: _passphraseObscured,
              textInputType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onChanged: (text) {
                _passphraseTextNotifier.value = text;
              },
              isError: false,
              isLengthVisible: false,
              maxLength: 100,
              placeholderText: t.verify_passphrase_screen.enter_passphrase,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationResultCard() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                _isVerificationResultSuccess ? 'assets/svg/green-circle-check.svg' : 'assets/svg/triangle-warning.svg',
                width: 28,
              ),
              CoconutLayout.spacing_200w,
              Expanded(
                child: Text(
                  _isVerificationResultSuccess
                      ? t.verify_passphrase_screen.result_title_success
                      : t.verify_passphrase_screen.result_title_failure,
                  style: CoconutTypography.heading4_18_Bold,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          CoconutLayout.spacing_300h,
          Text(
            _isVerificationResultSuccess
                ? t.verify_passphrase_screen.result_description_success
                : t.verify_passphrase_screen.result_description_failure,
            style: CoconutTypography.body2_14,
          ),
          CoconutLayout.spacing_400h,
          const Divider(color: CoconutColors.gray350, height: 1),
          CoconutLayout.spacing_400h,
          Row(
            children: [
              Text(
                _isVerificationResultSuccess ? t.verify_passphrase_screen.mfp : t.verify_passphrase_screen.saved_mfp,
                style: CoconutTypography.body2_14.setColor(CoconutColors.gray850),
              ),
              CoconutLayout.spacing_200w,
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _savedMfp ?? '',
                    style: CoconutTypography.body2_14_NumberBold.setColor(CoconutColors.black),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          CoconutLayout.spacing_400h,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVerificationResultSuccess
                    ? t.verify_passphrase_screen.xpub
                    : t.verify_passphrase_screen.recovered_mfp,
                style: CoconutTypography.body2_14.setColor(CoconutColors.gray850),
              ),
              Expanded(
                child: Text(
                  textAlign: TextAlign.end,
                  _isVerificationResultSuccess ? _extendedPublicKey ?? '' : _recoveredMfp ?? '',
                  style: CoconutTypography.body2_14_Number.copyWith(
                    color: _isVerificationResultSuccess ? CoconutColors.black : CoconutColors.hotPink,
                    fontWeight: _isVerificationResultSuccess ? FontWeight.w400 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
