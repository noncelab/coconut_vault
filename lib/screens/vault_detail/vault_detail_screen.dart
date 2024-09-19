import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/model/vault_list_item.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';

class VaultDetails extends StatefulWidget {
  final String id;

  const VaultDetails({super.key, required this.id});

  @override
  State<VaultDetails> createState() => _VaultDetailsState();
}

class _VaultDetailsState extends State<VaultDetails> {
  // usedAccounts: segwit / legacy

  final double iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(builder: (context, model, child) {
      final VaultListItem vaultListItem =
          model.getVaultById(int.parse(widget.id));
      return Container(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(children: [
          _Button(
              SvgPicture.asset('assets/svg/menu/details.svg',
                  width: iconSize, colorFilter: iconColorList[1]),
              '${vaultListItem.name.length > 10 ? '${vaultListItem.name.substring(0, 7)}...' : vaultListItem.name} 정보',
              '저장된 니모닉 문구 등을 확인할 수 있어요', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/vault-settings',
                arguments: {'id': widget.id});
          }, iconBackgroundColorList[1]),
          _Divider(),
          _Button(
              SvgPicture.asset('assets/svg/menu/key-outline.svg',
                  width: iconSize, colorFilter: iconColorList[2]),
              '서명하기',
              '월렛에서 만든 정보를 스캔하고 서명해요', () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/psbt-scanner',
                arguments: {'id': widget.id});
          }, iconBackgroundColorList[2]),
          _Divider(),
          _Button(
              SvgPicture.asset('assets/svg/menu/address.svg',
                  width: iconSize, colorFilter: iconColorList[3]),
              '주소 보기',
              '${vaultListItem.name.length > 10 ? '${vaultListItem.name.substring(0, 7)}...' : vaultListItem.name}에서 추출한 주소를 확인해요',
              () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/address-list',
                arguments: {'id': widget.id});
          }, iconBackgroundColorList[3]),
          _Divider(),
          _Button(
              SvgPicture.asset('assets/svg/menu/out.svg',
                  width: iconSize, colorFilter: iconColorList[4]),
              '내보내기',
              '보기 전용 지갑을 월렛에 추가해요', () {
            Navigator.pop(context);

            Navigator.pushNamed(context, '/sync-to-wallet',
                arguments: {'id': widget.id});
          }, iconBackgroundColorList[4]),
        ]),
      );
    });
  }

  final iconColorList = <ColorFilter>[
    const ColorFilter.mode(Color.fromRGBO(107, 9, 195, 1.0), BlendMode.srcIn),
    const ColorFilter.mode(Color.fromRGBO(0, 91, 53, 1.0), BlendMode.srcIn),
    const ColorFilter.mode(Color.fromRGBO(17, 114, 0, 1.0), BlendMode.srcIn),
    const ColorFilter.mode(Color.fromRGBO(153, 43, 0, 1.0), BlendMode.srcIn),
    const ColorFilter.mode(Color.fromRGBO(126, 15, 19, 1.0), BlendMode.srcIn),
  ];

  final iconBackgroundColorList = <Color>[
    const Color.fromRGBO(235, 223, 249, 1.0),
    const Color.fromRGBO(216, 244, 234, 1.0),
    const Color.fromRGBO(219, 242, 201, 1.0),
    const Color.fromRGBO(254, 231, 213, 1.0),
    const Color.fromRGBO(254, 216, 217, 1.0),
  ];

  Widget _Divider() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Divider(
        height: 0,
        color: MyColors.lightgrey,
      ));

  Widget _Button(SvgPicture icon, String title, String description,
          VoidCallback onPressed, Color iconBackgroundColor) =>
      ShrinkAnimationButton(
          onPressed: onPressed,
          defaultColor: MyColors.white,
          pressedColor: MyColors.grey.withOpacity(0.07),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(child: icon)),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: Styles.body2.merge(const TextStyle(
                          fontFamily: 'Pretendard',
                          color: MyColors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
                  Text(description,
                      style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          color: MyColors.transparentBlack_70)),
                ]),
              ])));
}
