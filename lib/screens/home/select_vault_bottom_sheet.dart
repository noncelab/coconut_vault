import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

enum BalanceMode {
  includingPending,
  onlyUnspent, // UtxoStatus.unspent (UtxoStatus.locked 제외)
}

class SelectVaultBottomSheet extends StatefulWidget {
  final Function(int)? onVaultSelected;
  final List<VaultListItemBase>? vaultList;
  final int? selectedId;
  final int? walletId;
  final ScrollController? scrollController;
  final String? subLabel;
  final bool isNextIconVisible;
  final List<Widget>? children;

  const SelectVaultBottomSheet({
    super.key,
    this.onVaultSelected,
    this.vaultList,
    this.selectedId,
    this.walletId,
    this.scrollController,
    this.subLabel,
    this.children,
    this.isNextIconVisible = true,
  });

  @override
  State<SelectVaultBottomSheet> createState() => _SelectVaultBottomSheetState();
}

class _SelectVaultBottomSheetState extends State<SelectVaultBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoconutColors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child:
                  widget.children != null
                      ? Column(children: widget.children!)
                      : Column(
                        children: List.generate(widget.vaultList?.length ?? 0, (index) {
                          int walletId = widget.vaultList![index].id;
                          return Container(
                            padding: const EdgeInsets.only(bottom: 8),
                            margin: index == 0 ? const EdgeInsets.only(top: 8) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Sizes.size8),
                              child: VaultRowItem(
                                vault: widget.vaultList![index],
                                isSelected: widget.selectedId == walletId,
                                isSelectable: true,
                                onSelected: () {
                                  if (walletId == widget.selectedId) return;
                                  widget.onVaultSelected?.call(walletId);
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
