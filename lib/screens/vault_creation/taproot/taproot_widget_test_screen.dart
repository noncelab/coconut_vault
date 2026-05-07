import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:flutter/material.dart';

class TaprootWidgetTestScreen extends StatelessWidget {
  const TaprootWidgetTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taproot Widget Test Screen')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('(role: TaprootParticipantRole.parent, isMine: true)', style: CoconutTypography.body3_12),
              TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                isMine: true,
                onTap: () => print('Parent card tapped'),
              ),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.parent, isMine: false)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(role: TaprootParticipantRole.parent, isMine: false),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.child, isMine: true)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(role: TaprootParticipantRole.child, isMine: true),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.child, isMine: false)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(role: TaprootParticipantRole.child, isMine: false),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.parent, hasSingleParent: true,)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(role: TaprootParticipantRole.parent, isMine: false, hasSingleParent: true),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.child, hasSingleParent: true, isMine: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(role: TaprootParticipantRole.child, isMine: false, hasSingleParent: true),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.parent, hasSingleParent: false, isMine: true, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(role: TaprootParticipantRole.parent, isMine: true, isValid: false),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.child, hasSingleParent: false, isMine: false, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(role: TaprootParticipantRole.child, isMine: false, isValid: false),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.parent, hasSingleParent: true, isMine: true, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                isMine: true,
                hasSingleParent: true,
                isValid: false,
              ),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.child, hasSingleParent: true, isMine: false, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                isMine: false,
                hasSingleParent: true,
                isValid: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
