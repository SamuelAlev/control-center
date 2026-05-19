import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A thin 1px separator line, drawn flat with a token-derived color.
///
/// Defaults to a horizontal hairline in `borderSecondary`. Pass [axis] for a
/// vertical rule, [thickness] to widen the stroke, and [indent]/[endIndent] to
/// inset the line from its leading/trailing edges along its length.
class CcDivider extends StatelessWidget {
  /// Creates a [CcDivider].
  const CcDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  /// Orientation of the line.
  final Axis axis;

  /// Stroke color; defaults to the `borderSecondary` token.
  final Color? color;

  /// Stroke thickness in logical pixels.
  final double thickness;

  /// Inset from the leading edge along the line's length.
  final double indent;

  /// Inset from the trailing edge along the line's length.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lineColor = color ?? t.borderSecondary;
    final isHorizontal = axis == Axis.horizontal;

    final line = SizedBox(
      width: isHorizontal ? null : thickness,
      height: isHorizontal ? thickness : null,
      child: ColoredBox(color: lineColor),
    );

    final padding = isHorizontal
        ? EdgeInsets.only(left: indent, right: endIndent)
        : EdgeInsets.only(top: indent, bottom: endIndent);

    if (indent == 0 && endIndent == 0) {
      return line;
    }
    return Padding(padding: padding, child: line);
  }
}
