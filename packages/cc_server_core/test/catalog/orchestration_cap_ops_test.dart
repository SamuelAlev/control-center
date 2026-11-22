import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show
        NotFoundException,
        OrchestrationCapRefusedException,
        RepoOpKind,
        ValidationException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/orchestration_cap_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:cc_server_core/src/runtime/server_pipeline_goals.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

const _ws = 'ws-1';
const _other = 'ws-2';
final _t0 = DateTime.utc(2026, 11, 20, 9);
const _usd = 1000000;

class _Runs implements PipelineRunRepository {
  final Map<String, PipelineRun> byId = {};

  @override
  Future<PipelineRun?> getRun(String id) async => byId[id];

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async =>
      byId.values.where((r) => !r.isTerminal).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Messages implements MessagingRepository {
  final List<({String spaceId, String type, Map<String, dynamic>? metadata})>
  sent = [];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    sent.add((spaceId: spaceId, type: messageType, metadata: metadata));
    return 'm-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// Resumes a held run only when the gate no longer holds it, as the real
/// engine does.
class _Engine implements PipelineEngine {
  _Engine(this.runs);
  final _Runs runs;
  late OrchestrationBudgetGate gate;
  final List<String> resumed = [];

  @override
  Future<bool> resumeHeld(String ws, String runId) async {
    final run = runs.byId[runId];
    if (run == null || await gate.check(run) != null) {
      return false;
    }
    resumed.add(runId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

Orchestration _orchestration({
  String id = 'orch-1',
  String ws = _ws,
  int? cap = 5 * _usd,
  String? spaceId = 'space-1',
  String? runId = 'run-1',
  OrchestrationStatus status = OrchestrationStatus.executing,
}) => Orchestration(
  id: id,
  workspaceId: ws,
  proposal: const OrchestrationProposal(
    goal: 'Plan',
    roles: [],
    subTickets: [],
    synthesis: SynthesisSpec(roleKey: 'lead', prompt: 'Wrap', outputSchema: {}),
  ),
  createdAt: _t0,
  updatedAt: _t0,
  spaceId: spaceId,
  pipelineRunId: runId,
  maxCostMicros: cap,
  status: status,
);

PipelineRun _run({String? requester = 'ada', int spent = 5 * _usd}) =>
    PipelineRun(
      id: 'run-1',
      templateId: 'tpl',
      workspaceId: _ws,
      status: PipelineRunStatus.suspended,
      triggerPayload: {kPipelineRequestedByKey: ?requester},
      startedAt: _t0,
      totalCostMicros: spent,
      state: const {kBudgetHoldStateKey: <String, Object?>{}},
    );

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoOrchestrationRepository orchestrations;
  late _Runs runs;
  late _Messages messages;
  late Set<String> noSpace;
  late List<RepoOp> ops;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in [_ws, _other]) {
      await seedTestWorkspace(global, dbs, ws);
      // The orchestration's space and run rows are not this test's.
      await dbs.of(ws).customStatement('PRAGMA foreign_keys = OFF');
    }
    orchestrations = DaoOrchestrationRepository(dbs);
    runs = _Runs()..byId['run-1'] = _run();
    messages = _Messages();
    noSpace = {};
    await orchestrations.insert(_orchestration());
    ops = buildOrchestrationCapOps(
      orchestrations: orchestrations,
      caps: orchestrations,
      runs: runs,
      messages: messages,
      requireSpace: (ws, userId, spaceId) async {
        if (noSpace.contains(userId)) {
          throw const ValidationException(
            'No access to this space',
            code: 'space_access_denied',
          );
        }
      },
      reposExposedBy: (ws, spaceId) async => ['repo-$spaceId'],
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  RepoOp op() => ops.singleWhere((o) => o.name == 'orchestration.raiseCap');

  RepoOpContext ctx(
    Object? micros, {
    String user = 'ada',
    WorkspaceRole role = WorkspaceRole.member,
    String ws = _ws,
    String id = 'orch-1',
  }) => RepoOpContext(
    args: {'orchestration_id': id, 'max_cost_micros': micros},
    workspaceId: ws,
    deviceId: 'device-1',
    userId: user,
    role: role,
  );

  Future<int?> cap() async =>
      (await orchestrations.getById(_ws, 'orch-1'))!.maxCostMicros;

  Matcher refused(String kind) => throwsA(
    isA<OrchestrationCapRefusedException>().having((e) => e.code, 'kind', kind),
  );

  test('the op: a mutation for members, with the write grant on the '
      "space's repositories", () async {
    final raise = op();
    expect(raise.name, 'orchestration.raiseCap');
    expect(raise.kind, RepoOpKind.mutate);
    expect(raise.minRole, WorkspaceRole.member);
    expect(raise.repoAccess, RepoGrantLevel.write);
    expect(await raise.repoAccessVia!(ctx(6 * _usd)), ['repo-space-1']);
  });

  test("the run's requester raises it: the column, a system row and the "
      'values the audit keeps', () async {
    final result = await op().handler(ctx(8 * _usd));
    expect(result, {
      'orchestration_id': 'orch-1',
      'old_micros': 5 * _usd,
      'new_micros': 8 * _usd,
    });
    expect(await cap(), 8 * _usd);
    final row = messages.sent.single;
    expect(row.spaceId, 'space-1');
    expect(row.type, 'system');
    expect(row.metadata, {
      'kind': kOrchestrationCapRaisedRow,
      'orchestration_id': 'orch-1',
      'old_micros': 5 * _usd,
      'new_micros': 8 * _usd,
      'user_id': 'ada',
    });
  });

  group('who may raise it', () {
    test('another member is refused', () async {
      await expectLater(
        op().handler(ctx(8 * _usd, user: 'bob')),
        refused(OrchestrationCapRefusedException.notYoursKind),
      );
      expect(await cap(), 5 * _usd);
    });

    test('a member without the space is refused, by the space gate', () async {
      noSpace.add('ada');
      await expectLater(
        op().handler(ctx(8 * _usd)),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'kind',
            'space_access_denied',
          ),
        ),
      );
      await expectLater(op().repoAccessVia!(ctx(8 * _usd)), throwsA(anything));
      expect(await cap(), 5 * _usd);
    });

    test("an admin is refused on a person's run", () async {
      await expectLater(
        op().handler(ctx(8 * _usd, user: 'root', role: WorkspaceRole.admin)),
        refused(OrchestrationCapRefusedException.notYoursKind),
      );
      expect(await cap(), 5 * _usd);
    });

    test("an admin raises a bot's run; a member does not", () async {
      runs.byId['run-1'] = _run(requester: null);
      await expectLater(
        op().handler(ctx(8 * _usd, user: 'bob')),
        refused(OrchestrationCapRefusedException.notYoursKind),
      );
      await op().handler(
        ctx(8 * _usd, user: 'root', role: WorkspaceRole.admin),
      );
      expect(await cap(), 8 * _usd);
    });

    test('an orchestration of another workspace is not found', () async {
      await orchestrations.insert(_orchestration(id: 'orch-x', ws: _other));
      await expectLater(
        op().handler(ctx(8 * _usd, id: 'orch-x')),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        (await orchestrations.getById(_other, 'orch-x'))!.maxCostMicros,
        5 * _usd,
      );
    });
  });

  group('what it may be raised to', () {
    for (final (label, value) in [
      ('lower', 4 * _usd),
      ('equal', 5 * _usd),
      ('not an integer', 6.5 * _usd + 0.5),
      ('a string', '6000000'),
      ('removal by null', null),
      ('removal by zero', 0),
      ('over the ceiling', kOrchestrationCapCeilingMicros + 1),
    ]) {
      test('$label is refused', () async {
        await expectLater(
          op().handler(ctx(value)),
          refused(OrchestrationCapRefusedException.invalidKind),
        );
        expect(await cap(), 5 * _usd);
        expect(messages.sent, isEmpty);
      });
    }

    test('below what was spent is refused', () async {
      runs.byId['run-1'] = _run(spent: 9 * _usd);
      await expectLater(
        op().handler(ctx(8 * _usd)),
        refused(OrchestrationCapRefusedException.invalidKind),
      );
      expect(await cap(), 5 * _usd);
    });

    test('the ceiling itself is allowed', () async {
      await op().handler(ctx(kOrchestrationCapCeilingMicros));
      expect(await cap(), kOrchestrationCapCeilingMicros);
    });

    test('an orchestration created without a cap has none to raise', () async {
      await orchestrations.insert(_orchestration(id: 'orch-free', cap: null));
      await expectLater(
        op().handler(ctx(8 * _usd, id: 'orch-free')),
        refused(OrchestrationCapRefusedException.invalidKind),
      );
    });
  });

  test('two raises at once: one wins, the other is refused with the fresh '
      'value', () async {
    final results = await Future.wait([
      op()
          .handler(ctx(7 * _usd))
          .then<Object>((v) => v, onError: (Object e) => e),
      op()
          .handler(ctx(9 * _usd))
          .then<Object>((v) => v, onError: (Object e) => e),
    ]);
    final won = results.whereType<Map<String, dynamic>>().single;
    final lost = results.whereType<OrchestrationCapRefusedException>().single;
    expect(lost.code, OrchestrationCapRefusedException.changedKind);
    expect(lost.currentMicros, won['new_micros']);
    expect(await cap(), won['new_micros']);
    expect(messages.sent, hasLength(1));
    final wire = mapAppExceptionToRpc(lost)!;
    expect(wire.data, {
      'kind': OrchestrationCapRefusedException.changedKind,
      'max_cost_micros': won['new_micros'],
    });
  });

  group('nothing else a member can call writes the row', () {
    test('the pack is raiseCap alone, and the catalog inserts or rewrites '
        'no orchestration', () {
      expect([for (final o in ops) o.name], ['orchestration.raiseCap']);
      final catalog = File(
        'lib/src/remote_rpc_catalog.dart',
      ).readAsStringSync();
      for (final name in ['orchestration.insert', 'orchestration.update']) {
        expect(catalog, isNot(contains("name: '$name'")), reason: name);
      }
    });

    test('a held run stays held and capped after every write a member can '
        'still make', () async {
      final engine = _Engine(runs);
      final gate = OrchestrationBudgetGate(
        orchestrations: orchestrations,
        runs: runs,
        messages: messages,
        eventBus: DomainEventBus(),
        engine: () => engine,
        now: () => _t0,
      );
      engine.gate = gate;
      expect(await gate.check(runs.byId['run-1']!), isNotNull, reason: 'held');
      // Another member, and an admin on a person's run, may not raise it.
      await expectLater(
        op().handler(ctx(9 * _usd, user: 'carol')),
        throwsA(isA<OrchestrationCapRefusedException>()),
      );
      await expectLater(
        op().handler(ctx(9 * _usd, user: 'root', role: WorkspaceRole.admin)),
        throwsA(isA<OrchestrationCapRefusedException>()),
      );
      // What the server's use cases write when a member approves, cancels
      // or edits (every column but the cap, from the row they read).
      final stored = (await orchestrations.getById(_ws, 'orch-1'))!;
      expect(
        await orchestrations.update(
          stored.copyWith(maxCostMicros: 0, errorMessage: 'edited'),
          read: stored,
        ),
        isTrue,
      );
      await _flush();
      final after = (await orchestrations.getById(_ws, 'orch-1'))!;
      expect(after.maxCostMicros, 5 * _usd);
      expect(after.pipelineRunId, 'run-1');
      expect(after.spaceId, 'space-1');
      expect(await gate.check(runs.byId['run-1']!), isNotNull);
      expect(engine.resumed, isEmpty);
      await gate.dispose();
    });

    test('the cap follows a proposed row, the approval writes the cap of '
        'the revision it read, and a stale write changes nothing', () async {
      await orchestrations.insert(
        _orchestration(
          id: 'orch-2',
          runId: null,
          status: OrchestrationStatus.proposed,
        ),
      );
      Future<Orchestration> row() async =>
          (await orchestrations.getById(_ws, 'orch-2'))!;
      final proposed = await row();
      // An agent's revision carries its budget.
      final revised = proposed.copyWith(revision: 2, maxCostMicros: 7 * _usd);
      expect(await orchestrations.update(revised, read: proposed), isTrue);
      expect((await row()).maxCostMicros, 7 * _usd);
      // An approval that read revision 2 while revision 3 (50 USD) landed:
      // refused, so no run executes revision 2 under a cap nobody approved.
      final shown = await row();
      final third = shown.copyWith(revision: 3, maxCostMicros: 50 * _usd);
      expect(await orchestrations.update(third, read: shown), isTrue);
      expect(
        await orchestrations.update(
          shown.copyWith(status: OrchestrationStatus.approved),
          read: shown,
        ),
        isFalse,
      );
      expect((await row()).status, OrchestrationStatus.proposed);
      // Approving revision 3 as read writes its cap with it.
      final r3 = await row();
      expect(
        await orchestrations.update(
          r3.copyWith(
            status: OrchestrationStatus.approved,
            approvedRevision: 3,
          ),
          read: r3,
        ),
        isTrue,
      );
      final approved = await row();
      expect(approved.status, OrchestrationStatus.approved);
      expect(approved.maxCostMicros, 50 * _usd);
      // A write computed from the proposed row before the approval: refused,
      // and the status, the cap and the plan stay the approved ones.
      expect(
        await orchestrations.update(
          proposed.copyWith(maxCostMicros: 1 * _usd),
          read: proposed,
        ),
        isFalse,
      );
      final after = await row();
      expect(after.status, OrchestrationStatus.approved);
      expect(after.revision, 3);
      expect(after.maxCostMicros, 50 * _usd);
    });

    test('a stale proposed write over an executing row leaves its status, '
        'run and cap', () async {
      final executing = (await orchestrations.getById(_ws, 'orch-1'))!;
      final stale = executing.copyWith(status: OrchestrationStatus.proposed);
      expect(
        await orchestrations.update(
          stale.copyWith(maxCostMicros: 50 * _usd),
          read: stale,
        ),
        isFalse,
      );
      final after = (await orchestrations.getById(_ws, 'orch-1'))!;
      expect(after.status, OrchestrationStatus.executing);
      expect(after.pipelineRunId, 'run-1');
      expect(after.maxCostMicros, 5 * _usd);
    });
  });

  test('the hold lifts once', () async {
    final engine = _Engine(runs);
    final gate = OrchestrationBudgetGate(
      orchestrations: orchestrations,
      runs: runs,
      messages: messages,
      eventBus: DomainEventBus(),
      engine: () => engine,
      now: () => _t0,
    );
    engine.gate = gate;
    expect(await gate.check(runs.byId['run-1']!), isNotNull, reason: 'held');
    await _flush();
    expect(engine.resumed, isEmpty, reason: 'still at the cap');
    await Future.wait([
      op().handler(ctx(7 * _usd)).then<Object?>((v) => v, onError: (_) => null),
      op().handler(ctx(9 * _usd)).then<Object?>((v) => v, onError: (_) => null),
    ]);
    await _flush();
    expect(engine.resumed, ['run-1']);
  });

  group('can_raise_cap', () {
    test('per viewer: the requester; an admin only on a bot run', () {
      expect(
        canRaiseOrchestrationCap(
          requester: 'ada',
          userId: 'ada',
          isAdmin: false,
        ),
        isTrue,
      );
      expect(
        canRaiseOrchestrationCap(
          requester: 'ada',
          userId: 'root',
          isAdmin: true,
        ),
        isFalse,
      );
      expect(
        canRaiseOrchestrationCap(
          requester: null,
          userId: 'root',
          isAdmin: true,
        ),
        isTrue,
      );
      expect(
        canRaiseOrchestrationCap(
          requester: null,
          userId: 'bob',
          isAdmin: false,
        ),
        isFalse,
      );
    });

    test('a held run carries it on the wire; a run that is not held does '
        'not', () {
      final held = pipelineRunToWireFor(ctx(null), _run());
      expect(held['can_raise_cap'], isTrue);
      expect(
        pipelineRunToWireFor(ctx(null, user: 'bob'), _run())['can_raise_cap'],
        isFalse,
      );
      expect(
        pipelineRunToWireFor(
          ctx(null, user: 'root', role: WorkspaceRole.admin),
          _run(requester: null),
        )['can_raise_cap'],
        isTrue,
      );
      final going = _run().copyWith(state: const {});
      expect(
        pipelineRunToWireFor(ctx(null), going),
        isNot(contains('can_raise_cap')),
      );
    });

    test('a watch frame gets it per frame, asking the role only for a held '
        'bot run', () async {
      final asked = <String>[];
      Future<bool> isAdminIn(String ws) async {
        asked.add(ws);
        return true;
      }

      Map<String, dynamic> wire(PipelineRun run) => {
        'workspace_id': run.workspaceId,
        'state': run.state,
        'trigger_payload': ?run.triggerPayload,
      };
      final person = await withCanRaiseCap(
        {'run': wire(_run())},
        userId: 'root',
        isAdminIn: isAdminIn,
      );
      expect((person['run'] as Map)['can_raise_cap'], isFalse);
      expect(asked, isEmpty);
      final list = await withCanRaiseCap(
        {
          'runs': [
            wire(_run(requester: null)),
            wire(_run(requester: null)),
            wire(_run().copyWith(state: const {})),
          ],
        },
        userId: 'root',
        isAdminIn: isAdminIn,
      );
      final runs = (list['runs'] as List).cast<Map<String, dynamic>>();
      expect(runs[0]['can_raise_cap'], isTrue);
      expect(runs[1]['can_raise_cap'], isTrue);
      expect(runs[2], isNot(contains('can_raise_cap')));
      expect(asked, [_ws], reason: 'once per workspace per frame');
    });
  });
}
