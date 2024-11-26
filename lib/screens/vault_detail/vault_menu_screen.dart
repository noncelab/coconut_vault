import 'package:coconut_vault/model/data/vault_list_item_base.dart';

import 'package:coconut_vault/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';

const double iconSize = 16;

const iconColorList = <ColorFilter>[
  ColorFilter.mode(Color.fromRGBO(93, 59, 120, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(0, 91, 53, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(17, 114, 0, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(153, 43, 0, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(126, 15, 19, 1.0), BlendMode.srcIn),
];

const iconBackgroundColorList = <Color>[
  Color.fromRGBO(226, 208, 255, 1.0),
  Color.fromRGBO(216, 244, 234, 1.0),
  Color.fromRGBO(219, 242, 201, 1.0),
  Color.fromRGBO(254, 231, 213, 1.0),
  Color.fromRGBO(254, 216, 217, 1.0),
];

class VaultMenuScreen extends StatefulWidget {
  final int id;
  final bool isMultiSig;

  const VaultMenuScreen({super.key, required this.id, this.isMultiSig = false});

  @override
  State<VaultMenuScreen> createState() => _VaultMenuScreenState();
}

class _VaultMenuScreenState extends State<VaultMenuScreen> {
  // usedAccounts: segwit / legacy

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(builder: (context, model, child) {
      final VaultListItemBase vaultListItem = model.getVaultById(widget.id);

      if (!widget.isMultiSig) {
        return Container(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(children: [
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/details.svg',
                    width: iconSize, colorFilter: iconColorList[1]),
                '${TextUtils.ellipsisIfLonger(vaultListItem.name)} 정보',
                '저장된 니모닉 문구 등을 확인할 수 있어요', () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/vault-settings',
                arguments: {'id': widget.id},
              );
            }, iconBackgroundColorList[1]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/key-outline.svg',
                    width: iconSize, colorFilter: iconColorList[2]),
                '서명하기',
                '월렛에서 만든 정보를 스캔하고 서명해요', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/psbt-scanner',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[2]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/address.svg',
                    width: iconSize, colorFilter: iconColorList[3]),
                '주소 보기',
                '${TextUtils.ellipsisIfLonger(vaultListItem.name)}에서 추출한 주소를 확인해요',
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/address-list',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[3]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/out.svg',
                    width: iconSize, colorFilter: iconColorList[4]),
                '내보내기',
                '보기 전용 지갑을 추가하거나 다중 서명 지갑의 키로 사용해요', () {
              Navigator.pop(context);

              Navigator.pushNamed(context, '/select-sync-type',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[4]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/in.svg',
                    width: iconSize, colorFilter: iconColorList[0]),
                '다중 서명 지갑 가져오기',
                '이 키가 포함된 다중 서명 지갑 정보를 추가해요', () async {
              Navigator.pop(context);

              Navigator.pushNamed(context, '/signer-scanner',
                  arguments: {'id': widget.id, 'isCopy': true});
            }, iconBackgroundColorList[0]),
          ]),
        );
      } else {
        return Container(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(children: [
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/details.svg',
                    width: iconSize, colorFilter: iconColorList[1]),
                '${TextUtils.ellipsisIfLonger(vaultListItem.name)} 정보',
                '다중 서명 지갑의 정보를 확인할 수 있어요 ', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/multisig-setting',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[1]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/2keys.svg',
                    width: iconSize, colorFilter: iconColorList[2]),
                '다중 서명하기',
                '전송 정보를 스캔하고 서명해요', () {
              Navigator.pop(context);
              // TODO: 스캐너 이동 로직 추가 필요함
              model.testChangeMultiSig(true);
              // Navigator.pushNamed(
              //   context,
              //   '/psbt-scanner',
              //   arguments: {'id': '${vaults.first.id}'},
              // );
              Navigator.pushNamed(
                context,
                '/multi-signature',
                arguments: {
                  'sendAddress': 'bcrt1qr97x085t309sfya99yc0mc0p4yx8x4rmm4mncz',
                  'bitcoinString': '0.0100 0000',
                },
              );
            }, iconBackgroundColorList[2]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/address.svg',
                    width: iconSize, colorFilter: iconColorList[3]),
                '주소 보기',
                '${vaultListItem.name.length > 10 ? '${vaultListItem.name.substring(0, 7)}...' : vaultListItem.name}에서 추출한 주소를 확인해요',
                () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/address-list',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[3]),
            bottomMenuDivider(),
            bottomMenuButton(
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
      }
    });
  }
}

Widget bottomMenuDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Divider(
      height: 0,
      color: MyColors.lightgrey,
    ));

Widget bottomMenuButton(SvgPicture icon, String title, String description,
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
