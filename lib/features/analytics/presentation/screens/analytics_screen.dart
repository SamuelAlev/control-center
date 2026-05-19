import 'package:control_center/di/providers.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/activity_heatmap_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/agents_roster.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/leaderboard_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/top_performer_hero.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/user_badges_card.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/workspace_pulse_card.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
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
    ref.watch(snapshotAggregatorProvider);
    final l10n = AppLocalizations.of(context);

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
        FTooltip(
          tipBuilder: (_, _) => Text(l10n.refresh),
          child: FButton.icon(
            onPress: refreshAll,
            child: const Icon(LucideIcons.refreshCw, size: 16),
          ),
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
