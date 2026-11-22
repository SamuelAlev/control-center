import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, OrchestrationCapRefusedException;
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/save_orchestration_revision_use_case.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/orchestration_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';
final _t0 = DateTime.utc(2026, 11, 20, 9);

class _Orchestrations implements OrchestrationRepository {
  final Map<String, Orchestration> rows = {};

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async {
    final o = rows[id];
    return o != null && o.workspaceId == workspaceId ? o : null;
  }

  @override
  Future<Orchestration?> forParentTicket(String ws, String ticketId) async =>
      rows.values.where((o) => o.parentTicketId == ticketId).firstOrNull;

  @override
  Future<Orchestration?> forPipelineRun(String ws, String runId) async =>
      rows.values.where((o) => o.pipelineRunId == runId).firstOrNull;

  @override
  Stream<List<Orchestration>> watchForWorkspace(String ws) =>
      Stream.value([...rows.values]);

  @override
  Stream<Orchestration?> watchById(String ws, String id) =>
      Stream.value(rows[id]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// Pipeline runs by id, each acting for its requester (or no one).
class _Runs implements PipelineRunRepository {
  final Map<String, PipelineRun> byId = {};

  void add(String id, {String workspaceId = _ws, String? requester}) =>
      byId[id] = PipelineRun(
        id: id,
        templateId: 'tpl',
        workspaceId: workspaceId,
        status: PipelineRunStatus.running,
        triggerPayload: {kPipelineRequestedByKey: ?requester},
        startedAt: _t0,
      );

  @override
  Future<PipelineRun?> getRun(String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// Never reached: a refused save stops before the use case.
class _NoRevisions implements OrchestrationRevisionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

const _proposal = OrchestrationProposal(
  goal: 'ship it',
  roles: [ProposedRole(roleKey: 'lead', title: 'Lead', existingAgentId: 'a1')],
  subTickets: [
    ProposedSubTicket(key: 's1', title: 'Do', roleKey: 'lead', dependsOn: []),
  ],
  synthesis: SynthesisSpec(
    roleKey: 'lead',
    prompt: 'combine',
    outputSchema: {'type': 'object'},
  ),
);

/// The orchestration ops follow the orchestration's space: a member who may
/// not read it neither sees nor moves it.
void main() {
  late _Orchestrations orchestrations;
  late _Runs runs;
  late List<String> cancelled;
  late List<String> approved;
  late List<String> widened;
  late List<String> continued;
  late ({List<RepoOp> ops, List<WatchQuery> watches}) pack;

  Orchestration orchestration(String id, String? spaceId) => Orchestration(
    id: id,
    workspaceId: _ws,
    proposal: _proposal,
    status: OrchestrationStatus.executing,
    spaceId: spaceId,
    parentTicketId: 'ticket-$id',
    pipelineRunId: 'run-$id',
    createdAt: _t0,
    updatedAt: _t0,
  );

  setUp(() {
    orchestrations = _Orchestrations();
    for (final (id, space) in [
      ('o-open', 'space-1'),
      ('o-secret', 'space-secret'),
      ('o-none', null),
    ]) {
      orchestrations.rows[id] = orchestration(id, space);
    }
    runs = _Runs();
    cancelled = [];
    approved = [];
    widened = [];
    continued = [];
    // The use cases' own refusal of an orchestration not in the workspace.
    Future<void> own(String ws, String id) async {
      if (await orchestrations.getById(ws, id) == null) {
        throw NotFoundException('No orchestration $id');
      }
    }

    pack = buildOrchestrationOps(
      orchestrations: orchestrations,
      revisions: null,
      runs: runs,
      requireSpace: (ws, user, space) async {
        if (space == 'space-secret') {
          throw const AuthException('space hidden');
        }
      },
      reposExposedBy: (ws, space) async => ['repo-$space'],
      callerSeesWorkspace: (_, _) async => true,
      approve: (ws, id, {approvedByUserId}) async {
        await own(ws, id);
        approved.add(id);
      },
      approveScoped: null,
      cancel: (ws, id) async {
        await own(ws, id);
        cancelled.add(id);
      },
      approveNodes: (ws, id, keys) async {
        await own(ws, id);
        widened.add(id);
      },
      saveRevision: SaveOrchestrationRevisionUseCase(
        orchestrations: orchestrations,
        revisions: _NoRevisions(),
        validator: const OrchestrationProposalValidator(),
      ),
      divergenceMarkers: null,
      continueNode: (ws, id, key) async {
        await own(ws, id);
        continued.add(id);
      },
    );
  });

  RepoOp op(String name) => pack.ops.singleWhere((o) => o.name == name);

  RepoOpContext ctx(Map<String, dynamic> args) => RepoOpContext(
    args: args,
    workspaceId: _ws,
    deviceId: 'device-1',
    userId: 'carol',
    role: WorkspaceRole.member,
  );

  Future<Object?> read(String name, Map<String, dynamic> args) async =>
      ((await op(name).handler(ctx(args))) as Map)['orchestration'];

  test('a hidden space reads as absent', () async {
    expect(await read('orchestration.getById', {'id': 'o-secret'}), isNull);
    expect(
      await read('orchestration.forParentTicket', {
        'ticket_id': 'ticket-o-secret',
      }),
      isNull,
    );
    expect(
      await read('orchestration.forPipelineRun', {
        'pipeline_run_id': 'run-o-secret',
      }),
      isNull,
    );
    expect(await read('orchestration.getById', {'id': 'o-open'}), isNotNull);
    expect(await read('orchestration.getById', {'id': 'o-none'}), isNotNull);
  });

  test('the watches leave it out', () async {
    final listed = await pack.watches
        .singleWhere((w) => w.name == 'orchestration.watchForWorkspace')
        .handler(
          const WatchQueryContext(
            args: {},
            workspaceId: _ws,
            deviceId: 'device-1',
            userId: 'carol',
          ),
        )
        .first;
    expect([
      for (final o in listed['orchestrations'] as List) (o as Map)['id'],
    ], unorderedEquals(['o-open', 'o-none']));
    final one = await pack.watches
        .singleWhere((w) => w.name == 'orchestration.watchById')
        .handler(
          const WatchQueryContext(
            args: {'id': 'o-secret'},
            workspaceId: _ws,
            deviceId: 'device-1',
            userId: 'carol',
          ),
        )
        .first;
    expect(one['orchestration'], isNull);
  });

  test('a move on it is refused by the space gate', () async {
    await expectLater(
      op('orchestration.cancel').handler(ctx({'orchestration_id': 'o-secret'})),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      op(
        'orchestration.approve',
      ).handler(ctx({'orchestration_id': 'o-secret'})),
      throwsA(isA<AuthException>()),
    );
    expect(cancelled, isEmpty);
    await op(
      'orchestration.cancel',
    ).handler(ctx({'orchestration_id': 'o-open'}));
    expect(cancelled, ['o-open']);
  });

  group('moves that start or widen work', () {
    const widening = [
      'orchestration.approveNodes',
      'orchestration.continueNode',
    ];
    const starting = [
      'orchestration.approve',
      ...widening,
      'orchestration.saveRevision',
    ];

    setUp(() {
      // Alice approved o-open (her run); o-bot's run acts for no one;
      // o-draft is proposed, with no run yet.
      runs.add('run-o-open', requester: 'alice');
      runs.add('run-o-none', requester: 'alice');
      runs.add('run-o-bot');
      orchestrations.rows['o-bot'] = orchestration(
        'o-bot',
        'space-1',
      ).copyWith(pipelineRunId: 'run-o-bot');
      orchestrations.rows['o-draft'] = Orchestration(
        id: 'o-draft',
        workspaceId: _ws,
        proposal: _proposal,
        status: OrchestrationStatus.proposed,
        spaceId: 'space-1',
        createdAt: _t0,
        updatedAt: _t0,
      );
    });

    Map<String, dynamic> argsFor(String op, String id) => {
      'orchestration_id': id,
      if (op == 'orchestration.approveNodes') 'node_keys': ['s1'],
      if (op == 'orchestration.continueNode') 'node_key': 's1',
      if (op == 'orchestration.saveRevision') ...{
        'proposal_json': _proposal.toJsonString(),
        'base_revision': 1,
      },
    };

    Future<Map<String, dynamic>> call(
      String user,
      String op,
      String id, {
      WorkspaceRole role = WorkspaceRole.member,
      RepoGrantLevel grant = RepoGrantLevel.write,
      String workspaceId = _ws,
    }) =>
        RepoOpDispatcher(
          registry: RepoOpRegistry(pack.ops),
          mapException: mapAppExceptionToRpc,
          resolveRole: (ws, u) async => role,
          resolveRepoGrant: (ws, u, repo) async =>
              repo == 'repo-space-1' ? grant : RepoGrantLevel.none,
        ).call(
          id: 1,
          params: {
            'op': op,
            'args': {'workspace_id': workspaceId, ...argsFor(op, id)},
          },
          deviceId: 'device-1',
          userId: user,
          sessionCapability: SessionCapability.fullClient,
        );

    Object? kindOf(Map<String, dynamic> res) =>
        ((res['error'] as Map?)?['data'] as Map?)?['kind'];

    test('each needs the member role and the write grant on the repositories '
        "of the orchestration's space; cancel does not", () async {
      for (final name in starting) {
        final o = op(name);
        expect(o.minRole, WorkspaceRole.member, reason: name);
        expect(o.repoAccess, RepoGrantLevel.write, reason: name);
        expect(await o.repoAccessVia!(ctx(argsFor(name, 'o-open'))), [
          'repo-space-1',
        ], reason: name);
        expect(
          await o.repoAccessVia!(ctx(argsFor(name, 'o-none'))),
          isEmpty,
          reason: '$name: no space, no repository, no grant asked',
        );
        await expectLater(
          o.repoAccessVia!(ctx(argsFor(name, 'o-secret'))),
          throwsA(isA<AuthException>()),
          reason: '$name: a hidden space refuses first',
        );
      }
      expect(op('orchestration.cancel').repoAccess, isNull);
    });

    test('a member with the read grant is refused all four, before anything '
        'moves', () async {
      for (final name in starting) {
        final res = await call(
          'alice',
          name,
          'o-open',
          grant: RepoGrantLevel.read,
        );
        expect(kindOf(res), 'repo_grant_required', reason: name);
      }
      expect([...approved, ...widened, ...continued], isEmpty);
      expect(orchestrations.rows['o-open']!.revision, 1);
    });

    test(
      "a member with the write grant who is not the run's person is "
      'refused widening it, and may still approve a draft and cancel',
      () async {
        for (final name in widening) {
          final res = await call('bob', name, 'o-open');
          expect(kindOf(res), OrchestrationCapRefusedException.notYoursKind);
        }
        expect([...widened, ...continued], isEmpty);
        expect(
          (await call('bob', 'orchestration.approve', 'o-draft'))['result'],
          isNotNull,
        );
        expect(
          (await call('bob', 'orchestration.cancel', 'o-open'))['result'],
          isNotNull,
        );
        expect(approved, ['o-draft']);
        expect(cancelled, ['o-open']);
      },
    );

    test("the run's person widens it, in a space or without one", () async {
      for (final id in ['o-open', 'o-none']) {
        for (final name in widening) {
          expect(
            (await call('alice', name, id))['result'],
            isNotNull,
            reason: '$name $id',
          );
        }
      }
      expect(widened, ['o-open', 'o-none']);
      expect(continued, ['o-open', 'o-none']);
    });

    test("an admin widens a run that acts for no one, not a person's run; a "
        'member widens neither', () async {
      for (final name in widening) {
        expect(
          kindOf(await call('dana', name, 'o-open', role: WorkspaceRole.admin)),
          OrchestrationCapRefusedException.notYoursKind,
        );
        expect(
          kindOf(await call('bob', name, 'o-bot')),
          OrchestrationCapRefusedException.notYoursKind,
        );
        expect(
          (await call(
            'dana',
            name,
            'o-bot',
            role: WorkspaceRole.admin,
          ))['result'],
          isNotNull,
        );
      }
      expect(widened, ['o-bot']);
      expect(continued, ['o-bot']);
    });

    test('across workspaces: a run of another workspace acts for no one, and '
        "another workspace's orchestration is not found", () async {
      // o-open's run id names a run of ws-2 that Alice requested there.
      runs.add('run-o-open', workspaceId: 'ws-2', requester: 'alice');
      for (final name in widening) {
        expect(
          kindOf(await call('alice', name, 'o-open')),
          OrchestrationCapRefusedException.notYoursKind,
        );
        final res = await call('alice', name, 'o-open', workspaceId: 'ws-2');
        expect(res['result'], isNull, reason: name);
        expect(res['error'], isNotNull, reason: name);
      }
      expect([...widened, ...continued], isEmpty);
    });
  });
}
