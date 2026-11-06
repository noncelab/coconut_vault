import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class NumberFormatBottomSheet extends StatefulWidget {
  const NumberFormatBottomSheet({super.key});

  @override
  State<NumberFormatBottomSheet> createState() => _NumberFormatBottomSheetState();
}

class _NumberFormatBottomSheetState extends State<NumberFormatBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Selector<VisibilityProvider, NumberFormatPreset>(
      selector: (_, provider) => provider.numberFormatPreset,
      builder: (context, preset, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            title: t.general.number_format,
            context: context,
            onBackPressed: null,
            isBottom: true,
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: Sizes.size16, right: Sizes.size16),
            child: ListView.separated(
              itemCount: NumberFormatPreset.values.length,
              itemBuilder: (context, index) {
                final item = NumberFormatPreset.values[index];
                return _buildUnitItem(item.displayLabel, preset == item, () async {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  await context.read<VisibilityProvider>().changeNumberFormatPreset(item);
                });
              },
              separatorBuilder: (context, index) {
                return Divider(color: CoconutColors.black.withValues(alpha: 0.12), height: 1);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitItem(String title, bool isChecked, VoidCallback onPress) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: Sizes.size20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CoconutTypography.body2_14_Bold.copyWith(
                      color: CoconutColors.black,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ),
            if (isChecked)
              Padding(
                padding: const EdgeInsets.only(right: Sizes.size8),
                child: SvgPicture.asset(
                  'assets/svg/check.svg',
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
