import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/vault_setup_info_view_model_base.dart';
import 'package:coconut_vault/widgets/card/vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupInfoVaultItemCard<T extends VaultSetupInfoViewModelBase<VaultListItemBase>> extends StatelessWidget {
  final GlobalKey tooltipKey;
  final VoidCallback onTooltipClicked;
  final void Function(T viewModel) onNameChangeClicked;

  const SetupInfoVaultItemCard({
    super.key,
    required this.tooltipKey,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, viewModel, child) {
        return VaultItemCard(
          vaultItem: viewModel.vaultItem,
          onTooltipClicked: onTooltipClicked,
          onNameChangeClicked: () => onNameChangeClicked(viewModel),
          tooltipKey: tooltipKey,
        );
      },
    );
  }
}
