import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat panel surface — a hairline-bordered container that holds content.
///
/// Per DESIGN.md it carries no shadow in flow: depth comes from the border, not
/// elevation. The fill/border come from [tokens] ([CcCardTokens.panel] by
/// default, or [CcCardTokens.surface] for the tighter secondary surface).
///
/// When [interactive] is true and [onPressed] is non-null the card becomes a
/// [CcTappable] that washes its background to the token hover color on hover and
/// exposes itself as a semantic button.
class CcCard extends StatelessWidget {
  /// Creates a [CcCard].
  const CcCard({
    super.key,
    required this.child,
    this.padding,
    this.interactive = false,
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

  /// Tap handler for an [interactive] card.
  final VoidCallback? onPressed;

  /// Surface colors; defaults to [CcCardTokens.panel].
  final CcCardTokens? tokens;

  /// Accessibility label for an interactive card.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final cardTokens = tokens ?? CcCardTokens.panel(t);
    final resolvedPadding = padding ?? const EdgeInsets.all(AppSpacing.md);
    final isInteractive = interactive && onPressed != null;

    if (!isInteractive) {
      return _surface(cardTokens.bg, cardTokens.border, resolvedPadding);
    }

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brLg,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
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
              color: hovered ? cardTokens.hoverBg : null,
              borderRadius: AppRadii.brLg,
            ),
            child: Padding(padding: resolvedPadding, child: child),
          ),
        );
      },
    );
  }

  Widget _surface(Color bg, Color border, EdgeInsets resolvedPadding) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: border),
      ),
      child: Padding(padding: resolvedPadding, child: child),
    );
  }
}
