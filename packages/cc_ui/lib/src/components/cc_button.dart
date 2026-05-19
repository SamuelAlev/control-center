import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Visual treatment for a [CcButton], resolved through [CcButtonTokens].
enum CcButtonVariant {
  /// Ink-black at rest, warming to orange on hover — the default action.
  primary,

  /// Bordered surface, border strengthens on hover.
  secondary,

  /// Solid orange — the loudest call to action.
  accent,

  /// Panel fill, border darkens to ink on hover.
  line,

  /// Transparent, only a hover wash.
  ghost,

  /// Solid red — destructive actions (delete, remove).
  destructive,
}

/// Height/padding scale for a [CcButton].
enum CcButtonSize {
  /// Medium — 36px tall (the default).
  md,

  /// Small — 38px tall (text-natural line + tight padding).
  sm,
}

/// A flat, ripple-free button built on [CcTappable].
///
/// The design system has no ink ripple: hover and press are reported through
/// color washes (and a 1px downward nudge while pressed). Hierarchy comes from
/// the [variant] color set, never weight. Text is always supplied by the caller
/// (usually a localized [Text]) via [child].
class CcButton extends StatelessWidget {
  /// Creates a [CcButton].
  const CcButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.variant = CcButtonVariant.primary,
    this.size = CcButtonSize.md,
    this.icon,
    this.trailing,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
    this.fullWidth = false,
    this.semanticLabel,
  });

  /// The button label — usually a [Text]. The caller localizes it.
  final Widget child;

  /// Tap handler. When null the button is disabled.
  final VoidCallback? onPressed;

  /// The color treatment.
  final CcButtonVariant variant;

  /// The height/padding scale.
  final CcButtonSize size;

  /// Optional leading icon (rendered at 16px in the foreground color).
  final IconData? icon;

  /// Optional trailing widget (e.g. a chevron or count).
  final Widget? trailing;

  /// When true the button shows an inline spinner and stops responding to taps.
  final bool loading;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// When true the button stretches to fill its horizontal constraints.
  final bool fullWidth;

  /// Accessibility label (defaults to the child's own semantics).
  final String? semanticLabel;

  /// Resolves the color set for [variant] from [t].
  CcButtonTokens _tokens(DesignSystemTokens t) {
    switch (variant) {
      case CcButtonVariant.primary:
        return CcButtonTokens.primary(t);
      case CcButtonVariant.secondary:
        return CcButtonTokens.secondary(t);
      case CcButtonVariant.accent:
        return CcButtonTokens.accent(t);
      case CcButtonVariant.line:
        return CcButtonTokens.line(t);
      case CcButtonVariant.ghost:
        return CcButtonTokens.ghost(t);
      case CcButtonVariant.destructive:
        return CcButtonTokens.destructive(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = _tokens(t);
    final height = size == CcButtonSize.md ? 36.0 : 38.0;
    final horizontal = size == CcButtonSize.md ? 18.0 : 14.0;
    final disabled = onPressed == null || loading;

    return CcTappable(
      onPressed: disabled ? null : onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      borderRadius: AppRadii.brSm,
      focusRingColor: t.focusRing,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);

        final Color bg;
        final Color fg;
        final Color border;
        if (disabled) {
          bg = t.bgDisabled;
          fg = t.textDisabled;
          border = tokens.border.a == 0
              ? tokens.border
              : t.borderDisabled;
        } else if (pressed) {
          bg = tokens.bgPressed;
          fg = tokens.fg;
          border = tokens.borderHover;
        } else if (hovered) {
          bg = tokens.bgHover;
          fg = tokens.fg;
          border = tokens.borderHover;
        } else {
          bg = tokens.bg;
          fg = tokens.fg;
          border = tokens.border;
        }

        Widget content = _buildContent(context, fg);
        content = AnimatedContainer(
          duration: CcMotion.resolve(context, CcMotion.fast),
          curve: CcMotion.standard,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: border,
              width: 1,
            ),
          ),
          child: content,
        );

        if (fullWidth) {
          content = SizedBox(width: double.infinity, child: content);
        }

        // Pressed nudge — a flat 1px downward shift instead of a ripple.
        if (pressed && !disabled) {
          content = Transform.translate(
            offset: const Offset(0, 1),
            child: content,
          );
        }

        return content;
      },
    );
  }

  Widget _buildContent(BuildContext context, Color fg) {
    final children = <Widget>[];
    if (loading) {
      children.add(_CcButtonSpinner(color: fg));
      children.add(const SizedBox(width: AppSpacing.sm));
    } else if (icon != null) {
      children.add(Icon(icon, size: 16, color: fg));
      children.add(const SizedBox(width: AppSpacing.sm));
    }

    children.add(
      Flexible(
        child: DefaultTextStyle.merge(
          style: CcTypography.body.copyWith(color: fg),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: 16),
            child: child,
          ),
        ),
      ),
    );

    if (trailing != null) {
      children.add(const SizedBox(width: AppSpacing.sm));
      children.add(
        DefaultTextStyle.merge(
          style: CcTypography.body.copyWith(color: fg),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: 16),
            child: trailing!,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

/// A small inline determinate-free spinner used while a [CcButton] is loading.
///
/// A thin rotating arc painted with [CustomPaint]; collapses to a static ring
/// when motion is reduced.
class _CcButtonSpinner extends StatefulWidget {
  const _CcButtonSpinner({required this.color});

  final Color color;

  @override
  State<_CcButtonSpinner> createState() => _CcButtonSpinnerState();
}

class _CcButtonSpinnerState extends State<_CcButtonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CcMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SpinnerPainter(
            color: widget.color,
            turns: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.turns});

  final Color color;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = color;
    final rect = Offset.zero & size;
    const sweep = 4.2; // ~240deg arc.
    final start = turns * 6.283185307179586; // 2*pi.
    canvas.drawArc(rect.deflate(1), start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.color != color;
}
