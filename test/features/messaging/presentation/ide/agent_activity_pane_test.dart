import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_pane.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 7, 26);

AgentRunLog _run({
  String id = 'run-1',
  RunStatus status = RunStatus.completed,
  String? summary = 'scout the repo',
  int costCents = 42,
}) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  conversationId: 'c-1',
  startedAt: _t0,
  completedAt: status == RunStatus.running
      ? null
      : _t0.add(const Duration(seconds: 9)),
  status: status,
  summary: summary,
  cost: RunCost(estimatedCostCents: costCents, durationMs: 9000),
);

class _StaticRunLogRepo implements AgentRunLogRepository {
  _StaticRunLogRepo(this.logs);

  final List<AgentRunLog> logs;

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(logs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StaticRelay implements RunTranscriptRelayPort {
  _StaticRelay({
    this.segments = const [],
    this.fail = false,
    this.unsupported = false,
  });

  final List<TranscriptSegment> segments;
  final bool fail;

  /// Mimics a server binary older than the run-transcript ops.
  final bool unsupported;

  @override
  Stream<RunTranscriptEvent> watchRunTranscript(String runId) =>
      fail || unsupported
      ? Stream.error(StateError('boom'))
      : Stream.value(RunTranscriptSeed(segments, live: false));

  @override
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId) async {
    if (unsupported) {
      throw const RunActivityUnsupportedException();
    }
    if (fail) {
      throw StateError('boom');
    }
    return segments;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<AgentRunLog> logs,
    required RunTranscriptRelayPort relay,
    Widget? pane,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentRunLogRepositoryProvider.overrideWithValue(
            _StaticRunLogRepo(logs),
          ),
          runTranscriptRelayPortProvider.overrideWithValue(relay),
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
                body:
                    pane ??
                    const AgentActivityPane(
                      workspaceId: 'ws-1',
                      channelId: 'c-1',
                      runId: 'run-1',
                      agentId: 'agent-1',
                      fallbackLabel: 'scout',
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    // Fixed pumps, not `pumpAndSettle`: a running agent's status dot pulses
    // forever (presence over decoration), so settling never completes. Enough
    // turns for the transcript provider's one-shot fallback to resolve too.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shows the run label and its cost/token stats', (tester) async {
    await pump(
      tester,
      logs: [_run()],
      relay: _StaticRelay(
        segments: [TextSegment(text: 'found it', startedAt: _t0)],
      ),
    );

    expect(find.text('scout the repo'), findsOneWidget);
    // The stat bar's localized labels, from the shared RunActivityStatBar.
    expect(find.text('tokens'), findsOneWidget);
    expect(find.text('cost'), findsOneWidget);
    expect(find.text('tools'), findsOneWidget);
    expect(find.text('duration'), findsOneWidget);
  });

  testWidgets('renders text, tool and error segments in the timeline', (
    tester,
  ) async {
    await pump(
      tester,
      logs: [_run()],
      relay: _StaticRelay(
        segments: [
          TextSegment(text: 'planning the work', startedAt: _t0),
          ToolSegment(
            toolName: 'Read',
            toolCallId: 'c1',
            outputs: 'file body',
            status: ToolSegmentStatus.ok,
            startedAt: _t0,
          ),
          ErrorSegment(message: 'a recorded failure', startedAt: _t0),
        ],
      ),
    );

    expect(find.textContaining('planning the work'), findsWidgets);
    expect(find.textContaining('Read'), findsWidgets);
    expect(find.textContaining('a recorded failure'), findsWidgets);
  });

  testWidgets('a running run with nothing yet shows the waiting state', (
    tester,
  ) async {
    await pump(
      tester,
      logs: [_run(status: RunStatus.running)],
      relay: _StaticRelay(),
    );

    expect(find.text('Waiting for activity…'), findsOneWidget);
  });

  testWidgets('a finished run with nothing recorded says so', (tester) async {
    await pump(tester, logs: [_run()], relay: _StaticRelay());

    expect(find.text('No activity was recorded for this run'), findsOneWidget);
    expect(
      find.textContaining('before activity capture was enabled'),
      findsOneWidget,
    );
  });

  testWidgets('a run absent from the conversation reads as unavailable', (
    tester,
  ) async {
    await pump(
      tester,
      logs: [_run(id: 'some-other-run')],
      relay: _StaticRelay(),
    );

    expect(find.text('This run is no longer available'), findsOneWidget);
  });

  testWidgets('a failed transcript read offers a retry', (tester) async {
    await pump(tester, logs: [_run()], relay: _StaticRelay(fail: true));

    expect(find.text("Couldn't load this run's activity"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the unavailable constructor renders only that state', (
    tester,
  ) async {
    await pump(
      tester,
      logs: [_run()],
      relay: _StaticRelay(),
      pane: const AgentActivityPane.unavailable(),
    );

    expect(find.text('This run is no longer available'), findsOneWidget);
    // No header, so no stat bar.
    expect(find.text('tokens'), findsNothing);
  });

  testWidgets('a stale server says so instead of blaming the run', (
    tester,
  ) async {
    // The misleading case: an older cc_server serves neither op, which used to
    // render as "no activity was recorded for this run" — true of the response,
    // false about the run, and it hid the actual fix (restart the app).
    await pump(tester, logs: [_run()], relay: _StaticRelay(unsupported: true));

    expect(
      find.text('Activity capture is unavailable on the connected server'),
      findsOneWidget,
    );
    expect(find.textContaining('Restart the app'), findsOneWidget);
    expect(
      find.text('No activity was recorded for this run'),
      findsNothing,
      reason: 'must not blame the run for a server-capability gap',
    );
  });
}
