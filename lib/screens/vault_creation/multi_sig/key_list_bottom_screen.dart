import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/assign_key_screen.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

class KeyListBottomScreen extends StatefulWidget {
  final List<SinglesigVaultListItem> vaultList;
  final List<AssignedVaultListItem> assignedList;
  final void Function(SinglesigVaultListItem) onPressed;

  const KeyListBottomScreen({
    super.key,
    required this.onPressed,
    required this.vaultList,
    required this.assignedList,
  });

  @override
  _KeyListBottomScreenState createState() => _KeyListBottomScreenState();
}

class _KeyListBottomScreenState extends State<KeyListBottomScreen> {
  // 상태를 관리하는 리스트
  late List<bool> isPressedList;

  @override
  void initState() {
    super.initState();
    isPressedList = List<bool>.filled(widget.vaultList.length, false);
  }

  void _handleSelection(int index) {
    setState(() {
      for (int i = 0; i < widget.vaultList.length; i++) {
        isPressedList[i] = false;
      }
      isPressedList[index] = true;
    });
    widget.onPressed(widget.vaultList[index]);
  }

  bool _checkAssignedItem(SinglesigVaultListItem item) {
    for (var assignedItem in widget.assignedList) {
      if (item == assignedItem.item) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(children: [
        const SizedBox(
          height: 20,
        ),
        ...List.generate(widget.vaultList.length, (index) {
          if (_checkAssignedItem(widget.vaultList[index])) return Container();
          return VaultRowItem(
            vault: widget.vaultList[index],
            isSelectable: true,
            isPressed: isPressedList[index],
            onSelected: () => _handleSelection(index),
            resetSelected: () {},
          );
        }),
        const SizedBox(
          height: 50,
        ),
      ]),
    );
  }
}
