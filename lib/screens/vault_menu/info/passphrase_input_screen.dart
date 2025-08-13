import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class PassphraseInputScreen extends StatefulWidget {
  const PassphraseInputScreen({super.key, required this.id});
  final int id;

  @override
  State<PassphraseInputScreen> createState() => _PassphraseInputScreen();
}

class _PassphraseInputScreen extends State<PassphraseInputScreen> {
  final ValueNotifier<String> _passphraseTextNotifier = ValueNotifier<String>('');
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showError = false;

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
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildPassphraseInput(),
                    ),
                  ),
                  if (_showError) ...[
                    Text(t.passphrase_input_screen.passphrase_error,
                        style: CoconutTypography.body3_12.setColor(CoconutColors.hotPink)),
                    CoconutLayout.spacing_300h,
                  ],
                  ValueListenableBuilder<String>(
                      valueListenable: _passphraseTextNotifier,
                      builder: (context, value, child) {
                        return CoconutButton(
                          onPressed: verifyPassphrase,
                          isActive: _inputController.text.isNotEmpty,
                          width: double.infinity,
                          height: 52,
                          text: t.confirm,
                        );
                      }),
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
    bool success = result['success'];
    _showError = !success;
    setState(() {});
    if (success) {
      Navigator.pop(context, {'success': success, 'passphrase': _inputController.text});
    }
  }
}
