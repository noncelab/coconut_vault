import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/widgets.dart';

class SlidingSegmentedControl extends StatefulWidget {
  final Map<int, String> options;
  final Function(int) onValueChanged;
  final double? fixedWidth;
  final double? height;
  const SlidingSegmentedControl(
      {super.key,
      required this.options,
      required this.onValueChanged,
      this.fixedWidth,
      this.height});

  @override
  State<SlidingSegmentedControl> createState() => _SlidingSegmentedControlState();
}

class _SlidingSegmentedControlState extends State<SlidingSegmentedControl> {
  int _selectedValue = 0;

  @override
  Widget build(BuildContext context) {
    return CustomSlidingSegmentedControl<int>(
      initialValue: 0,
      children: {
        for (var element in widget.options.entries)
          element.key: Text(element.value,
              style: CoconutTypography.body3_12.setColor(
                  _selectedValue == element.key ? CoconutColors.black : CoconutColors.gray350)),
      },
      decoration: BoxDecoration(
        color: CoconutColors.gray200,
        borderRadius: BorderRadius.circular(30),
      ),
      thumbDecoration: BoxDecoration(
        color: CoconutColors.gray300,
        borderRadius: BorderRadius.circular(30),
      ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInToLinear,
      onValueChanged: (value) {
        setState(() {
          _selectedValue = value;
        });
        widget.onValueChanged(value);
      },
      fixedWidth: widget.fixedWidth,
      height: widget.height,
    );
  }
}
