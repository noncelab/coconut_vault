import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_export_format_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum WalletApp { coconut, sparrow, nunchuk, bluewallet }

class SelectSyncOptionBottomSheet extends StatefulWidget {
  final Function(SyncOption) onSyncOptionSelected;
  final ScrollController? scrollController;
  final List<SyncOption>? options;
  final String? title;

  const SelectSyncOptionBottomSheet({
    super.key,
    required this.onSyncOptionSelected,
    this.scrollController,
    this.options,
    this.title,
  });

  static List<SyncOption> get signerOptions => [
    SyncOption(
      app: WalletApp.coconut,
      title: t.multi_sig_setting_screen.add_signer.coconut_vault,
      iconPath:
          NetworkType.currentNetworkType.isTestnet
              ? 'assets/svg/coconut/coconut-vault-regtest.svg'
              : 'assets/svg/coconut/coconut-vault.svg',
      format: WalletExportFormatEnum.coconut,
    ),
    ..._SelectSyncOptionBottomSheetState.defaultSyncOptions.skip(1),
  ];

  @override
  State<SelectSyncOptionBottomSheet> createState() => _SelectSyncOptionBottomSheetState();
}

class _SelectSyncOptionBottomSheetState extends State<SelectSyncOptionBottomSheet> {
  List<SyncOption> get _syncOptions => widget.options ?? defaultSyncOptions;

  static List<SyncOption> get defaultSyncOptions => [
    SyncOption(
      app: WalletApp.coconut,
      title: t.watch_only_options.coconut_wallet,
      iconPath:
          NetworkType.currentNetworkType.isTestnet
              ? "assets/svg/coconut/coconut-regtest.svg"
              : "assets/svg/watch-only-icons/coconut.svg",
      format: WalletExportFormatEnum.coconut,
    ),
    SyncOption(
      app: WalletApp.sparrow,
      title: t.watch_only_options.sparrow,
      iconPath: "assets/svg/watch-only-icons/sparrow.svg",
      format: WalletExportFormatEnum.bcUr,
    ),
    SyncOption(
      app: WalletApp.nunchuk,
      title: t.watch_only_options.nunchuk,
      iconPath: "assets/svg/watch-only-icons/nunchuk.svg",
      format: WalletExportFormatEnum.bcUr,
    ),
    if (!NetworkType.currentNetworkType.isTestnet)
      SyncOption(
        app: WalletApp.bluewallet,
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
        title: widget.title ?? t.watch_only_options.title,
        context: context,
        onBackPressed: null,
        isBottom: true,
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var row = 0; row < _syncOptions.length; row += 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      child:
                          row + column < _syncOptions.length
                              ? _buildSyncOptionItem(_syncOptions[row + column])
                              : const SizedBox(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOptionItem(SyncOption option) {
    final isCoconutWalletRegtest =
        option.format == WalletExportFormatEnum.coconut && NetworkType.currentNetworkType.isTestnet;

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
              if (isCoconutWalletRegtest)
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: CoconutColors.gray800, borderRadius: BorderRadius.circular(12)),
                  child: SvgPicture.asset(option.iconPath),
                )
              else
                SizedBox(width: 36, height: 36, child: SvgPicture.asset(option.iconPath)),
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
  final WalletApp? app;
  final String iconPath;
  final WalletExportFormatEnum format;

  SyncOption({required this.title, required this.iconPath, required this.format, this.app});
}
