import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// A flat panel surface — a hairline-bordered container that holds content.
///
/// Per DESIGN.md it carries no shadow in flow: depth comes from the border, not
/// elevation. The fill/border come from [tokens] ([CcCardTokens.panel] by
/// default, or [CcCardTokens.surface] for the tighter secondary surface).
///
/// When [interactive] is true and [onPressed] is non-null the card becomes a
/// [CcTappable] that washes its background to the token hover color on hover and
/// exposes itself as a semantic button. Parents that are not buttons but still
/// need the wash (drag sources) pass [hovered] instead.
class CcCard extends StatelessWidget {
  /// Creates a [CcCard].
  const CcCard({
    super.key,
    required this.child,
    this.padding,
    this.interactive = false,
    this.hovered = false,
    this.onPressed,
    this.tokens,
    this.semanticLabel,
  });

  /// The card's content.
  final Widget child;

  /// Inner padding; defaults to `EdgeInsets.all(AppSpacing.md)`.
  final EdgeInsets? padding;

  /// Whether the card responds to hover/press as a tappable surface. Only takes
  /// effect when [onPressed] is also non-null.
  final bool interactive;

  /// Paints the hover wash without making the card a button. Parents that
  /// track pointer state (drag sources) set this. Ignored when [interactive]
  /// is true — pointer state drives the wash there.
  final bool hovered;

  /// Tap handler for an [interactive] card.
  final VoidCallback? onPressed;

  /// Surface colors; defaults to [CcCardTokens.panel].
  final CcCardTokens? tokens;

  /// Accessibility label for an interactive card.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final cardTokens = tokens ?? CcCardTokens.panel(t);
    final resolvedPadding = padding ?? const EdgeInsets.all(AppSpacing.md);
    final isInteractive = interactive && onPressed != null;

    if (!isInteractive) {
      return _surface(cardTokens, resolvedPadding, washed: hovered);
    }

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brLg,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final washed =
            states.contains(WidgetState.pressed) ||
            (states.contains(WidgetState.hovered) &&
                !CcFluidHover.isItemActive(context));
        return _surface(cardTokens, resolvedPadding, washed: washed);
      },
    );
  }

  Widget _surface(
    CcCardTokens cardTokens,
    EdgeInsets resolvedPadding, {
    required bool washed,
  }) {
    // The hover token is a translucent wash; layer it over the base fill so
    // the panel never becomes transparent.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardTokens.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: cardTokens.border),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: washed ? cardTokens.hoverBg : null,
          borderRadius: AppRadii.brLg,
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
