import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/wake_run_ledger.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show WakeQueuePorts, WakeQueueService;
import 'package:cc_server_core/src/catalog/wake_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// The wakes of two workspaces, each found only in its own.
class _Wakes implements WakeRepository {
  final Map<String, Map<String, Wake>> byWs = {};

  void put(Wake w) => (byWs[w.workspaceId] ??= {})[w.id] = w;

  int _move(String ws, List<String> ids, Set<WakeState> from, WakeState to) {
    var moved = 0;
    for (final id in ids) {
      final w = byWs[ws]?[id];
      if (w != null && from.contains(w.state)) {
        put(w.copyWith(state: to));
        moved++;
      }
    }
    return moved;
  }

  @override
  Future<Wake?> getById(String workspaceId, String id) async =>
      byWs[workspaceId]?[id];

  @override
  Future<int> cancel(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) async => _move(workspaceId, ids, {
    WakeState.pending,
    WakeState.held,
  }, WakeState.cancelled);

  @override
  Future<int> release(String workspaceId, {required List<String> ids}) async =>
      _move(workspaceId, ids, {WakeState.held}, WakeState.pending);

  @override
  Future<List<Wake>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeState>? states,
  }) async => [
    for (final w in byWs[workspaceId]?.values ?? const <Wake>[])
      if (w.conversationId == conversationId &&
          (states == null || states.contains(w.state)))
        w,
  ];

  @override
  Future<List<Wake>> listPendingFor(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async => [
    for (final w in byWs[workspaceId]?.values ?? const <Wake>[])
      if (w.conversationId == conversationId &&
          w.agentId == agentId &&
          w.state == WakeState.pending)
        w,
  ];

  @override
  Future<List<String>> claim(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  }) async => [
    for (final id in ids)
      if (_move(workspaceId, [id], {WakeState.pending}, WakeState.claimed) == 1)
        id,
  ];

  @override
  Future<int> markDelivered(
    String workspaceId, {
    required List<String> ids,
    required String? runId,
    required DateTime now,
  }) async {
    var moved = 0;
    for (final id in ids) {
      final w = byWs[workspaceId]?[id];
      if (w != null && w.state == WakeState.claimed) {
        put(w.copyWith(state: WakeState.delivered, deliveredRunId: runId));
        moved++;
      }
    }
    return moved;
  }

  @override
  Future<int> countDeliveredRunsSince(
    String workspaceId, {
    required DateTime since,
    String? conversationId,
  }) async => 0;

  @override
  Future<DateTime?> earliestPendingNotBefore(String workspaceId) async => null;

  @override
  Stream<List<Wake>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value([
    for (final w in byWs[workspaceId]?.values ?? const <Wake>[])
      if (w.conversationId == conversationId &&
          (w.state == WakeState.pending || w.state == WakeState.held))
        w,
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ledger implements WakeRunLedger {
  @override
  Future<void> addWakeIds(String w, String r, List<String> ids) async {}

  @override
  Future<WakeLedgerRun?> runForWake(String w, String id) async => null;
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => switch ((workspaceId, conversationId)) {
    ('ws-1', 'conv-1') || ('ws-2', 'conv-2') => Conversation(
      id: conversationId,
      workspaceId: workspaceId,
      spaceId: 'sp-$workspaceId',
      title: 't',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
    _ => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The `wakes.*` ops: workspace isolation at each op (a foreign wake or
/// conversation id is a `WorkspaceMismatchException`), the space gate, and
/// the wire shapes.
void main() {
  late _Wakes wakes;
  late WakeQueueService queue;
  late List<RepoOp> ops;
  late List<WatchQuery> watches;
  late Set<String> unreadableSpaces;
  late int dispatched;

  final t0 = DateTime.utc(2026, 5, 1, 12);

  Wake wake(
    String id,
    String ws, {
    WakeState state = WakeState.pending,
    String? requestedByUserId,
  }) => Wake(
    id: id,
    workspaceId: ws,
    spaceId: 'sp-$ws',
    conversationId: ws == 'ws-1' ? 'conv-1' : 'conv-2',
    agentId: 'agent-1',
    reason: WakeReason.peerMessage,
    payload: 'secret payload',
    dedupKey: 'k:$id',
    notBefore: t0,
    state: state,
    stateReason: state == WakeState.held ? 'stopped' : null,
    requestedByUserId: requestedByUserId,
    createdAt: t0,
  );

  setUp(() async {
    wakes = _Wakes()
      ..put(wake('a', 'ws-1'))
      ..put(wake('h', 'ws-1', state: WakeState.held))
      ..put(wake('b', 'ws-2'));
    unreadableSpaces = {};
    dispatched = 0;
    queue = WakeQueueService(
      wakes: wakes,
      runLedger: _Ledger(),
      clock: () => t0,
      timerFactory: (_, _) => Timer(const Duration(days: 1), () {}),
      ports: WakeQueuePorts(
        workspaceActive: (_) async => true,
        conversationSpace: (ws, _) async => 'sp-$ws',
        agent: (ws, id) async => Agent(
          id: id,
          name: 'Builder',
          title: 't',
          agentMdPath: '/tmp/a.md',
          workspaceId: ws,
          skills: AgentSkills(const []),
          createdAt: t0,
        ),
        isMember: (_, _) async => true,
        takenOver: (_, _) async => false,
        budgetBlocked: (_, _) async => false,
        liveSessions: (_) => const [],
        hasLiveRun: (_, _, _) async => false,
        dispatch: (_) async => 'run-${++dispatched}',
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async {},
      ),
    );
    final pack = buildWakeOps(
      wakeQueue: () => queue,
      wakes: wakes,
      conversations: _Conversations(),
      requireSpace: (ws, user, space) async {
        if (unreadableSpaces.contains(space)) {
          throw const ValidationException('space_access_denied');
        }
      },
      guardSpace: (ws, user, space, source) => source,
    );
    ops = pack.ops;
    watches = pack.watches;
    // Nothing is delivered before the queue starts.
    await queue.start();
  });

  tearDown(() => queue.stop());

  RepoOpContext ctx(
    Map<String, dynamic> args, {
    String ws = 'ws-1',
    String userId = 'user-1',
  }) => RepoOpContext(
    args: args,
    workspaceId: ws,
    deviceId: 'device-1',
    userId: userId,
  );

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> args, {
    String ws = 'ws-1',
    String userId = 'user-1',
  }) async => Map<String, dynamic>.from(
    await ops
            .firstWhere((o) => o.name == name)
            .handler(ctx(args, ws: ws, userId: userId))
        as Map,
  );

  Stream<dynamic> watch(
    Map<String, dynamic> args, {
    String ws = 'ws-1',
    String userId = 'user-1',
  }) => watches.single.handler(
    WatchQueryContext(
      args: args,
      workspaceId: ws,
      deviceId: 'device-1',
      userId: userId,
    ),
  );

  test('the pack is the four ops, each open to members', () {
    expect(
      [for (final o in ops) o.name],
      ['wakes.cancel', 'wakes.release', 'wakes.deliverNow'],
    );
    expect(watches.single.name, 'wakes.watchForConversation');
    for (final o in ops) {
      expect(o.kind, RepoOpKind.mutate);
    }
  });

  test('no queue, no ops', () {
    final pack = buildWakeOps(
      wakeQueue: null,
      wakes: null,
      conversations: _Conversations(),
      requireSpace: (_, _, _) async {},
      guardSpace: (_, _, _, s) => s,
    );
    expect(pack.ops, isEmpty);
    expect(pack.watches, isEmpty);
  });

  group('workspace isolation', () {
    for (final (name, args) in [
      ('wakes.cancel', {'wake_id': 'b'}),
      ('wakes.release', {'wake_id': 'b'}),
      ('wakes.deliverNow', {'wake_id': 'b'}),
      ('wakes.release', {'conversation_id': 'conv-2'}),
    ]) {
      test('$name with another workspace\'s id is refused', () async {
        await expectLater(
          call(name, args),
          throwsA(isA<WorkspaceMismatchException>()),
        );
        expect(wakes.byWs['ws-2']!['b']!.state, WakeState.pending);
      });
    }

    test("the watch refuses another workspace's conversation", () async {
      await expectLater(
        watch({'conversation_id': 'conv-2'}).first,
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('a space the caller cannot read is refused', () async {
      unreadableSpaces.add('sp-ws-1');
      await expectLater(
        call('wakes.cancel', {'wake_id': 'a'}),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        watch({'conversation_id': 'conv-1'}).first,
        throwsA(isA<ValidationException>()),
      );
      expect(wakes.byWs['ws-1']!['a']!.state, WakeState.pending);
    });
  });

  test('the watch lists pending and held wakes, never the payload', () async {
    final frame = await watch({'conversation_id': 'conv-1'}).first as Map;
    final rows = (frame['wakes'] as List).cast<Map<String, dynamic>>();
    expect([for (final r in rows) r['id']], unorderedEquals(['a', 'h']));
    final a = rows.firstWhere((r) => r['id'] == 'a');
    expect(a, {
      'id': 'a',
      'workspace_id': 'ws-1',
      'space_id': 'sp-ws-1',
      'conversation_id': 'conv-1',
      'agent_id': 'agent-1',
      'reason': 'peer_message',
      'origin': 'peer-message',
      'headline': 'another agent sent you a message',
      'state': 'pending',
      'lane': 'aside',
      'not_before': '2026-05-01T12:00:00.000Z',
      'created_at': '2026-05-01T12:00:00.000Z',
      'attempt': 0,
      'can_release': true,
    });
    expect(frame.toString(), isNot(contains('secret payload')));
  });

  test('every time on the wire is UTC ISO 8601 with Z, even from local '
      'times', () {
    final local = DateTime(2026, 5, 1, 14, 30, 5);
    final wire = wakeToWire(
      wake('a', 'ws-1').copyWith(
        notBefore: local,
        expiresAt: local.add(const Duration(hours: 1)),
      ),
      viewerId: 'user-1',
    );
    for (final key in ['not_before', 'created_at', 'expires_at']) {
      expect(wire[key] as String, endsWith('Z'), reason: key);
    }
    expect(wire['not_before'], local.toUtc().toIso8601String());
  });

  test('the wire names what raised a wake (source agent, goal, rule, ask) '
      'and leaves out what is absent', () {
    final raised = wakeToWire(
      wake('r', 'ws-1').copyWith(
        detail: WakeDetail(
          sourceAgentId: 'agent-2',
          goalId: 'goal-1',
          ruleId: 'rule-1',
          askId: 'ask-1',
        ),
      ),
      viewerId: 'user-1',
    );
    expect(raised['source_agent_id'], 'agent-2');
    expect(raised['goal_id'], 'goal-1');
    expect(raised['rule_id'], 'rule-1');
    expect(raised['ask_id'], 'ask-1');
    final plain = wakeToWire(wake('p', 'ws-1'), viewerId: 'user-1');
    for (final key in ['source_agent_id', 'goal_id', 'rule_id', 'ask_id']) {
      expect(plain.containsKey(key), isFalse, reason: key);
    }
  });

  group("a person's wake is theirs", () {
    // Ada (user-1) stopped her run: her wake `ada` is held. Ben (user-2)
    // has the space too.
    setUp(() {
      wakes.put(
        wake('ada', 'ws-1', state: WakeState.held, requestedByUserId: 'user-1'),
      );
    });

    final notYours = throwsA(
      isA<AuthException>().having((e) => e.code, 'code', wakeNotYoursKind),
    );

    test('Ben may not deliver now or release it, but may cancel it', () async {
      await expectLater(
        call('wakes.deliverNow', {'wake_id': 'ada'}, userId: 'user-2'),
        notYours,
      );
      await expectLater(
        call('wakes.release', {'wake_id': 'ada'}, userId: 'user-2'),
        notYours,
      );
      expect(wakes.byWs['ws-1']!['ada']!.state, WakeState.held);
      expect(dispatched, 0);
      expect(await call('wakes.cancel', {'wake_id': 'ada'}, userId: 'user-2'), {
        'cancelled': true,
      });
    });

    test("Ben's conversation release takes only the bot wakes; with none "
        "left but Ada's it is refused", () async {
      expect(
        await call('wakes.release', {
          'conversation_id': 'conv-1',
        }, userId: 'user-2'),
        {'released': 1},
      );
      expect(wakes.byWs['ws-1']!['h']!.state, isNot(WakeState.held));
      expect(wakes.byWs['ws-1']!['ada']!.state, WakeState.held);
      await expectLater(
        call('wakes.release', {'conversation_id': 'conv-1'}, userId: 'user-2'),
        notYours,
      );
      expect(wakes.byWs['ws-1']!['ada']!.state, WakeState.held);
    });

    test('Ada may deliver it now', () async {
      expect(await call('wakes.deliverNow', {'wake_id': 'ada'}), {
        'outcome': 'started',
        'run_id': 'run-1',
      });
    });

    test('the refusal reaches the client as unauthorized, kind '
        'wake_not_yours', () async {
      Object? refused;
      try {
        await call('wakes.deliverNow', {'wake_id': 'ada'}, userId: 'user-2');
      } on Object catch (e) {
        refused = e;
      }
      expect(mapAppExceptionToRpc(refused!)?.data, {'kind': wakeNotYoursKind});
    });

    test('can_release is answered per caller', () async {
      Future<Map<String, dynamic>> row(String userId) async {
        final frame =
            await watch({'conversation_id': 'conv-1'}, userId: userId).first
                as Map;
        return (frame['wakes'] as List).cast<Map<String, dynamic>>().firstWhere(
          (r) => r['id'] == 'ada',
        );
      }

      expect((await row('user-1'))['can_release'], isTrue);
      expect((await row('user-2'))['can_release'], isFalse);
      expect((await row('user-2'))['requested_by_user_id'], 'user-1');
    });
  });

  test('cancel, release and deliver now act on the caller\'s wakes', () async {
    expect(await call('wakes.cancel', {'wake_id': 'a'}), {'cancelled': true});
    expect(wakes.byWs['ws-1']!['a']!.state, WakeState.cancelled);
    expect(await call('wakes.cancel', {'wake_id': 'a'}), {'cancelled': false});
    final receipt = await call('wakes.deliverNow', {'wake_id': 'h'});
    expect(receipt, {'outcome': 'started', 'run_id': 'run-1'});
    expect(await call('wakes.release', {'conversation_id': 'conv-1'}), {
      'released': 0,
    });
  });

  test('deliver now on a settled wake is refused', () async {
    await call('wakes.cancel', {'wake_id': 'a'});
    await expectLater(
      call('wakes.deliverNow', {'wake_id': 'a'}),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          'wake_settled',
        ),
      ),
    );
  });
}
