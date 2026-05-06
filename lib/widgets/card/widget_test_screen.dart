import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:flutter/material.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _selectedIndex = -1;
  late final _MockTaprootVaultListItem _mockVaultItem = _MockTaprootVaultListItem();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CoconutAppBar.build(context: context, title: 'SelectableOptionCard Test'),
      backgroundColor: CoconutColors.gray100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableOptionCard(
                    title: '옵션 1 (설명 있음)',
                    description: '이것은 첫 번째 옵션에 대한 설명입니다. 내용이 길어질 경우 어떻게 보이는지 확인합니다.',
                    bottomAssetPath: 'assets/png/single-key.png',
                    imageScale: 4.0,
                    isSelected: _selectedIndex == 0,
                    height: 195,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SelectableOptionCard(
                    title: '옵션 2 (설명 있음)',
                    description: '두 번째 옵션입니다.',
                    bottomAssetPath: 'assets/png/multi-keys.png',
                    imageScale: 4.0,
                    isSelected: _selectedIndex == 1,
                    height: 195,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableOptionCard(
                    title: '옵션 3 (설명 없음)',
                    bottomAssetPath: 'assets/png/coin.png',
                    imageScale: 4.0,
                    isSelected: _selectedIndex == 2,
                    height: 118,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 32),
            TaprootVaultItemCard(vaultItem: _mockVaultItem, showTaprootWalletInfo: true),
          ],
        ),
      ),
    );
  }
}

class _MockTaprootVaultListItem extends TaprootVaultListItem {
  _MockTaprootVaultListItem()
    : super(
        id: 1,
        name: 'Name',
        colorIndex: 0,
        iconIndex: 0,
        vaultType: WalletType.values.first,
        createdAt: DateTime.now(),
        isParent: true,
      );
}
