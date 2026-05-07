import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TaprootSetupSummaryCard extends StatelessWidget {
  static const double _guideLineX = 0;
  static const double _sectionIndent = 12.5;
  static const double _cardSpacing = 4;
  static const double _sectionSpacing = 25;
  static const double _sectionTitleSpacing = 8;

  final List<TaprootParticipantCard> itemList;
  final TaprootSetupSummaryCardType taprootSetupSummaryCardType; // 카드 타입, 트리 타입, 컬럼 타입 중 선택(default: 카드타입)

  const TaprootSetupSummaryCard({
    super.key,
    required this.itemList,
    this.taprootSetupSummaryCardType = TaprootSetupSummaryCardType.card,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: 'TaprootSetupSummaryCard',
        context: context,
        backgroundColor: CoconutColors.white,
      ),
      body: SingleChildScrollView(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (taprootSetupSummaryCardType == TaprootSetupSummaryCardType.card) {
      return _buildCardTypeLayout();
    }
    if (taprootSetupSummaryCardType == TaprootSetupSummaryCardType.tree) {
      return _buildTreeTypeLayout();
    }
    return _buildColumnTypeLayout();
  }

  Widget _buildCardTypeLayout() {
    return Column(children: itemList);
  }

  Widget _buildTreeTypeLayout() {
    final signerItems = itemList.where((item) => item.locktime == null).toList();
    final inheritanceItems = itemList.where((item) => item.locktime != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GuideSpacer(height: 40),
        _SummarySection(
          title: t.taproot.setup_summary_card.signer_configuration,
          isLastSection: inheritanceItems.isEmpty,
          children: signerItems,
        ),
        if (inheritanceItems.isNotEmpty) ...[
          const _GuideSpacer(height: _sectionSpacing),
          _SummarySection(
            title: t.taproot.setup_summary_card.inheritance_condition,
            isLastSection: true,
            children: inheritanceItems,
          ),
        ],
      ],
    );
  }

  Widget _buildColumnTypeLayout() {
    return Container();
  }
}

class _GuideContentRow extends StatelessWidget {
  final Widget child;
  final bool showBranch;
  final bool isLastGuideRow;
  final bool showLockIcon;

  const _GuideContentRow({
    required this.child,
    this.showBranch = false,
    this.isLastGuideRow = false,
    this.showLockIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: TaprootSetupSummaryCard._sectionIndent,
            child: CustomPaint(
              painter: _GuideRailPainter(
                showBranch: showBranch,
                drawBottom: !isLastGuideRow,
                isRoundedEnd: isLastGuideRow,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: child),
                if (showLockIcon) ...[
                  const SizedBox(width: 4),
                  SvgPicture.asset('assets/svg/lock.svg', width: 16, height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final List<TaprootParticipantCard> children;
  final bool isLastSection;

  const _SummarySection({required this.title, required this.children, this.isLastSection = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GuideContentRow(
          showLockIcon: _areAllLocktimesPast,
          child: Text(title, style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.gray600)),
        ),
        const _GuideSpacer(height: TaprootSetupSummaryCard._sectionTitleSpacing),
        for (int index = 0; index < children.length; index++) ...[
          if (index > 0) const _GuideSpacer(height: TaprootSetupSummaryCard._cardSpacing),
          _GuideContentRow(
            showBranch: true,
            isLastGuideRow: isLastSection && index == children.length - 1,
            child: children[index],
          ),
        ],
      ],
    );
  }

  bool get _areAllLocktimesPast {
    return children.isNotEmpty && children.every((child) => _isPastLocktime(child.locktime));
  }

  bool _isPastLocktime(int? locktime) {
    if (locktime == null) {
      return false;
    }

    final locktimeDate = DateTime.fromMillisecondsSinceEpoch(_toMilliseconds(locktime));
    return locktimeDate.isBefore(DateTime.now());
  }

  int _toMilliseconds(int locktime) {
    if (locktime >= 1000000000000) {
      return locktime;
    }
    return locktime * 1000;
  }
}

class _GuideSpacer extends StatelessWidget {
  final double height;

  const _GuideSpacer({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: TaprootSetupSummaryCard._sectionIndent, child: CustomPaint(painter: _GuideRailPainter())),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _GuideRailPainter extends CustomPainter {
  static const double _cornerRadius = 14;

  final bool showBranch;
  final bool drawBottom;
  final bool isRoundedEnd;

  const _GuideRailPainter({this.showBranch = false, this.drawBottom = true, this.isRoundedEnd = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CoconutColors.gray200
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const lineX = TaprootSetupSummaryCard._guideLineX;
    const branchEndX = TaprootSetupSummaryCard._sectionIndent;
    final centerY = size.height / 2;

    if (isRoundedEnd && showBranch) {
      final radius = _cornerRadius.clamp(0, centerY);
      final path =
          Path()
            ..moveTo(lineX, 0)
            ..lineTo(lineX, centerY - radius)
            ..quadraticBezierTo(lineX, centerY, lineX + radius, centerY)
            ..lineTo(branchEndX, centerY);
      canvas.drawPath(path, paint);
      return;
    }

    canvas.drawLine(const Offset(lineX, 0), Offset(lineX, drawBottom ? size.height : centerY), paint);

    if (showBranch) {
      canvas.drawLine(Offset(lineX, centerY), Offset(branchEndX, centerY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideRailPainter oldDelegate) {
    return oldDelegate.showBranch != showBranch ||
        oldDelegate.drawBottom != drawBottom ||
        oldDelegate.isRoundedEnd != isRoundedEnd;
  }
}

enum TaprootSetupSummaryCardType { card, tree, column }
