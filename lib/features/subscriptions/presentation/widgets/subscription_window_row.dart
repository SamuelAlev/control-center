import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One quota window: its label, the percentage used, a meter, and when it
/// resets.
///
/// Shared by the title-bar usage pill and Settings → Adapters, so a plan reads
/// identically wherever it is surfaced — the same wording, the same colour
/// ramp, the same countdown format.
class SubscriptionWindowRow extends StatelessWidget {
  /// Creates a [SubscriptionWindowRow].
  const SubscriptionWindowRow({required this.window, super.key});

  /// The quota window to render.
  final SubscriptionWindow window;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pct = (window.usedFraction * 100).round();
    final reset = window.resetsAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                window.label,
                style: TextStyle(color: t.textSecondary, fontSize: 12),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CcProgressBar(
          value: window.usedFraction,
          height: 6,
          color: subscriptionUsageColor(window.usedFraction, t),
          semanticLabel: '${window.label}: $pct%',
        ),
        if (reset != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.resetsIn(formatSubscriptionReset(reset)),
            style: TextStyle(color: t.textTertiary, fontSize: 11),
          ),
        ],
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
