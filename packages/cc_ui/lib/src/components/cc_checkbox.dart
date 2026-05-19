import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat 18x18 checkbox.
///
/// Checked fills with the accent color and draws a white check glyph via
/// [CustomPaint]; unchecked shows a hairline-bordered surface that picks up a
/// hover wash. Built on [CcTappable] for the shared hover/press/focus treatment
/// and keyboard activation. Passing a null [onChanged] disables the control.
class CcCheckbox extends StatelessWidget {
  /// Creates a [CcCheckbox].
  const CcCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the checkbox is checked.
  final bool value;

  /// Called with the toggled value when tapped. Null disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _size = 18;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final enabled = onChanged != null;
    final duration = CcMotion.resolve(context, CcMotion.fast);

    return CcTappable(
      onPressed: enabled ? () => onChanged!(!value) : null,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);

        Color fillColor;
        Color borderColor;
        if (value) {
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

        final checkColor = enabled ? t.fgWhite : t.fgDisabled;

        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: borderColor),
            ),
            child: AnimatedOpacity(
              opacity: value ? 1 : 0,
              duration: duration,
              curve: CcMotion.standard,
              child: CustomPaint(
                painter: _CheckPainter(color: checkColor),
                size: const Size(_size, _size),
              ),
            ),
          ),
        );
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
