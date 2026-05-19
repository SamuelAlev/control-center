import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Usage headline strip: five lifetime figures — total tokens, the peak
/// single day, the longest session and the current / longest active-day
/// streaks.
///
/// Every figure here is a plain quantity with no good/bad verdict attached, so
/// none of them carries a tone.
class UsageSummaryStrip extends ConsumerWidget {
  /// Creates a [UsageSummaryStrip].
  const UsageSummaryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(usageSummaryProvider);

    return ObsStatStrip(
      entries: [
        ObsStatStripEntry(
          label: l10n.obsUsageTotalTokens,
          value: fmtTokens(summary.totalTokens),
        ),
        ObsStatStripEntry(
          label: l10n.obsUsagePeakTokens,
          value: fmtTokens(summary.peakDayTokens),
        ),
        ObsStatStripEntry(
          label: l10n.obsUsageLongestSession,
          value: summary.longestSessionMs == 0
              ? '—'
              : fmtSpan(summary.longestSessionMs),
        ),
        ObsStatStripEntry(
          label: l10n.obsUsageCurrentStreak,
          value: l10n.obsUsageDayCount(summary.currentStreakDays),
        ),
        ObsStatStripEntry(
          label: l10n.obsUsageLongestStreak,
          value: l10n.obsUsageDayCount(summary.longestStreakDays),
        ),
      ],
    );
  }
}
