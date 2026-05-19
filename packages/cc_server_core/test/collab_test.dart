import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
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
        ({String channelId, String content, String senderId, String senderType})
      >[];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    sent.add((
      channelId: channelId,
      content: content,
      senderId: senderId,
      senderType: senderType,
    ));
    return id ?? 'sys-msg-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scripted [AgentRunLogRepository]: [activeByConversation] seeds
/// `watchActiveByConversation`, [byId] seeds `getById`. Every other member is
/// unused by the collab services under test.
class _FakeAgentRunLogRepository implements AgentRunLogRepository {
  final Map<String, List<AgentRunLog>> activeByConversation = {};
  final Map<String, AgentRunLog> byId = {};

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value(
    activeByConversation['$workspaceId:$conversationId'] ?? const [],
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
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  status: status,
  role: role,
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
    final steered = <({String runId, String message})>[];
    late Set<String> pausable;
    late TakeoverService service;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, workspaceId);
      db = dbs.of(workspaceId);
      messaging = _FakeMessagingRepository();
      runLogs = _FakeAgentRunLogRepository();
      paused.clear();
      stopped.clear();
      resumed.clear();
      steered.clear();
      pausable = {};
      service = TakeoverService(
        workspaceDbs: dbs,
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
        steerRun: (runId, message) async {
          steered.add((runId: runId, message: message));
          return true;
        },
        conversationChanges: (workspaceId, channelId) async => [
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

    test('begin pauses pausable runs, stops non-pausable ones, writes the '
        'Caches marker and posts a system message', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversation['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
        _run('run-stubborn', agentId: 'a2'),
      ];

      final marker = await service.begin(
        workspaceId: 'ws1',
        channelId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      expect(paused, ['run-pausable']);
      expect(stopped, ['run-stubborn']);
      expect(marker['paused_run_ids'], ['run-pausable']);
      expect(marker['stopped_run_ids'], ['run-stubborn']);

      final raw = await db.cacheDao.read(
        workspaceId,
        TakeoverService.cacheKind,
        'ch1',
      );
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['user_id'], 'u1');
      expect(decoded['display_name'], 'Ada');

      expect(messaging.sent, hasLength(1));
      expect(messaging.sent.single.content, contains('Ada took over'));
      expect(messaging.sent.single.senderType, 'agent');
    });

    test('a second begin throws', () async {
      runLogs.activeByConversation['ws1:ch1'] = [];
      await service.begin(
        workspaceId: 'ws1',
        channelId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );

      await expectLater(
        service.begin(
          workspaceId: 'ws1',
          channelId: 'ch1',
          userId: 'u2',
          displayName: 'Grace',
        ),
        throwsStateError,
      );
    });

    test('handBack posts the diff summary, steers + resumes paused runs and '
        'clears the marker', () async {
      pausable.add('run-pausable');
      runLogs.activeByConversation['ws1:ch1'] = [
        _run('run-pausable', agentId: 'a1'),
      ];
      await service.begin(
        workspaceId: 'ws1',
        channelId: 'ch1',
        userId: 'u1',
        displayName: 'Ada',
      );
      messaging.sent.clear();

      final result = await service.handBack(
        workspaceId: 'ws1',
        channelId: 'ch1',
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

    test('status/isActive read the Caches marker', () async {
      expect(await service.isActive('ws1', 'ch1'), isFalse);
      expect(await service.status('ws1', 'ch1'), isNull);

      runLogs.activeByConversation['ws1:ch1'] = [];
      await service.begin(
        workspaceId: 'ws1',
        channelId: 'ch1',
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
            String channelId,
            String agentId,
            String workspaceId,
            String prompt,
          })
        >[];
    var clock = DateTime(2026, 1, 1);
    late CheckerDispatchListener listener;
    const workspaceId = 'ws1';
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;
    late WorkspaceDatabase db;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, workspaceId);
      db = dbs.of(workspaceId);
      runLogs = _FakeAgentRunLogRepository();
      eventBus = DomainEventBus();
      dispatches.clear();
      clock = DateTime(2026, 1, 1);
      listener = CheckerDispatchListener(
        eventBus: eventBus,
        workspaceDbs: dbs,
        runLogs: runLogs,
        dispatchChecker:
            ({
              required String channelId,
              required String agentId,
              required String prompt,
              required String workspaceId,
            }) async {
              dispatches.add((
                channelId: channelId,
                agentId: agentId,
                workspaceId: workspaceId,
                prompt: prompt,
              ));
            },
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

    test(
      "a configured checker dispatches on another agent's completed main run",
      () async {
        await db.cacheDao.put(
          'ws1',
          CheckerDispatchListener.cacheKind,
          'ch1',
          jsonEncode({'agent_id': 'checker-agent'}),
        );
        runLogs.byId['run-1'] = _run(
          'run-1',
          agentId: 'worker-agent',
          status: RunStatus.completed,
        );

        eventBus.publish(
          AgentRunCompleted(
            agentId: 'worker-agent',
            workspaceId: 'ws1',
            conversationId: 'ch1',
            runId: 'run-1',
            occurredAt: clock,
          ),
        );

        await _pumpUntil(() => dispatches.isNotEmpty);
        expect(dispatches.single.agentId, 'checker-agent');
        expect(dispatches.single.channelId, 'ch1');
        expect(dispatches.single.workspaceId, 'ws1');
      },
    );

    test("the checker's own completion never re-triggers", () async {
      await db.cacheDao.put(
        'ws1',
        CheckerDispatchListener.cacheKind,
        'ch1',
        jsonEncode({'agent_id': 'checker-agent'}),
      );

      eventBus.publish(
        AgentRunCompleted(
          agentId: 'checker-agent',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          occurredAt: clock,
        ),
      );

      // Give the async handler a chance to run, then assert nothing fired.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test('a sub-agent run never triggers a review (main runs only)', () async {
      await db.cacheDao.put(
        'ws1',
        CheckerDispatchListener.cacheKind,
        'ch1',
        jsonEncode({'agent_id': 'checker-agent'}),
      );
      runLogs.byId['run-sub'] = _run(
        'run-sub',
        agentId: 'worker-agent',
        status: RunStatus.completed,
        role: AgentRunRole.sub,
      );

      eventBus.publish(
        AgentRunCompleted(
          agentId: 'worker-agent',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          runId: 'run-sub',
          occurredAt: clock,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });

    test('the cooldown suppresses a burst', () async {
      await db.cacheDao.put(
        'ws1',
        CheckerDispatchListener.cacheKind,
        'ch1',
        jsonEncode({'agent_id': 'checker-agent'}),
      );

      eventBus.publish(
        AgentRunCompleted(
          agentId: 'worker-1',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          occurredAt: clock,
        ),
      );
      await _pumpUntil(() => dispatches.length == 1);

      // A second completion moments later, within the cooldown, is absorbed.
      clock = clock.add(const Duration(seconds: 5));
      eventBus.publish(
        AgentRunCompleted(
          agentId: 'worker-2',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          occurredAt: clock,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, hasLength(1));

      // Past the cooldown window, the next completion dispatches again.
      clock = clock.add(const Duration(minutes: 3));
      eventBus.publish(
        AgentRunCompleted(
          agentId: 'worker-3',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          occurredAt: clock,
        ),
      );
      await _pumpUntil(() => dispatches.length == 2);
    });

    test('no checker configured means nothing dispatches', () async {
      eventBus.publish(
        AgentRunCompleted(
          agentId: 'worker-1',
          workspaceId: 'ws1',
          conversationId: 'ch1',
          occurredAt: clock,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(dispatches, isEmpty);
    });
  });
}
