import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agents_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 7, 26);

/// Builds a run log. Pass [startedAt] whenever a test depends on which run is
/// an agent's CURRENT one — the default is shared by every fixture, so relying on
/// it would only prove list order rather than the newest-run rule.
AgentRunLog _run({
  required String id,
  String agentId = 'agent-1',
  RunStatus status = RunStatus.completed,
  String? summary,
  String? parentRunId,
  DateTime? startedAt,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'c-1',
  startedAt: startedAt ?? _t0,
  status: status,
  summary: summary,
  parentRunId: parentRunId,
);

class _StaticRunLogRepo implements AgentRunLogRepository {
  _StaticRunLogRepo(this.logs);

  final List<AgentRunLog> logs;

  // The AGENTS panel is a SPACE-level surface: it lists who has worked in the
  // space, across every conversation in it, so it reads the space stream.
  @override
  Stream<List<AgentRunLog>> watchBySpace(String workspaceId, String spaceId) =>
      Stream.value(logs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  /// One parent run with a spawned subagent — the shape the section exists for.
  final parentAndChild = [
    _run(id: 'run-parent', status: RunStatus.running, summary: 'main work'),
    _run(
      id: 'run-child',
      status: RunStatus.running,
      summary: 'scout the repo',
      parentRunId: 'run-parent',
    ),
  ];

  Future<List<AgentRunTarget>> pump(
    WidgetTester tester, {
    required List<AgentRunLog> logs,
  }) async {
    final opened = <AgentRunTarget>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentRunLogRepositoryProvider.overrideWithValue(
            _StaticRunLogRepo(logs),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: CcToastScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: AgentsSection(
                    spaceId: 'c-1',
                    workspaceId: 'ws-1',
                    onOpenAgentRun: opened.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Fixed pumps: a running agent's status dot pulses forever, so
    // `pumpAndSettle` would never complete.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return opened;
  }

  testWidgets('renders a root agent row with its subagent nested beneath', (
    tester,
  ) async {
    await pump(tester, logs: parentAndChild);

    expect(find.text('agent-1'), findsOneWidget, reason: 'the root agent row');
    expect(find.text('scout the repo'), findsOneWidget, reason: 'the sub row');
  });

  testWidgets('tapping a SUBAGENT row asks for its own activity', (
    tester,
  ) async {
    final opened = await pump(tester, logs: parentAndChild);

    await tester.tap(find.text('scout the repo'));
    await tester.pump();

    expect(opened, hasLength(1));
    expect(opened.single.runId, 'run-child');
    expect(opened.single.label, 'scout the repo');
    expect(
      opened.single.isSubAgent,
      isTrue,
      reason: 'a subagent run has no home other than its own activity tab',
    );
  });

  testWidgets('tapping a ROOT agent row asks for the conversation', (
    tester,
  ) async {
    final opened = await pump(tester, logs: parentAndChild);

    await tester.tap(find.text('agent-1'));
    await tester.pump();

    expect(opened, hasLength(1));
    expect(opened.single.runId, 'run-parent');
    expect(
      opened.single.isSubAgent,
      isFalse,
      reason: "a top-level run's activity IS the conversation",
    );
  });

  testWidgets('shows the empty state when the conversation has no runs', (
    tester,
  ) async {
    await pump(tester, logs: const []);

    expect(find.text('scout the repo'), findsNothing);
  });

  group('extraction regression guard', () {
    testWidgets('a root row keeps its pause control while running', (
      tester,
    ) async {
      await pump(tester, logs: parentAndChild);

      // The control is announced via Semantics, not a Tooltip.
      expect(
        find.byIcon(AppIcons.pause),
        findsWidgets,
        reason: 'the pause affordance moved with the section',
      );
    });

    testWidgets('a root row renders no keyboard hint', (tester) async {
      await pump(tester, logs: parentAndChild);

      // The ⌘N row hints advertised a shortcut that no longer exists, so no
      // kbd chip may render here.
      expect(find.byType(CcKbd), findsNothing);
    });
  });

  testWidgets("a subagent's guide line hangs under the parent row's dot", (
    tester,
  ) async {
    await pump(tester, logs: parentAndChild);

    // The connector paints its vertical guide one dot-radius in from its own
    // left edge, so aligning that edge with the parent's dot puts the line
    // under the dot's center — not floating out to the right of the label.
    final connector = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}'.contains('Tree'),
    );
    expect(connector, findsOneWidget, reason: 'the child row is connected');

    final parentDot = find.byType(AgentStatusDot).first;
    expect(tester.getTopLeft(connector).dx, tester.getTopLeft(parentDot).dx);
    // The connector fills its row's content box, so its 5px vertical bleed
    // exactly spans the row padding and consecutive siblings share one
    // unbroken line.
    expect(tester.getSize(connector).height, 20);
    // One indent level, deliberately tighter than the row height: a subagent
    // reads as a detail of its parent rather than a column of its own.
    expect(tester.getSize(connector).width, 12);
  });

  testWidgets('the guide line descends from the parent dot, not from the '
      'row boundary below it', (tester) async {
    await pump(tester, logs: parentAndChild);

    // The parent row paints the head of the rail itself: without it the line
    // began a row-padding below the dot and read as floating rather than
    // hanging off this agent.
    final head = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}'.contains('Trunk'),
    );
    expect(head, findsOneWidget, reason: 'only the parent row has children');

    final headRect = tester.getRect(head);
    expect(
      headRect.center.dy,
      tester.getCenter(find.byType(AgentStatusDot).first).dy,
      reason:
          'symmetric row padding puts the dot on the box centre line, '
          'which is where the painter starts the stroke',
    );

    final connector = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}'.contains('Tree'),
    );
    // Row bottom == connector top minus the connector's upward bleed: the two
    // strokes meet with no gap.
    expect(headRect.bottom, tester.getTopLeft(connector).dy - 5);
  });

  testWidgets('a childless agent paints no dangling guide head', (
    tester,
  ) async {
    await pump(
      tester,
      logs: [_run(id: 'solo', status: RunStatus.running)],
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && '${w.painter.runtimeType}'.contains('Trunk'),
      ),
      findsNothing,
    );
  });

  testWidgets('a third level renders and its parent paints a head for it', (
    tester,
  ) async {
    // The section renders the whole tree, not a fixed two levels: a subagent
    // that spawned its own subagent gets a row and its parent's guide head now
    // descends to something real instead of being suppressed.
    await pump(
      tester,
      logs: [
        ...parentAndChild,
        _run(
          id: 'run-grandchild',
          status: RunStatus.running,
          summary: 'deeper still',
          parentRunId: 'run-child',
        ),
      ],
    );

    expect(find.text('deeper still'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && '${w.painter.runtimeType}'.contains('Trunk'),
      ),
      findsNWidgets(2),
      reason: 'the root row and the subagent row both have rendered children',
    );
  });

  /// Message A spawned `explorer-a`; message B then spawned `explorer-b`/`-c`.
  final twoRunsOneAgent = [
    _run(
      id: 'run-a',
      status: RunStatus.completed,
      summary: 'first attempt',
      startedAt: _t0,
    ),
    _run(
      id: 'sub-a',
      status: RunStatus.completed,
      summary: 'explorer-a',
      parentRunId: 'run-a',
      startedAt: _t0.add(const Duration(minutes: 1)),
    ),
    _run(
      id: 'run-b',
      status: RunStatus.running,
      summary: null,
      startedAt: _t0.add(const Duration(hours: 1)),
    ),
    _run(
      id: 'sub-b',
      status: RunStatus.running,
      summary: 'explorer-b',
      parentRunId: 'run-b',
      startedAt: _t0.add(const Duration(hours: 1, minutes: 1)),
    ),
    _run(
      id: 'sub-c',
      status: RunStatus.running,
      summary: 'explorer-c',
      parentRunId: 'run-b',
      startedAt: _t0.add(const Duration(hours: 1, minutes: 2)),
    ),
  ];

  testWidgets("a new run replaces the previous run's rows", (tester) async {
    // The behaviour this section is built around: sending a message gives a
    // fresh tree. The agent row stands for the newest run, its subagents hang
    // directly beneath and the previous turn leaves the sidebar entirely.
    await pump(tester, logs: twoRunsOneAgent);

    for (final label in ['explorer-b', 'explorer-c']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: '$label must have a row',
      );
    }
    expect(find.text('first attempt'), findsNothing);
    expect(find.text('explorer-a'), findsNothing);
    // No per-run layer survives, so nothing needs an ordinal name any more.
    expect(find.textContaining('Run #2'), findsNothing);
    expect(find.textContaining('run-b'), findsNothing);
    // The agent id appears once, on the agent's own identity row. It appearing
    // twice — again on a summary-less run row beneath it — is what read as the
    // agent being a subagent of itself.
    expect(
      find.text('agent-1'),
      findsOneWidget,
      reason: 'the agent identity row only; no run row may repeat the raw id',
    );
  });

  testWidgets('each subagent dot reports its own outcome', (tester) async {
    // One glance has to separate the subagent that finished from the one that
    // failed, the one still working and the one still queued.
    await pump(
      tester,
      logs: [
        _run(id: 'main', status: RunStatus.running, summary: 'working'),
        _run(
          id: 'sub-ok',
          status: RunStatus.completed,
          summary: 'finished well',
          parentRunId: 'main',
        ),
        _run(
          id: 'sub-bad',
          status: RunStatus.error,
          summary: 'blew up',
          parentRunId: 'main',
        ),
        _run(
          id: 'sub-busy',
          status: RunStatus.running,
          summary: 'still going',
          parentRunId: 'main',
        ),
        _run(
          id: 'sub-wait',
          status: RunStatus.pending,
          summary: 'not started',
          parentRunId: 'main',
        ),
      ],
    );

    final t = DesignSystemTokens.light();
    final dots = tester
        .widgetList<AgentStatusDot>(find.byType(AgentStatusDot))
        .map((d) => d.visual.dotColor)
        .toList();

    // Agent row first, then its subagents in order.
    expect(dots, [
      t.fgBrandPrimary, // main run: running -> accent
      t.fgSuccessSecondary, // finished well -> green
      t.fgErrorSecondary, // blew up -> red
      t.fgBrandPrimary, // still going -> accent
      t.fgQuaternary, // not started -> grey
    ]);
  });

  testWidgets('the header count matches the rendered rows', (tester) async {
    // A superseded run used to inflate the total while contributing no row, so
    // the header read 5/13 over three visible rows. The tree now holds exactly
    // what is drawn: 1 agent row + 2 subagents.
    await pump(tester, logs: twoRunsOneAgent);

    expect(find.text('0/3'), findsOneWidget);
  });
}
