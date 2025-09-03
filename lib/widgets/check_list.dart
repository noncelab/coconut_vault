import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:flutter/material.dart';

class ChecklistItem {
  String title;
  bool isChecked;

  ChecklistItem({required this.title, this.isChecked = false});
}

class ChecklistTile extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<bool?> onChanged;

  const ChecklistTile({super.key, required this.item, required this.onChanged});

  @override
  State<ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<ChecklistTile> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.item.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
          widget.onChanged(isChecked); // 부모 상태 업데이트
          vibrateExtraLight();
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        color: Colors.transparent, // 터치 이벤트를 감지할 수 있도록 배경색을 설정
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CoconutCheckbox(
              isSelected: isChecked,
              onChanged: (value) {
                setState(() {
                  isChecked = value;
                  widget.onChanged(value);
                  vibrateExtraLight();
                });
              },
              width: 16,
            ),
            CoconutLayout.spacing_200w,
            Expanded(
              child: Text(
                widget.item.title,
                style: CoconutTypography.body2_14_Bold.setColor(
                  CoconutColors.gray800,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
