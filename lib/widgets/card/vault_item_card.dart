import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VaultItemCard extends StatelessWidget {
  final VaultListItemBase vaultItem;
  final VoidCallback onTooltipClicked;
  final VoidCallback onNameChangeClicked;
  final GlobalKey tooltipKey;

  const VaultItemCard({
    super.key,
    required this.vaultItem,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
    required this.tooltipKey,
  });

  @override
  Widget build(BuildContext context) {
    List<MultisigSigner>? signers;
    bool isMultisig = false;
    late int colorIndex;
    late int iconIndex;
    late String rightText;
    late String tooltipText;

    if (vaultItem is MultisigVaultListItem) {
      /// 멀티 시그
      MultisigVaultListItem multiVault = vaultItem as MultisigVaultListItem;
      signers = multiVault.signers;
      colorIndex = multiVault.colorIndex;
      iconIndex = multiVault.iconIndex;
      int innerSignerCount = multiVault.signers.where((s) => s.innerVaultId != null).length;
      rightText =
          '${innerSignerCount > multiVault.requiredSignatureCount ? multiVault.requiredSignatureCount : innerSignerCount}개 서명 가능';

      tooltipText = '${multiVault.requiredSignatureCount}/${multiVault.signers.length}';
      isMultisig = true;
    } else {
      /// 싱글 시그
      SingleSigVaultListItem singleVault = vaultItem as SingleSigVaultListItem;
      final singlesigVault = singleVault.coconutVault as SingleSignatureVault;
      colorIndex = singleVault.colorIndex;
      iconIndex = singleVault.iconIndex;
      rightText = singlesigVault.keyStore.masterFingerprint;
      tooltipText = '지갑 ID';
    }

    return Container(
      margin: isMultisig
          ? const EdgeInsets.only(top: 20, left: 16, right: 16)
          : const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
          border: isMultisig ? null : Border.all(color: CoconutColors.borderLightGray, width: 1),
          gradient: isMultisig
              ? BoxDecorations.getMultisigLinearGradient(
                  CustomColorHelper.getGradientColors(signers!))
              : null),
      child: Container(
        margin: isMultisig ? const EdgeInsets.all(2) : null,
        padding: isMultisig ? const EdgeInsets.all(20) : const EdgeInsets.all(24),
        decoration: isMultisig
            ? BoxDecoration(
                color: CoconutColors.white,
                borderRadius: BorderRadius.circular(26), // defaultRadius로 통일하면 border 넓이가 균일해보이지 않음
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BackgroundColorPalette[colorIndex],
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: SvgPicture.asset(CustomIcons.getPathByIndex(iconIndex),
                    colorFilter: ColorFilter.mode(ColorPalette[colorIndex], BlendMode.srcIn),
                    width: 28.0)),
            const SizedBox(width: 8.0),
            Flexible(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                        child: Text(
                      vaultItem.name,
                      style: Styles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 7),
                    GestureDetector(
                        onTap: () {
                          onNameChangeClicked();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8), color: CoconutColors.gray150),
                          child: const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.edit,
                              color: CoconutColors.gray800,
                              size: 14,
                            ),
                          ),
                        ))
                  ]),
                ],
              ),
            ),
            const Spacer(
              flex: 1,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rightText,
                  style: isMultisig
                      ? TextStyle(
                          fontFamily: CustomFonts.number.getFontFamily,
                          color: CoconutColors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)
                      : Styles.h3.merge(TextStyle(fontFamily: CustomFonts.number.getFontFamily)),
                ),
                TooltipButton(
                  isSelected: false,
                  text: tooltipText,
                  isLeft: true,
                  iconkey: tooltipKey,
                  containerMargin: EdgeInsets.zero,
                  onTap: () {},
                  onTapDown: (details) {
                    onTooltipClicked();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
