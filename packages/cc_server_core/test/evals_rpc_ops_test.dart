import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException;
import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/services/eval_runner.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/evals/evals_rpc_ops.dart';
import 'package:test/test.dart';

/// Map-backed [EvalsRepository] fake. Only the members the eval ops touch carry
/// real behaviour; the rest forward to [noSuchMethod] and throw.
class _FakeEvalsRepository implements EvalsRepository {
  final Map<String, EvalSuite> suitesByWsId = {};
  final Map<String, EvalRun> runsByWsId = {};
  final Map<String, SessionRecording> recordingsByWsId = {};
  final Map<String, GoldenSession> goldensByWsId = {};
  final Map<String, AgentConfigVersion> versionsByWsId = {};
  bool deletedSuite = false;
  bool deletedGolden = false;

  String _suiteKey(String ws, String id) => '$ws:$id';

  @override
  Future<List<EvalSuite>> suites(String workspaceId) async =>
      suitesByWsId.values.where((s) => s.workspaceId == workspaceId).toList();

  @override
  Future<EvalSuite?> suiteById(String workspaceId, String id) async =>
      suitesByWsId[_suiteKey(workspaceId, id)];

  @override
  Future<void> upsertSuite(EvalSuite suite) async {
    suitesByWsId[_suiteKey(suite.workspaceId, suite.id)] = suite;
  }

  @override
  Future<void> deleteSuite(String workspaceId, String id) async {
    suitesByWsId.remove(_suiteKey(workspaceId, id));
    deletedSuite = true;
  }

  @override
  Future<List<EvalRun>> runsForSuite(
    String workspaceId,
    String suiteId, {
    int limit = 50,
  }) async => runsByWsId.values
      .where((r) => r.workspaceId == workspaceId && r.suiteId == suiteId)
      .toList();

  @override
  Future<List<SessionRecording>> recordings(
    String workspaceId, {
    String? agentId,
    int limit = 50,
  }) async => recordingsByWsId.values.where((r) {
    if (r.workspaceId != workspaceId) {
      return false;
    }
    if (agentId != null && r.agentId != agentId) {
      return false;
    }
    return true;
  }).toList();

  @override
  Future<List<GoldenSession>> goldens(String workspaceId) async =>
      goldensByWsId.values.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Future<List<GoldenSession>> goldensForAgent(
    String workspaceId,
    String agentId,
  ) async => goldensByWsId.values
      .where((g) => g.workspaceId == workspaceId && g.agentId == agentId)
      .toList();

  @override
  Future<void> upsertGolden(GoldenSession golden) async {
    goldensByWsId[_suiteKey(golden.workspaceId, golden.id)] = golden;
  }

  @override
  Future<void> deleteGolden(String workspaceId, String id) async {
    goldensByWsId.remove(_suiteKey(workspaceId, id));
    deletedGolden = true;
  }

  @override
  Future<List<AgentConfigVersion>> configVersionsForAgent(
    String workspaceId,
    String agentId,
  ) async => versionsByWsId.values
      .where((v) => v.workspaceId == workspaceId && v.agentId == agentId)
      .toList();

  @override
  Stream<List<EvalSuite>> watchSuites(String workspaceId) => Stream.value(
    suitesByWsId.values.where((s) => s.workspaceId == workspaceId).toList(),
  );

  @override
  Stream<List<EvalRun>> watchRunsForSuite(String workspaceId, String suiteId) =>
      Stream.value(
        runsByWsId.values
            .where((r) => r.workspaceId == workspaceId && r.suiteId == suiteId)
            .toList(),
      );

  @override
  Stream<List<SessionRecording>> watchRecordings(String workspaceId) =>
      Stream.value(
        recordingsByWsId.values
            .where((r) => r.workspaceId == workspaceId)
            .toList(),
      );

  @override
  Stream<List<GoldenSession>> watchGoldens(String workspaceId) => Stream.value(
    goldensByWsId.values.where((g) => g.workspaceId == workspaceId).toList(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A no-op [EvalRunner] that records its invocation and returns a fixed
/// scorecard. Constructed via a factory so it can be injected as the
/// `runnerFactory` argument.
class _RecordingEvalRunner implements EvalRunner {
  _RecordingEvalRunner(this._scorecard);

  final EvalScorecard _scorecard;
  bool runCalled = false;
  EvalSuite? lastSuite;
  String? lastConfigHash;
  int? lastBatchSize;
  String? lastTriggeredBy;

  @override
  Future<EvalScorecard> runSuite({
    required EvalSuite suite,
    required String configHash,
    int? batchSize,
    String triggeredBy = 'manual',
    String? runId,
    String? jobId,
  }) async {
    runCalled = true;
    lastSuite = suite;
    lastConfigHash = configHash;
    lastBatchSize = batchSize;
    lastTriggeredBy = triggeredBy;
    return _scorecard;
  }
}

RepoOpContext _ctx(
  Map<String, dynamic> args, {
  String workspaceId = 'ws-1',
  String userId = 'user-1',
}) => RepoOpContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: 'device-1',
  userId: userId,
);

WatchQueryContext _watchCtx(
  Map<String, dynamic> args, {
  String workspaceId = 'ws-1',
}) => WatchQueryContext(
  args: args,
  workspaceId: workspaceId,
  deviceId: 'device-1',
  userId: 'user-1',
);

EvalSuite _suite({
  String id = 's-1',
  String workspaceId = 'ws-1',
  String name = 'starter',
  DateTime? createdAt,
}) => EvalSuite(
  id: id,
  workspaceId: workspaceId,
  name: name,
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  updatedAt: createdAt ?? DateTime.utc(2026, 1, 1),
);

const _greenScorecard = EvalScorecard(
  batchSize: 4,
  passRate: 0.75,
  passRateStdDev: 0.1,
  avgCostCents: 12,
  costStdDev: 1,
  avgTurns: 3,
  avgDurationMs: 1500,
  perGraderPassRate: {'outcome_success': 0.75},
  repsPassed: 3,
);

void main() {
  group('eval wire mappers', () {
    test('evalSuiteToWire, evalRunToWire serialize every field', () {
      final wire = evalSuiteToWire(
        EvalSuite(
          id: 's-1',
          workspaceId: 'ws-1',
          name: 'suite',
          description: 'd',
          taskJson: '{}',
          gradersJson: '[]',
          fixtureRef: 'fx',
          fixtureSha: 'sha',
          defaultBatchSize: 2,
          isStarter: true,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(wire['id'], 's-1');
      expect(wire['name'], 'suite');
      expect(wire['description'], 'd');
      expect(wire['taskJson'], '{}');
      expect(wire['gradersJson'], '[]');
      expect(wire['fixtureRef'], 'fx');
      expect(wire['fixtureSha'], 'sha');
      expect(wire['defaultBatchSize'], 2);
      expect(wire['isStarter'], isTrue);
      expect(wire['createdAt'], contains('2026-01-01'));
      expect(wire['updatedAt'], contains('2026-01-02'));

      final runWire = evalRunToWire(
        EvalRun(
          id: 'r-1',
          workspaceId: 'ws-1',
          suiteId: 's-1',
          configHash: 'hash',
          batchSize: 3,
          scorecardJson: '{}',
          passRate: 0.5,
          status: 'done',
          costCents: 9,
          triggeredBy: 'ci',
          jobId: 'j-1',
          createdAt: DateTime.utc(2026, 1, 1),
          startedAt: DateTime.utc(2026, 1, 2),
          finishedAt: DateTime.utc(2026, 1, 3),
        ),
      );
      expect(runWire['id'], 'r-1');
      expect(runWire['suiteId'], 's-1');
      expect(runWire['configHash'], 'hash');
      expect(runWire['batchSize'], 3);
      expect(runWire['scorecardJson'], '{}');
      expect(runWire['passRate'], 0.5);
      expect(runWire['status'], 'done');
      expect(runWire['costCents'], 9);
      expect(runWire['triggeredBy'], 'ci');
      expect(runWire['jobId'], 'j-1');
      expect(runWire['startedAt'], contains('2026-01-02'));
      expect(runWire['finishedAt'], contains('2026-01-03'));
    });

    test(
      'recordingToWire, goldenToWire, configVersionToWire serialize fields',
      () {
        final recWire = recordingToWire(
          SessionRecording(
            id: 'rec-1',
            workspaceId: 'ws-1',
            runLogId: 'log-1',
            agentId: 'a-1',
            conversationId: 'c-1',
            configHash: 'hash',
            hashVersion: 2,
            eventCount: 7,
            title: 'T',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
        expect(recWire['id'], 'rec-1');
        expect(recWire['runLogId'], 'log-1');
        expect(recWire['agentId'], 'a-1');
        expect(recWire['conversationId'], 'c-1');
        expect(recWire['configHash'], 'hash');
        expect(recWire['hashVersion'], 2);
        expect(recWire['eventCount'], 7);
        expect(recWire['title'], 'T');

        final goldWire = goldenToWire(
          GoldenSession(
            id: 'g-1',
            workspaceId: 'ws-1',
            agentId: 'a-1',
            recordingId: 'rec-1',
            mode: 'live',
            name: 'golden',
            enabled: false,
            lastStatus: 'failed',
            lastScorecardJson: '{}',
            blessedBy: 'user-1',
            blessedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        expect(goldWire['id'], 'g-1');
        expect(goldWire['agentId'], 'a-1');
        expect(goldWire['recordingId'], 'rec-1');
        expect(goldWire['mode'], 'live');
        expect(goldWire['name'], 'golden');
        expect(goldWire['enabled'], isFalse);
        expect(goldWire['lastStatus'], 'failed');
        expect(goldWire['lastScorecardJson'], '{}');
        expect(goldWire['blessedBy'], 'user-1');

        final vWire = configVersionToWire(
          AgentConfigVersion(
            id: 'v-1',
            workspaceId: 'ws-1',
            agentId: 'a-1',
            configHash: 'hash',
            hashVersion: 1,
            status: 'live',
            scorecardJson: '{}',
            promotedBy: 'user-1',
            promotedAt: DateTime.utc(2026, 1, 2),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
        expect(vWire['id'], 'v-1');
        expect(vWire['agentId'], 'a-1');
        expect(vWire['configHash'], 'hash');
        expect(vWire['hashVersion'], 1);
        expect(vWire['status'], 'live');
        expect(vWire['scorecardJson'], '{}');
        expect(vWire['promotedBy'], 'user-1');
        expect(vWire['promotedAt'], contains('2026-01-02'));
      },
    );
  });

  group('buildEvalsOps', () {
    late _FakeEvalsRepository repo;

    setUp(() {
      repo = _FakeEvalsRepository();
    });

    RepoOp op(List<RepoOp> ops, String name) =>
        ops.firstWhere((o) => o.name == name);

    test('the catalog declares every eval op', () {
      final ops = buildEvalsOps(repository: repo);
      expect(
        ops.map((o) => o.name),
        containsAll([
          'evals.upsertSuite',
          'evals.deleteSuite',
          'evals.runSuite',
          'evals.blessGolden',
          'evals.reliability',
        ]),
      );
    });

    group('evals.upsertSuite', () {
      test(
        'creates a new suite, encoding the task/graders maps to JSON',
        () async {
          final ops = buildEvalsOps(repository: repo);
          final result = await op(ops, 'evals.upsertSuite').handler(
            _ctx({
              'workspace_id': 'ws-1',
              'name': 'My suite',
              'description': 'desc',
              'task': {'kind': 'x'},
              'graders': [
                {'type': 'y'},
              ],
              'fixture_ref': 'fx',
              'default_batch_size': 3,
            }),
          );
          final id = result['id'] as String;
          final saved = await repo.suiteById('ws-1', id);
          expect(saved, isNotNull);
          expect(saved!.name, 'My suite');
          expect(saved.description, 'desc');
          expect(saved.taskJson, '{"kind":"x"}');
          expect(saved.gradersJson, '[{"type":"y"}]');
          expect(saved.fixtureRef, 'fx');
          expect(saved.defaultBatchSize, 3);
        },
      );

      test('preserves the createdAt of an existing suite', () async {
        final created = DateTime.utc(2025, 6, 1);
        repo.suitesByWsId['ws-1:fixed'] = _suite(
          id: 'fixed',
          createdAt: created,
        );
        final ops = buildEvalsOps(repository: repo);
        await op(ops, 'evals.upsertSuite').handler(
          _ctx({'workspace_id': 'ws-1', 'id': 'fixed', 'name': 'renamed'}),
        );
        final saved = await repo.suiteById('ws-1', 'fixed');
        expect(saved!.createdAt, created);
        expect(saved.name, 'renamed');
      });

      test('accepts task/graders as raw JSON strings', () async {
        final ops = buildEvalsOps(repository: repo);
        final id = await op(ops, 'evals.upsertSuite').handler(
          _ctx({
            'workspace_id': 'ws-1',
            'name': 's',
            'task': '{"k":1}',
            'graders': '[]',
          }),
        );
        final saved = await repo.suiteById('ws-1', id['id'] as String);
        expect(saved!.taskJson, '{"k":1}');
        expect(saved.gradersJson, '[]');
      });

      test('defaults empty task/graders to {}/[]', () async {
        final ops = buildEvalsOps(repository: repo);
        final id = await op(
          ops,
          'evals.upsertSuite',
        ).handler(_ctx({'workspace_id': 'ws-1', 'name': 's'}));
        final saved = await repo.suiteById('ws-1', id['id'] as String);
        expect(saved!.taskJson, '{}');
        expect(saved.gradersJson, '[]');
        expect(saved.defaultBatchSize, 1);
      });
    });

    test('evals.deleteSuite removes the suite', () async {
      repo.suitesByWsId['ws-1:s-1'] = _suite();
      final result = await op(
        buildEvalsOps(repository: repo),
        'evals.deleteSuite',
      ).handler(_ctx({'workspace_id': 'ws-1', 'suite_id': 's-1'}));
      expect(result['ok'], isTrue);
      expect(repo.deletedSuite, isTrue);
      expect(repo.suitesByWsId, isEmpty);
    });

    group('evals.runSuite', () {
      test('throws NotFoundException when the suite is missing', () async {
        final ops = buildEvalsOps(repository: repo);
        await expectLater(
          op(
            ops,
            'evals.runSuite',
          ).handler(_ctx({'workspace_id': 'ws-1', 'suite_id': 'missing'})),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('throws ValidationException when no runner is wired', () async {
        repo.suitesByWsId['ws-1:s-1'] = _suite();
        final ops = buildEvalsOps(repository: repo);
        await expectLater(
          op(
            ops,
            'evals.runSuite',
          ).handler(_ctx({'workspace_id': 'ws-1', 'suite_id': 's-1'})),
          throwsA(isA<ValidationException>()),
        );
      });

      test(
        'runs the suite via the injected runner and returns the scorecard',
        () async {
          repo.suitesByWsId['ws-1:s-1'] = _suite();
          late final _RecordingEvalRunner runner;
          final ops = buildEvalsOps(
            repository: repo,
            runnerFactory: () {
              runner = _RecordingEvalRunner(_greenScorecard);
              return runner;
            },
          );
          final result = await op(ops, 'evals.runSuite').handler(
            _ctx({
              'workspace_id': 'ws-1',
              'suite_id': 's-1',
              'config_hash': 'config-7',
              'batch_size': 4,
              'triggered_by': 'ci',
            }),
          );
          final scorecard = result['scorecard'] as Map;
          expect(scorecard['batchSize'], 4);
          expect(runner.runCalled, isTrue);
          expect(runner.lastSuite!.id, 's-1');
          expect(runner.lastConfigHash, 'config-7');
          expect(runner.lastBatchSize, 4);
          expect(runner.lastTriggeredBy, 'ci');
        },
      );

      test('defaults config_hash and triggered_by when omitted', () async {
        repo.suitesByWsId['ws-1:s-1'] = _suite();
        late final _RecordingEvalRunner runner;
        final ops = buildEvalsOps(
          repository: repo,
          runnerFactory: () {
            runner = _RecordingEvalRunner(_greenScorecard);
            return runner;
          },
        );
        await op(
          ops,
          'evals.runSuite',
        ).handler(_ctx({'workspace_id': 'ws-1', 'suite_id': 's-1'}));
        expect(runner.lastConfigHash, 'live');
        expect(runner.lastTriggeredBy, 'manual');
        expect(runner.lastBatchSize, isNull);
      });
    });

    test(
      'evals.blessGolden inserts a golden blessed by the calling user',
      () async {
        final result =
            await op(
              buildEvalsOps(repository: repo),
              'evals.blessGolden',
            ).handler(
              _ctx({
                'workspace_id': 'ws-1',
                'agent_id': 'a-1',
                'recording_id': 'rec-1',
                'mode': 'live',
                'name': 'my-golden',
              }, userId: 'user-7'),
            );
        final id = result['id'] as String;
        final saved = repo.goldensByWsId['ws-1:$id']!;
        expect(saved.agentId, 'a-1');
        expect(saved.recordingId, 'rec-1');
        expect(saved.mode, 'live');
        expect(saved.name, 'my-golden');
        expect(saved.blessedBy, 'user-7');
      },
    );

    test('evals.blessGolden defaults mode/name when omitted', () async {
      await op(buildEvalsOps(repository: repo), 'evals.blessGolden').handler(
        _ctx({
          'workspace_id': 'ws-1',
          'agent_id': 'a-1',
          'recording_id': 'rec-1',
        }),
      );
      final saved = repo.goldensByWsId.values.single;
      expect(saved.mode, 'deterministic');
      expect(saved.name, '');
    });

    group('evals.reliability', () {
      test(
        'weights the pass rate over graded config-version scorecards',
        () async {
          // Two versions: one with a green scorecard (3/4 pass), one without.
          repo.versionsByWsId['ws-1:v-1'] = AgentConfigVersion(
            id: 'v-1',
            workspaceId: 'ws-1',
            agentId: 'a-1',
            configHash: 'h1',
            createdAt: DateTime.utc(2026, 1, 1),
            scorecardJson: _greenScorecard.toJsonString(),
          );
          repo.versionsByWsId['ws-1:v-2'] = AgentConfigVersion(
            id: 'v-2',
            workspaceId: 'ws-1',
            agentId: 'a-1',
            configHash: 'h2',
            createdAt: DateTime.utc(2026, 1, 1),
          );
          final result = await op(
            buildEvalsOps(repository: repo),
            'evals.reliability',
          ).handler(_ctx({'workspace_id': 'ws-1', 'agent_id': 'a-1'}));
          final reliability = result['reliability'] as Map;
          // Only the graded version contributes (4 runs, 0.75 pass-rate).
          expect(reliability['score'], 0.75);
          expect(reliability['recommended'], isA<String>());
          expect(reliability['rationale'], isA<List>());
        },
      );

      test('skips unparseable scorecards and reports no evidence', () async {
        repo.versionsByWsId['ws-1:v-1'] = AgentConfigVersion(
          id: 'v-1',
          workspaceId: 'ws-1',
          agentId: 'a-1',
          configHash: 'h1',
          createdAt: DateTime.utc(2026, 1, 1),
          scorecardJson: 'not-json',
        );
        repo.versionsByWsId['ws-1:v-2'] = AgentConfigVersion(
          id: 'v-2',
          workspaceId: 'ws-1',
          agentId: 'a-1',
          configHash: 'h2',
          createdAt: DateTime.utc(2026, 1, 1),
          scorecardJson: '',
        );
        final result = await op(
          buildEvalsOps(repository: repo),
          'evals.reliability',
        ).handler(_ctx({'workspace_id': 'ws-1', 'agent_id': 'a-1'}));
        final reliability = result['reliability'] as Map;
        expect(reliability['score'], 0.0);
      });
    });
  });

  group('buildEvalsWatchQueries', () {
    late _FakeEvalsRepository repo;

    setUp(() {
      repo = _FakeEvalsRepository();
    });

    WatchQuery query(List<WatchQuery> q, String name) =>
        q.firstWhere((e) => e.name == name);

    test('evals.watchSuites emits a suites snapshot', () async {
      repo.suitesByWsId['ws-1:s-1'] = _suite();
      final snapshot = await query(
        buildEvalsWatchQueries(repository: repo),
        'evals.watchSuites',
      ).handler(_watchCtx({})).first;
      expect(snapshot['suites'] as List, hasLength(1));
    });

    test('evals.watchRunsForSuite emits a runs snapshot', () async {
      repo.runsByWsId['ws-1:r-1'] = EvalRun(
        id: 'r-1',
        workspaceId: 'ws-1',
        suiteId: 's-1',
        configHash: 'h',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final snapshot = await query(
        buildEvalsWatchQueries(repository: repo),
        'evals.watchRunsForSuite',
      ).handler(_watchCtx({'suite_id': 's-1'})).first;
      expect(snapshot['runs'] as List, hasLength(1));
    });

    test('evals.watchRunsForSuite defaults to an empty suite id', () async {
      final snapshot = await query(
        buildEvalsWatchQueries(repository: repo),
        'evals.watchRunsForSuite',
      ).handler(_watchCtx({})).first;
      expect(snapshot['runs'] as List, isEmpty);
    });
  });
}
