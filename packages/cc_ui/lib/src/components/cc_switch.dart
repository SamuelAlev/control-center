import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat on/off switch.
///
/// A 36x20 rounded-pill track holding a 16px circular thumb that slides between
/// the off and on positions ([CcMotion.fast]). On, the track fills with the
/// accent color; off, it shows a neutral tertiary fill with a hairline border.
/// Built on [CcTappable] so it picks up the shared hover/press/focus treatment
/// and keyboard activation. Passing a null [onChanged] disables the control.
class CcSwitch extends StatelessWidget {
  /// Creates a [CcSwitch].
  const CcSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the toggled value when tapped. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _trackWidth = 36;
  static const double _trackHeight = 20;
  static const double _thumbSize = 16;
  static const double _thumbInset = 2;

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
      borderRadius: const BorderRadius.all(Radius.circular(_trackHeight / 2)),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);

        Color trackColor;
        Color borderColor;
        if (value) {
          trackColor = hovered ? t.accentHover : t.accent;
          borderColor = trackColor;
        } else {
          trackColor = t.bgTertiary;
          borderColor = t.borderPrimary;
        }
        if (!enabled) {
          trackColor = t.bgDisabled;
          borderColor = t.borderDisabled;
        }

        final thumbColor = enabled ? t.fgWhite : t.fgDisabled;

        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            width: _trackWidth,
            height: _trackHeight,
            padding: const EdgeInsets.all(_thumbInset),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius:
                  const BorderRadius.all(Radius.circular(_trackHeight / 2)),
              border: Border.all(color: borderColor),
            ),
            child: AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: duration,
              curve: CcMotion.standard,
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
