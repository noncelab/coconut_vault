import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class TestnetLabelWidget extends StatelessWidget {
  const TestnetLabelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<VisibilityProvider, String>(
      selector: (_, provider) => provider.language,
      builder: (context, language, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: CoconutColors.cyanBlue,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          child: Text(
            t.testnet,
            style: CoconutTypography.body2_14.merge(
              const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: CoconutColors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
