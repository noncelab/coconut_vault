import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SelectExternalWalletBottomSheet extends StatefulWidget {
  final List<ExternalWalletButton> externalWalletButtonList;
  final int? selectedIndex;
  final Function(int) onSelected;
  const SelectExternalWalletBottomSheet({
    super.key,
    required this.externalWalletButtonList,
    this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<SelectExternalWalletBottomSheet> createState() => _SelectExternalWalletBottomSheetState();
}

class _SelectExternalWalletBottomSheetState extends State<SelectExternalWalletBottomSheet> {
  int? selectedIndex;
  int? _committedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
    _committedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        customTitle: Text(t.multi_sig_setting_screen.add_icon.title, style: CoconutTypography.body1_16_Bold),
        context: context,
        isBottom: true,
        height: kToolbarHeight,
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
              isActive: selectedIndex != _committedIndex,
              onButtonClicked: () {
                if (selectedIndex == null || selectedIndex! >= widget.externalWalletButtonList.length) {
                  return;
                }

                final selectedButton = widget.externalWalletButtonList[selectedIndex!];
                final hwwName = selectedButton.name;
                // 선택 확정 및 콜백 호출을 다이얼로그보다 먼저 실행
                setState(() {
                  _committedIndex = selectedIndex;
                  widget.onSelected(selectedIndex!);
                });

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return CoconutPopup(
                      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
                      title: t.multi_sig_setting_screen.popup.title(name: hwwName),
                      description: t.multi_sig_setting_screen.popup.description(name: hwwName),
                      rightButtonText: t.multi_sig_setting_screen.popup.button,
                      onTapRight: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
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
              child: Text(
                button.name,
                style: CoconutTypography.body2_14.merge(const TextStyle(height: 1.2)),
                textAlign: TextAlign.center,
              ),
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
