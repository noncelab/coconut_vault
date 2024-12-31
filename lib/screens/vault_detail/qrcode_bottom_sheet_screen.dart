import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/qrcode_info.dart';
import 'package:coconut_vault/widgets/qrcode_link_info.dart';

class QrcodeBottomSheetScreen extends StatefulWidget {
  const QrcodeBottomSheetScreen(
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
  State<QrcodeBottomSheetScreen> createState() =>
      _QrcodeBottomSheetScreenState();
}

class _QrcodeBottomSheetScreenState extends State<QrcodeBottomSheetScreen> {
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
        : QRCodeInfo(
            qrData: widget.qrData,
            qrcodeTopWidget: widget.qrcodeTopWidget,
            toastMessage: '클립보드에 복사되었어요.',
          );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.buildWithClose(
            title: widget.title ?? '', context: context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: Paddings.container,
              color: MyColors.white,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}
