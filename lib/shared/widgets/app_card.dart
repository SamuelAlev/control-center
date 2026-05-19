import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A hover-aware drop-in for [CcCard] that follows the design system's
/// `bg-primary` / `bg-primary_hover` tokens.
///
/// Behaves like [CcCard] — forwards [title], [subtitle], [image], [child] —
/// but when [onTap] is provided the background washes to the token hover color
/// while the pointer is over the card (handled by [CcCard]'s built-in
/// interactive surface). Border colors come from the design-system
/// `border-secondary` token via [CcCard].
///
/// Use this anywhere a card should react to hover. Non-interactive cards can
/// keep using [CcCard] directly — they already inherit `bg-primary` from the
/// theme.
class AppCard extends StatelessWidget {
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

  /// Optional tap handler. When provided, the card becomes interactive so it
  /// also picks up focus + keyboard activation and the hover wash.
  final VoidCallback? onTap;

  /// Optional focus node. Reserved for callers that drive keyboard focus from
  /// the outside (e.g. list-cursor shortcuts).
  final FocusNode? focusNode;

  /// Optional inner padding. When null [CcCard] applies its default padding.
  final EdgeInsets? padding;

  /// Drop the default content padding (equivalent to the old `FCard.raw`).
  final bool raw;

  /// Animation duration for the hover color transition.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final body = _composeBody();
    final resolvedPadding = padding ?? (raw ? EdgeInsets.zero : null);

    return CcCard(
      padding: resolvedPadding,
      interactive: onTap != null,
      onPressed: onTap,
      child: body,
    );
  }

  Widget _composeBody() {
    final content = child ?? const SizedBox.shrink();
    if (title == null && subtitle == null && image == null) {
      return content;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?image,
        ?title,
        ?subtitle,
        if (child != null) content,
      ],
    );
  }
}
