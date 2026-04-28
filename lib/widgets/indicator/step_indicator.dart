import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/widgets/entropy_base/entropy_common_widget.dart';
import 'package:flutter/cupertino.dart';

class StepIndicator extends StatelessWidget {
  final bool usePassphrase;
  final int step;
  final Function(int) onStepSelected;

  const StepIndicator({super.key, required this.usePassphrase, required this.step, required this.onStepSelected});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      visible: usePassphrase,
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Stack(
            children: [
              const SizedBox(
                height: 50,
                width: 120,
                child: Center(
                  child: DottedDivider(
                    height: 2.0,
                    width: 100,
                    dashWidth: 2.0,
                    dashSpace: 4.0,
                    color: CoconutColors.gray400,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: NumberWidget(number: 1, selected: step == 0, onSelected: () => onStepSelected(0)),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: NumberWidget(number: 2, selected: step == 1, onSelected: () => onStepSelected(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
