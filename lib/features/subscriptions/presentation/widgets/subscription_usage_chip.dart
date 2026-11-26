import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/ai_brand_logo.dart';
import 'package:flutter/widgets.dart';

/// One provider's entry in the pill: its mark and its worst account's reading.
class ProviderUsageReading {
  /// Creates a [ProviderUsageReading].
  const ProviderUsageReading({
    required this.providerId,
    required this.displayName,
    required this.fraction,
    required this.failed,
    this.balance,
  });

  /// The provider's id, which also picks its logo.
  final String providerId;

  /// The provider's name, spoken in place of the logo.
  final String displayName;

  /// The most-constrained account's used fraction, or null when no account of
  /// this provider produced a reading (a sign-in is needed, the plan reports
  /// no windows, or the fetch failed). `1.0` for a plan that said it is spent.
  final double? fraction;

  /// Whether any account's usage fetch failed outright.
  final bool failed;

  /// The money left on a prepaid provider, already formatted. Shown when
  /// there is no [fraction]: a balance has no share used to report.
  final String? balance;
}

/// The title-bar chip: each provider's logo beside its reading, in one
/// bordered control that opens the usage flyout.
class SubscriptionUsageChip extends StatelessWidget {
  /// Creates a [SubscriptionUsageChip].
  const SubscriptionUsageChip({
    required this.readings,
    required this.onTap,
    super.key,
  });

  /// One entry per configured provider, in the server's provider order.
  final List<ProviderUsageReading> readings;

  /// Opens the flyout.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    String? percent(ProviderUsageReading r) {
      final f = r.fraction;
      return f == null ? null : '${(f * 100).round()}%';
    }

    String? left(ProviderUsageReading r) {
      final balance = r.balance;
      return balance == null
          ? null
          : l10n.subscriptionUsageBalanceLeft(balance);
    }

    String? spoken(ProviderUsageReading r) =>
        percent(r) ??
        left(r) ??
        (r.failed ? l10n.subscriptionUsageUnavailable : null);

    // The logos are pictures, so a screen reader gets the provider names and
    // readings spelled out instead.
    final summary = [
      for (final r in readings) [r.displayName, ?spoken(r)].join(' '),
    ].join(', ');

    return CcTooltip(
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.bottomCenter,
      message: l10n.subscriptionUsage,
      child: CcTappable(
        onPressed: onTap,
        semanticLabel: '${l10n.subscriptionUsage}: $summary',
        borderRadius: AppRadii.brSm,
        builder: (context, states) {
          final hover = states.contains(WidgetState.hovered);
          final bg = hover ? t.bgSecondaryHover : t.bgSecondary;
          // Pre-blend lineStrong against the hover fill so the border tween
          // runs between two OPAQUE endpoints (same treatment as
          // CcButtonTokens.secondary): lerping the raw fg@16% token against
          // opaque borderPrimary peaks darker than either end mid-tween — a
          // dark-border flicker on hover↔rest.
          final border = hover
              ? Color.alphaBlend(t.lineStrong, t.bgSecondaryHover)
              : t.borderPrimary;
          return AnimatedContainer(
            // A color wash, so reduced motion keeps a short fade.
            duration: CcMotion.resolveFade(context, CcMotion.moderateExit),
            curve: Curves.easeOut,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: border),
            ),
            // The label above already speaks every reading.
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < readings.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    _ReadingChip(
                      reading: readings[i],
                      label: percent(readings[i]) ?? readings[i].balance,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  const _ReadingChip({required this.reading, required this.label});

  final ProviderUsageReading reading;

  /// The rendered percentage or balance, or null when the provider has no
  /// reading.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final f = reading.fraction;
    final text = label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AiBrandLogo(
          brand: AiBrand.forProvider(reading.providerId),
          // No reading: the mark alone, receded. The flyout says why.
          color: text == null && !reading.failed
              ? t.textQuaternary
              : t.textSecondary,
          size: 12,
        ),
        if (text == null && reading.failed) ...[
          const SizedBox(width: AppSpacing.xxs),
          Icon(AppIcons.alertTriangle, size: 11, color: t.textWarningPrimary),
        ],
        if (text != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppFonts.numericStyle(
              // The number is the status (colour only reinforces it), and the
              // text tokens are the ones that clear contrast at 11px.
              color: f == null
                  ? t.textSecondary
                  : f >= 0.9
                  ? t.textErrorPrimary
                  : f >= 0.75
                  ? t.textWarningPrimary
                  : t.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
