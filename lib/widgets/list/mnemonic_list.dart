import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class MnemonicList extends StatefulWidget {
  const MnemonicList({super.key, required this.mnemonic, this.isLoading = false});

  final String mnemonic;
  final bool isLoading;

  @override
  State<MnemonicList> createState() => _MnemonicListState();
}

class _MnemonicListState extends State<MnemonicList> with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();

    // 파도타기 애니메이션 컨트롤러 초기화
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityAnimations = List.generate(24, (index) {
      final delay = (index / 2).floor() * 0.1;
      return Tween<double>(begin: 0.3, end: 0.3).animate(
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

    // 로딩 중일 때만 애니메이션 시작
    if (widget.isLoading) {
      _waveAnimationController.repeat();
    }
  }

  @override
  void didUpdateWidget(MnemonicList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 로딩 상태가 변경되면 애니메이션 제어
    if (widget.isLoading && !oldWidget.isLoading) {
      _waveAnimationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _waveAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');
    final itemCount = widget.isLoading ? 12 : words.length;

    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2열로 배치
          childAspectRatio: 2.5, // 각 아이템의 가로:세로 = 2.5:1
          crossAxisSpacing: 12, // 열 간격
          mainAxisSpacing: 8, // 행 간격
        ),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          // 로딩 중일 때 파도타기 애니메이션 적용
          if (widget.isLoading && index < _opacityAnimations.length) {
            return AnimatedBuilder(
              animation: _waveAnimationController,
              builder: (context, child) {
                final delay = (index / 2).floor() * 0.1;
                final progress = _waveAnimationController.value;
                final waveProgress = (progress - delay) % 1.0;

                // 파도 효과: 0.3 -> 1.0 -> 0.3으로 부드럽게 변화
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
                      border: Border.all(color: CoconutColors.black.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (index + 1).toString().padLeft(2, '0'),
                          style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray500),
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

          // 로딩 완료 후 정상 표시
          return Container(
            padding: const EdgeInsets.only(left: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: CoconutColors.black.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray500),
                ),
                CoconutLayout.spacing_300w,
                Expanded(
                  child: Text(
                    words[index],
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
