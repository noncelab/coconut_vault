import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
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
    final double qrSize = MediaQuery.of(context).size.width * 275 / 375;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.qrcodeTopWidget != null) ...[
            widget.qrcodeTopWidget!,
            const SizedBox(height: 25)
          ],
          Stack(
            children: [
              Container(
                  width: qrSize, height: qrSize, decoration: BoxDecorations.shadowBoxDecoration),
              QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: qrSize,
              ),
            ],
          ),
          const SizedBox(height: 32),
          CopyTextContainer(
            text: widget.qrData,
            textStyle: CoconutTypography.body2_14_Number,
            toastMsg: t.toast.mnemonic_copied,
          ),
        ],
      ),
    );
  }
}
