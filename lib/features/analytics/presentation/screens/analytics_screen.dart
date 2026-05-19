import 'package:control_center/di/providers.dart';
import 'package:control_center/features/analytics/presentation/screens/analytics_keepalive_bindings.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/activity_heatmap_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/agents_roster.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/leaderboard_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/top_performer_hero.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/user_badges_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/workspace_pulse_card.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent performance analytics: scorecards, leaderboard, badges and workspace
/// health, with a refresh control reporting when the data was last checked.
class AnalyticsScreen extends ConsumerStatefulWidget {
  /// Creates an [AnalyticsScreen].
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  AgentSort _sort = AgentSort.xp;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() {
      if (_searchCtl.text != _query) {
        setState(() => _query = _searchCtl.text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(xpEngineProvider);
    keepAnalyticsSnapshotAlive(ref);
    final l10n = AppLocalizations.of(context);

    // Stamp freshness when the scorecards (the screen's primary fetch) reload.
    ref.listen(allAgentScorecardsProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('analytics');
      }
    });
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['analytics']),
    );

    void refreshAll() {
      ref
        ..invalidate(allAgentScorecardsProvider)
        ..invalidate(leaderboardProvider)
        ..invalidate(allWorkspaceHealthProvider)
        ..invalidate(userBadgesProvider);
    }

    return ScopedShortcuts(
      scope: '/analytics',
      bindings: {'analytics.refresh': refreshAll},
      child: PageWrapper(
      title: l10n.navAnalytics,
      subtitle: l10n.topPerformersDescription,
      actions: [
        RefreshControl(
          lastChecked: lastChecked,
          tooltip: l10n.refresh,
          onRefresh: refreshAll,
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const TopPerformerHero(),
          const SizedBox(height: 20),
          const UserBadgesCard(),
          const SizedBox(height: 20),
          const ActivityHeatmapCard(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 880;
              if (isNarrow) {
                return const Column(
                  children: [
                    LeaderboardCard(),
                    SizedBox(height: 16),
                    WorkspacePulseCard(),
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: LeaderboardCard()),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: WorkspacePulseCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AgentsRoster(
            controller: _searchCtl,
            query: _query,
            sort: _sort,
            onSortChanged: (s) => setState(() => _sort = s),
          ),
        ],
      ),
      ),
    );
  }
}
