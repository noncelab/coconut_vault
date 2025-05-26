import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/check_list.dart';

class SecuritySelfCheckScreen extends StatefulWidget {
  final VoidCallback? onNextPressed;

  const SecuritySelfCheckScreen({
    super.key,
    this.onNextPressed,
  });

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
    return _items.every((item) => item.isChecked);
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
      appBar: widget.onNextPressed != null
          ? CustomAppBar.buildWithNext(
              title: t.checklist,
              context: context,
              onBackPressed: () {
                Navigator.of(context).pop();
              },
              onNextPressed: widget.onNextPressed!,
              isActive: _allItemsChecked, // 상태에 따라 'Next' 버튼 활성화
            )
          : CustomAppBar.build(
              title: t.checklist,
              context: context,
              onBackPressed: () {
                Navigator.of(context).pop();
              },
              hasRightIcon: false),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecorations.boxDecorationGrey,
                    child: Text(
                      t.security_self_check_screen.guidance,
                      style: Styles.subLabel.merge(const TextStyle(fontWeight: FontWeight.bold)),
                    )),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const double itemHeight = 40.0;
                  final double totalHeight = _items.length * itemHeight;
                  final bool needScrolling = totalHeight > constraints.maxHeight;

                  return needScrolling
                      ? SingleChildScrollView(
                          child: Column(
                            children: _items.asMap().entries.map((entry) {
                              int index = entry.key;
                              ChecklistItem item = entry.value;
                              return ChecklistTile(
                                item: item,
                                onChanged: (bool? value) {
                                  _onChecklistItemChanged(value, index);
                                },
                              );
                            }).toList(),
                          ),
                        )
                      : Column(
                          children: _items.asMap().entries.map((entry) {
                            int index = entry.key;
                            ChecklistItem item = entry.value;
                            return ChecklistTile(
                              item: item,
                              onChanged: (bool? value) {
                                _onChecklistItemChanged(value, index);
                              },
                            );
                          }).toList(),
                        );
                },
              )
            ]),
          ),
        ),
      ),
    );
  }
}
