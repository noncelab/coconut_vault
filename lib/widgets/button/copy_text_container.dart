import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CopyTextContainer extends StatefulWidget {
  final String text;
  final String toastMsg;
  final TextAlign? textAlign;
  final TextStyle? textStyle;
  final RichText? textRichText;
  const CopyTextContainer({
    super.key,
    required this.text,
    required this.toastMsg,
    this.textAlign,
    this.textStyle,
    this.textRichText,
  });

  static const MethodChannel _channel = MethodChannel(methodChannelOS);

  @override
  State<CopyTextContainer> createState() => _CopyTextContainerState();
}

class _CopyTextContainerState extends State<CopyTextContainer> {
  late Color _textColor;
  late Color _buttonColor;
  late Color _iconColor;

  @override
  void initState() {
    super.initState();
    _textColor = CoconutColors.black;
    _buttonColor = CoconutColors.gray100;
    _iconColor = CoconutColors.black;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _textColor = CoconutColors.black;
          _buttonColor = CoconutColors.gray100;
          _iconColor = CoconutColors.black;
        });

        Clipboard.setData(ClipboardData(text: widget.text)).then((value) => null);
        if (Platform.isAndroid) {
          try {
            final int version = await CopyTextContainer._channel.invokeMethod('getSdkVersion');

            // 안드로이드13 부터는 클립보드 복사 메세지가 나오기 때문에 예외 적용
            if (version > 31) {
              return;
            }
          } on PlatformException catch (e) {
            Logger.log("Failed to get platform version: '${e.message}'.");
          }
        }

        FToast fToast = FToast();

        if (!context.mounted) return;

        fToast.init(context);
        final toast = MyToast.getToastWidget(widget.toastMsg);
        fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 2));
      },
      onTapDown: (details) {
        setState(() {
          _textColor = CoconutColors.gray500;
          _buttonColor = CoconutColors.gray200;
          _iconColor = CoconutColors.gray500;
        });
      },
      onTapCancel: () {
        setState(() {
          _textColor = CoconutColors.black;
          _buttonColor = CoconutColors.gray100;
          _iconColor = CoconutColors.black;
        });
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CoconutStyles.radius_400),
          color: CoconutColors.gray150,
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  widget.textRichText != null
                      ? RichText(text: widget.textRichText!.text)
                      : Text(
                        widget.text,
                        textAlign: widget.textAlign ?? TextAlign.start,
                        style:
                            widget.textStyle?.setColor(_textColor) ??
                            CoconutTypography.body1_16_Number.setColor(_textColor),
                      ),
            ),
            CoconutLayout.spacing_400w,
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CoconutStyles.radius_100),
                color: _buttonColor,
              ),
              child: SvgPicture.asset(
                'assets/svg/copy.svg',
                colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
