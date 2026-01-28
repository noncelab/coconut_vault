import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';

class WalletInfoItemCard extends StatelessWidget {
  final GlobalKey tooltipKey;
  final VoidCallback onTooltipClicked;
  final void Function() onNameChangeClicked;
  final VaultListItemBase vaultItem;

  const WalletInfoItemCard({
    super.key,
    required this.tooltipKey,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
    required this.vaultItem,
  });

  @override
  Widget build(BuildContext context) {
    return VaultItemCard(
      vaultItem: vaultItem,
      onTooltipClicked: onTooltipClicked,
      onNameChangeClicked: () => onNameChangeClicked(),
      tooltipKey: tooltipKey,
    );
  }
}
