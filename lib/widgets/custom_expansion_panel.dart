import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class CustomExpansionPanel extends StatefulWidget {
  final Widget unExpansionWidget;
  final Widget expansionWidget;
  final bool isExpanded;
  final bool isAssigned;
  final VoidCallback onExpansionChanged;
  final VoidCallback? onAssignedClicked;
  final EdgeInsets padding;

  const CustomExpansionPanel({
    super.key,
    required this.unExpansionWidget,
    required this.expansionWidget,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.onAssignedClicked,
    this.isAssigned = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CustomExpansionPanel> createState() => _CustomExpansionPanelState();
}

class _CustomExpansionPanelState extends State<CustomExpansionPanel> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isPressed = false;
            });
            if (widget.isAssigned) {
              if (widget.onAssignedClicked != null) {
                widget.onAssignedClicked!();
              }
            } else {
              widget.onExpansionChanged();
            }
          },
          onTapDown: (details) {
            setState(() {
              isPressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              isPressed = false;
            });
          },
          child: Container(
            color: isPressed ? CoconutColors.gray150 : CoconutColors.white,
            padding: widget.padding,
            child: widget.unExpansionWidget,
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: widget.expansionWidget,
          crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
