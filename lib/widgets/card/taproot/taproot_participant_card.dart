import 'package:flutter/material.dart';

enum TaprootParticipantRole { parent, child }

/// 지갑 카드 내에 서명자 구성, 상속 조건에 사용되는 카드
class TaprootParticipantCard extends StatelessWidget {
  final TaprootParticipantRole role;
  final bool isMine;
  final bool isValid;

  const TaprootParticipantCard({super.key, required this.role, this.isMine = false, this.isValid = true});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
