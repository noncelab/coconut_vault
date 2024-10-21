import 'package:flutter/material.dart';
import 'package:coconut_vault/constants/app_info.dart';
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
    } else if (widget.qrData.contains('t.me')) {
      assetImageUrl = 'assets/png/telegram-logo.png';
      assetImageSize = const Size(48, 48);
    } else if (widget.qrData.contains('x.com')) {
      assetImageUrl = 'assets/jpg/x-logo.jpg';
    } else if (widget.qrData.contains('@')) {
      assetImageUrl = 'assets/png/mail-icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double qrSize = 375;

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
                    color: Colors.white,
                  ),
                ),
                QrImageView(
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: qrSize,
                  embeddedImage: AssetImage(assetImageUrl),
                  embeddedImageStyle:
                      QrEmbeddedImageStyle(size: assetImageSize),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
                widget.qrData.contains('@')
                    ? CONTACT_EMAIL_ADDRESS
                    : widget.qrData,
                style: Styles.body1
                    .merge(const TextStyle(fontFamily: 'SpaceGrotesk')),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            widget.qrData.contains('@')
                ? widget.qrData.contains('라이선스')
                    ? const Text(
                        'Please scan the QR code on a network-enabled device or send an email to the address above.\n\n네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 주소로 메일을 전송해 주세요.',
                        style: Styles.body1,
                        textAlign: TextAlign.center)
                    : const Text(
                        '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 주소로 메일을 전송해 주세요.',
                        style: Styles.body1,
                        textAlign: TextAlign.center)
                : const Text(
                    '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 URL 주소로 접속해 주세요.',
                    style: Styles.body1,
                    textAlign: TextAlign.center),
          ],
        ));
  }
}
