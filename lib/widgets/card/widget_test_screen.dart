import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_home_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/widgets/button/assignable_pill_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _selectedIndex = -1;
  int? _selectedVaultId;
  bool _isAssigned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = VaultHomeViewModel(
        context.read<AuthProvider>(),
        context.read<WalletProvider>(),
        context.read<PreferenceProvider>(),
      );
      if (!viewModel.isVaultsLoaded) {
        await viewModel.loadVaults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultList = context.watch<WalletProvider>().vaultList;

    return Scaffold(
      appBar: CoconutAppBar.build(context: context, title: 'SelectableOptionCard Test'),
      backgroundColor: CoconutColors.gray100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            MenuGrid(
              children: [
                SelectableOptionCard(
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
                SelectableOptionCard(
                  title: '옵션 2 (설명 있음)',
                  description: '두 번째 옵션입니다.',
                  bottomAssetPath: 'assets/png/multi-keys.png',
                  imageScale: 4.0,
                  isSelected: _selectedIndex == 1,
                  height: 195,
                  isDisabled: true,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                SelectableOptionCard(
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
              ],
            ),
            const SizedBox(height: 32),
            AssignablePillButton(
              isAssigned: _isAssigned,
              text: _isAssigned ? '할당됨' : '할당하기',
              activeColor: Colors.blue,
              iconWidget: Icon(
                _isAssigned ? Icons.check_circle : Icons.person_add,
                color: _isAssigned ? Colors.blue : CoconutColors.gray800,
              ),
              width: 1000,
              onPressed: () {
                setState(() {
                  _isAssigned = !_isAssigned;
                });
              },
            ),
            const SizedBox(height: 32),
            ...vaultList.map((vault) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: VaultRowItem(
                  vault: vault,
                  isSelected: _selectedVaultId == vault.id,
                  isKeyBorderVisible: true,
                  isSelectable: true,
                  isNextIconVisible: false,
                  onSelected: () {
                    setState(() {
                      _selectedVaultId = vault.id;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
