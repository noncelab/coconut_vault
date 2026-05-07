import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaprootVaultItemCard extends StatefulWidget {
  final VaultListItemBase vaultItem;
  final bool showTaprootWalletInfo;

  const TaprootVaultItemCard({super.key, required this.vaultItem, required this.showTaprootWalletInfo});

  @override
  State<TaprootVaultItemCard> createState() => _TaprootVaultItemCardState();
}

class _TaprootVaultItemCardState extends State<TaprootVaultItemCard> {
  @override
  Widget build(BuildContext context) {
    assert(widget.vaultItem is TaprootVaultListItem, 'vaultItem must be of type TaprootVaultListItem');
    final bool isParent = (widget.vaultItem as TaprootVaultListItem).isParent;

    //TODO: 지갑 종류에 따라 텍스트가 더 추가될 수 있음.
    String descriptionText = isParent ? t.taproot_vault_detail_screen.cosigner : t.taproot_vault_detail_screen.heir;

    List<Color> baseGradientColors = [
      CoconutColors.lightSky.withValues(alpha: 0.2),
      CoconutColors.periwinkle.withValues(alpha: 0.2),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoconutColors.gray200, width: 1),
        gradient: LinearGradient(
          colors: isParent ? baseGradientColors.reversed.toList() : baseGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildIcon(),
                      CoconutLayout.spacing_300w,
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                              child: Text(
                                widget.vaultItem.name,
                                style: CoconutTypography.body2_14_Bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showTaprootWalletInfo) ...[
                  CoconutLayout.spacing_200w,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildDateTime()],
                  ),
                ],
              ],
            ),
            if (widget.showTaprootWalletInfo) ...[const SizedBox(height: 16), _buildDescriptionText(descriptionText)],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTime() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              DateFormat('yy.MM.dd HH:mm').format(widget.vaultItem.createdAt),
              style: CoconutTypography.body3_12.setColor(CoconutColors.gray700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionText(String text) {
    final pattern = RegExp(r'共同署名者|공동 서명자|cosigner|상속자|相続人|heir', caseSensitive: false);
    final match = pattern.firstMatch(text);

    if (match == null) {
      return Text(text, style: CoconutTypography.body3_12.setColor(CoconutColors.gray800));
    }

    return RichText(
      text: TextSpan(
        style: CoconutTypography.body3_12.setColor(CoconutColors.gray800),
        children: [
          TextSpan(text: text.substring(0, match.start)),
          TextSpan(text: match.group(0), style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.gray800)),
          TextSpan(text: text.substring(match.end)),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final int colorIndex = widget.vaultItem.colorIndex;
    final int iconIndex = widget.vaultItem.iconIndex;

    return VaultIcon(iconIndex: iconIndex, colorIndex: colorIndex);
  }
}
