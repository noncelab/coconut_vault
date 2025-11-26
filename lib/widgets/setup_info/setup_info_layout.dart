import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/vault_setup_info_view_model_base.dart';
import 'package:coconut_vault/widgets/setup_info/setup_info_vault_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupInfoLayout<T extends VaultSetupInfoViewModelBase<VaultListItemBase>> extends StatelessWidget {
  final GlobalKey tooltipKey;
  final VoidCallback onTooltipClicked;
  final void Function(T viewModel) onNameChangeClicked;
  final Widget? Function(T viewModel)? linkedInfoBuilder;
  final Widget Function(T viewModel)? contentBuilder;
  final Widget Function(T viewModel) menuListBuilder;
  final Widget Function(T viewModel) tooltipBuilder;

  const SetupInfoLayout({
    super.key,
    required this.tooltipKey,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
    required this.menuListBuilder,
    required this.tooltipBuilder,
    this.linkedInfoBuilder,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, viewModel, child) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoconutLayout.spacing_500h,
                    SetupInfoVaultItemCard<T>(
                      tooltipKey: tooltipKey,
                      onTooltipClicked: onTooltipClicked,
                      onNameChangeClicked: onNameChangeClicked,
                    ),
                    if (linkedInfoBuilder != null) ...[
                      CoconutLayout.spacing_300h,
                      linkedInfoBuilder!(viewModel) ?? const SizedBox.shrink(),
                    ],
                    if (contentBuilder != null) contentBuilder!(viewModel),
                    CoconutLayout.spacing_500h,
                    menuListBuilder(viewModel),
                    CoconutLayout.spacing_1500h,
                  ],
                ),
                tooltipBuilder(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }
}
