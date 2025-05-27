import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';

class ExportDetailScreen extends StatefulWidget {
  final String exportDetail;

  const ExportDetailScreen({super.key, required this.exportDetail});

  @override
  State<ExportDetailScreen> createState() => _ExportDetailScreen();
}

class _ExportDetailScreen extends State<ExportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          context: context,
          title: t.export_detail_screen.title,
          backgroundColor: CoconutColors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding:
                  const EdgeInsets.symmetric(horizontal: CoconutLayout.defaultPadding, vertical: 0),
              child: Stack(
                children: [
                  CopyTextContainer(
                    text: widget.exportDetail,
                    textStyle: CoconutTypography.body2_14_Number,
                    toastMsg: t.export_detail_screen.info_copied,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
