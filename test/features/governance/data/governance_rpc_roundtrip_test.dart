import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest, RepoOpKind;
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart'
    show
        agentPresenceToWire,
        approvalCommentToWire,
        approvalToWire,
        orgGoalToWire;
import 'package:flutter_test/flutter_test.dart';

/// Proves the PRD 09 governance READ surface round-trips end to end over the
/// in-process RPC space: the server's real `*ToWire` functions encode the
/// domain entities and the real `cc_data` `Rpc*` adapters decode them back —
/// catching any wire-key drift or enum (de)serialization mismatch between the
/// two halves. Minimal handlers stand in for the full catalog, but they use the
/// SAME wire functions the live catalog ops use.
class _InitDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async {
    return <String, dynamic>{
      'jsonrpc': '2.0',
      'id': request.id,
      'result': <String, dynamic>{
        'protocolVersion': '2025-01-01',
        'capabilities': <String, dynamic>{'tools': <String, dynamic>{}},
      },
    };
  }
}

void main() {
  final now = DateTime.utc(2026, 6, 30, 12);
  final goal = OrgGoal(
    id: 'g1',
    workspaceId: 'ws1',
    title: 'Ship PRD 09',
    level: OrgGoalLevel.company,
    description: 'The company mission',
    status: OrgGoalStatus.active,
    progress: 42,
    createdAt: now,
    updatedAt: now,
  );
  final approval = Approval(
    id: 'a1',
    workspaceId: 'ws1',
    title: 'Exit plan mode',
    kind: ApprovalKind.planExit,
    status: ApprovalStatus.revisionRequested,
    requestedByActorType: 'agent',
    requestedById: 'agent-7',
    linkedTicketIds: const ['t1', 't2'],
    createdAt: now,
    updatedAt: now,
  );
  final comment = ApprovalComment(
    id: 'c1',
    approvalId: 'a1',
    workspaceId: 'ws1',
    authorType: 'user',
    authorId: 'u1',
    body: 'Tighten the rollback plan first.',
    createdAt: now,
  );
  const presence = AgentPresence(
    availability: AgentAvailability.online,
    workload: Workload.working,
    runningCount: 2,
    queuedCount: 1,
    capacity: 3,
  );

  late RemoteRpcSession session;
  late RemoteRpcClient client;

  setUp(() async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    session = RemoteRpcSession(
      deviceId: 'dev-1',
      userId: 'user-1',
      space: serverChannel,
      dispatcher: _InitDispatcher(),
      capability: SessionCapability.fullClient,
      workspaceResolver: (_) async => const [(id: 'ws1', name: 'WS One')],
      repoOps: RepoOpDispatcher(
        registry: RepoOpRegistry([
          RepoOp(
            name: 'goals.get',
            kind: RepoOpKind.read,
            requiredArgs: ['goal_id'],
            handler: (ctx) async => {'goal': orgGoalToWire(goal)},
          ),
          RepoOp(
            name: 'approvals.get',
            kind: RepoOpKind.read,
            requiredArgs: ['approval_id'],
            handler: (ctx) async => {'approval': approvalToWire(approval)},
          ),
          RepoOp(
            name: 'approvals.getComments',
            kind: RepoOpKind.read,
            requiredArgs: ['approval_id'],
            handler: (ctx) async => {
              'comments': [approvalCommentToWire(comment)],
            },
          ),
          RepoOp(
            name: 'agent_presence.forWorkspace',
            kind: RepoOpKind.read,
            handler: (ctx) async => {
              'presence': {'agent-7': agentPresenceToWire(presence)},
            },
          ),
        ], catalogVersion: 1),
      ),
      watchQueries: WatchQueryRegistry([
        WatchQuery(
          name: 'goals.watchForWorkspace',
          handler: (ctx) => Stream.value({
            'goals': [orgGoalToWire(goal)],
          }),
        ),
        WatchQuery(
          name: 'approvals.watchForWorkspace',
          handler: (ctx) => Stream.value({
            'approvals': [approvalToWire(approval)],
          }),
        ),
      ]),
    );
    await session.start();
    client = RemoteRpcClient(clientChannel)
      ..activeWorkspaceId = 'ws1'
      ..start();
    await client.initialize();
  });

  tearDown(() async {
    await client.close();
    await session.stop();
  });

  test('RpcGoalRepository round-trips a goal (read + watch)', () async {
    final repo = RpcGoalRepository(client);

    final fetched = await repo.getById('ws1', 'g1');
    expect(fetched, isNotNull);
    expect(fetched!.title, 'Ship PRD 09');
    expect(fetched.level, OrgGoalLevel.company);
    expect(fetched.status, OrgGoalStatus.active);
    expect(fetched.progress, 42);
    expect(fetched.createdAt, now);

    final watched = await repo.watchByWorkspace('ws1').first;
    expect(watched.single.id, 'g1');
  });

  test('RpcApprovalRepository round-trips an approval + comments', () async {
    final repo = RpcApprovalRepository(client);

    final fetched = await repo.getById('ws1', 'a1');
    expect(fetched, isNotNull);
    // The plan-exit kind + revision-requested status survive the storage-key
    // round-trip (kind via `.storage`, status via `.storage`).
    expect(fetched!.kind, ApprovalKind.planExit);
    expect(fetched.status, ApprovalStatus.revisionRequested);
    expect(fetched.linkedTicketIds, ['t1', 't2']);
    expect(fetched.requestedById, 'agent-7');

    final comments = await repo.getComments('ws1', 'a1');
    expect(comments.single.body, 'Tighten the rollback plan first.');

    final watched = await repo.watchByWorkspace('ws1').first;
    expect(watched.single.id, 'a1');
    final revisionOnly = await repo
        .watchByStatus('ws1', ApprovalStatus.revisionRequested.storage)
        .first;
    expect(revisionOnly.single.id, 'a1');
    final approvedOnly = await repo
        .watchByStatus('ws1', ApprovalStatus.approved.storage)
        .first;
    expect(approvedOnly, isEmpty);
  });

  test('RpcAgentPresenceReader round-trips the presence summary', () async {
    final reader = RpcAgentPresenceReader(client);
    final byAgent = await reader.presenceForWorkspace('ws1');
    final p = byAgent['agent-7'];
    expect(p, isNotNull);
    expect(p!.availability, AgentAvailability.online);
    expect(p.workload, Workload.working);
    // The PRD 09 acceptance phrasing.
    expect(p.summary, 'online + working (2/3)');
  });

  test('governance write methods throw (read-only over RPC)', () async {
    expect(
      () => RpcGoalRepository(client).upsert(goal),
      throwsUnsupportedError,
    );
    expect(
      () => RpcApprovalRepository(client).addComment(comment),
      throwsUnsupportedError,
    );
  });
}
