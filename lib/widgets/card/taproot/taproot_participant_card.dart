import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TaprootParticipantRole { parent, child }

/// 지갑 카드 내에 서명자 구성, 상속 조건에 사용되는 카드
class TaprootParticipantCard extends StatelessWidget {
  final TaprootParticipantRole role;
  final bool isMine;
  final bool isValid;
  final bool hasSingleParent;

  const TaprootParticipantCard({
    super.key,
    required this.role,
    this.isMine = false,
    this.isValid = true,
    this.hasSingleParent = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border, width: 1),
      ),
      padding: const EdgeInsets.only(top: 18, bottom: 18, left: 16, right: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: CoconutColors.gray200, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(5),
            child: SvgPicture.asset(style.iconAssetPath, width: 16, height: 16),
          ),
          CoconutLayout.spacing_200w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TODO: locktime이 있는지 여부에 따라 다르게 보여줘야 함
                    // if(locktime != null) ...[
                    //   Text('$locktime', style: CoconutTypography.body3_12),
                    // ],
                    // else...[
                    Text('assadsada', style: CoconutTypography.body3_12_Bold),
                    CoconutLayout.spacing_100w,
                    _rightIcon ?? Container(),
                  ],
                ),
                Text('00000000 · m/86’/0’/0’', style: CoconutTypography.caption_10.setColor(CoconutColors.gray600)),
              ],
            ),
          ),
          _roleWidget(style),
        ],
      ),
    );
  }

  _TaprootParticipantCardStyle get _style {
    if (!isMine) {
      return _TaprootParticipantCardStyle(
        background: CoconutColors.white,
        border: CoconutColors.gray300,
        roleBackgroundColor: CoconutColors.gray100,
        roleTextColor: CoconutColors.gray700,
        iconAssetPath: _iconAssetPath,
      );
    }
    if (!isValid) {
      return _TaprootParticipantCardStyle(
        background: CoconutColors.hotPink.withValues(alpha: 0.06),
        border: CoconutColors.hotPink.withValues(alpha: 0.5),
        roleBackgroundColor: CoconutColors.hotPink.withValues(alpha: 0.06),
        roleTextColor: CoconutColors.hotPink,
        iconAssetPath: _iconAssetPath,
      );
    }
    if (role == TaprootParticipantRole.parent) {
      return _TaprootParticipantCardStyle(
        background: CoconutColors.purple.withValues(alpha: 0.08),
        border: CoconutColors.purple.withValues(alpha: 0.5),
        roleBackgroundColor: CoconutColors.purple,
        roleTextColor: CoconutColors.white,
        iconAssetPath: _iconAssetPath,
      );
    }
    return _TaprootParticipantCardStyle(
      background: CoconutColors.sky.withValues(alpha: 0.08),
      border: CoconutColors.sky.withValues(alpha: 0.5),
      roleBackgroundColor: CoconutColors.sky,
      roleTextColor: CoconutColors.white,

      iconAssetPath: _iconAssetPath,
    );
  }

  String get _iconAssetPath {
    return switch (role) {
      TaprootParticipantRole.parent => 'assets/svg/parent.svg',
      TaprootParticipantRole.child => 'assets/svg/child.svg',
    };
  }

  SvgPicture? get _rightIcon {
    if (role == TaprootParticipantRole.child && isMine) {
      if (isValid) {
        // isValid를 locktime이 지났는지 판단하는 기준으로 변경해야함
        return SvgPicture.asset('assets/svg/unlock.svg', width: 16, height: 16);
      }
      return SvgPicture.asset('assets/svg/lock.svg', width: 16, height: 16);
    }
    return null;
  }

  Widget _roleWidget(_TaprootParticipantCardStyle style) {
    final text = _roleText;

    return Container(
      decoration: BoxDecoration(
        color: style.roleBackgroundColor,
        border: Border.all(color: style.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(text, style: CoconutTypography.caption_10.setColor(style.roleTextColor)),
    );
  }

  String get _roleText {
    if (isMine) {
      return isValid ? '나' : '공동 서명자';
    }
    if (role == TaprootParticipantRole.child) {
      return '조건부 서명자';
    }
    return hasSingleParent ? '서명자' : '공동 서명자';
  }
}

class _TaprootParticipantCardStyle {
  final Color background;
  final Color border;
  final Color roleBackgroundColor;
  final Color roleTextColor;
  final String iconAssetPath;

  const _TaprootParticipantCardStyle({
    required this.background,
    required this.border,
    required this.roleBackgroundColor,
    required this.roleTextColor,
    required this.iconAssetPath,
  });
}
