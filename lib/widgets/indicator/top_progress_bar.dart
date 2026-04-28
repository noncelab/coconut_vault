import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/cupertino.dart';

class TopProgressBar extends StatelessWidget {
  final bool visible;
  final int total;
  final int current;

  const TopProgressBar({super.key, required this.visible, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Visibility(
        visible: visible,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
        child: Container(
          padding: const EdgeInsets.only(bottom: 16),
          child: Stack(
            children: [
              ClipRRect(child: Container(height: 6, color: CoconutColors.black.withValues(alpha: 0.06))),
              ClipRRect(
                borderRadius:
                    current / total == 1
                        ? BorderRadius.zero
                        : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * (current / total),
                  color: CoconutColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
