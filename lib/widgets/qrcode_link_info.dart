import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/external_links.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../styles.dart';

class QRCodeLinkInfo extends StatefulWidget {
  final String qrData;
  final Widget? qrcodeTopWidget;

  const QRCodeLinkInfo({super.key, required this.qrData, this.qrcodeTopWidget});

  @override
  State<QRCodeLinkInfo> createState() => _QRCodeLinkInfoState();
}

class _QRCodeLinkInfoState extends State<QRCodeLinkInfo> {
  String assetImageUrl = '';
  Size assetImageSize = const Size(24, 24);

  @override
  void initState() {
    super.initState();
    if (widget.qrData.contains('powbitcoiner')) {
      assetImageUrl = 'assets/png/pow-logo.png';
      assetImageSize = const Size(48, 48);
    } else if (widget.qrData.contains('discord')) {
      assetImageUrl = 'assets/png/discord-logo.png';
      assetImageSize = const Size(48, 48);
    } else if (widget.qrData.contains('x.com')) {
      assetImageUrl = 'assets/jpg/x-logo.jpg';
    } else if (widget.qrData.contains('@')) {
      assetImageUrl = 'assets/png/mail-icon.png';
    }
  }

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
                  width: qrSize,
                  height: qrSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: CoconutColors.white,
                  ),
                ),
                QrImageView(
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: qrSize,
                  embeddedImage: AssetImage(assetImageUrl),
                  embeddedImageStyle: QrEmbeddedImageStyle(size: assetImageSize),
                ),
              ],
            ),
            CoconutLayout.spacing_400h,
            CopyTextContainer(
                text: widget.qrData.contains('@') ? CONTACT_EMAIL_ADDRESS : widget.qrData,
                toastMsg: t.toast.clipboard_copied,
                textStyle: CoconutTypography.body2_14_Number.setColor(CoconutColors.black)),
            CoconutLayout.spacing_600h,
            widget.qrData.contains('@')
                ? widget.qrData.contains(t.license)
                    ? const Text(
                        'Please scan the QR code on a network-enabled device or send an email to the address above.\n\n네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 주소로 메일을 전송해 주세요.',
                        style: CoconutTypography.body1_16,
                        textAlign: TextAlign.center)
                    : Text(t.scan_qr_email_link,
                        style: CoconutTypography.body1_16, textAlign: TextAlign.center)
                : Text(t.scan_qr_url_link,
                    style: CoconutTypography.body1_16, textAlign: TextAlign.center),
          ],
        ));
  }
}
