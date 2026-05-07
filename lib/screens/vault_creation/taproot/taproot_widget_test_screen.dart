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
                walletName: 'Test Wallet1',
                mfp: '12345678',
                derivationPath: "m/86'/0'/0'",
                locktime: 12345678,
                onTap: () => print('Parent card tapped'),
              ),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.parent, isMine: false)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                isMine: false,
                walletName: 'Test Wallet2',
                mfp: '87654321',
                derivationPath: "m/86'/0'/1'",
              ),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.child, isMine: true)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                isMine: true,
                walletName: 'Test Wallet3',
                mfp: '11111111',
                derivationPath: "m/86'/0'/2'",
              ),
              CoconutLayout.spacing_300h,
              const Text('(role: TaprootParticipantRole.child, isMine: false)', style: CoconutTypography.body3_12),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                isMine: false,
                walletName: 'Test Wallet4',
                mfp: '22222222',
                derivationPath: "m/86'/0'/3'",
              ),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.parent, hasSingleParent: true,)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                isMine: false,
                hasSingleParent: true,
                walletName: 'Test Wallet5',
                mfp: '33333333',
                derivationPath: "m/86'/0'/4'",
              ),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.child, hasSingleParent: true, isMine: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                isMine: false,
                hasSingleParent: true,
                walletName: 'Test Wallet6',
                mfp: '44444444',
                derivationPath: "m/86'/0'/5'",
              ),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.parent, hasSingleParent: false, isMine: true, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                isMine: true,
                isValid: false,
                walletName: 'Test Wallet7',
                mfp: '55555555',
                derivationPath: "m/86'/0'/6'",
              ),
              CoconutLayout.spacing_300h,
              const Text(
                '(role: TaprootParticipantRole.child, hasSingleParent: false, isMine: false, isValid: false)',
                style: CoconutTypography.body3_12,
              ),
              const TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                isMine: false,
                isValid: false,
                walletName: 'Test Wallet8',
                mfp: '66666666',
                derivationPath: "m/86'/0'/7'",
              ),
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
                walletName: 'Test Wallet9',
                mfp: '77777777',
                derivationPath: "m/86'/0'/8'",
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
                walletName: 'Test Wallet10',
                mfp: '88888888',
                derivationPath: "m/86'/0'/9'",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
