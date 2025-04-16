import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:provider/provider.dart';

class VaultTypeSelectionScreen extends StatefulWidget {
  const VaultTypeSelectionScreen({super.key});

  @override
  State<VaultTypeSelectionScreen> createState() => _VaultTypeSelectionScreenState();
}

class _VaultTypeSelectionScreenState extends State<VaultTypeSelectionScreen> {
  String? nextPath;
  bool _nextButtonEnabled = true;
  bool _showLoading = false;
  late String guideText;
  List<String> options = [AppRoutes.vaultCreationOptions, AppRoutes.multisigQuorumSelection];
  late final WalletProvider _walletProvider;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_loadingListener);
    guideText = '';
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_loadingListener);
    super.dispose();
  }

  void _loadingListener() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
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
      if (_walletProvider.isVaultListLoading) {
        setState(() {
          _nextButtonEnabled = false;
          _showLoading = true;
        });
      } else if (_walletProvider.vaultList.isNotEmpty) {
        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onTapSinglesigWallet() {
    setState(() {
      nextPath = options[0];
      guideText = t.select_vault_type_screen.single_sig;
      _nextButtonEnabled = true;
    });
  }

  void onTapMultisigWallet() {
    setState(() {
      nextPath = options[1];
      guideText = t.select_vault_type_screen.multisig;
      if (!_walletProvider.isVaultListLoading && _walletProvider.vaultList.isEmpty) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
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
                          color: MyColors.warningText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableButton(
                            text: t.single_sig_wallet,
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
                  decoration: const BoxDecoration(color: MyColors.transparentBlack_30),
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
