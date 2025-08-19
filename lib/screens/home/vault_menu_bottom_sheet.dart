import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/screens/common/multisig_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/passphrase_check_screen.dart';

import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';

const double iconSize = 16;

const iconColorList = <ColorFilter>[
  ColorFilter.mode(Color.fromRGBO(0, 91, 53, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(17, 114, 0, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(153, 43, 0, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(126, 15, 19, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(93, 59, 120, 1.0), BlendMode.srcIn),
  ColorFilter.mode(Color.fromRGBO(59, 81, 120, 1.0), BlendMode.srcIn),
];

const iconBackgroundColorList = <Color>[
  Color.fromRGBO(216, 244, 234, 1.0),
  Color.fromRGBO(219, 242, 201, 1.0),
  Color.fromRGBO(254, 231, 213, 1.0),
  Color.fromRGBO(254, 216, 217, 1.0),
  Color.fromRGBO(226, 208, 255, 1.0),
  Color.fromRGBO(208, 232, 255, 1.0),
];

class VaultMenuBottomSheet extends StatelessWidget {
  final int id;
  final bool isMultiSig;
  final bool hasPassphrase;
  final BuildContext parentContext;

  const VaultMenuBottomSheet(
      {super.key,
      required this.id,
      this.isMultiSig = false,
      required this.hasPassphrase,
      required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(builder: (ctx, model, child) {
      final vaultListItem = model.getVaultById(id);
      final buttons = isMultiSig
          ? _multiSigButtons(context, vaultListItem)
          : _singleSigButtons(context, vaultListItem);

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Column(
              children: buttons.expand((button) => [button, bottomMenuDivider()]).toList()
                ..removeLast(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildButton(BuildContext context, String iconPath, ColorFilter color, Color bgColor,
      String title, String desc, String route,
      {Map<String, dynamic>? extraArgs}) {
    return VaultMenuButton(
      icon: SvgPicture.asset('assets/svg/menu/$iconPath', width: iconSize, colorFilter: color),
      title: title,
      description: desc,
      iconBackgroundColor: bgColor,
      onPressed: () async {
        // 볼트 메뉴 바텀시트 없애기
        Navigator.pop(context);

        // 지갑 정보 내보내기 메뉴인데 패스프레이즈를 사용하는 경우, 확인하고 맞으면 진행한다.
        if (route == AppRoutes.syncToWallet && hasPassphrase) {
          final result = await MyBottomSheet.showBottomSheet_50<String?>(
              context: parentContext, child: PassphraseCheckScreen(id: id));
          if (result != null) {
            Navigator.pushNamed(parentContext, route, arguments: {'id': id, ...?extraArgs});
          }
        } else {
          Navigator.pushNamed(parentContext, route, arguments: {'id': id, ...?extraArgs});
        }
      },
    );
  }

  List<Widget> _multiSigButtons(BuildContext context, VaultListItemBase vault) {
    return [
      _buildButton(
          context,
          'details.svg',
          iconColorList[0],
          iconBackgroundColorList[0],
          t.vault_menu_screen.title.view_info(name: TextUtils.ellipsisIfLonger(vault.name)),
          t.vault_menu_screen.description.view_multisig_info,
          AppRoutes.multisigSetupInfo),
      _buildButton(
          context,
          '2keys.svg',
          iconColorList[1],
          iconBackgroundColorList[1],
          t.vault_menu_screen.title.multisig_sign,
          t.vault_menu_screen.description.sign,
          AppRoutes.psbtScanner),
      _buildButton(
          context,
          'address.svg',
          iconColorList[2],
          iconBackgroundColorList[2],
          t.vault_menu_screen.title.view_address,
          t.vault_menu_screen.description
              .view_address(name: TextUtils.ellipsisIfLonger(vault.name)),
          AppRoutes.addressList),
      _buildButton(
          context,
          'out.svg',
          iconColorList[3],
          iconBackgroundColorList[3],
          t.vault_menu_screen.title.export_xpub,
          t.vault_menu_screen.description.export_xpub,
          AppRoutes.syncToWallet),
    ];
  }

  List<Widget> _singleSigButtons(BuildContext context, VaultListItemBase vault) {
    return [
      _buildButton(
          context,
          'details.svg',
          iconColorList[0],
          iconBackgroundColorList[0],
          t.vault_menu_screen.title.view_info(name: TextUtils.ellipsisIfLonger(vault.name)),
          t.vault_menu_screen.description.view_single_sig_info,
          AppRoutes.singleSigSetupInfo),
      _buildButton(
          context,
          'key-outline.svg',
          iconColorList[1],
          iconBackgroundColorList[1],
          t.vault_menu_screen.title.single_sig_sign,
          t.vault_menu_screen.description.sign,
          AppRoutes.psbtScanner),
      _buildButton(
          context,
          'address.svg',
          iconColorList[2],
          iconBackgroundColorList[2],
          t.vault_menu_screen.title.view_address,
          t.vault_menu_screen.description
              .view_address(name: TextUtils.ellipsisIfLonger(vault.name)),
          AppRoutes.addressList),
      _buildButton(
          context,
          'out.svg',
          iconColorList[3],
          iconBackgroundColorList[3],
          t.vault_menu_screen.title.export_xpub,
          t.vault_menu_screen.description.export_xpub,
          AppRoutes.syncToWallet),
      _buildButton(
          context,
          'key-out.svg',
          iconColorList[4],
          iconBackgroundColorList[4],
          t.vault_menu_screen.title.use_as_multisig_signer,
          t.vault_menu_screen.description.use_as_multisig_signer,
          AppRoutes.multisigSignerBsmsExport),
      _buildButton(
          context,
          'in.svg',
          iconColorList[5],
          iconBackgroundColorList[5],
          t.vault_menu_screen.title.import_bsms,
          t.vault_menu_screen.description.import_bsms,
          AppRoutes.signerBsmsScanner,
          extraArgs: {'screenType': MultisigBsmsImportType.copy}),
    ];
  }

  Widget bottomMenuDivider() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Divider(
        height: 0,
        color: CoconutColors.gray150,
      ));
}

Widget bottomMenuButton(SvgPicture icon, String title, String description, VoidCallback onPressed,
        Color iconBackgroundColor) =>
    ShrinkAnimationButton(
      onPressed: onPressed,
      defaultColor: CoconutColors.white,
      pressedColor: CoconutColors.gray500.withOpacity(0.07),
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                  color: iconBackgroundColor, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: icon,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: CoconutTypography.body2_14.merge(
                    const TextStyle(
                      fontSize: 13,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  description,
                  style: CoconutTypography.body2_14.merge(
                    TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CoconutColors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

class VaultMenuButton extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;
  final Color iconBackgroundColor;
  final VoidCallback onPressed;

  const VaultMenuButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconBackgroundColor,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShrinkAnimationButton(
      onPressed: onPressed,
      defaultColor: CoconutColors.white,
      pressedColor: CoconutColors.gray500.withOpacity(0.07),
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                  color: iconBackgroundColor, borderRadius: BorderRadius.circular(14)),
              child: Center(child: icon),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: CoconutTypography.body2_14
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(description,
                  style: TextStyle(fontSize: 11, color: CoconutColors.black.withOpacity(0.7))),
            ]),
          ],
        ),
      ),
    );
  }
}
