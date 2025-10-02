import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_export_format_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SelectSyncOptionBottomSheet extends StatefulWidget {
  final Function(SyncOption) onSyncOptionSelected;
  final ScrollController? scrollController;

  const SelectSyncOptionBottomSheet({super.key, required this.onSyncOptionSelected, this.scrollController});

  @override
  State<SelectSyncOptionBottomSheet> createState() => _SelectSyncOptionBottomSheetState();
}

class _SelectSyncOptionBottomSheetState extends State<SelectSyncOptionBottomSheet> {
  final List<SyncOption> _syncOptions = [
    SyncOption(
      title: t.coconut,
      iconPath: "assets/svg/watch-only-icons/coconut.svg",
      format: WalletExportFormatEnum.coconut,
    ),
    SyncOption(
      title: t.watch_only_options.sparrow,
      iconPath: "assets/svg/watch-only-icons/sparrow.svg",
      format: WalletExportFormatEnum.bcUr,
    ),
    SyncOption(
      title: t.watch_only_options.nunchuk,
      iconPath: "assets/svg/watch-only-icons/nunchuk.svg",
      format: WalletExportFormatEnum.bcUr,
    ),
    SyncOption(
      title: t.watch_only_options.bluewallet,
      iconPath: "assets/svg/watch-only-icons/bluewallet.svg",
      format: WalletExportFormatEnum.descriptor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.watch_only_options.title,
        context: context,
        onBackPressed: null,
        isBottom: true,
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildSyncOptionItem(_syncOptions[0])),
                Expanded(child: _buildSyncOptionItem(_syncOptions[1])),
                Expanded(child: _buildSyncOptionItem(_syncOptions[2])),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildSyncOptionItem(_syncOptions[3])),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOptionItem(SyncOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShrinkAnimationButton(
        defaultColor: CoconutColors.white,
        pressedColor: CoconutColors.gray200,
        onPressed: () => widget.onSyncOptionSelected(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              SvgPicture.asset(option.iconPath),
              CoconutLayout.spacing_200h,
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Text(
                  option.title,
                  style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.gray800),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncOption {
  final String title;
  final String iconPath;
  final WalletExportFormatEnum format;

  SyncOption({required this.title, required this.iconPath, required this.format});
}
