import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A hover-aware drop-in for `FCard` that follows design system's
/// `bg-primary` / `bg-primary_hover` tokens.
///
/// Behaves like `FCard` — forwards [title], [subtitle], [image], [child] —
/// but the background animates from
/// `--color-bg-primary` to `--color-bg-primary_hover` when the pointer is
/// over the card. Border colors come from the global `FColors.border`
/// (which the theme wires to `--color-border-secondary`).
///
/// Use this anywhere a card should react to hover. Non-interactive cards
/// can keep using `FCard` directly — they already inherit `bg-primary`
/// from the theme.
class AppCard extends StatefulWidget {
  /// Creates a new [AppCard].
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.image,
    this.child,
    this.onTap,
    this.focusNode,
    this.padding,
    this.raw = false,
    this.duration = const Duration(milliseconds: 120),
  });

  /// Card title widget.
  final Widget? title;

  /// Card subtitle widget.
  final Widget? subtitle;

  /// Card image widget.
  final Widget? image;

  /// Card body child.
  final Widget? child;

  /// Optional tap handler. When provided, the card becomes a [FTappable] so
  /// it also picks up focus + keyboard activation.
  final VoidCallback? onTap;

  /// Optional focus node, forwarded to the inner [FTappable]. Lets callers
  /// drive keyboard focus from the outside (e.g. list-cursor shortcuts).
  final FocusNode? focusNode;

  /// Optional inner padding. When null the underlying `FCard` handles its
  /// own padding via `contentStyle`.
  final EdgeInsetsGeometry? padding;

  /// Use `FCard.raw` instead of `FCard` to avoid default content padding.
  final bool raw;

  /// Animation duration for the hover color transition.
  final Duration duration;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    final baseStyle = theme.cardStyle;
    final baseDecoration = baseStyle.decoration;

    final bg = _hovered
        ? (tokens?.bgPrimaryHover ?? theme.colors.muted)
        : (tokens?.bgPrimary ?? theme.colors.card);

    final decoration = baseDecoration is ShapeDecoration
        ? ShapeDecoration(shape: baseDecoration.shape, color: bg)
        : ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: theme.colors.border,
                width: theme.style.borderWidth,
              ),
              borderRadius: theme.style.borderRadius.lg,
            ),
            color: bg,
          );

    final child = widget.padding == null
        ? (widget.child ?? const SizedBox.shrink())
        : Padding(padding: widget.padding!, child: widget.child);

    final card = widget.raw
        ? FCard.raw(
            style: FCardStyle(
              decoration: decoration,
              contentStyle: baseStyle.contentStyle,
            ),
            child: child,
          )
        : FCard(
            style: FCardStyle(
              decoration: decoration,
              contentStyle: baseStyle.contentStyle,
            ),
            title: widget.title,
            subtitle: widget.subtitle,
            image: widget.image,
            child: child,
          );

    final hoverable = MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        child: card,
      ),
    );

    if (widget.onTap == null) {
      return hoverable;
    }

    return FTappable(
      onPress: widget.onTap,
      focusNode: widget.focusNode,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      onHoverChange: _setHovered,
      child: hoverable,
    );
  }
}
