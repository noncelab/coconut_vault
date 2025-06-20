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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.item.isChecked);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.item.isChecked
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20.0,
              color: MyColors.darkgrey,
            ),
            const SizedBox(width: 8),
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
