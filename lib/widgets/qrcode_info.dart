import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeInfo extends StatefulWidget {
  final String qrData;
  final Widget? qrcodeTopWidget;

  const QRCodeInfo({super.key, required this.qrData, this.qrcodeTopWidget});

  @override
  State<QRCodeInfo> createState() => _QRCodeInfoState();
}

class _QRCodeInfoState extends State<QRCodeInfo> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.qrcodeTopWidget != null) ...[widget.qrcodeTopWidget!, const SizedBox(height: 25)],
          AdaptiveQrImage(qrData: widget.qrData),
          const SizedBox(height: 32),
          CopyTextContainer(
            text: widget.qrData,
            textStyle: CoconutTypography.body2_14_Number,
            toastMsg: t.toast.clipboard_copied,
          ),
        ],
      ),
    );
  }
}
