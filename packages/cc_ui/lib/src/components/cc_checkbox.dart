import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:flutter/widgets.dart';

/// A flat 18x18 checkbox with an optional label.
///
/// Checked fills with the accent color and draws a white check glyph via
/// [CustomPaint]; the [indeterminate] state fills with accent and draws a dash
/// (used for parent "select all" checkboxes with a partial sublist). Built on
/// [CcTappable] for the shared hover/press/focus treatment and keyboard
/// activation. The tap target is enlarged to ≥32px so the control is
/// comfortably operable (the visible box stays 18px); an optional [label]
/// rendered beside the box is part of the same tap target. Passing a null
/// [onChanged] disables the control.
class CcCheckbox extends StatelessWidget {
  /// Creates a [CcCheckbox].
  const CcCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.indeterminate = false,
    this.semanticLabel,
    this.label,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         !indeterminate || !value,
         'An indeterminate checkbox is not checked.',
       );

  /// Whether the checkbox is checked.
  final bool value;

  /// Called with the toggled value when tapped. Null disables the checkbox.
  /// Tapping an [indeterminate] checkbox clears it (reports `false`).
  final ValueChanged<bool>? onChanged;

  /// Whether the checkbox shows the indeterminate (dash) state — a parent
  /// control whose sublist is partially selected.
  final bool indeterminate;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Optional label rendered beside the box and included in the tap target.
  final Widget? label;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _size = 18;
  static const double _target = 32;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final enabled = onChanged != null;
    final active = value || indeterminate;

    return CcTappable(
      onPressed: enabled
          ? () => onChanged!(indeterminate ? false : !value)
          : null,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);

        Color fillColor;
        Color borderColor;
        if (active) {
          fillColor = enabled ? t.accent : t.bgDisabled;
          borderColor = fillColor;
        } else {
          fillColor = pressed
              ? t.hoverStrong
              : hovered
              ? t.hover
              : t.surface;
          borderColor = enabled ? t.borderPrimary : t.borderDisabled;
        }

        final glyphColor = enabled ? t.fgWhite : t.fgDisabled;

        final Widget box = Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: borderColor),
            ),
            child: active
                ? CustomPaint(
                    painter: indeterminate
                        ? _DashPainter(color: glyphColor)
                        : _CheckPainter(color: glyphColor),
                    size: const Size(_size, _size),
                  )
                : null,
          ),
        );

        // Enlarge the tap target to ≥32px (the visible box stays 18px) and fold
        // an optional label into the same hit region.
        final Widget content = ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _target,
            minHeight: _target,
          ),
          child: label == null
              ? Center(child: box)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    box,
                    const SizedBox(width: 8),
                    Flexible(
                      child: DefaultTextStyle.merge(
                        style: CcTypography.bodySm.copyWith(
                          color: t.textPrimary,
                        ),
                        child: label!,
                      ),
                    ),
                  ],
                ),
        );

        // Expose the checked state to assistive tech.
        return Semantics(checked: value, child: content);
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.43, h * 0.70)
      ..lineTo(w * 0.74, h * 0.32);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}

/// Paints the horizontal dash used by the indeterminate checkbox state.
class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final h = size.height;
    final w = size.width;
    canvas.drawLine(
      Offset(w * 0.28, h * 0.5),
      Offset(w * 0.72, h * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
