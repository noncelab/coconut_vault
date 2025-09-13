import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_generation_screen.dart';
import 'package:coconut_vault/services/secure_memory.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicCoinflipConfirmationScreen extends StatefulWidget {
  const MnemonicCoinflipConfirmationScreen({super.key});

  @override
  State<MnemonicCoinflipConfirmationScreen> createState() =>
      _MnemonicCoinflipConfirmationScreenState();
}

class _MnemonicCoinflipConfirmationScreenState extends State<MnemonicCoinflipConfirmationScreen> {
  final ScrollController _scrollController = ScrollController();

  bool hasScrolledToBottom = false; // 니모닉 리스트를 끝까지 확인했는지 추적
  late Uint8List _mnemonic;
  late int _wordsCount;

  @override
  void initState() {
    super.initState();
    _mnemonic = Provider.of<WalletCreationProvider>(context, listen: false).secret;
    _wordsCount = utf8.decode(_mnemonic).split(' ').length;

    hasScrolledToBottom = utf8.decode(_mnemonic).split(' ').length == 12;
    // 스크롤 리스너 추가
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        // 스크롤이 끝에 가까워지면 확인 완료로 표시
        if (currentScroll >= maxScroll - 50) {
          if (!hasScrolledToBottom) {
            setState(() {
              hasScrolledToBottom = true;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    SecureMemory.wipe(_mnemonic);
    _wordsCount = 0;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.mnemonic_coin_flip_screen.title,
          context: context,
        ),
        body: SafeArea(
          child: MnemonicWords(
            wordsCount: _wordsCount,
            usePassphrase: false, // 이미 패프를 입력했기 때문에 false 고정
            onReset: () {},
            onNavigateToNext: () {
              Navigator.pushReplacementNamed(context, AppRoutes.mnemonicVerify);
            },
            from: MnemonicWordsFrom.coinflip,
          ),
        ),
      ),
    );
  }
}
