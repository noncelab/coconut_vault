import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen({
    super.key,
    required this.walletId,
  });

  final int walletId;

  @override
  State<MnemonicViewScreen> createState() => _MnemonicViewScreen();
}

class _MnemonicViewScreen extends State<MnemonicViewScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late WalletProvider _walletProvider;
  String? mnemonic;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletProvider.getSecret(widget.walletId).then((mnemonicValue) async {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          mnemonic = mnemonicValue;
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.view_mnemonic,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: CoconutColors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 48,
                      bottom: 24,
                    ),
                    child: Text(
                      t.mnemonic_view_screen.security_guide,
                      style: CoconutTypography.body1_16_Bold.setColor(
                        CoconutColors.warningText,
                      ),
                    ),
                  ),
                  MnemonicList(mnemonic: mnemonic ?? '', isLoading: mnemonic == null),
                  const SizedBox(height: 40),
                ],
              )),
        ),
      ),
    );
  }
}
