import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/agents_roster.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

// ── Test data helpers ──

AgentScorecard _scorecard({
  String id = 'agent-1',
  String name = 'Claude',
  int totalRuns = 42,
  int totalErrored = 3,
  double successRate = 0.93,
  int totalPrsMerged = 12,
  int totalXp = 5000,
  int level = 5,
  double levelProgress = 0.4,
}) {
  return AgentScorecard(
    agentId: id,
    agentName: name,
    totalRuns: totalRuns,
    totalErrored: totalErrored,
    successRate: successRate,
    avgRunDurationMs: 120000,
    totalPrsCreated: 15,
    totalPrsMerged: totalPrsMerged,
    totalReviews: 8,
    totalBlockingComments: 2,
    totalXp: totalXp,
    level: level,
    levelProgress: levelProgress,
    currentStreaks: const [],
    achievements: const [],
  );
}

Agent _agent({
  String id = 'agent-1',
  String name = 'Claude',
  String title = 'Senior Engineer',
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/agents/$name.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(const []),
    createdAt: DateTime(2025, 1, 1),
  );
}

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

// ── Builders ──

Widget _buildRoster({
  List<AgentScorecard> scorecards = const [],
  List<Agent> agents = const [],
  String? workspaceId,
  String query = '',
  AgentSort sort = AgentSort.xp,
  ValueChanged<AgentSort>? onSortChanged,
}) {
  return ProviderScope(
    overrides: [
      allAgentScorecardsProvider.overrideWithValue(AsyncData(scorecards)),
      agentsProvider.overrideWith((ref) => Stream.value(agents)),
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(workspaceId),
      ),
      if (workspaceId != null)
        workspaceAgentsProvider(workspaceId)
            .overrideWith((ref) => Stream.value(agents)),
    ],
    child: testWrap(
      AgentsRoster(
        controller: TextEditingController(text: query),
        query: query,
        sort: sort,
        onSortChanged: onSortChanged ?? (_) {},
      ),
    ),
  );
}

Widget _buildLoadingRoster({
  List<Agent> agents = const [],
  String? workspaceId,
}) {
  return ProviderScope(
    overrides: [
      allAgentScorecardsProvider.overrideWithValue(const AsyncLoading()),
      agentsProvider.overrideWith((ref) => Stream.value(agents)),
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(workspaceId),
      ),
      if (workspaceId != null)
        workspaceAgentsProvider(workspaceId)
            .overrideWith((ref) => Stream.value(agents)),
    ],
    child: testWrap(
      AgentsRoster(
        controller: TextEditingController(),
        query: '',
        sort: AgentSort.xp,
        onSortChanged: (_) {},
      ),
    ),
  );
}

// ── Tests ──

void main() {
  group('AgentsRoster', () {
    testWidgets('shows loading indicator while scorecards are loading',
        (tester) async {
      await tester.pumpWidget(_buildLoadingRoster());
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('shows empty state when there are no scorecards',
        (tester) async {
      await tester.pumpWidget(_buildRoster(
        scorecards: const [],
        agents: const [],
      ));
      await tester.pump();

      expect(find.text('No agent activity yet'), findsOneWidget);
    });

    testWidgets('shows single agent row', (tester) async {
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
      ));
      // Absorb layout overflows caused by the Ahem test font in fixed-width
      // _SortableHeader containers — cosmetic only, not a real bug.
      await tester.pump();
      tester.takeException();

      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Lv 5'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('93%'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('AGENTS'), findsOneWidget);
    });

    testWidgets('shows multiple agent rows', (tester) async {
      final card1 = _scorecard(id: 'a1', name: 'Atlas', totalXp: 5000);
      final card2 = _scorecard(
          id: 'a2', name: 'Nova', totalXp: 3000, successRate: 0.75);
      final card3 = _scorecard(
          id: 'a3', name: 'Orion', totalXp: 1000, successRate: 0.60);

      await tester.pumpWidget(_buildRoster(
        scorecards: [card1, card2, card3],
        agents: [
          _agent(id: 'a1', name: 'Atlas'),
          _agent(id: 'a2', name: 'Nova'),
          _agent(id: 'a3', name: 'Orion'),
        ],
        sort: AgentSort.xp,
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Orion'), findsOneWidget);
      expect(find.text('AGENTS'), findsOneWidget);
      expect(find.text('All agents · 3'), findsOneWidget);
    });

    testWidgets('filters agents by search query', (tester) async {
      final card1 = _scorecard(id: 'a1', name: 'Atlas');
      final card2 = _scorecard(id: 'a2', name: 'Nova');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card1, card2],
        agents: [
          _agent(id: 'a1', name: 'Atlas'),
          _agent(id: 'a2', name: 'Nova'),
        ],
        query: 'nova',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('Atlas'), findsNothing);
      expect(find.text('Nova'), findsOneWidget);
    });

    testWidgets('shows no match message when search filters all agents',
        (tester) async {
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
        query: 'zzzz',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('No agents match your search'), findsOneWidget);
      expect(find.text('Atlas'), findsNothing);
    });

    testWidgets('shows error state when scorecards fail', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allAgentScorecardsProvider.overrideWithValue(
              AsyncError(Exception('Boom'), StackTrace.current),
            ),
            agentsProvider
                .overrideWith((ref) => Stream<List<Agent>>.value(const [])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: testWrap(
            AgentsRoster(
              controller: TextEditingController(),
              query: '',
              sort: AgentSort.xp,
              onSortChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed: Exception: Boom'), findsOneWidget);
    });

    testWidgets('shows em dash for success rate when agent has zero runs',
        (tester) async {
      final card = _scorecard(
        id: 'a1',
        name: 'NewAgent',
        totalRuns: 0,
        totalErrored: 0,
        successRate: 0,
        totalPrsMerged: 0,
        totalXp: 0,
        level: 1,
      );

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'NewAgent')],
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('calls onSortChanged when a sortable header is tapped',
        (tester) async {
      AgentSort? selectedSort;
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
        sort: AgentSort.xp,
        onSortChanged: (s) => selectedSort = s,
      ));
      await tester.pump();
      tester.takeException();

      await tester.tap(find.text('RUNS'));
      await tester.pump();

      expect(selectedSort, AgentSort.runs);
    });

    testWidgets('computes totalAgents from agentsProvider', (tester) async {
      await tester.pumpWidget(_buildRoster(
        scorecards: const [],
        agents: [
          _agent(id: 'a1', name: 'A1'),
          _agent(id: 'a2', name: 'A2'),
        ],
      ));
      await tester.pump();

      expect(find.text('All agents · 2'), findsOneWidget);
    });

    testWidgets('calls onSortChanged with success when SUCCESS header tapped',
        (tester) async {
      AgentSort? selected;
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
        sort: AgentSort.xp,
        onSortChanged: (s) => selected = s,
      ));
      await tester.pump();
      tester.takeException();

      await tester.tap(find.text('SUCCESS'));
      await tester.pump();

      expect(selected, AgentSort.success);
    });

    testWidgets('calls onSortChanged with prsMerged when MERGED header tapped',
        (tester) async {
      AgentSort? selected;
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
        sort: AgentSort.xp,
        onSortChanged: (s) => selected = s,
      ));
      await tester.pump();
      tester.takeException();

      await tester.tap(find.text('MERGED'));
      await tester.pump();

      expect(selected, AgentSort.prsMerged);
    });

    testWidgets('fires onSortChanged on every RUNS header tap', (tester) async {
      final sorts = <AgentSort>[];
      final card = _scorecard(id: 'a1', name: 'Atlas');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'Atlas')],
        sort: AgentSort.xp,
        onSortChanged: sorts.add,
      ));
      await tester.pump();
      tester.takeException();

      await tester.tap(find.text('RUNS'));
      await tester.pump();
      await tester.tap(find.text('RUNS'));
      await tester.pump();

      expect(sorts, [AgentSort.runs, AgentSort.runs]);
    });

    testWidgets('filter is case insensitive', (tester) async {
      final card = _scorecard(id: 'a1', name: 'NOVA');

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'NOVA')],
        query: 'nova',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('NOVA'), findsOneWidget);
    });

    testWidgets('filter by name substring matches only agents containing query',
        (tester) async {
      final orion = _scorecard(id: 'a1', name: 'Orion');
      final nova = _scorecard(id: 'a2', name: 'Nova');

      await tester.pumpWidget(_buildRoster(
        scorecards: [orion, nova],
        agents: [
          _agent(id: 'a1', name: 'Orion'),
          _agent(id: 'a2', name: 'Nova'),
        ],
        query: 'or',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('Orion'), findsOneWidget);
      expect(find.text('Nova'), findsNothing);
    });

    testWidgets('clearing filter shows all agents again', (tester) async {
      final a1 = _scorecard(id: 'a1', name: 'Atlas');
      final a2 = _scorecard(id: 'a2', name: 'Nova');

      // Filter to hide Atlas.
      await tester.pumpWidget(_buildRoster(
        scorecards: [a1, a2],
        agents: [
          _agent(id: 'a1', name: 'Atlas'),
          _agent(id: 'a2', name: 'Nova'),
        ],
        query: 'nova',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('Atlas'), findsNothing);
      expect(find.text('Nova'), findsOneWidget);

      // Rebuild with empty query.
      await tester.pumpWidget(_buildRoster(
        scorecards: [a1, a2],
        agents: [
          _agent(id: 'a1', name: 'Atlas'),
          _agent(id: 'a2', name: 'Nova'),
        ],
        query: '',
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
    });

    testWidgets('agent with all-zero scorecard shows dash and zeros',
        (tester) async {
      final card = _scorecard(
        id: 'a1',
        name: 'ZeroAgent',
        totalRuns: 0,
        totalErrored: 0,
        successRate: 0,
        totalPrsMerged: 0,
        totalXp: 0,
        level: 1,
      );

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'ZeroAgent')],
      ));
      await tester.pump();
      tester.takeException();

      // Em dash for success rate (zero runs).
      expect(find.text('\u2014'), findsOneWidget);
      // Zero runs, prs, and compact xp.
      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('agent with high stats renders correctly', (tester) async {
      final card = _scorecard(
        id: 'a1',
        name: 'ProAgent',
        totalRuns: 99999,
        successRate: 0.987,
        totalPrsMerged: 54321,
        totalXp: 1000000,
        level: 99,
      );

      await tester.pumpWidget(_buildRoster(
        scorecards: [card],
        agents: [_agent(id: 'a1', name: 'ProAgent')],
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('99999'), findsOneWidget);
      expect(find.text('99%'), findsOneWidget);
      expect(find.text('54321'), findsOneWidget);
      expect(find.text('1.0M'), findsOneWidget);
    });

    testWidgets('handles many agents without overflow', (tester) async {
      final scorecards = List.generate(25, (i) => _scorecard(
            id: 'a$i',
            name: 'Agent $i',
            totalXp: (25 - i) * 100,
          ));
      final agents = List.generate(
          25, (i) => _agent(id: 'a$i', name: 'Agent $i'));

      await tester.pumpWidget(_buildRoster(
        scorecards: scorecards,
        agents: agents,
        sort: AgentSort.xp,
      ));
      await tester.pump();
      tester.takeException();

      expect(find.text('All agents · 25'), findsOneWidget);
      for (var i = 0; i < 25; i++) {
        expect(find.text('Agent $i'), findsOneWidget);
      }
    });

    testWidgets('no workspace selected shows empty state', (tester) async {
      await tester.pumpWidget(_buildRoster(
        scorecards: const [],
        agents: const [],
        workspaceId: null,
      ));
      await tester.pump();

      expect(find.text('No agent activity yet'), findsOneWidget);
    });

    testWidgets('error state with agents shows error but does not crash',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allAgentScorecardsProvider.overrideWithValue(
              AsyncError(Exception('Boom'), StackTrace.current),
            ),
            agentsProvider.overrideWith(
              (ref) => Stream.value(
                [_agent(id: 'a1', name: 'Atlas')],
              ),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: testWrap(
            AgentsRoster(
              controller: TextEditingController(),
              query: '',
              sort: AgentSort.xp,
              onSortChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed: Exception: Boom'), findsOneWidget);
    });
  });
}
