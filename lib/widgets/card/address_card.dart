import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:flutter/cupertino.dart';

class AddressCard extends StatelessWidget {
  final VoidCallback onPressed;

  final String address;
  final String derivationPath;
  const AddressCard({
    super.key,
    required this.onPressed,
    required this.address,
    required this.derivationPath,
  });

  @override
  Widget build(BuildContext context) {
    var path = derivationPath.split('/');
    var index = path[path.length - 1];

    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          borderRadius: CoconutBorder.defaultRadius,
          color: CoconutColors.gray150,
        ),
        padding: CoconutPadding.widgetContainer,
        margin: const EdgeInsets.only(
          bottom: 8,
          left: 16,
          right: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: CoconutColors.black.withOpacity(0.3),
              ),
              child: Text(
                index,
                style: CoconutTypography.body3_12.setColor(
                  CoconutColors.white,
                ),
              ),
            ),
            Expanded(
              child: Text(
                TextUtils.truncateNameMax25(address),
                style: CoconutTypography.body1_16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
