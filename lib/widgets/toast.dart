import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/styles.dart';
import 'package:flutter/material.dart';

class ToastWidget extends StatefulWidget {
  final VoidCallback onClose;
  final String message;

  const ToastWidget({super.key, required this.onClose, this.message = ''});

  @override
  ToastWidgetState createState() => ToastWidgetState();
}

class ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  void hide(VoidCallback onAnimationEnd) {
    _controller.reverse().then((value) {
      onAnimationEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        widget.message.isEmpty ? t.toast.clipboard_copied : widget.message;

    return SlideTransition(
      position: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: MyColors.transparentBlack_30,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayMessage,
              style: Styles.body2Bold
                  .merge(const TextStyle(color: MyColors.white)),
            ),
            const Icon(
              Icons.check,
              color: MyColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
