import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/presence/agent_presence_synthesizer.dart';
import 'package:test/test.dart';

/// Feeds [watchRecent] from a controller so a test can push successive run-log
/// snapshots. Every other member is unused by the synthesizer.
class _FakeRunLogRepository implements AgentRunLogRepository {
  final _runs = StreamController<List<AgentRunLog>>.broadcast();

  void emit(List<AgentRunLog> runs) => _runs.add(runs);

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => _runs.stream;

  Future<void> close() => _runs.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Resolves display names for the roster; unknown ids fall back to the id.
class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this.names);

  final Map<String, String> names;

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    final name = names[id];
    if (name == null) {
      return null;
    }
    return Agent(
      id: id,
      name: name,
      title: name,
      agentMdPath: '/tmp/$id/AGENTS.md',
      workspaceId: 'ws-1',
      skills: AgentSkills(const []),
      createdAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentRunLog _run(
  String id, {
  required String agentId,
  required String conversationId,
  required DateTime startedAt,
  // A run carries BOTH ids and they are never the same value. Defaulted per
  // conversation so a test that only cares about which run wins still produces
  // a distinguishable space.
  String? spaceId,
  String? workspaceId = 'ws-1',
  RunStatus status = RunStatus.running,
  DateTime? completedAt,
  int costCents = 0,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: workspaceId,
  conversationId: conversationId,
  spaceId: spaceId ?? 'space-of-$conversationId',
  startedAt: startedAt,
  completedAt: completedAt,
  status: status,
  cost: RunCost(estimatedCostCents: costCents),
);

/// Waits until [condition] holds — the synthesizer publishes from a
/// fire-and-forget stream listener.
Future<void> _pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition never became true within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('AgentPresenceSynthesizer', () {
    late PresenceHub hub;
    late _FakeRunLogRepository runLogs;
    late AgentPresenceSynthesizer synthesizer;
    final now = DateTime(2026, 7, 26, 12);

    setUp(() async {
      hub = PresenceHub();
      runLogs = _FakeRunLogRepository();
      synthesizer = AgentPresenceSynthesizer(
        hub: hub,
        runLogs: runLogs,
        agents: _FakeAgentRepository({'ceo': 'ceo'}),
        now: () => now,
      );
      await synthesizer.start();
    });

    tearDown(() async {
      await synthesizer.stop();
      await runLogs.close();
      hub.dispose();
    });

    ParticipantPresence? entryFor(String agentId) {
      for (final wire in hub.snapshot('ws-1')) {
        final entry = ParticipantPresence.fromWire(wire);
        if (entry.principal.id == agentId) {
          return entry;
        }
      }
      return null;
    }

    test(
      'an agent with concurrent runs is published once, from its live run',
      () async {
        // Newest-first, as the run-log stream delivers it. The older run has just
        // finished in another conversation and still lingers.
        runLogs.emit([
          _run(
            'run-live',
            agentId: 'ceo',
            conversationId: 'conv-live',
            startedAt: now.subtract(const Duration(minutes: 1)),
            costCents: 250,
          ),
          _run(
            'run-done',
            agentId: 'ceo',
            conversationId: 'conv-old',
            startedAt: now.subtract(const Duration(minutes: 5)),
            status: RunStatus.completed,
            completedAt: now.subtract(const Duration(seconds: 2)),
            costCents: 999,
          ),
        ]);

        await _pumpUntil(() => entryFor('ceo') != null);
        final entry = entryFor('ceo')!;
        // The live run decides state, locus and cost. When the finished run won
        // (it is older and the last write won) the roster reported `done` with
        // the wrong conversation — and follow-mode, which rides the locus,
        // navigated the follower to it.
        expect(entry.agent?.state, AgentLiveState.running);
        expect(entry.agent?.costUsd, closeTo(2.5, 1e-9));
        // The locus names the run's SPACE (what a route addresses) and carries
        // its conversation (which tab to focus) — never the conversation id in
        // the space slot, which routed followers to a space that never existed.
        expect(
          entry.locus,
          const SpaceLocus(
            spaceId: 'space-of-conv-live',
            conversationId: 'conv-live',
          ),
        );
        // Exactly one entry for the agent.
        expect(hub.snapshot('ws-1'), hasLength(1));
      },
    );

    test('the published locus is stable across repeated passes over the same '
        'runs', () async {
      final runs = [
        _run(
          'run-b',
          agentId: 'ceo',
          conversationId: 'conv-b',
          startedAt: now.subtract(const Duration(minutes: 1)),
        ),
        _run(
          'run-a',
          agentId: 'ceo',
          conversationId: 'conv-a',
          startedAt: now.subtract(const Duration(minutes: 9)),
        ),
      ];
      // Overlapping triggers: the publish pass must not interleave with itself
      // (that is what made the winning run — and so the locus — arbitrary).
      runLogs
        ..emit(runs)
        ..emit(runs.reversed.toList())
        ..emit(runs);

      await _pumpUntil(() => entryFor('ceo') != null);
      final seen = <String?>{};
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        seen.add((entryFor('ceo')?.locus as SpaceLocus?)?.spaceId);
      }
      expect(seen, {'space-of-conv-b'});
    });

    test('a run with no space publishes the agent without a locus', () async {
      // No `?? conversationId` fallback: a conversation id in the space slot
      // builds a route to a space that does not exist, which is worse than an
      // agent the roster simply cannot navigate to.
      runLogs.emit([
        _run(
          'run-spaceless',
          agentId: 'ceo',
          conversationId: 'conv-live',
          spaceId: '',
          startedAt: now,
        ),
      ]);

      await _pumpUntil(() => entryFor('ceo') != null);
      final entry = entryFor('ceo')!;
      expect(entry.agent?.state, AgentLiveState.running);
      expect(entry.locus, isNull);
    });

    test('drops runs with no workspace', () async {
      runLogs.emit([
        _run(
          'run-orphan',
          agentId: 'ceo',
          conversationId: 'conv-live',
          startedAt: now,
          workspaceId: null,
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(hub.snapshot('ws-1'), isEmpty);
    });
  });
}
