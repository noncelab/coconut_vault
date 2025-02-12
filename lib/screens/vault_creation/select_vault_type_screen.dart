import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:provider/provider.dart';

class SelectVaultTypeScreen extends StatefulWidget {
  const SelectVaultTypeScreen({super.key});

  @override
  State<SelectVaultTypeScreen> createState() => _SelectVaultTypeScreenState();
}

class _SelectVaultTypeScreenState extends State<SelectVaultTypeScreen> {
  String? nextPath;
  bool _nextButtonEnabled = true;
  bool _showLoading = false;
  late String guideText;
  List<String> options = ['/vault-creation-options', '/select-multisig-quorum'];
  late final WalletProvider model;

  @override
  void initState() {
    super.initState();
    model = Provider.of<WalletProvider>(context, listen: false);
    model.isVaultListLoadingNotifier.addListener(_loadingListener);
    guideText = '';
  }

  @override
  void dispose() {
    model.isVaultListLoadingNotifier.removeListener(_loadingListener);
    super.dispose();
  }

  void _loadingListener() {
    if (!mounted) return;

    if (!model.isVaultListLoadingNotifier.value) {
      if (_showLoading && nextPath != null) {
        setState(() {
          _nextButtonEnabled = true;
          _showLoading = false;
        });

        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onNextPressed() async {
    if (nextPath == options[0]) {
      // '일반 지갑' 선택 시
      Navigator.pushNamed(context, nextPath!);
    } else if (nextPath == options[1]) {
      // '다중 서명 지갑' 선택 시
      if (model.isVaultListLoading) {
        setState(() {
          _nextButtonEnabled = false;
          _showLoading = true;
        });
      } else if (model.vaultList.isNotEmpty) {
        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onTapSinglesigWallet() {
    setState(() {
      nextPath = options[0];
      guideText = t.select_vault_type_screen.singlesig;
      _nextButtonEnabled = true;
    });
  }

  void onTapMultisigWallet() {
    setState(() {
      nextPath = options[1];
      guideText = t.select_vault_type_screen.multisig;
      if (!model.isVaultListLoading && model.vaultList.isEmpty) {
        _nextButtonEnabled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: MyColors.white,
          appBar: CustomAppBar.buildWithNext(
            title: t.select_vault_type_screen.title,
            context: context,
            onNextPressed: () => onNextPressed(),
            isActive: _nextButtonEnabled,
          ),
          body: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                child: Column(
                  children: [
                    Text(guideText),
                    const SizedBox(height: 10),
                    Text(
                      (nextPath == options[1] &&
                              !model.isVaultListLoading &&
                              model.vaultList.isEmpty)
                          ? t.select_vault_type_screen.empty_key
                          : '',
                      style: Styles.caption.merge(
                        const TextStyle(
                          color: MyColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableButton(
                            text: t.singlesig_wallet,
                            onTap: onTapSinglesigWallet,
                            isPressed: nextPath == options[0],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableButton(
                            text: t.multisig_wallet,
                            onTap: onTapMultisigWallet,
                            isPressed: nextPath == options[1],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _showLoading,
                child: Container(
                  decoration:
                      const BoxDecoration(color: MyColors.transparentBlack_30),
                  child: Center(
                      child: MessageActivityIndicator(
                          message: t.select_vault_type_screen.loading_keys)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
