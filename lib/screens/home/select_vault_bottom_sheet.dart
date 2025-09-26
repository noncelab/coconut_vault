import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

enum BalanceMode {
  includingPending,
  onlyUnspent, // UtxoStatus.unspent (UtxoStatus.locked 제외)
}

class SelectVaultBottomSheet extends StatefulWidget {
  final Function(int) onVaultSelected;
  final List<VaultListItemBase> vaultList;
  final int? selectedId;
  final int? walletId;
  final ScrollController? scrollController;
  final String? subLabel;
  final bool isNextIconVisible;

  const SelectVaultBottomSheet({
    super.key,
    required this.onVaultSelected,
    required this.vaultList,
    this.selectedId,
    this.walletId,
    this.scrollController,
    this.subLabel,
    this.isNextIconVisible = true,
  });

  @override
  State<SelectVaultBottomSheet> createState() => _SelectVaultBottomSheetState();
}

class _SelectVaultBottomSheetState extends State<SelectVaultBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.select_vault_bottom_sheet.select_wallet,
        context: context,
        onBackPressed: null,
        subLabel:
            widget.subLabel != null
                ? Text(
                  widget.subLabel ?? '',
                  style: CoconutTypography.body3_12.setColor(CoconutColors.black.withValues(alpha: 0.7)),
                )
                : null,
        showSubLabel: widget.subLabel != null,
        isBottom: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                children: List.generate(widget.vaultList.length, (index) {
                  int walletId = widget.vaultList[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.size8),
                      child: VaultRowItem(
                        vault: widget.vaultList[index],
                        isSelected: widget.selectedId == walletId,
                        isSelectable: true,
                        onSelected: () {
                          if (walletId == widget.selectedId) return;
                          widget.onVaultSelected(walletId);
                        },
                        isNextIconVisible: widget.isNextIconVisible,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
