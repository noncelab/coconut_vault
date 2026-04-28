import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:flutter/material.dart';

class TaprootSetupSummaryCard extends StatelessWidget {
  final List<TaprootParticipantCard> itemList;
  final bool isCardType; // 카드 타입, 트리 타입 중 선택(default: 카드타입)

  const TaprootSetupSummaryCard({super.key, required this.itemList, this.isCardType = true});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
