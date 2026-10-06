import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One quota window: its label, a meter, how much of it is used and when it
/// resets.
///
/// Shared by the title-bar usage popover and Settings → Adapters, so a plan
/// reads identically wherever it is surfaced — the same wording, the same
/// colour ramp, the same countdown format.
class SubscriptionWindowRow extends StatelessWidget {
  /// Creates a [SubscriptionWindowRow].
  const SubscriptionWindowRow({
    required this.window,
    this.valueOverride,
    super.key,
  });

  /// The quota window to render.
  final SubscriptionWindow window;

  /// Replaces the "N% used" reading under the meter.
  ///
  /// A credit balance is read in money, not percent: `$1.41` of a `$600` cap
  /// rounds to "0%", which is true and tells the operator nothing.
  final String? valueOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pct = (window.usedFraction * 100).round();
    final reading = valueOverride ?? l10n.subscriptionUsagePercentUsed(pct);
    final reset = window.resetsAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          window.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        CcProgressBar(
          value: window.usedFraction,
          height: 6,
          color: subscriptionUsageColor(window.usedFraction, t),
          // fg@8%: reads as a track on the white panel AND on the warm
          // surface the popover groups windows on, in both themes.
          trackColor: t.hoverStrong,
          semanticLabel: '${window.label}: $reading',
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                reading,
                style: TextStyle(color: t.textSecondary, fontSize: 12),
              ),
            ),
            if (reset != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.resetsIn(formatSubscriptionReset(reset)),
                style: TextStyle(color: t.textTertiary, fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A quota meter reads as calm when there's headroom and escalates as it fills:
/// success (under 75% used), warning (75–90%), danger (90%+). Never the only
/// signal — the percentage and labels are always shown alongside.
Color subscriptionUsageColor(double usedFraction, DesignSystemTokens t) {
  if (usedFraction >= 0.9) {
    return t.danger;
  }
  if (usedFraction >= 0.75) {
    return t.warn;
  }
  return t.success;
}

/// Compact "40m" / "2h 10m" / "3d" until [when] (assumed future).
String formatSubscriptionReset(DateTime when) {
  final d = when.difference(DateTime.now());
  if (d.inMinutes <= 0) {
    return '0m';
  }
  if (d.inHours < 1) {
    return '${d.inMinutes}m';
  }
  if (d.inHours < 24) {
    final mins = d.inMinutes % 60;
    return mins == 0 ? '${d.inHours}h' : '${d.inHours}h ${mins}m';
  }
  return '${d.inDays}d';
}
