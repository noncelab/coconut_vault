import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VerifyPassphraseScreen extends StatefulWidget {
  const VerifyPassphraseScreen({super.key, required this.id});
  final int id;

  @override
  State<VerifyPassphraseScreen> createState() => _VerifyPassphraseScreenState();
}

class _VerifyPassphraseScreenState extends State<VerifyPassphraseScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  late final AnimationController _progressController;
  final ValueNotifier<String> _passphraseTextNotifier = ValueNotifier<String>('');

  bool _isPassphraseVerified = false;
  bool _isVerificationResultSuccess = false;
  String? _savedMfp;
  String? _recoveredMfp;
  String? _extendedPublicKey;

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
    // 기본: 전체 높이 - SafeArea top, bottom - toolbarHeight. 결과 데이터가 보이고 키보드가 열려 있는 경우 추가 height 조절(스크롤 가능 하도록)
    double appbarHeight = 56;
    final scrollViewHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        appbarHeight +
        ((_isPassphraseVerified && _inputFocusNode.hasFocus)
            ? FixedBottomButton.fixedBottomButtonDefaultHeight +
                FixedBottomButton.fixedBottomButtonDefaultBottomPadding +
                16
            : 0);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: GestureDetector(
        onTap: _closeKeyboard,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.verify_passphrase_screen.title,
              context: context,
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CoconutLayout.defaultPadding),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: scrollViewHeight,
                        child: Column(
                          children: [
                            CoconutLayout.spacing_600h,
                            Text(t.verify_passphrase_screen.description,
                                style: CoconutTypography.body1_16_Bold),
                            CoconutLayout.spacing_600h,
                            _buildPassphraseInput(),
                            CoconutLayout.spacing_1000h,
                            if (_isPassphraseVerified) _buildVerificationResultCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_inputFocusNode.hasFocus)
                    ValueListenableBuilder<String>(
                        valueListenable: _passphraseTextNotifier,
                        builder: (_, value, child) {
                          return FixedBottomButton(
                            onButtonClicked: verifyPassphrase,
                            text: t.verify_passphrase_screen.start_verification,
                            textColor: CoconutColors.white,
                            showGradient: false,
                            isActive: _inputController.text.isNotEmpty,
                            backgroundColor: CoconutColors.black,
                          );
                        }),
                ],
              ),
            )),
      ),
    );
  }

  Future<void> verifyPassphrase() async {
    _closeKeyboard();
    CustomDialogs.showLoadingDialog(context, t.verify_passphrase_screen.loading_description);

    final walletProvider = context.read<WalletProvider>();
    final result = await compute(WalletIsolates.verifyPassphrase, {
      'mnemonic': await walletProvider.getSecret(widget.id),
      'passphrase': _inputController.text,
      'valutListItem': walletProvider.getVaultById(widget.id)
    });

    if (!mounted) return;
    Navigator.of(context).pop();
    _isPassphraseVerified = true;
    _isVerificationResultSuccess = result['success'];
    _savedMfp = result['savedMfp'];
    _recoveredMfp = result['recoveredMfp'];
    _extendedPublicKey = result['extendedPublicKey'] as String?;
    setState(() {});
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
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onChanged: (text) {
              _passphraseTextNotifier.value = text;
            },
            isError: false,
            isLengthVisible: false,
            maxLength: 100,
            placeholderText: t.verify_passphrase_screen.enter_passphrase,
            suffix: _inputController.text.isNotEmpty
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
        });
  }

  Widget _buildVerificationResultCard() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  _isVerificationResultSuccess
                      ? 'assets/svg/green-circle-check.svg'
                      : 'assets/svg/triangle-warning.svg',
                  width: 28,
                ),
                CoconutLayout.spacing_200w,
                Text(
                    _isVerificationResultSuccess
                        ? t.verify_passphrase_screen.result_title_success
                        : t.verify_passphrase_screen.result_title_failure,
                    style: CoconutTypography.heading4_18_Bold),
              ],
            ),
            CoconutLayout.spacing_300h,
            Text(
                _isVerificationResultSuccess
                    ? t.verify_passphrase_screen.result_description_success
                    : t.verify_passphrase_screen.result_description_failure,
                style: CoconutTypography.body3_12),
            CoconutLayout.spacing_400h,
            const Divider(
              color: CoconutColors.gray350,
              height: 1,
            ),
            CoconutLayout.spacing_400h,
            Row(
              children: [
                Text(
                    _isVerificationResultSuccess
                        ? t.verify_passphrase_screen.mfp
                        : t.verify_passphrase_screen.saved_mfp,
                    style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.black)),
                const Spacer(),
                Text(_savedMfp ?? '',
                    style: CoconutTypography.body3_12.setColor(CoconutColors.black)),
              ],
            ),
            CoconutLayout.spacing_400h,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 90,
                    child: Text(
                        _isVerificationResultSuccess
                            ? t.verify_passphrase_screen.xpub
                            : t.verify_passphrase_screen.recovered_mfp,
                        style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.black))),
                if (_isVerificationResultSuccess)
                  Expanded(
                    child: Text(_extendedPublicKey ?? '',
                        style: CoconutTypography.body3_12.setColor(CoconutColors.black),
                        maxLines: 4),
                  ),
                if (!_isVerificationResultSuccess) ...[
                  const Spacer(),
                  Text(_recoveredMfp ?? '',
                      style: CoconutTypography.body3_12.setColor(CoconutColors.black)),
                ]
              ],
            ),
          ],
        ));
  }
}
