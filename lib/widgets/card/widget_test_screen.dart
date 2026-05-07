import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/button/assignable_pill_button.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:flutter/material.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _selectedIndex = -1;
  bool _isPillApproved = false;
  bool _isPill2Approved = false;
  bool _isPill3Approved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CoconutAppBar.build(context: context, title: 'Widget Test Screen'),
      backgroundColor: CoconutColors.gray100,
      body: Padding(
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text('AssignablePillButton', style: CoconutTypography.body1_16_Bold),
            ),
            const SizedBox(height: 16),
            AssignablePillButton(
              width: MediaQuery.sizeOf(context).width * 0.9,
              isAssigned: _isPillApproved,
              iconWidget: Container(
                key: ValueKey<bool>(_isPillApproved),
                width: 21,
                height: 21,
                decoration: BoxDecoration(color: CoconutColors.purple, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.center,
                child: Text('나', style: CoconutTypography.body3_12.setColor(CoconutColors.white)),
              ),
              text: '부모 지갑 - MFPXXXXX',
              activeColor: CoconutColors.purple,
              onPressed: () {
                setState(() {
                  _isPillApproved = !_isPillApproved;
                });
              },
            ),
            const SizedBox(height: 16),
            AssignablePillButton(
              width: MediaQuery.sizeOf(context).width * 0.9,
              isAssigned: _isPill2Approved,
              text: '부모 지갑 - MFPXXXXX',
              activeColor: CoconutColors.purple,
              onPressed: () {
                setState(() {
                  _isPill2Approved = !_isPill2Approved;
                });
              },
            ),
            const SizedBox(height: 16),
            AssignablePillButton(
              width: MediaQuery.sizeOf(context).width * 0.9,
              isAssigned: _isPill3Approved,
              text: '부모 지갑 - MFPXXXXX',
              activeColor: CoconutColors.purple,
              onPressed: () {
                setState(() {
                  _isPill3Approved = !_isPill3Approved;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
