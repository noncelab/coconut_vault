import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/vault_detail/vault_detail_screen.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';

import '../model/vault_list_item.dart';
import '../styles.dart';

class VaultRowItem extends StatefulWidget {
  const VaultRowItem({super.key, required this.vault});

  final VaultListItem vault;

  @override
  State<VaultRowItem> createState() => _VaultRowItemState();
}

class _VaultRowItemState extends State<VaultRowItem> {
  @override
  Widget build(BuildContext context) {
    final row = ShrinkAnimationButton(
        pressedColor: MyColors.darkgrey.withOpacity(0.05),
        onPressed: () {
          MyBottomSheet.showBottomSheet(
              context: context,
              title: widget.vault.name.length > 20
                  ? '${widget.vault.name.substring(0, 17)}...'
                  : widget.vault.name,
              child: VaultDetails(id: widget.vault.id.toString()));
        },
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Row(children: [
              // 1) 아이콘
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BackgroundColorPalette[widget.vault.colorIndex],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: SvgPicture.asset(
                      CustomIcons.getPathByIndex(widget.vault.iconIndex),
                      colorFilter: ColorFilter.mode(
                          ColorPalette[widget.vault.colorIndex],
                          BlendMode.srcIn),
                      width: 20.0)),
              const SizedBox(width: 8.0),
              // 2) 이름
              Expanded(
                child: Text(
                  widget.vault.name,
                  style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: MyColors.black,
                      letterSpacing: 0.2),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              // 3) 오른쪽 화살표
              SvgPicture.asset('assets/svg/arrow-right.svg',
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                      MyColors.darkgrey, BlendMode.srcIn))
            ])));

    return Column(
      children: [
        row,
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}
