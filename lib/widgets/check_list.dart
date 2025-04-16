import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';

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
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        color: Colors.transparent, // 터치 이벤트를 감지할 수 있도록 배경색을 설정
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isChecked ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              size: 20.0,
              color: MyColors.darkgrey,
            ),
            const SizedBox(width: 8), // 체크박스와 텍스트 사이의 가로 간격 조정
            Expanded(
              child: Text(
                widget.item.title,
                style: Styles.label.merge(const TextStyle(color: MyColors.darkgrey)),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
