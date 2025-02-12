import 'package:coconut_vault/model/singlesig/singlesig_vault_list_item.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

class KeyListBottomScreen extends StatefulWidget {
  final List<SinglesigVaultListItem> vaultList;
  final void Function(int) onPressed;

  const KeyListBottomScreen({
    super.key,
    required this.onPressed,
    required this.vaultList,
  });

  @override
  State<KeyListBottomScreen> createState() => _KeyListBottomScreenState();
}

class _KeyListBottomScreenState extends State<KeyListBottomScreen> {
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
  }

  void _handleSelection(int index) {
    setState(() {
      selectedIndex = index;
    });
    widget.onPressed(index);
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
          return VaultRowItem(
            vault: widget.vaultList[index],
            isSelectable: true,
            isPressed: index == selectedIndex,
            onSelected: () => _handleSelection(index),
          );
        }),
        const SizedBox(
          height: 50,
        ),
      ]),
    );
  }
}
