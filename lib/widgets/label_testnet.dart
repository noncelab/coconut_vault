import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/cupertino.dart';

import '../styles.dart';

class TestnetLabelWidget extends StatelessWidget {
  const TestnetLabelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: MyColors.cyanblue,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Text(
        t.testnet,
        style: Styles.label.merge(
          const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: MyColors.white,
          ),
        ),
      ),
    );
  }
}
