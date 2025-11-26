import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrWithCopyTextScreen extends StatelessWidget {
  final String title;
  final Widget? tooltipDescription;
  final String qrData;
  final Widget Function(BuildContext context, double qrWidth)? bottomBuilder;
  final Widget? footer;

  const QrWithCopyTextScreen({
    super.key,
    required this.title,
    this.tooltipDescription,
    required this.qrData,
    this.bottomBuilder,
    this.footer,
  });

  double _calcQrWidth(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.76;
  }

  @override
  Widget build(BuildContext context) {
    final qrWidth = _calcQrWidth(context);

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: title,
        context: context,
        isBottom: false,
        onBackPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (tooltipDescription != null) ...[tooltipDescription!],
              CoconutLayout.spacing_300h,
              Center(
                child: Container(
                  width: qrWidth,
                  decoration: CoconutBoxDecoration.shadowBoxDecoration,
                  child: QrImageView(data: qrData),
                ),
              ),
              CoconutLayout.spacing_500h,
              _buildCopyButton(qrData, qrWidth),
              CoconutLayout.spacing_1500h,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(String qrData, double qrWidth) {
    return SizedBox(
      width: qrWidth,
      child: CopyTextContainer(
        text: qrData,
        textStyle: CoconutTypography.body2_14_Number,
        toastMsg: t.toast.clipboard_copied,
      ),
    );
  }
}
