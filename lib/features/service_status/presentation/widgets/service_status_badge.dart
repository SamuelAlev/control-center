import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/ai_brand_logo.dart';
import 'package:flutter/widgets.dart';

/// The sidebar entry's live status badge: a colored dot, led by the faulty
/// services' logos. The status word is not painted — colour is the signal —
/// and rides along as [semanticLabel] so screen readers still hear the state.
/// In the icon-only rail the badge straddles the item square's top-trailing
/// corner, so it drops the logos there and keeps the bare dot.
class ServiceStatusBadge extends StatelessWidget {
  /// Creates a [ServiceStatusBadge].
  const ServiceStatusBadge({
    required this.color,
    required this.semanticLabel,
    required this.faulty,
    required this.selected,
    super.key,
  });

  /// The headline (worst-across-providers) indicator colour.
  final Color color;

  /// The headline status word.
  final String semanticLabel;

  /// The services that are not operational, in flyout order.
  final List<AiBrand> faulty;

  /// Whether the row is selected: the logo rings follow its brand fill.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final dot = ServiceStatusDot(color: color);
    final rail = CcSidebarScope.collapsedOf(context) ?? false;
    return Semantics(
      label: semanticLabel,
      child: rail || faulty.isEmpty
          ? dot
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ServiceLogoStack(
                  brands: faulty,
                  ringColor: selected ? tokens.bgBrandSolid : tokens.sidebar,
                ),
                const SizedBox(width: AppSpacing.sm),
                dot,
              ],
            ),
    );
  }
}

/// A glowing status dot, shared by the badge and the flyout's rows.
class ServiceStatusDot extends StatelessWidget {
  /// Creates a [ServiceStatusDot].
  const ServiceStatusDot({required this.color, this.size = 8, super.key});

  /// The status colour.
  final Color color;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

/// Overlapping monochrome circles naming the faulty services — who is down,
/// at a glance, without opening the flyout.
///
/// At most [maxSlots] circles: when the brands fit they are all drawn,
/// otherwise the last slot becomes an "N+" count of the ones left out (five
/// faulty services with three slots draw two marks and "3+"). Later circles
/// sit on top of earlier ones, so the count lands nearest the dot.
///
/// Decorative: the badge carries the status word as its semantic label and
/// the flyout names every service.
class ServiceLogoStack extends StatelessWidget {
  /// Creates a [ServiceLogoStack].
  const ServiceLogoStack({
    required this.brands,
    required this.ringColor,
    this.maxSlots = 3,
    this.size = 18,
    super.key,
  }) : assert(maxSlots >= 2, 'one slot cannot hold a mark and a count');

  /// The services to draw, in order.
  final List<AiBrand> brands;

  /// The surface behind the stack: a ring in this colour parts overlapping
  /// circles, and a hairline inside it outlines each one.
  final Color ringColor;

  /// Most circles drawn, the overflow count included.
  final int maxSlots;

  /// Edge length of each circle, ring included.
  final double size;

  static const double _overlap = 5;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final overflows = brands.length > maxSlots;
    final shown = overflows ? brands.take(maxSlots - 1).toList() : brands;
    final slots = <Widget>[
      for (final brand in shown)
        AiBrandLogo(brand: brand, color: tokens.textPrimary, size: size * 0.55),
      if (overflows)
        Text(
          l10n.serviceStatusOverflowCount(brands.length - shown.length),
          maxLines: 1,
          style: TextStyle(
            fontSize: 8.5,
            height: 1,
            fontWeight: FontWeight.w700,
            color: tokens.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
    ];
    final step = size - _overlap;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + (slots.length - 1) * step,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < slots.length; i++)
              PositionedDirectional(
                start: i * step,
                // The outer ring in the surface colour parts overlapping
                // circles; the hairline inside it draws each one's edge.
                child: Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // One step off the sidebar in both themes (bgTertiary
                      // nearly vanishes into it in light).
                      color: tokens.borderSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.borderPrimary),
                    ),
                    child: slots[i],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The colour of a provider's (or the headline) status indicator.
Color serviceIndicatorColor(
  DesignSystemTokens? tokens,
  GitHubStatusIndicator? indicator, {
  bool hasError = false,
}) {
  if (hasError) {
    return tokens?.muted ?? const Color(0xFF8B8B8B);
  }
  switch (indicator) {
    case GitHubStatusIndicator.none:
      return tokens?.success ?? const Color(0xFF1FAE5C);
    case GitHubStatusIndicator.minor:
      return tokens?.warn ?? const Color(0xFFE0B400);
    case GitHubStatusIndicator.major:
      return tokens?.warn ?? const Color(0xFFE07B00);
    case GitHubStatusIndicator.critical:
      return tokens?.danger ?? const Color(0xFFD93636);
    case GitHubStatusIndicator.maintenance:
      return tokens?.muted ?? const Color(0xFF3478F6);
    case GitHubStatusIndicator.unknown:
    case null:
      return tokens?.muted ?? const Color(0xFF8B8B8B);
  }
}
