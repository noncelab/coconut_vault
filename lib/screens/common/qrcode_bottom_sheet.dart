import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/qrcode_info.dart';
import 'package:coconut_vault/widgets/qrcode_link_info.dart';

// Usage:
// 1. settings/app_info_screen.dart
// 2. settings/license_screen.dart
// 3. vault_menu/info/multisig_setup_info_screen.dart
// 4. vault_menu/info/single_sig_setup_info_screen.dart
class QrcodeBottomSheet extends StatefulWidget {
  const QrcodeBottomSheet(
      {super.key,
      required this.qrData,
      this.qrcodeTopWidget,
      this.title,
      this.fromAppInfo = false});

  final String qrData;
  final Widget? qrcodeTopWidget;
  final String? title;
  final bool fromAppInfo;

  @override
  State<QrcodeBottomSheet> createState() => _QrcodeBottomSheetState();
}

class _QrcodeBottomSheetState extends State<QrcodeBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildContent() {
    return widget.fromAppInfo
        ? QRCodeLinkInfo(
            qrData: widget.qrData,
            qrcodeTopWidget: widget.qrcodeTopWidget,
          )
        : QRCodeInfo(qrData: widget.qrData, qrcodeTopWidget: widget.qrcodeTopWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: widget.title ?? '',
          context: context,
          isBottom: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: CoconutPadding.container,
              color: CoconutColors.white,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}
