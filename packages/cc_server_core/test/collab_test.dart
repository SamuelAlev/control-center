import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_harness/context.dart'
    show serializeHarnessHistory, splitPinnedEvidence;
import 'package:cc_harness/loop.dart'
    show
        SteeringChannel,
        SteeringMessage,
        SteeringQueue,
        laneMessageOrigin;
import 'package:cc_harness/messages.dart'
    show HarnessMessage, HarnessMessageOrigin;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/collab/checker_listener.dart';
import 'package:cc_server_core/src/collab/takeover_service.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Records every `sendMessage` call; every other [MessagingRepository] member
/// is unused by the collab services under test and — thanks to the
/// [noSuchMethod] override — throws loudly if one is ever called.
class _FakeMessagingRepository implements MessagingRepository {
  final sent =
      <
        ({String spaceId, String content, String senderId, String senderType})
      >[];

  /// Makes every send throw, to exercise failure paths.
  bool failSends = false;

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    if (failSends) {
      throw StateError('send failed');
    }
    sent.add((
      spaceId: spaceId,
      content: content,
      senderId: senderId,
      senderType: senderType,
    ));
    return id ?? 'sys-msg-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

/// Scripted [AgentRunLogRepository]: [activeByConversationSeeds] seeds
/// `watchActiveByConversation`, [byId] seeds `getById`. Every other member is
/// unused by the collab services under test.
class _FakeAgentRunLogRepository implements AgentRunLogRepository {
  final Map<String, List<AgentRunLog>> activeByConversationSeeds = {};

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async =>
      activeByConversationSeeds['$workspaceId:$conversationId'] ?? const [];
  final Map<String, AgentRunLog> byId = {};

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(
    activeByConversationSeeds['$workspaceId:$conversationId'] ?? const [],
  );

  // The take-over guard asks the SPACE-scoped stream; same seed map, keyed by
  // the space it is handed.
  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    activeByConversationSeeds['$workspaceId:$spaceId'] ?? const [],
  );

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentRunLog _run(
  String id, {
  required String agentId,
  RunStatus status = RunStatus.running,
  AgentRunRole role = AgentRunRole.main,
  String? spaceId,
  String? conversationId,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  status: status,
  role: role,
  spaceId: spaceId,
  conversationId: conversationId,
  startedAt: DateTime.now(),
);

/// Polls [condition] until it is true or [timeout] elapses — used to await
/// [CheckerDispatchListener]'s fire-and-forget event handling without a
/// flaky fixed sleep.
Future<void> _pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition never became true within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('TakeoverService', () {
    const workspaceId = 'ws1';
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;
    late WorkspaceDatabase db;
    late _FakeMessagingRepository messaging;
    late _FakeAgentRunLogRepository runLogs;
    final paused = <String>[];
    final stopped = <String>[];
    final resumed = <String>[];
    final steered = <({String runId, String message, String? source})>[];
    late Set<String> pausable;
    late TakeoverService service;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, workspaceId);
      db = dbs.of(workspaceId);
      await db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              id: 'ch1',
              name: 'General',
              workspaceId: workspaceId,
            ),
          );
      messaging = _FakeMessagingRepository();
      runLogs = _FakeAgentRunLogRepository();
      paused.clear();
      stopped.clear();
      resumed.clear();
      steered.clear();
      pausable = {};
      service = TakeoverService(
        takeovers: DaoSpaceTakeoverRepository(dbs),
        runLogs: runLogs,
        messaging: messaging,
        pauseRun: (runId) async {
          final ok = pausable.contains(runId);
          if (ok) {
            paused.add(runId);
          }
          return ok;
        },
        resumeRun: (runId) async {
          resumed.add(runId);
          return true;
        },
        stopRun: (ws, runId) async {
          stopped.add(runId);
        },
        steerRun: (runId, message, {required source}) async {
          steered.add((runId: runId, message: message, source: source));
          return true;
        },
        conversationChanges: (workspaceId, spaceId) async => [
          PrFile(
            filename: 'lib/a.dart',
            status: PrFileStatus.modified,
            additions: 3,
            deletions: 1,
            patch: '',
          ),
        ],
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('begin pauses pausable runs, stops non-pausable ones, records the '
        'take-over and posts a system message', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversationSeeds['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
        _run('run-stubborn', agentId: 'a2'),
      ];

      final marker = await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      expect(paused, ['run-pausable']);
      expect(stopped, ['run-stubborn']);
      expect(marker['paused_run_ids'], ['run-pausable']);
      expect(marker['stopped_run_ids'], ['run-stubborn']);

      final stored = await DaoSpaceTakeoverRepository(
        dbs,
      ).get(workspaceId, 'ch1');
      expect(stored?.userId, 'u1');
      expect(stored?.displayName, 'Ada');
      expect(stored?.pausedRunIds, ['run-pausable']);

      expect(messaging.sent, hasLength(1));
      expect(messaging.sent.single.content, contains('Ada took over'));
      expect(messaging.sent.single.senderType, 'system');
    });

    test('a second begin throws', () async {
      runLogs.activeByConversationSeeds['ws1:ch1'] = [];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      await expectLater(
        service.begin(
          workspaceId: 'ws1',
          spaceId: 'ch1',
          userId: 'u2',
          displayName: 'Grace',
        ),
        throwsStateError,
      );
    });

    test('handBack posts the diff summary, steers + resumes paused runs and '
        'clears the marker', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversationSeeds['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
      ];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      messaging.sent.clear();

      final result = await service.handBack(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      expect(result['resumed_run_ids'], ['run-pausable']);
      expect(messaging.sent, hasLength(1));
      expect(
        messaging.sent.single.content,
        contains('handed the worktree back'),
      );
      expect(messaging.sent.single.content, contains('1 file(s) changed'));
      expect(resumed, ['run-pausable']);
      expect(steered, hasLength(1));
      expect(steered.single.runId, 'run-pausable');

      expect(await service.isActive('ws1', 'ch1'), isFalse);
    });

    test('the hand-back steers the diff as the server and only the note as '
        'the person, so a compaction pins only the note', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversationSeeds['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
      ];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      await service.handBack(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
        note: 'Keep the public API unchanged.',
      );
      expect(steered.map((s) => s.source), ['takeover', null]);
      expect(steered.first.message, contains('1 file(s) changed'));
      expect(steered.first.message, isNot(contains('public API')));
      expect(steered.last.message, 'Note from Ada: Keep the public API '
          'unchanged.');

      final lane = SteeringQueue();
      for (final s in steered) {
        lane.enqueue(
          SteeringMessage(
            content: s.message,
            channel: SteeringChannel.steering,
            enqueuedAt: DateTime(2026),
            source: s.source,
          ),
        );
      }
      final drained = lane.drainSteering();
      final digest = serializeHarnessHistory([
        HarnessMessage.user('Fix it.', origin: HarnessMessageOrigin.person),
        for (final m in drained)
          HarnessMessage.user(m.content, origin: laneMessageOrigin(m)),
      ]);
      final pinned = splitPinnedEvidence(digest).pinned;
      expect(pinned, contains('Keep the public API unchanged.'));
      expect(pinned, isNot(contains('file(s) changed')));
      expect(digest, contains('file(s) changed'), reason: 'summarised');
    });

    test('concurrent begins: exactly one wins the claim', () async {
      runLogs.activeByConversationSeeds['ws1:ch1'] = [];
      final outcomes = await Future.wait([
        for (final (id, name) in [('u1', 'Ada'), ('u2', 'Grace')])
          service
              .begin(
                workspaceId: 'ws1',
                spaceId: 'ch1',
                userId: id,
                displayName: name,
              )
              .then(
                (_) => true,
                onError: (Object e) => e is StateError ? false : throw e,
              ),
      ]);
      expect(outcomes.where((won) => won), hasLength(1));
      expect(messaging.sent, hasLength(1));
    });

    test('only the holder or an admin can hand back', () async {
      runLogs.activeByConversationSeeds['ws1:ch1'] = [];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      await expectLater(
        service.handBack(
          workspaceId: 'ws1',
          spaceId: 'ch1',
          userId: 'u2',
          displayName: 'Grace',
        ),
        throwsStateError,
      );
      expect(await service.isActive('ws1', 'ch1'), isTrue);

      await service.handBack(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u2',
        displayName: 'Grace',
        asAdmin: true,
      );
      expect(await service.isActive('ws1', 'ch1'), isFalse);
    });

    test('a failing hand-back step never leaves the marker behind', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversationSeeds['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
      ];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      messaging.failSends = true;
      await expectLater(
        service.handBack(
          workspaceId: 'ws1',
          spaceId: 'ch1',
          userId: 'u1',
          displayName: 'Ada',
        ),
        throwsStateError,
      );
      expect(await service.isActive('ws1', 'ch1'), isFalse);
      expect(resumed, ['run-pausable'], reason: 'the run still resumes');
    });

    test('watch follows the marker as it is claimed and cleared', () async {
      runLogs.activeByConversationSeeds['ws1:ch1'] = [];
      final seen = <String?>[];
      final sub = service
          .watch('ws1', 'ch1')
          .listen((m) => seen.add(m?['user_id'] as String?));
      await pumpEventQueue();
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      await pumpEventQueue();
      await service.handBack(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isNull);
      expect(seen, contains('u1'));
      expect(seen.last, isNull);
    });

    test('status/isActive read the Caches marker', () async {
      expect(await service.isActive('ws1', 'ch1'), isFalse);
      expect(await service.status('ws1', 'ch1'), isNull);

      runLogs.activeByConversationSeeds['ws1:ch1'] = [];
      await service.begin(
        workspaceId: 'ws1',
        spaceId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      expect(await service.isActive('ws1', 'ch1'), isTrue);
      final status = await service.status('ws1', 'ch1');
      expect(status, isNotNull);
      expect(status!['user_id'], 'u1');
    });
  });

  group('CheckerDispatchListener', () {
    late _FakeAgentRunLogRepository runLogs;
    late DomainEventBus eventBus;
    final dispatches =
        <
          ({
            String spaceId,
            String? conversationId,
            String agentId,
            String workspaceId,
            String prompt,
          })
        >[];
    var clock = DateTime(2026, 1, 1);
    late CheckerDispatchListener listener;
    final goalRuns = <String>{};
    const workspaceId = 'ws1';
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;
    late WorkspaceDatabase db;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, workspaceId);
      db = dbs.of(workspaceId);
      await db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              id: 'ch1',
              name: 'General',
              workspaceId: workspaceId,
            ),
          );
      runLogs = _FakeAgentRunLogRepository();
      eventBus = DomainEventBus();
      dispatches.clear();
      goalRuns.clear();
      clock = DateTime(2026, 1, 1);
      listener = CheckerDispatchListener(
        eventBus: eventBus,
        checkers: DaoSpaceCheckerRepository(dbs),
        runLogs: runLogs,
        dispatchChecker:
            ({
              required String spaceId,
              required String? conversationId,
              required String agentId,
              required String prompt,
              required String workspaceId,
              required String sourceAgentId,
              required String sourceRunId,
            }) async {
              dispatches.add((
                spaceId: spaceId,
                conversationId: conversationId,
                agentId: agentId,
                workspaceId: workspaceId,
                prompt: prompt,
              ));
            },
        isGoalRun:
            ({required String workspaceId, required String runId}) async =>
                goalRuns.contains(runId),
        cooldown: const Duration(minutes: 2),
        now: () => clock,
      );
      listener.start();
    });

    tearDown(() async {
      await listener.stop();
      eventBus.dispose();
      await db.close();
    });

    /// A finished run of [agentId] in the space `ch1`, in a conversation
    /// whose id is not the space's, and the event its settlement publishes.
    AgentRunSettled finished(
      String runId, {
      required String agentId,
      AgentRunRole role = AgentRunRole.main,
      String? spaceId = 'ch1',
      RunEndReason reason = RunEndReason.completed,
    }) {
      runLogs.byId[runId] = _run(
        runId,
        agentId: agentId,
        status: RunStatus.completed,
        role: role,
        spaceId: spaceId,
        conversationId: 'conv-7',
      );
      return AgentRunSettled(
        agentId: agentId,
        workspaceId: 'ws1',
        spaceId: spaceId,
        conversationId: 'conv-7',
        runId: runId,
        status: reason == RunEndReason.completed
            ? RunStatus.completed
            : RunStatus.error,
        endReason: reason,
        costMicros: 0,
        limitResetsAt: null,
        wakeIds: const [],
        requestedByUserId: null,
        wakeReason: null,
        occurredAt: clock,
      );
    }

    Future<void> setChecker() async {
      // The checker is an agent of the workspace; the setting goes with it.
      await dbs
          .of('ws1')
          .customStatement(
            'INSERT OR IGNORE INTO agents '
            '(id, name, title, agent_md_path, workspace_id, skills) '
            "VALUES ('checker-agent', 'Checker', 'Agent', '', 'ws1', '')",
          );
      await DaoSpaceCheckerRepository(
        dbs,
      ).setChecker('ws1', 'ch1', 'checker-agent');
    }

    test("a configured checker reviews another agent's completed main run, "
        "in the run's space and conversation", () async {
      await setChecker();

      eventBus.publish(finished('run-1', agentId: 'worker-agent'));

      await _pumpUntil(() => dispatches.isNotEmpty);
      expect(dispatches.single.agentId, 'checker-agent');
      // The space is the run's, not the event's conversation id.
      expect(dispatches.single.spaceId, 'ch1');
      expect(dispatches.single.conversationId, 'conv-7');
      expect(dispatches.single.workspaceId, 'ws1');
    });

    test('a run outside any space is not reviewed', () async {
      await setChecker();

      eventBus.publish(
        finished('run-1', agentId: 'worker-agent', spaceId: null),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test("the checker's own completion never re-triggers", () async {
      await setChecker();

      eventBus.publish(finished('run-1', agentId: 'checker-agent'));

      // Give the async handler a chance to run, then assert nothing fired.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test('a sub-agent run never triggers a review (main runs only)', () async {
      await setChecker();

      eventBus.publish(
        finished('run-sub', agentId: 'worker-agent', role: AgentRunRole.sub),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test('the cooldown suppresses a burst', () async {
      await setChecker();

      eventBus.publish(finished('run-1', agentId: 'worker-1'));
      await _pumpUntil(() => dispatches.length == 1);

      // A second completion moments later, within the cooldown, is absorbed.
      clock = clock.add(const Duration(seconds: 5));
      eventBus.publish(finished('run-2', agentId: 'worker-2'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, hasLength(1));

      // Past the cooldown window, the next completion dispatches again.
      clock = clock.add(const Duration(minutes: 3));
      eventBus.publish(finished('run-3', agentId: 'worker-3'));
      await _pumpUntil(() => dispatches.length == 2);
    });

    test('a goal segment or a goal review is not reviewed; an ordinary run '
        'still is', () async {
      await setChecker();
      goalRuns
        ..add('run-goal')
        ..add('run-goal-review');

      eventBus
        ..publish(finished('run-goal', agentId: 'worker-agent'))
        ..publish(finished('run-goal-review', agentId: 'reviewer-agent'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);

      eventBus.publish(finished('run-plain', agentId: 'worker-agent'));
      await _pumpUntil(() => dispatches.isNotEmpty);
      expect(dispatches.single.agentId, 'checker-agent');
    });

    test('a stopped run is not reviewed', () async {
      await setChecker();

      eventBus
        ..publish(
          finished(
            'run-stopped',
            agentId: 'worker-agent',
            reason: RunEndReason.stoppedByUser,
          ),
        )
        ..publish(
          finished(
            'run-shutdown',
            agentId: 'worker-agent',
            reason: RunEndReason.serverStopped,
          ),
        );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test('a run that failed is still reviewed', () async {
      await setChecker();

      eventBus.publish(
        finished('run-err', agentId: 'worker-agent', reason: RunEndReason.error),
      );
      await _pumpUntil(() => dispatches.isNotEmpty);
    });

    test('no checker configured means nothing dispatches', () async {
      eventBus.publish(finished('run-1', agentId: 'worker-1'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });
  });
}
