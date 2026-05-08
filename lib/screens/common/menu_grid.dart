import 'package:flutter/widgets.dart';

/// A widget that arranges a list of [children] into a grid.
///
/// This widget is useful for creating layouts with a fixed number of columns,
/// similar to the option selection screens. It dynamically builds rows and
/// columns, ensuring that items in the same row are aligned at the top.
class MenuGrid extends StatelessWidget {
  /// The widgets to display in the grid.
  final List<Widget> children;

  /// The number of columns in the grid.
  final int crossAxisCount;

  /// The vertical spacing between rows.
  final double mainAxisSpacing;

  /// The horizontal spacing between columns.
  final double crossAxisSpacing;

  const MenuGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += crossAxisCount) {
      final rowItems = <Widget>[];
      for (var j = 0; j < crossAxisCount; j++) {
        final itemIndex = i + j;
        if (itemIndex < children.length) {
          rowItems.add(Expanded(child: children[itemIndex]));
        } else {
          // Add an empty expanded widget to fill the row
          // and maintain the alignment of items in the last row.
          rowItems.add(const Expanded(child: SizedBox.shrink()));
        }

        // Add spacing between columns, but not after the last item.
        if (j < crossAxisCount - 1) {
          rowItems.add(SizedBox(width: crossAxisSpacing));
        }
      }

      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowItems));

      // Add spacing between rows, but not after the last row.
      if (i + crossAxisCount < children.length) {
        rows.add(SizedBox(height: mainAxisSpacing));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
