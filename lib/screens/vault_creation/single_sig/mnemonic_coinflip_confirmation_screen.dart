import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicCoinflipConfirmationScreen extends StatefulWidget {
  const MnemonicCoinflipConfirmationScreen({super.key});

  @override
  State<MnemonicCoinflipConfirmationScreen> createState() =>
      _MnemonicCoinflipConfirmationScreenState();
}

class _MnemonicCoinflipConfirmationScreenState extends State<MnemonicCoinflipConfirmationScreen> {
  late WalletCreationProvider _walletCreationProvider;
  final ScrollController _scrollController = ScrollController();

  bool hasScrolledToBottom = false; // 니모닉 리스트를 끝까지 확인했는지 추적

  @override
  void initState() {
    super.initState();
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

    hasScrolledToBottom = _walletCreationProvider.secret!.split(' ').length == 12;

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
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                child: Column(
                  children: [
                    Text(
                      t.mnemonic_generate_screen.backup_guide,
                      textAlign: TextAlign.center,
                      style: CoconutTypography.body1_16_Bold.setColor(
                        CoconutColors.warningText,
                      ),
                    ),
                    CoconutLayout.spacing_400h,
                    _buildGeneratedMnemonicList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            FixedBottomButton(
              isActive: true,
              onButtonClicked: () {
                if (hasScrolledToBottom) {
                  Navigator.pushReplacementNamed(context, AppRoutes.mnemonicVerify);
                } else {
                  // 아직 끝까지 확인하지 않았다면 스크롤을 하단으로 이동
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              backgroundColor: CoconutColors.black,
              text: hasScrolledToBottom ? t.complete : t.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedMnemonicList() {
    bool gridviewColumnFlag = false;

    return Padding(
      padding: const EdgeInsets.only(
        left: 40.0,
        right: 40.0,
        top: 16,
        bottom: 120,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2열로 배치
          childAspectRatio: 2.5, // 각 아이템의 가로:세로 = 2.5:1
          crossAxisSpacing: 12, // 열 간격
          mainAxisSpacing: 8, // 행 간격
        ),
        itemCount: _walletCreationProvider.secret!.split(' ').length,
        itemBuilder: (BuildContext context, int index) {
          if (index % 2 == 0) {
            gridviewColumnFlag = !gridviewColumnFlag;
          }

          return Container(
            padding: const EdgeInsets.only(left: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: CoconutColors.black.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: CoconutTypography.body3_12_Number.setColor(
                    CoconutColors.gray500,
                  ),
                ),
                CoconutLayout.spacing_300w,
                Expanded(
                  child: Text(
                    _walletCreationProvider.secret!.split(' ')[index],
                    style: CoconutTypography.body2_14,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
