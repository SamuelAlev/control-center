import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 7, 26);

AgentRunLog _run({
  required String id,
  String agentId = 'agent-1',
  RunStatus status = RunStatus.completed,
  String? parentRunId,
  String? spawnToolCallId,
  int costCents = 0,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: 'ws-1',
  conversationId: 'c-1',
  startedAt: _t0,
  status: status,
  parentRunId: parentRunId,
  spawnToolCallId: spawnToolCallId,
  cost: RunCost(estimatedCostCents: costCents),
);

/// Feeds a scripted run-log stream, so a test can push a second emission and
/// assert a derived provider re-emits.
class _ScriptedRunLogRepo implements AgentRunLogRepository {
  _ScriptedRunLogRepo(this._controller);

  final StreamController<List<AgentRunLog>> _controller;
  int subscriptions = 0;

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) {
    subscriptions++;
    return _controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves scripted relay frames, or fails the subscription to exercise the
/// one-shot fallback.
class _ScriptedRelay implements RunTranscriptRelayPort {
  _ScriptedRelay({
    this.frames = const [],
    this.oneShot = const [],
    this.failWatch = false,
  });

  final List<RunTranscriptEvent> frames;
  final List<TranscriptSegment> oneShot;
  final bool failWatch;
  int oneShotCalls = 0;

  @override
  Stream<RunTranscriptEvent> watchRunTranscript(String runId) {
    if (failWatch) {
      return Stream.error(StateError('op unknown'));
    }
    return Stream.fromIterable(frames);
  }

  @override
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId) async {
    oneShotCalls++;
    return oneShot;
  }
}

void main() {
  const convKey = (workspaceId: 'ws-1', conversationId: 'c-1');
  const runKey = (workspaceId: 'ws-1', runId: 'run-1');

  ProviderContainer container({
    AgentRunLogRepository? repo,
    RunTranscriptRelayPort? relay,
  }) {
    final c = ProviderContainer(
      overrides: [
        if (repo != null) agentRunLogRepositoryProvider.overrideWithValue(repo),
        if (relay != null)
          runTranscriptRelayPortProvider.overrideWithValue(relay),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// The transcript after every scripted frame has landed.
  ///
  /// Holds a subscription so the autoDispose provider is not disposed mid-load,
  /// and drains the microtask queue rather than awaiting `.future` — that
  /// resolves on the FIRST emission, which for a seed-then-updates script is
  /// just the seed.
  Future<List<TranscriptSegment>> readTranscript(ProviderContainer c) async {
    final sub = c.listen(runTranscriptProvider(runKey), (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.read(runTranscriptProvider(runKey)).value ?? const [];
  }

  group('runInConversationProvider', () {
    test('selects the run by id out of the conversation stream', () async {
      final ctl = StreamController<List<AgentRunLog>>();
      addTearDown(ctl.close);
      final c = container(repo: _ScriptedRunLogRepo(ctl));
      const key = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'run-1');
      final sub = c.listen(runInConversationProvider(key), (_, _) {});
      addTearDown(sub.close);

      ctl.add([_run(id: 'run-0'), _run(id: 'run-1', costCents: 5)]);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(runInConversationProvider(key)).value?.id, 'run-1');
      expect(
        c.read(runInConversationProvider(key)).value?.cost.estimatedCostCents,
        5,
      );
    });

    test('re-emits when the run row changes', () async {
      final ctl = StreamController<List<AgentRunLog>>();
      addTearDown(ctl.close);
      final c = container(repo: _ScriptedRunLogRepo(ctl));
      const key = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'run-1');
      final sub = c.listen(runInConversationProvider(key), (_, _) {});
      addTearDown(sub.close);

      ctl.add([_run(id: 'run-1', status: RunStatus.running)]);
      await Future<void>.delayed(Duration.zero);
      expect(
        c.read(runInConversationProvider(key)).value?.status,
        RunStatus.running,
      );

      ctl.add([_run(id: 'run-1', costCents: 12)]);
      await Future<void>.delayed(Duration.zero);
      expect(
        c.read(runInConversationProvider(key)).value?.status,
        RunStatus.completed,
      );
      expect(
        c.read(runInConversationProvider(key)).value?.cost.estimatedCostCents,
        12,
      );
    });

    test(
      'resolves to null (not loading) once an absent run is known',
      () async {
        final ctl = StreamController<List<AgentRunLog>>();
        addTearDown(ctl.close);
        final c = container(repo: _ScriptedRunLogRepo(ctl));
        const key = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'gone');
        final sub = c.listen(runInConversationProvider(key), (_, _) {});
        addTearDown(sub.close);

        ctl.add([_run(id: 'run-1')]);
        await Future<void>.delayed(Duration.zero);

        final state = c.read(runInConversationProvider(key));
        expect(state.hasValue, isTrue);
        expect(state.value, isNull);
      },
    );
  });

  group('shared conversation subscription', () {
    test('the tree and a run row ride ONE run-log subscription', () async {
      final ctl = StreamController<List<AgentRunLog>>.broadcast();
      addTearDown(ctl.close);
      final repo = _ScriptedRunLogRepo(ctl);
      final c = container(repo: repo);
      const runRowKey = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'run-1');

      final a = c.listen(conversationRunTreeProvider(convKey), (_, _) {});
      final b = c.listen(runInConversationProvider(runRowKey), (_, _) {});
      addTearDown(a.close);
      addTearDown(b.close);
      await Future<void>.delayed(Duration.zero);

      expect(repo.subscriptions, 1);
    });
  });

  group('runTranscriptProvider', () {
    test('folds a seed frame into the segment list', () async {
      final c = container(
        relay: _ScriptedRelay(
          frames: [
            RunTranscriptSeed([TextSegment(text: 'planning', startedAt: _t0)]),
          ],
        ),
      );

      final segments = await readTranscript(c);

      expect(segments, hasLength(1));
      expect((segments.single as TextSegment).text, 'planning');
    });

    test('applies opens, deltas and closes on top of the seed', () async {
      final c = container(
        relay: _ScriptedRelay(
          frames: [
            const RunTranscriptSeed([]),
            RunTranscriptUpdates([
              SegmentOpened(0, TextSegment(text: 'a', startedAt: _t0)),
              const SegmentDelta(0, 'b'),
              SegmentOpened(
                1,
                ToolSegment(toolName: 'Read', toolCallId: 'c1', startedAt: _t0),
              ),
              SegmentClosed(
                1,
                ToolSegment(
                  toolName: 'Read',
                  toolCallId: 'c1',
                  outputs: 'body',
                  status: ToolSegmentStatus.ok,
                  startedAt: _t0,
                ),
              ),
            ]),
          ],
        ),
      );

      final segments = await readTranscript(c);

      expect(segments, hasLength(2));
      expect((segments[0] as TextSegment).text, 'ab');
      expect((segments[1] as ToolSegment).status, ToolSegmentStatus.ok);
    });

    test('an unrecorded run yields an empty list, not an error', () async {
      final c = container(
        relay: _ScriptedRelay(
          frames: [const RunTranscriptSeed([], live: false)],
        ),
      );

      expect(await readTranscript(c), isEmpty);
    });

    test('degrades to the one-shot read when the relay op is absent', () async {
      final relay = _ScriptedRelay(
        failWatch: true,
        oneShot: [TextSegment(text: 'replayed', startedAt: _t0)],
      );
      final c = container(relay: relay);

      final segments = await readTranscript(c);

      expect(relay.oneShotCalls, 1);
      expect((segments.single as TextSegment).text, 'replayed');
    });

    test('the EmptyRunTranscriptRelayPort reads as nothing recorded', () async {
      final c = container(relay: const EmptyRunTranscriptRelayPort());

      expect(await readTranscript(c), isEmpty);
    });
  });

  group('runToolCountProvider', () {
    test('counts only tool segments', () async {
      final c = container(
        relay: _ScriptedRelay(
          frames: [
            RunTranscriptSeed([
              TextSegment(text: 'prose', startedAt: _t0),
              ToolSegment(toolName: 'Read', toolCallId: 'c1', startedAt: _t0),
              ToolSegment(toolName: 'Grep', toolCallId: 'c2', startedAt: _t0),
              ErrorSegment(message: 'boom', startedAt: _t0),
            ]),
          ],
        ),
      );
      final sub = c.listen(runToolCountProvider(runKey), (_, _) {});
      addTearDown(sub.close);

      await readTranscript(c);

      expect(c.read(runToolCountProvider(runKey)), 2);
    });
  });

  group('runIdForSpawnToolCallProvider', () {
    test('resolves the child run spawned by a task tool call', () async {
      final ctl = StreamController<List<AgentRunLog>>();
      addTearDown(ctl.close);
      final c = container(repo: _ScriptedRunLogRepo(ctl));
      const key = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'call-task-1');
      final sub = c.listen(runIdForSpawnToolCallProvider(key), (_, _) {});
      addTearDown(sub.close);

      ctl.add([
        _run(id: 'run-parent'),
        _run(
          id: 'run-child',
          parentRunId: 'run-parent',
          spawnToolCallId: 'call-task-1',
        ),
        _run(
          id: 'run-other-child',
          parentRunId: 'run-parent',
          spawnToolCallId: 'call-task-2',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(runIdForSpawnToolCallProvider(key)), 'run-child');
    });

    test(
      'is null for a transcript recorded before spawn correlation',
      () async {
        final ctl = StreamController<List<AgentRunLog>>();
        addTearDown(ctl.close);
        final c = container(repo: _ScriptedRunLogRepo(ctl));
        const key = (workspaceId: 'ws-1', spaceId: 'c-1', runId: 'call-old');
        final sub = c.listen(runIdForSpawnToolCallProvider(key), (_, _) {});
        addTearDown(sub.close);

        ctl.add([_run(id: 'run-child', parentRunId: 'run-parent')]);
        await Future<void>.delayed(Duration.zero);

        expect(c.read(runIdForSpawnToolCallProvider(key)), isNull);
      },
    );
  });
}
