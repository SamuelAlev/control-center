import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_icon.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
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

  /// Solid green — an affirming verdict (approve, accept, confirm).
  ///
  /// Reach for this only where the ACT itself is the positive half of a
  /// signed pair the user is choosing between (approve vs request changes).
  /// A plain confirm ("Save", "Create") is [primary]: green there is
  /// decoration, and this design system spends color on state, not on
  /// emphasis.
  success,

  /// Solid red — destructive actions (delete, remove) and the negative half
  /// of a verdict pair (request changes).
  destructive,

  /// Transparent with red text/icon and a soft red hover wash — a
  /// destructive action that sits in a toolbar or header beside [ghost]
  /// siblings, where a solid [destructive] block would outshout the content.
  /// The confirm dialog it opens still uses [destructive].
  ghostDestructive,
}

/// Height/padding scale for a [CcButton] — the 32/40/48 control ramp.
enum CcButtonSize {
  /// Medium — 40px tall (the default; matches field height).
  md,

  /// Small — 32px tall (compact toolbar/inline size).
  sm,

  /// Large — 48px tall (dialog footers, primary flows).
  lg,
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
  }) : _caret = false;

  /// The caret half of a [CcSplitButton]: the same fill and states as the
  /// action it is attached to, padded for a lone glyph.
  const CcButton._caret({
    required this.child,
    required this.onPressed,
    required this.variant,
    required this.size,
    required this.semanticLabel,
  }) : icon = null,
       trailing = null,
       loading = false,
       focusNode = null,
       autofocus = false,
       fullWidth = false,
       _caret = true;

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
  /// It stays focusable, so focus is not lost while it is busy.
  final bool loading;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// When true the button stretches to fill its horizontal constraints.
  final bool fullWidth;

  /// Accessibility label (defaults to the child's own semantics).
  final String? semanticLabel;

  final bool _caret;

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
      case CcButtonVariant.success:
        return CcButtonTokens.success(t);
      case CcButtonVariant.destructive:
        return CcButtonTokens.destructive(t);
      case CcButtonVariant.ghostDestructive:
        return CcButtonTokens.ghostDestructive(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final tokens = _tokens(t);
    final baseHeight = switch (size) {
      CcButtonSize.sm => 32.0,
      CcButtonSize.md => 40.0,
      CcButtonSize.lg => 48.0,
    };
    // Exactly the ramp height at the default text size; a larger text size
    // grows the button by as much as the label's line grows, so the label is
    // never cut off.
    const label = CcTypography.body;
    final line = label.fontSize! * label.height!;
    final scaledLine =
        MediaQuery.textScalerOf(context).scale(label.fontSize!) * label.height!;
    final height = math.max(baseHeight, baseHeight - line + scaledLine);
    final horizontal = _caret
        ? AppSpacing.sm
        : (size == CcButtonSize.sm ? 12.0 : 16.0);
    final disabled = onPressed == null || loading;

    return CcTappable(
      onPressed: disabled ? null : onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      // A button that turns busy under the keyboard keeps focus, so the next
      // Tab continues from it rather than from the top of the page.
      focusableWhenDisabled: loading,
      borderRadius: AppRadii.brSm,
      focusRingColor: t.focusRing,
      // The ring colour is the accent fill (and close to the green and red
      // ones), so it sits 2px clear of the button, on the page around it.
      focusRingOffset: 2,
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
          border = tokens.border.a == 0 ? tokens.border : t.borderDisabled;
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
          duration: CcMotion.resolveFade(context, CcMotion.fast),
          curve: CcMotion.standard,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          // A button wider than its content (full-width footers) start-aligns
          // its label. In hugging mode the alignment must stay null: a
          // Container with a non-null alignment expands to fill bounded
          // constraints, which stretched the button instead of hugging its
          // content.
          alignment: fullWidth ? AlignmentDirectional.centerStart : null,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: border, width: 1),
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
      children.add(CcIcon(icon!, size: 16, color: fg));
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

    return SelectionContainer.disabled(
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

/// An action with its alternatives attached: [child] runs [onPressed], and a
/// caret joined to its end opens a menu of [items].
///
/// Use it where one choice is the usual one and the others are variations of
/// the same act (approve / approve for a while), so the row carries one button
/// instead of one per variation. The two halves share [variant] and are set a
/// hairline apart, so they read as one control with two targets.
///
/// A null [onPressed] or [loading] disables both halves: the alternatives are
/// the same act, and are no more available than it is.
class CcSplitButton extends StatefulWidget {
  /// Creates a [CcSplitButton].
  const CcSplitButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.items,
    required this.menuSemanticLabel,
    this.variant = CcButtonVariant.primary,
    this.size = CcButtonSize.md,
    this.loading = false,
  });

  /// The main action's label, usually a localized [Text].
  final Widget child;

  /// Runs the main action. Null disables the whole control.
  final VoidCallback? onPressed;

  /// The alternatives the caret offers.
  final List<CcMenuItem> items;

  /// Names the caret for assistive technology ("More approval options").
  final String menuSemanticLabel;

  /// The color treatment of both halves.
  final CcButtonVariant variant;

  /// The height/padding scale of both halves.
  final CcButtonSize size;

  /// Shows the main action busy and disables both halves.
  final bool loading;

  @override
  State<CcSplitButton> createState() => _CcSplitButtonState();
}

class _CcSplitButtonState extends State<CcSplitButton> {
  final CcOverlayController _menu = CcOverlayController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: CcButton(
            variant: widget.variant,
            size: widget.size,
            loading: widget.loading,
            onPressed: widget.onPressed,
            child: widget.child,
          ),
        ),
        // The seam: the surface behind shows through, so the halves stay
        // distinct in every variant without a border colour of their own.
        const SizedBox(width: 1),
        CcMenu(
          controller: _menu,
          // The caret is a button of its own: it toggles the menu itself, or
          // the menu's tap handler and the button's would both fire.
          toggleOnTargetTap: false,
          semanticLabel: widget.menuSemanticLabel,
          targetAnchor: AlignmentDirectional.bottomEnd,
          followerAnchor: AlignmentDirectional.topEnd,
          items: widget.items,
          target: CcButton._caret(
            variant: widget.variant,
            size: widget.size,
            semanticLabel: widget.menuSemanticLabel,
            onPressed: enabled ? _menu.toggle : null,
            child: const CcIcon(CcIcons.chevronDown, size: 14),
          ),
        ),
      ],
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
