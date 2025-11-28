import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/icon_path.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SelectExternalWalletBottomSheet extends StatefulWidget {
  final List<ExternalWalletButton> externalWalletButtonList;
  final int? selectedIndex;
  const SelectExternalWalletBottomSheet({super.key, required this.externalWalletButtonList, this.selectedIndex});

  @override
  State<SelectExternalWalletBottomSheet> createState() => _SelectExternalWalletBottomSheetState();
}

class _SelectExternalWalletBottomSheetState extends State<SelectExternalWalletBottomSheet> {
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        customTitle: Text(t.multi_sig_setting_screen.add_icon.title, style: CoconutTypography.body1_16_Bold),
        context: context,
        isBottom: true,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: _buildWalletButtonRows(),
              ),
            ),
            FixedBottomButton(
              text: t.complete,
              showGradient: false,
              isActive: selectedIndex != widget.selectedIndex,
              onButtonClicked: () {
                if (selectedIndex == null || selectedIndex! >= widget.externalWalletButtonList.length) {
                  return;
                }

                final signerSource = _getSignerSourceByIconSource();
                final selectedButton = widget.externalWalletButtonList[selectedIndex!];
                final hwwName = selectedButton.name;

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CoconutPopup(
                      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
                      title: t.multi_sig_setting_screen.add_icon_complete,
                      description: t.multi_sig_setting_screen.add_icon_complete_description(name: hwwName),
                      rightButtonText: t.confirm,
                      onTapRight: () {
                        Navigator.pop(context);
                        Navigator.pop(context, signerSource);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  SignerSource? _getSignerSourceByIconSource() {
    if (selectedIndex == null || selectedIndex! >= widget.externalWalletButtonList.length) {
      return null;
    }

    final selectedButton = widget.externalWalletButtonList[selectedIndex!];
    final iconSource = selectedButton.iconSource;

    switch (iconSource) {
      case kCoconutVaultIconPath:
        return SignerSource.coconutvault;
      case kKeystoneIconPath:
        return SignerSource.keystone3pro;
      case kSeedSignerIconPath:
        return SignerSource.seedsigner;
      case kJadeIconPath:
        return SignerSource.jade;
      case kColdCardIconPath:
        return SignerSource.coldcard;
      case kKruxIconPath:
        return SignerSource.krux;
      default:
        return null;
    }
  }

  List<Widget> _buildWalletButtonRows() {
    const int itemsPerRow = 3;
    final List<Widget> rows = [];

    for (int i = 0; i < widget.externalWalletButtonList.length; i += itemsPerRow) {
      final endIndex =
          (i + itemsPerRow < widget.externalWalletButtonList.length)
              ? i + itemsPerRow
              : widget.externalWalletButtonList.length;

      final List<Widget> rowChildren = [];
      for (int j = i; j < endIndex; j++) {
        rowChildren.add(Expanded(child: _buildWalletIconShrinkButton(widget.externalWalletButtonList[j], j)));
      }

      while (rowChildren.length < itemsPerRow) {
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: rowChildren));

      if (endIndex < widget.externalWalletButtonList.length) {
        rows.add(CoconutLayout.spacing_300h);
      }
    }

    return rows;
  }

  Widget _buildWalletIconShrinkButton(ExternalWalletButton button, int index) {
    return ShrinkAnimationButton(
      border: Border.all(color: selectedIndex == index ? CoconutColors.gray700 : CoconutColors.white, width: 1.5),
      borderRadius: 12,
      onPressed: () => setState(() => selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            SvgPicture.asset(button.iconSource),
            CoconutLayout.spacing_100h,
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(button.name, style: CoconutTypography.body2_14, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class ExternalWalletButton {
  final String name;
  final String iconSource;

  ExternalWalletButton({required this.name, required this.iconSource});
}
