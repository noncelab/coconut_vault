import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
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
  late AnimationController _waveAnimationController;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // 파도타기 애니메이션 컨트롤러 초기화
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityAnimations = List.generate(12, (index) {
      final delay = (index / 2).floor() * 0.1;
      return Tween<double>(
        begin: 0.3,
        end: 0.3,
      ).animate(
        CurvedAnimation(
          parent: _waveAnimationController,
          curve: Interval(
            delay.clamp(0.0, 1.0),
            (delay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    // 파도타기 애니메이션 시작
    _waveAnimationController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletProvider.getSecret(widget.walletId).then((mnemonicValue) async {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          mnemonic = mnemonicValue;
        });
        // mnemonic이 로드되면 애니메이션 중지
        _waveAnimationController.stop();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _waveAnimationController.dispose();
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
        isBottom: true,
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
                      t.mnemonic_generate_screen.backup_guide,
                      style: CoconutTypography.body1_16_Bold.setColor(
                        CoconutColors.warningText,
                      ),
                    ),
                  ),
                  buildGeneratedMnemonicList(),
                  const SizedBox(height: 40),
                ],
              )),
        ),
      ),
    );
  }

  Widget buildGeneratedMnemonicList() {
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
        itemCount: mnemonic?.split(' ').length ?? 12,
        itemBuilder: (BuildContext context, int index) {
          if (index % 2 == 0) {
            gridviewColumnFlag = !gridviewColumnFlag;
          }

          // mnemonic이 null일 때 파도타기 애니메이션 적용
          if (mnemonic == null && index < _opacityAnimations.length) {
            return AnimatedBuilder(
              animation: _waveAnimationController,
              builder: (context, child) {
                final delay = (index / 2).floor() * 0.1;
                final progress = _waveAnimationController.value;
                final waveProgress = (progress - delay) % 1.0;

                // 파도 효과: 0.6 -> 1.0 -> 0.6으로 부드럽게 변화
                double opacity = 0.3;
                if (waveProgress >= 0 && waveProgress <= 0.3) {
                  final waveValue = waveProgress / 0.3;
                  opacity = 0.3 + (0.7 * waveValue);
                } else if (waveProgress > 0.3 && waveProgress <= 0.6) {
                  final waveValue = (waveProgress - 0.3) / 0.3;
                  opacity = 1.0 - (0.7 * waveValue);
                }

                return Opacity(
                  opacity: opacity,
                  child: Container(
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
                        const Expanded(
                          child: Text(
                            '',
                            style: CoconutTypography.body2_14,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // mnemonic이 로드된 후 정상 표시
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
                    mnemonic?.split(' ')[index] ?? '',
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
