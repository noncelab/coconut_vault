import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/parent_creation_step_widgets.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:flutter/material.dart';

class ParentCreationCompletionSteps {
  ParentCreationCompletionSteps._();

  static List<TextSpan> timelineTitleList() {
    return [
      TextSpan(text: t.taproot.parent_creation_screen.step_4.title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_4.title_2),
    ];
  }

  static Widget timelineIndicator({
    required ParentWalletType parentWalletType,
    required TaprootVaultCreationTimelineInfo? timelineInfo,
    required String timelockDateTimeText,
    required VoidCallback onCompleted,
  }) {
    final timeline = t.taproot.parent_creation_screen.step_4.timeline;

    return TimelineStepIndicator(
      onCompleted: onCompleted,
      enableTapToSkip: true,
      timelineStepItemList: [
        TimelineStepItem(
          title: timeline.created_parent_wallet,
          description: _parentWalletDescription(parentWalletType: parentWalletType, timelineInfo: timelineInfo),
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: timeline.set_child_wallet,
          description: _childWalletDescription(timelineInfo),
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: timeline.set_child_wallet_timelock,
          description: timelockDateTimeText,
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: timeline.active_child_wallet,
          description: timeline.time_after(date: timelockDateTimeText),
          status: TimelineStepStatus.future,
        ),
      ],
    );
  }

  static Widget maybeLaterButton({required VoidCallback onTap}) {
    return CoconutUnderlinedButton(
      text: t.taproot.parent_creation_screen.step_4.timeline.maybe_later,
      textStyle: CoconutTypography.body2_14,
      onTap: onTap,
    );
  }

  static List<TextSpan> exportQrTitleList() {
    final complete = t.taproot.parent_creation_screen.step_4.complete;
    return [TextSpan(text: complete.title_1), TextSpan(text: complete.title_2)];
  }

  static Widget exportQrBody({required String qrData}) {
    return ParentWalletSyncQr(qrData: qrData);
  }

  static String _parentWalletDescription({
    required ParentWalletType parentWalletType,
    required TaprootVaultCreationTimelineInfo? timelineInfo,
  }) {
    final masterFingerprint = timelineInfo?.parentMasterFingerprint ?? '';
    if (parentWalletType == ParentWalletType.multisig) {
      final externalMasterFingerprint = timelineInfo?.externalParentMasterFingerprint ?? '';
      final masterFingerprints = <String>[
        masterFingerprint,
        externalMasterFingerprint,
      ].where((masterFingerprint) => masterFingerprint.isNotEmpty);
      return '${t.multisig_wallet} | MFP: ${masterFingerprints.join(', ')}';
    }

    return t.taproot.parent_creation_screen.singlesig_wallet_with_mfp(mfp: masterFingerprint);
  }

  static String _childWalletDescription(TaprootVaultCreationTimelineInfo? timelineInfo) {
    final masterFingerprint = timelineInfo?.childMasterFingerprint ?? '';
    return t.taproot.parent_creation_screen.taproot_wallet_with_mfp(mfp: masterFingerprint);
  }
}
