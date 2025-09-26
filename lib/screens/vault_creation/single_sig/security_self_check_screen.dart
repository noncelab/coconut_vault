import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/check_list.dart';

class SecuritySelfCheckScreen extends StatefulWidget {
  final VoidCallback? onNextPressed;

  const SecuritySelfCheckScreen({super.key, this.onNextPressed});

  @override
  State<SecuritySelfCheckScreen> createState() => _SecuritySelfCheckScreenState();
}

class _SecuritySelfCheckScreenState extends State<SecuritySelfCheckScreen> {
  final List<ChecklistItem> _items = [
    ChecklistItem(title: t.security_self_check_screen.check1),
    ChecklistItem(title: t.security_self_check_screen.check2),
    ChecklistItem(title: t.security_self_check_screen.check3),
    ChecklistItem(title: t.security_self_check_screen.check4),
    ChecklistItem(title: t.security_self_check_screen.check5),
    ChecklistItem(title: t.security_self_check_screen.check6),
    ChecklistItem(title: t.security_self_check_screen.check7),
    ChecklistItem(title: t.security_self_check_screen.check8),
    ChecklistItem(title: t.security_self_check_screen.check9),
  ];

  bool get _allItemsChecked {
    if (_items.every((item) => item.isChecked)) {
      vibrateExtraLight();
      return true;
    }
    return false;
  }

  void _onChecklistItemChanged(bool? value, int index) {
    setState(() {
      _items[index].isChecked = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar:
          widget.onNextPressed != null
              ? CoconutAppBar.build(title: t.checklist, context: context)
              : CoconutAppBar.build(
                title: t.checklist,
                context: context,
                onBackPressed: () {
                  Navigator.of(context).pop();
                },
              ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: CoconutBorder.defaultRadius,
                        color: CoconutColors.gray150,
                      ),
                      child: Text(
                        t.security_self_check_screen.guidance,
                        style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.black),
                      ),
                    ),
                  ),
                  CoconutLayout.spacing_400h,
                  ..._items.asMap().entries.map((entry) {
                    int index = entry.key;
                    ChecklistItem item = entry.value;
                    return ChecklistTile(
                      item: item,
                      onChanged: (bool? value) {
                        _onChecklistItemChanged(value, index);
                      },
                    );
                  }),
                  CoconutLayout.spacing_2000h,
                ],
              ),
            ),
            FixedBottomButton(
              onButtonClicked: widget.onNextPressed!,
              text: t.next,
              textColor: CoconutColors.white,
              showGradient: true,
              gradientPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 110),
              isActive: _allItemsChecked,
              backgroundColor: CoconutColors.black,
            ),
          ],
        ),
      ),
    );
  }
}
