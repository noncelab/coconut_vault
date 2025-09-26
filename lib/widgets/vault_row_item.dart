import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/icon/vault_icon_small.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class VaultRowItem extends StatefulWidget {
  const VaultRowItem({
    super.key,
    required this.vault,
    this.entryPoint,
    this.isSelectable = false,
    this.onSelected,
    this.isPressed = false,
    this.isStarVisible = false,
    this.isFavorite = false,
    this.isPrimaryWallet,
    this.isEditMode = false,
    this.isLastItem,
    this.onTapStar,
    this.onLongPressed,
    this.index,
    this.isNextIconVisible = true,
    this.isKeyBorderVisible = false,
    this.isSelected = false,
    this.enableShotenName = true,
  });

  final VaultListItemBase vault;
  final bool isSelectable;
  final VoidCallback? onSelected;
  final bool isPressed;
  final bool isStarVisible;
  final bool isFavorite;
  final bool? isPrimaryWallet;
  final bool isEditMode;
  final bool? isLastItem;
  final ValueChanged<(bool, int)>? onTapStar;
  final String? entryPoint;
  final VoidCallback? onLongPressed;
  final int? index;
  final bool isNextIconVisible;
  final bool isKeyBorderVisible;
  final bool isSelected;
  final bool enableShotenName;

  /// 스켈레톤 UI를 반환하는 static 메서드
  static Widget buildSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 37),
        child: Row(
          children: [
            // 1) 아이콘 스켈레톤 (VaultItemIcon과 동일한 크기)
            Shimmer.fromColors(
              baseColor: CoconutColors.gray300,
              highlightColor: CoconutColors.gray150,
              child: Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(color: CoconutColors.gray300, borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(width: 8.0),
            // 2) 텍스트 영역 (VaultRowItem의 Expanded 영역과 동일)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지갑 이름 스켈레톤
                  Shimmer.fromColors(
                    baseColor: CoconutColors.gray300,
                    highlightColor: CoconutColors.gray150,
                    child: Container(
                      height: 16.0,
                      width: 120.0,
                      decoration: BoxDecoration(color: CoconutColors.gray300, borderRadius: BorderRadius.circular(4.0)),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  // 서브타이틀 스켈레톤 (멀티시그 정보 또는 기본 지갑 표시)
                  Shimmer.fromColors(
                    baseColor: CoconutColors.gray300,
                    highlightColor: CoconutColors.gray150,
                    child: Container(
                      height: 12.0,
                      width: 80.0,
                      decoration: BoxDecoration(color: CoconutColors.gray300, borderRadius: BorderRadius.circular(4.0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // 3) 화살표 아이콘 스켈레톤 (chevron-right와 동일한 크기)
            Shimmer.fromColors(
              baseColor: CoconutColors.gray300,
              highlightColor: CoconutColors.gray150,
              child: Container(
                width: 6.0,
                height: 10.0,
                decoration: BoxDecoration(color: CoconutColors.gray300, borderRadius: BorderRadius.circular(1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<VaultRowItem> createState() => _VaultRowItemState();
}

class _VaultRowItemState extends State<VaultRowItem> {
  bool isPressing = false;

  bool _isMultiSig = false;
  String _subtitleText = '';
  bool _isUsedToMultiSig = false;
  List<MultisigSigner>? _multiSigners;
  bool hasPassphrase = false;

  Future<void> checkPassphraseStatus() async {
    hasPassphrase = await context.read<WalletProvider>().hasPassphrase(widget.vault.id);
  }

  @override
  void initState() {
    super.initState();
    checkPassphraseStatus();
  }

  void _updateVault() {
    _isMultiSig = false;
    _subtitleText = '';
    _isUsedToMultiSig = false;
    _multiSigners = null;

    if (widget.vault.vaultType == WalletType.multiSignature) {
      _isMultiSig = true;
      final multi = widget.vault as MultisigVaultListItem;
      _subtitleText = '${multi.requiredSignatureCount}/${multi.signers.length}';
      _multiSigners = multi.signers;
    } else {
      final single = widget.vault as SingleSigVaultListItem;
      if (single.linkedMultisigInfo != null) {
        final multisigKey = single.linkedMultisigInfo!;
        if (multisigKey.keys.isNotEmpty) {
          final model = Provider.of<WalletProvider>(context, listen: false);
          try {
            final multisig = model.getVaultById(multisigKey.keys.first);
            _subtitleText = t.wallet_subtitle(
              name: TextUtils.ellipsisIfLonger(multisig.name),
              index: multisigKey.values.first + 1,
            );
            _isUsedToMultiSig = true;
          } catch (_) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateVault();

    if (widget.isEditMode) {
      return _buildVaultContainerWidget(
        onTapStar: (pair) {
          if (widget.isPrimaryWallet != null) {
            widget.onTapStar?.call(pair);
          }
        },
        index: widget.index,
      );
    }
    return ShrinkAnimationButton(
      pressedColor: CoconutColors.gray150,
      borderGradientColors: widget.isKeyBorderVisible
          ? [CoconutColors.black.withValues(alpha: 0.08), CoconutColors.black.withValues(alpha: 0.08)]
          : null,
      borderWidth: 1,
      borderRadius: 8,
      onPressed: () {
        if (widget.onSelected != null) {
          widget.onSelected!();
          return;
        }
        Navigator.pushNamed(
          context,
          widget.vault.vaultType == WalletType.multiSignature
              ? AppRoutes.multisigSetupInfo
              : AppRoutes.singleSigSetupInfo,
          arguments: {'id': widget.vault.id, 'entryPoint': widget.entryPoint},
        );
      },
      onLongPressed: () {
        widget.onLongPressed?.call();
      },
      child: _buildVaultContainerWidget(),
    );
  }

  Widget _buildVaultContainerWidget({ValueChanged<(bool, int)>? onTapStar, int? index}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.isEditMode ? 8 : 20, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 37),
        child: Row(
          children: [
            if (widget.isEditMode)
              Opacity(
                opacity: widget.isStarVisible ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (!widget.isStarVisible) return;
                    onTapStar?.call((!widget.isFavorite, widget.vault.id));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/svg/${widget.isFavorite ? 'star-filled' : 'star-outlined'}.svg',
                      colorFilter: ColorFilter.mode(
                        widget.isFavorite ? CoconutColors.gray800 : CoconutColors.gray500,
                        BlendMode.srcIn,
                      ),
                      width: 18,
                    ),
                  ),
                ),
              ),
            VaultIconSmall(
              iconIndex: widget.vault.iconIndex,
              colorIndex: widget.vault.colorIndex,
              gradientColors:
                  _isMultiSig && _multiSigners != null ? CustomColorHelper.getGradientColors(_multiSigners!) : null,
            ),
            CoconutLayout.spacing_200w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.enableShotenName
                              ? widget.vault.name.length > 8
                                  ? '${widget.vault.name.substring(0, 8)}...'
                                  : widget.vault.name
                              : widget.vault.name,
                          style: CoconutTypography.body2_14_Bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_isMultiSig || _isUsedToMultiSig) ...{
                        Text(_subtitleText, style: CoconutTypography.body3_12.copyWith(color: CoconutColors.gray600)),
                      },
                      if (widget.isPrimaryWallet == true) ...[
                        if (_isMultiSig || _isUsedToMultiSig)
                          Text(
                            ' • ${t.vault_list_screen.primary_wallet}',
                            style: CoconutTypography.body3_12.setColor(CoconutColors.gray500),
                          )
                        else
                          Text(
                            t.vault_list_screen.primary_wallet,
                            style: CoconutTypography.body3_12.setColor(CoconutColors.gray500),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            CoconutLayout.spacing_200w,
            widget.isNextIconVisible
                ? widget.isEditMode
                    ? ReorderableDragStartListener(
                        index: index!,
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SvgPicture.asset('assets/svg/hamburger.svg'),
                          ),
                        ),
                      )
                    : SvgPicture.asset('assets/svg/chevron-right.svg', width: 6, height: 10)
                : widget.isSelectable
                    ? Icon(
                        Icons.check_rounded,
                        size: 24,
                        color: CoconutColors.black.withOpacity(widget.isSelected ? 1 : 0.1),
                      )
                    : widget.isEditMode
                        ? ReorderableDragStartListener(
                            index: index!,
                            child: GestureDetector(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SvgPicture.asset('assets/svg/hamburger.svg'),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
