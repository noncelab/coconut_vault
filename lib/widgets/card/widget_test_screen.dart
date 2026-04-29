import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:flutter/material.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
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
                    pngAssetPath: 'assets/png/single-key.png',
                    height: 195,
                    onTap: () {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SelectableOptionCard(
                    title: '옵션 2 (설명 있음)',
                    description: '두 번째 옵션입니다.',
                    pngAssetPath: 'assets/png/multi-keys.png',
                    height: 195,
                    onTap: () {
                      setState(() {});
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
                    pngAssetPath: 'assets/png/coin.png',
                    height: 118,
                    onTap: () {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
