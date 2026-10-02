import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// A short vertical connector line, optionally ending in an arrow.
class FlowConnector extends StatelessWidget {
  const FlowConnector({
    super.key,
    this.height = 22,
    this.color = AppColors.borderStrong,
    this.showArrow = false,
  });

  final double height;
  final Color color;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 2, height: height, color: color),
        if (showArrow)
          Icon(Icons.arrow_drop_down, size: 16, color: color),
      ],
    );
  }
}
