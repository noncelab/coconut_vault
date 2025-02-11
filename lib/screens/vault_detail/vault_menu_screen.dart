import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_scanner_screen.dart';

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
  ColorFilter.mode(Color.fromRGBO(59, 81, 120, 1.0), BlendMode.srcIn),
];

const iconBackgroundColorList = <Color>[
  Color.fromRGBO(226, 208, 255, 1.0),
  Color.fromRGBO(216, 244, 234, 1.0),
  Color.fromRGBO(219, 242, 201, 1.0),
  Color.fromRGBO(254, 231, 213, 1.0),
  Color.fromRGBO(254, 216, 217, 1.0),
  Color.fromRGBO(208, 232, 255, 1.0),
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
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Column(children: [
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/details.svg',
                    width: iconSize, colorFilter: iconColorList[1]),
                t.vault_menu_screen.title.menu1(
                    name: TextUtils.ellipsisIfLonger(vaultListItem.name)),
                t.vault_menu_screen.description.menu1, () {
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
                t.vault_menu_screen.title.menu2,
                t.vault_menu_screen.description.menu2, () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/psbt-scanner',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[2]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/address.svg',
                    width: iconSize, colorFilter: iconColorList[3]),
                t.vault_menu_screen.title.menu3,
                t.vault_menu_screen.description.menu3(
                    name: TextUtils.ellipsisIfLonger(vaultListItem.name)), () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/address-list',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[3]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/out.svg',
                    width: iconSize, colorFilter: iconColorList[4]),
                t.vault_menu_screen.title.menu4,
                t.vault_menu_screen.description.menu4, () {
              Navigator.pop(context);

              Navigator.pushNamed(context, '/sync-to-wallet',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[4]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/key-out.svg',
                    width: iconSize, colorFilter: iconColorList[0]),
                t.vault_menu_screen.title.menu5,
                t.vault_menu_screen.description.menu5, () {
              Navigator.pop(context);

              Navigator.pushNamed(context, '/signer-bsms',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[0]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/in.svg',
                    width: iconSize, colorFilter: iconColorList[5]),
                t.vault_menu_screen.title.menu6,
                t.vault_menu_screen.description.menu6, () async {
              Navigator.pop(context);

              Navigator.pushNamed(
                context,
                '/signer-scanner',
                arguments: {
                  'id': widget.id,
                  'screenType': SignerScannerScreenType.copy,
                },
              );
            }, iconBackgroundColorList[5]),
          ]),
        );
      } else {
        return Container(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
          child: Column(children: [
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/details.svg',
                    width: iconSize, colorFilter: iconColorList[1]),
                t.vault_menu_screen.title.menu7(
                    name: TextUtils.ellipsisIfLonger(vaultListItem.name)),
                t.vault_menu_screen.description.menu7, () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/multisig-setting',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[1]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/2keys.svg',
                    width: iconSize, colorFilter: iconColorList[2]),
                t.vault_menu_screen.title.menu8,
                t.vault_menu_screen.description.menu8, () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/psbt-scanner',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[2]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/address.svg',
                    width: iconSize, colorFilter: iconColorList[3]),
                t.vault_menu_screen.title.menu3,
                t.vault_menu_screen.description.menu3(
                    name: TextUtils.ellipsisIfLonger(vaultListItem.name)), () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/address-list',
                  arguments: {'id': widget.id});
            }, iconBackgroundColorList[3]),
            bottomMenuDivider(),
            bottomMenuButton(
                SvgPicture.asset('assets/svg/menu/out.svg',
                    width: iconSize, colorFilter: iconColorList[4]),
                t.vault_menu_screen.title.menu4,
                t.vault_menu_screen.description.menu4, () {
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
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
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
                    maxLines: 1,
                    style: Styles.body2.merge(const TextStyle(
                        fontFamily: 'Pretendard',
                        color: MyColors.black,
                        fontSize: 13,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w500))),
                Text(description,
                    style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        color: MyColors.transparentBlack_70)),
              ]),
            ])));
