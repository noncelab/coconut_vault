import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

class KeyListBottomSheet extends StatefulWidget {
  final List<SingleSigVaultListItem> vaultList;
  final void Function(int) onPressed;
  final ScrollController? scrollController;
  const KeyListBottomSheet({super.key, required this.onPressed, required this.vaultList, this.scrollController});

  @override
  State<KeyListBottomSheet> createState() => _KeyListBottomSheetState();
}

class _KeyListBottomSheetState extends State<KeyListBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  void _handleSelection(int index) {
    widget.onPressed(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.vaultList.length,
          itemBuilder: (context, i) {
            final index = i % widget.vaultList.length;
            return Column(
              children: [
                VaultRowItem(
                  enableShotenName: false,
                  vault: widget.vaultList[index],
                  onSelected: () => _handleSelection(index),
                  isNextIconVisible: false,
                  isKeyBorderVisible: true,
                ),
                CoconutLayout.spacing_300h,
              ],
            );
          },
        ),
      ),
    );
  }
}
