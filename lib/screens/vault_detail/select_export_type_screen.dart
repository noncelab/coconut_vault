import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';

class SelectExportTypeScreen extends StatefulWidget {
  final int id;

  const SelectExportTypeScreen({super.key, required this.id});

  @override
  State<SelectExportTypeScreen> createState() => _SelectExportTypeScreenState();
}

class _SelectExportTypeScreenState extends State<SelectExportTypeScreen> {
  String? nextPath;
  late String guideText;
  List<String> options = ['/sync-to-wallet', '/signer-bsms'];

  @override
  void initState() {
    super.initState();
    guideText = t.select_export_type_screen.export_type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
          title: t.select_export_type_screen.title,
          context: context,
          onNextPressed: () {
            Navigator.pushReplacementNamed(context, nextPath!, arguments: {
              'id': widget.id,
            });
          },
          isActive: nextPath != null),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            Text(guideText),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: t.select_export_type_screen.watch_only,
                    onTap: () {
                      setState(() {
                        nextPath = options[0];
                      });
                    },
                    isPressed: nextPath == options[0],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableButton(
                    text: t.select_export_type_screen.multisig,
                    onTap: () {
                      setState(() {
                        nextPath = options[1];
                      });
                    },
                    isPressed: nextPath == options[1],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
