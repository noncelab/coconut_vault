import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomToast {
  static void showToast({
    required BuildContext context,
    required String text,
    int seconds = 5,
    bool visibleIcon = true,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
            top: 70,
            child: ToastWidget(
              text: text,
              visibleIcon: visibleIcon,
              onDismiss: () {
                overlayEntry.remove();
              },
              duration: seconds,
            )));

    Overlay.of(context).insert(overlayEntry);
  }

  static void showWarningToast({
    required BuildContext context,
    required String text,
    int seconds = 5,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
            top: 70,
            child: ToastWidget(
              text: text,
              visibleIcon: true,
              svgIconPath: 'assets/svg/tooltip/triangle-warning.svg',
              iconColor: CoconutColors.warningYellow,
              backgroundColor: CoconutColors.warningYellowBackground,
              onDismiss: () {
                overlayEntry.remove();
              },
              duration: seconds,
            )));

    Overlay.of(context).insert(overlayEntry);
  }
}

class ToastWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  final String text;
  final bool visibleIcon;
  final String svgIconPath;
  final Color backgroundColor;
  final Color iconColor;
  final int duration;

  const ToastWidget({
    super.key,
    required this.onDismiss,
    required this.text,
    required this.visibleIcon,
    required this.duration,
    this.svgIconPath = 'assets/svg/tooltip/info.svg',
    this.backgroundColor = CoconutColors.gray800,
    this.iconColor = CoconutColors.white,
  });

  @override
  State<StatefulWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(seconds: widget.duration), () {
      if (mounted) {
        _startFadeOut();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startFadeOut() {
    _controller.forward().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  // _controller.forward().then((_) => widget.onDismiss());
                  _startFadeOut();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    width: MediaQuery.of(context).size.width - 24,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: widget.backgroundColor,
                        border: Border.all(color: CoconutColors.borderGray, width: 0.5)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (widget.visibleIcon)
                        Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SvgPicture.asset(widget.svgIconPath,
                                width: 14,
                                colorFilter: ColorFilter.mode(widget.iconColor, BlendMode.srcIn))),
                      Expanded(
                        child: Text(
                          widget.text,
                          style: CoconutTypography.body3_12.merge(
                            const TextStyle(
                              color: CoconutColors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      )
                    ])),
              ))),
    );
  }
}
