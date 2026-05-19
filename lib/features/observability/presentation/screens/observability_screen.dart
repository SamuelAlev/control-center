import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/insights_tab.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/live_tab.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/quality_tab.dart';
import 'package:control_center/features/observability/presentation/widgets/tabs/usage_tab.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The observability hub: four tabs over the workspace run-log feed — Usage
/// (lifetime token totals, the activity calendar, the per-model trend and
/// split), Insights (time-ranged KPIs, charts, breakdowns, per-agent and
/// per-run rows), Live (roster, quotas, goal, fleet) and Quality (benchmark,
/// evals).
class ObservabilityScreen extends ConsumerStatefulWidget {
  /// Creates an [ObservabilityScreen].
  const ObservabilityScreen({super.key});

  @override
  ConsumerState<ObservabilityScreen> createState() =>
      _ObservabilityScreenState();
}

class _ObservabilityScreenState extends ConsumerState<ObservabilityScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScopedShortcuts(
      scope: '/observability',
      bindings: const {},
      child: PageWrapper(
        title: l10n.navObservability,
        subtitle: l10n.obsScreenSubtitle,
        child: CcTabView(
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
          scrollable: false,
          expand: true,
          tabs: [
            CcTabViewEntry(
              label: Text(l10n.obsTabUsage),
              content: const UsageTab(),
            ),
            CcTabViewEntry(
              label: Text(l10n.obsTabInsights),
              content: const InsightsTab(),
            ),
            CcTabViewEntry(
              label: Text(l10n.obsTabLive),
              content: const LiveTab(),
            ),
            CcTabViewEntry(
              label: Text(l10n.obsTabQuality),
              content: const QualityTab(),
            ),
          ],
        ),
      ),
    );
  }
}
