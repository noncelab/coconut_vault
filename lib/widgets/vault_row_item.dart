import 'package:coconut_vault/utils/colors_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/screens/vault_detail/vault_menu_screen.dart';
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
  // TODO : 추후 로직 변경될 수 있음
  bool _isMultiSig = false;
  bool _isUsedToMultiSig = false;

  @override
  void initState() {
    super.initState();

    // TODO : 볼트 속성 업데이트
    _isMultiSig = false;
    _isUsedToMultiSig = true;
  }

  @override
  Widget build(BuildContext context) {
    final row = ShrinkAnimationButton(
        pressedColor: MyColors.darkgrey.withOpacity(0.05),
        borderGradientColors: _isMultiSig
            ? [
                CustomColorHelper.getColorByIndex(0),
                MyColors.borderLightgrey,
                CustomColorHelper.getColorByIndex(4),
              ]
            : null,
        onPressed: () {
          // TODO: UI 확인용, 추후 변경 필요함
          if (_isMultiSig) {
            Navigator.pushNamed(context, '/multisig-setting',
                arguments: {'id': '${widget.vault.id}'});
          } else {
            MyBottomSheet.showBottomSheet(
              context: context,
              title: widget.vault.name.length > 20
                  ? '${widget.vault.name.substring(0, 17)}...'
                  : widget.vault.name,
              child: VaultMenuScreen(
                  id: widget.vault.id.toString(), isMultisig: _isMultiSig),
            );
          }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: M/N, 다중 지갑의 N키 처리 필요 (지갑명 10글자 말줄임)
                    if (_isMultiSig) ...{
                      Text(
                        '2/3',
                        style: Styles.body2.copyWith(color: MyColors.body2Grey),
                      ),
                    } else if (_isUsedToMultiSig) ...{
                      Text(
                        '다중다중 지갑의 2번 키',
                        style: Styles.body2.copyWith(color: MyColors.body2Grey),
                      ),
                    },
                    Text(
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
                  ],
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
