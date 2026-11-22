import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart' show ToolCallForms, plainToolForm;
import 'package:cc_harness/loop.dart' show SteeringQueue;
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_infra/cc_infra.dart'
    show SteeringQueueService, SteeringSessionView;
import 'package:cc_server_core/src/catalog/steering_force_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// One conversation's messages, with the steering patch the service writes.
/// [rows] are ws-1's; [elsewhere] another workspace's, under the same ids.
class _Messages implements MessagingRepository {
  final rows = <String, Message>{};
  final elsewhere = <String, Message>{};

  Map<String, Message> _of(String workspaceId) =>
      workspaceId == 'ws-1' ? rows : elsewhere;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => [
    for (final m in _of(workspaceId).values)
      if (m.conversationId == conversationId && m.spaceId == spaceId) m,
  ];

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      _of(workspaceId)[messageId];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) async {
    final store = _of(workspaceId);
    final row = store[messageId]!;
    store[messageId] = row.copyWith(
      content: content,
      metadata: metadata,
      messageType: messageType == null
          ? null
          : MessageType.values.firstWhere(
              (t) => t.name == messageType || t.toString() == messageType,
              orElse: () => MessageType.text,
            ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The conversation's live runs ([active]; none by default).
class _NoRuns implements AgentRunLogRepository {
  final active = <AgentRunLog>[];

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => [
    for (final r in active)
      if (r.workspaceId == workspaceId && r.conversationId == conversationId)
        r,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A live harness run of conv-1 acting for [requestedByUserId].
class _Session implements SteeringSessionView {
  _Session(this.requestedByUserId, {this.runLogId = 'run-1'});

  @override
  final String? requestedByUserId;
  @override
  final String? runLogId;
  @override
  final String? workspaceId = 'ws-1';
  @override
  final String? conversationId = 'conv-1';
  @override
  final String? spaceId = 'space-1';
  @override
  final String? agentId = 'agent-1';
  @override
  bool get acceptsSteering => true;
  @override
  bool get readOnly => false;
  @override
  bool get freshHistory => false;
  @override
  final SteeringQueue steeringQueue = SteeringQueue();
  @override
  ToolCallForms toolForms = plainToolForm;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgentRunLog _run(String id, String? person) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  conversationId: 'conv-1',
  spaceId: 'space-1',
  startedAt: DateTime.utc(2026, 7, 1),
  status: RunStatus.running,
  requestedByUserId: person,
);

Message _queued(String id, int order, String sender, {bool write = false}) =>
    Message(
      id: id,
      spaceId: 'space-1',
      conversationId: 'conv-1',
      senderId: sender,
      senderType: SenderType.user,
      content: 'card $id',
      messageType: MessageType.steering,
      metadata: {
        'steerState': 'queued',
        'steerOrder': order,
        if (write) SteeringQueueService.writerWriteKey: true,
      },
      createdAt: DateTime.utc(2026, 7, 1),
    );

class _Dispatch implements MessagingPort {
  final stopped = <String>[];

  @override
  Future<void> stopRun(String workspaceId, String runLogId) async =>
      stopped.add(runLogId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Message _held(
  String id,
  int order, {
  String heldBy = 'stop',
  String? resetsAt,
  String sender = 'user-1',
}) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  senderId: sender,
  senderType: SenderType.user,
  content: 'card $id',
  messageType: MessageType.steering,
  metadata: {
    'steerState': 'held',
    'steerOrder': order,
    'steerHeldBy': heldBy,
    'steerLimitResetsAt': ?resetsAt,
  },
  createdAt: DateTime.utc(2026, 7, 1),
);

void main() {
  late _Messages messages;
  late List<String> sent;
  late List<String?> sentFor;
  late List<String> ownershipChecks;
  late RepoOp release;
  late List<RepoOp> ops;
  late _NoRuns runs;
  late List<_Session> sessions;
  late _Dispatch dispatch;
  // The members who hold the write grant on the space's repositories.
  late Set<String> writers;

  setUp(() {
    messages = _Messages();
    sent = [];
    sentFor = [];
    ownershipChecks = [];
    runs = _NoRuns();
    sessions = [];
    dispatch = _Dispatch();
    writers = {'user-1'};
    final queue = SteeringQueueService(
      messagingRepository: messages,
      runLogRepository: runs,
      eventBus: null,
      writerName: (_, id) async => id,
      dispatchResponder:
          ({
            required String workspaceId,
            required String spaceId,
            String? conversationId,
            required String content,
            String? senderUserId,
            List<MessageAttachment> attachments = const [],
            List<String> promptImageRefs = const [],
          }) async {
            sent.add(content);
            sentFor.add(senderUserId);
          },
      sessionsForConversation: (_) => sessions,
    );
    ops = buildSteeringForceOps(
      steeringQueue: queue,
      dispatch: dispatch,
      assertSpaceOwned: (workspaceId, spaceId, userId) async {
        ownershipChecks.add('$workspaceId/$spaceId/$userId');
        if (userId != 'user-1' && userId != 'user-2') {
          throw const AuthException('Not your space.');
        }
      },
      steerGate: steeringWriteGate(
        steeringQueue: queue,
        requireSpaceWrite: (workspaceId, userId, spaceId) async {
          if (!writers.contains(userId)) {
            throw const RepoGrantRequiredException(
              RepoGrantLevel.write,
              'No write access to this repo',
            );
          }
        },
      ),
      resolveRoleDefinition: null,
    );
    release = ops.singleWhere((op) => op.name == 'steering.release');
  });

  RepoOp op(String name) => ops.singleWhere((o) => o.name == name);

  RepoOpContext cardCtx(String userId, Map<String, Object?> args) =>
      RepoOpContext(
        args: {'space_id': 'space-1', 'conversation_id': 'conv-1', ...args},
        workspaceId: 'ws-1',
        deviceId: 'device-1',
        userId: userId,
      );

  Future<Object?> refusalOf(Future<Object?> call) async {
    try {
      await call;
    } on Object catch (e) {
      return e;
    }
    return null;
  }

  RepoOpContext ctx(
    String userId, {
    Object? heldBy = 'stop',
    String workspaceId = 'ws-1',
  }) => RepoOpContext(
    args: {
      'space_id': 'space-1',
      'conversation_id': 'conv-1',
      'held_by': ?heldBy,
    },
    workspaceId: workspaceId,
    deviceId: 'device-1',
    userId: userId,
  );

  test('releases the held cards and sends them when no run is live', () async {
    messages.rows['m-1'] = _held('m-1', 0);
    messages.rows['m-2'] = _held('m-2', 1);

    final result = await release.handler(ctx('user-1'));

    expect(result, {'released': 2, 'kept': 0});
    expect(ownershipChecks, ['ws-1/space-1/user-1']);
    expect(sent, ['card m-1\n\ncard m-2']);
  });

  test('is refused for a caller who does not own the space', () async {
    messages.rows['m-1'] = _held('m-1', 0);

    await expectLater(
      release.handler(ctx('user-3')),
      throwsA(isA<AuthException>()),
    );
    expect(sent, isEmpty);
    expect(messages.rows['m-1']!.metadata!['steerState'], 'held');
  });

  test('releases nothing when nothing is held', () async {
    expect(await release.handler(ctx('user-1')), {'released': 0, 'kept': 0});
    expect(sent, isEmpty);
  });

  test("a member sends only their own held cards; another person's stay "
      'held', () async {
    messages.rows['m-1'] = _held('m-1', 0);
    messages.rows['m-2'] = _held('m-2', 1, sender: 'user-2');

    expect(await release.handler(ctx('user-2')), {'released': 1, 'kept': 1});
    expect(sent, ['card m-2']);
    expect(sentFor, ['user-2']);
    expect(messages.rows['m-1']!.metadata!['steerState'], 'held');
  });

  test("a member with no held card of their own, while another person's "
      'are held, is refused with steering_not_yours; nothing moves', () async {
    messages.rows['m-1'] = _held('m-1', 0);
    messages.rows['m-2'] = _held('m-2', 1);
    Object? refusal;
    try {
      await release.handler(ctx('user-2'));
    } on Object catch (e) {
      refusal = e;
    }
    expect(refusal, isA<SteeringNotYoursException>());
    expect(mapAppExceptionToRpc(refusal!)!.data, {
      'kind': 'steering_not_yours',
      'others_held': 2,
    });
    expect(sent, isEmpty);
    expect(
      messages.rows.values.map((m) => m.metadata!['steerState']),
      everyElement('held'),
    );
  });

  test("held_by 'stop' releases what the stop held; a usage-limit pause's "
      'cards stay held', () async {
    messages.rows['m-1'] = _held('m-1', 0);
    messages.rows['m-2'] = _held('m-2', 1, heldBy: 'limit:run-9');
    messages.rows['m-3'] = _held('m-3', 2);

    expect(await release.handler(ctx('user-1')), {'released': 2, 'kept': 0});
    expect(sent, ['card m-1\n\ncard m-3']);
    expect(messages.rows['m-2']!.metadata!['steerState'], 'held');
    expect(messages.rows['m-2']!.metadata!['steerHeldBy'], 'limit:run-9');
  });

  test("a pause's cards are refused with steering_held_by_limit and the "
      'reset; nothing moves', () async {
    messages.rows['m-1'] = _held(
      'm-1',
      0,
      heldBy: 'limit:run-9',
      resetsAt: '2026-07-01T14:00:00.000Z',
    );
    Object? refusal;
    try {
      await release.handler(ctx('user-1', heldBy: 'limit:run-9'));
    } on Object catch (e) {
      refusal = e;
    }
    expect(refusal, isA<SteeringHeldByLimitException>());
    final wire = mapAppExceptionToRpc(refusal!)!;
    expect(wire.data, {
      'kind': 'steering_held_by_limit',
      'resets_at': '2026-07-01T14:00:00.000Z',
    });
    expect(ownershipChecks, ['ws-1/space-1/user-1']);
    expect(sent, isEmpty);
    expect(messages.rows['m-1']!.metadata!['steerState'], 'held');
  });

  test('held_by is required, with no default; a malformed one is refused '
      'before anything is read', () async {
    expect(release.requiredArgs, contains('held_by'));
    messages.rows['m-1'] = _held('m-1', 0);
    for (final bad in [null, '', 'limit:', 'limit: ', 'person', 7]) {
      await expectLater(
        release.handler(ctx('user-1', heldBy: bad)),
        throwsA(isA<ValidationException>()),
        reason: '$bad',
      );
    }
    expect(ownershipChecks, isEmpty);
    expect(messages.rows['m-1']!.metadata!['steerState'], 'held');
  });

  test("another workspace's conversation under the same ids is not "
      'touched', () async {
    messages.elsewhere['m-1'] = _held('m-1', 0);

    expect(await release.handler(ctx('user-1')), {'released': 0, 'kept': 0});
    expect(sent, isEmpty);
    expect(messages.elsewhere['m-1']!.metadata!['steerState'], 'held');
  });

  group('steering.update: only its writer edits a card', () {
    test("another writer's edit is refused with steering_not_yours; the row "
        'and the live lane keep the text', () async {
      messages.rows['m-1'] = _queued('m-1', 0, 'user-1', write: true);
      runs.active.add(_run('run-1', 'user-1'));
      final lane = _Session('user-1');
      sessions.add(lane);
      lane.steeringQueue.pushSteering('card m-1', ref: 'm-1');

      final refusal = await refusalOf(
        op('steering.update').handler(
          cardCtx('user-2', {'message_id': 'm-1', 'message': 'merge it'}),
        ),
      );

      expect(refusal, isA<SteeringNotYoursException>());
      expect(
        (mapAppExceptionToRpc(refusal!)!.data! as Map)['kind'],
        'steering_not_yours',
      );
      expect(messages.rows['m-1']!.content, 'card m-1');
      expect(
        lane.steeringQueue.drainSteering().map((m) => m.content),
        ['card m-1'],
      );
    });

    test("the writer's own edit reaches the live lane", () async {
      messages.rows['m-1'] = _queued('m-1', 0, 'user-1', write: true);
      runs.active.add(_run('run-1', 'user-1'));
      final lane = _Session('user-1');
      sessions.add(lane);
      lane.steeringQueue.pushSteering('card m-1', ref: 'm-1');

      expect(
        await op('steering.update').handler(
          cardCtx('user-1', {'message_id': 'm-1', 'message': 'stop at tests'}),
        ),
        {'ok': true},
      );
      expect(messages.rows['m-1']!.content, 'stop at tests');
      expect(
        lane.steeringQueue.drainSteering().map((m) => m.content),
        ['stop at tests'],
      );
    });
  });

  group('steering another person\'s run needs the write grant', () {
    test("a read-only member's deliver and forced send into another person's "
        'live run are refused with the forge kind; nothing is pushed or '
        'stopped', () async {
      messages.rows['m-2'] = _queued('m-2', 0, 'user-2');
      runs.active.add(_run('run-1', 'user-1'));
      final lane = _Session('user-1');
      sessions.add(lane);

      for (final name in ['steering.deliver', 'steering.forceSend']) {
        final refusal = await refusalOf(
          op(name).handler(cardCtx('user-2', {'message_id': 'm-2'})),
        );
        expect(refusal, isA<RepoGrantRequiredException>(), reason: name);
        expect(mapAppExceptionToRpc(refusal!)!.data, {
          'kind': 'repo_grant_required',
          'level': 'write',
        }, reason: name);
      }
      expect(lane.steeringQueue.isEmpty, isTrue);
      expect(dispatch.stopped, isEmpty);
      expect(messages.rows['m-2']!.metadata!['steerState'], 'queued');
    });

    test('into their own live run a read-only member steers as today',
        () async {
      messages.rows['m-2'] = _queued('m-2', 0, 'user-2');
      runs.active.add(_run('run-2', 'user-2'));
      final lane = _Session('user-2', runLogId: 'run-2');
      sessions.add(lane);

      expect(
        await op('steering.deliver').handler(
          cardCtx('user-2', {'message_id': 'm-2'}),
        ),
        {'delivered': true},
      );
      expect(
        lane.steeringQueue.drainSteering().map((m) => m.content),
        ['card m-2'],
      );
    });

    test("a write-grant member steers another person's run as today, the "
        'writer named to the model', () async {
      writers.add('user-2');
      messages.rows['m-2'] = _queued('m-2', 0, 'user-2', write: true);
      runs.active.add(_run('run-1', 'user-1'));
      final lane = _Session('user-1');
      sessions.add(lane);

      expect(
        await op('steering.deliver').handler(
          cardCtx('user-2', {'message_id': 'm-2'}),
        ),
        {'delivered': true},
      );
      final text = lane.steeringQueue.drainSteering().single.content;
      expect(text, contains('user-2'));
      expect(text, endsWith('card m-2'));
    });

    test('the gate: refused only when the text would reach a run that does '
        'not act for the caller; with no run live it falls through', () async {
      final gate = steeringWriteGate(
        steeringQueue: null,
        requireSpaceWrite: (_, user, _) async {
          if (!writers.contains(user)) {
            throw const RepoGrantRequiredException(
              RepoGrantLevel.write,
              'No write access to this repo',
            );
          }
        },
      );
      // No queue wired: nothing to steer, so a read-only caller passes.
      expect(await gate(cardCtx('user-2', {}), 'space-1', 'conv-1'), isFalse);
      expect(await gate(cardCtx('user-1', {}), 'space-1', 'conv-1'), isTrue);
    });
  });
}
