import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
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
  Uint8List _mnemonic = Uint8List(0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _setMnemonic();
  }

  Future<void> _setMnemonic() async {
    try {
      _mnemonic = await _walletProvider.getSecret(widget.walletId);
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (context) => CoconutPopup(
                title: 'View Mnemonic',
                description: 'Failed to load mnemonic\n${e.toString()}',
                onTapRight: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }));
      });
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mnemonic.wipe();
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
        child: Stack(
          children: [
            SingleChildScrollView(
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
                      MnemonicList(mnemonic: _mnemonic, isLoading: _isLoading),
                      const SizedBox(height: 40),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
