import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VaultItemSettingBottomSheet extends StatefulWidget {
  final int id;

  const VaultItemSettingBottomSheet({super.key, required this.id});

  @override
  State<VaultItemSettingBottomSheet> createState() => _VaultItemSettingBottomSheetState();
}

class _VaultItemSettingBottomSheetState extends State<VaultItemSettingBottomSheet> {
  late final PreferenceProvider _preferenceProvider;
  late bool _isPrimaryWallet;

  final GlobalKey<CoconutShakeAnimationState> _primaryWalletShakeKey =
      GlobalKey<CoconutShakeAnimationState>();

  @override
  void initState() {
    super.initState();
    _preferenceProvider = context.read<PreferenceProvider>();
    _isPrimaryWallet = _preferenceProvider.vaultOrder.first == widget.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 0, bottom: 80, left: 20, right: 20),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 4,
            decoration: BoxDecoration(
              color: CoconutColors.gray400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          CoconutLayout.spacing_400h,
          _buildToggleWidget(
            t.vault_list_screen.settings.primary_wallet,
            _isPrimaryWallet
                ? t.vault_list_screen.settings.primary_wallet_abled_description
                : t.vault_list_screen.settings.primary_wallet_disabled_description,
            _isPrimaryWallet,
            true,
            (bool value) {
              if (!value) {
                _primaryWalletShakeKey.currentState?.shake();
                return;
              }
              setState(() {
                _isPrimaryWallet = value;
              });
              final updatedOrder = [
                widget.id,
                ..._preferenceProvider.vaultOrder.where((id) => id != widget.id),
              ];
              _preferenceProvider.setVaultOrder(updatedOrder);
            },
          ),
          CoconutLayout.spacing_400h,
        ],
      ),
    );
  }

  Widget _buildToggleWidget(
    String title,
    String description,
    bool value,
    bool shouldHideWhenOn,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CoconutTypography.body3_12),
            Text(
              description,
              style: CoconutTypography.body3_12.setColor(CoconutColors.gray400),
            ),
          ],
        ),
        Visibility(
          visible: shouldHideWhenOn ? !value : true,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: CoconutSwitch(
            isOn: value,
            activeColor: CoconutColors.black,
            thumbColor: value ? CoconutColors.black : CoconutColors.white,
            trackColor: CoconutColors.gray300,
            scale: 0.8,
            onChanged: (bool newValue) {
              setState(() {
                onChanged(newValue);
              });
            },
          ),
        ),
      ],
    );
  }
}
