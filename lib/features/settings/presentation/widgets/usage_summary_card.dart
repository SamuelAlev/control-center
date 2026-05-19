import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Adapters → "Usage & cost" (PRD 05, feature #12).
///
/// Shows the workspace's spend over the last 7 days (from observed run-cost
/// history) plus, when known, the nearest quota-window reset — e.g.
/// *"$12.40 spent this week, resets in 40m"*.
class UsageSummaryCard extends ConsumerWidget {
  /// Creates a [UsageSummaryCard].
  const UsageSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(weeklyCostSummaryProvider);
    final tokens = context.designSystem;

    return SectionCard(
      label: l10n.usageAndCost,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      headerPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      subtitle: Text(l10n.usageAndCostDescription),
      child: summary.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => Text(l10n.failedWithError('$e')),
        data: (data) {
          if (data.isEmpty) {
            return Text(
              l10n.noUsageYet,
              style: TextStyle(color: tokens?.textTertiary),
            );
          }
          final reset = data.nextResetAt;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$${data.totalUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.spentThisWeek,
                    style: TextStyle(color: tokens?.textTertiary),
                  ),
                ],
              ),
              if (reset != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.resetsIn(_formatUntil(reset)),
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                ),
              ],
              const SizedBox(height: 12),
              ..._breakdown(context, data),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _breakdown(BuildContext context, CostSummary data) {
    final tokens = context.designSystem;
    final entries = data.byProvider.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(e.key, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                '\$${e.value.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: tokens?.textSecondary),
              ),
            ],
          ),
        ),
    ];
  }

  /// Compact "in 40m" / "in 2h 10m" / "in 3d" until [when] (assumed future).
  static String _formatUntil(DateTime when) {
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
}
