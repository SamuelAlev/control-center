import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/evals_mapper.dart';
import 'package:test/test.dart';

/// Unit tests for [EvalsMapper] — the bidirectional row↔entity mapping for the
/// five PRD 21 eval tables. The round-trip (toCompanion → fromRow via a rebuilt
/// entity) is the load-bearing assertion: a field the mapper forgets would
/// silently reset on persist.
void main() {
  const mapper = EvalsMapper();

  group('EvalsMapper session recordings', () {
    final createdAt = DateTime.utc(2026, 7, 1, 9);

    final row = SessionRecordingsTableData(
      id: 'rec-1',
      workspaceId: 'ws-1',
      runLogId: 'log-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      configHash: 'hash-1',
      hashVersion: 2,
      eventsRef: 'events://ref',
      cassetteRef: 'cassette://ref',
      fixtureRef: 'fixture://ref',
      eventCount: 42,
      title: 'First recording',
      createdAt: createdAt,
    );

    test('recordingFromRow maps every field verbatim', () {
      final r = mapper.recordingFromRow(row);
      expect(r.id, 'rec-1');
      expect(r.workspaceId, 'ws-1');
      expect(r.runLogId, 'log-1');
      expect(r.agentId, 'agent-1');
      expect(r.conversationId, 'conv-1');
      expect(r.configHash, 'hash-1');
      expect(r.hashVersion, 2);
      expect(r.eventsRef, 'events://ref');
      expect(r.cassetteRef, 'cassette://ref');
      expect(r.fixtureRef, 'fixture://ref');
      expect(r.eventCount, 42);
      expect(r.title, 'First recording');
      expect(r.createdAt, createdAt);
    });

    test('recordingFromRow tolerates null optional fields', () {
      final sparse = SessionRecordingsTableData(
        id: 'rec-2',
        workspaceId: 'ws-1',
        runLogId: 'log-2',
        configHash: 'hash-2',
        hashVersion: 1,
        eventCount: 0,
        title: '',
        createdAt: createdAt,
      );
      final r = mapper.recordingFromRow(sparse);
      expect(r.agentId, isNull);
      expect(r.conversationId, isNull);
      expect(r.eventsRef, isNull);
      expect(r.cassetteRef, isNull);
      expect(r.fixtureRef, isNull);
    });

    test('recordingToCompanion carries every field as a Value', () {
      final original = mapper.recordingFromRow(row);
      final c = mapper.recordingToCompanion(original);
      expect(c.id.value, 'rec-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.runLogId.value, 'log-1');
      expect(c.agentId.value, 'agent-1');
      expect(c.conversationId.value, 'conv-1');
      expect(c.configHash.value, 'hash-1');
      expect(c.hashVersion.value, 2);
      expect(c.eventsRef.value, 'events://ref');
      expect(c.cassetteRef.value, 'cassette://ref');
      expect(c.fixtureRef.value, 'fixture://ref');
      expect(c.eventCount.value, 42);
      expect(c.title.value, 'First recording');
      expect(c.createdAt.value, createdAt);
    });

    test('round-trip preserves every field', () {
      final original = mapper.recordingFromRow(row);
      final rebuilt = mapper.recordingToCompanion(original).toData();
      expect(rebuilt, row);
    });
  });

  group('EvalsMapper golden sessions', () {
    final blessedAt = DateTime.utc(2026, 6, 1, 10);

    final row = GoldenSessionsTableData(
      id: 'g-1',
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      recordingId: 'rec-1',
      mode: 'live',
      name: 'baseline',
      enabled: true,
      lastStatus: 'pass',
      lastScorecardJson: '{"score": 0.9}',
      blessedBy: 'sam',
      blessedAt: blessedAt,
    );

    test('goldenFromRow maps every field verbatim', () {
      final g = mapper.goldenFromRow(row);
      expect(g.id, 'g-1');
      expect(g.workspaceId, 'ws-1');
      expect(g.agentId, 'agent-1');
      expect(g.recordingId, 'rec-1');
      expect(g.mode, 'live');
      expect(g.name, 'baseline');
      expect(g.enabled, isTrue);
      expect(g.lastStatus, 'pass');
      expect(g.lastScorecardJson, '{"score": 0.9}');
      expect(g.blessedBy, 'sam');
      expect(g.blessedAt, blessedAt);
    });

    test('goldenFromRow tolerates null optional fields', () {
      final sparse = GoldenSessionsTableData(
        id: 'g-2',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        recordingId: 'rec-2',
        mode: 'deterministic',
        name: '',
        enabled: true,
        lastStatus: 'unknown',
        blessedAt: blessedAt,
      );
      final g = mapper.goldenFromRow(sparse);
      expect(g.lastScorecardJson, isNull);
      expect(g.blessedBy, isNull);
    });

    test('goldenToCompanion carries every field as a Value', () {
      final original = mapper.goldenFromRow(row);
      final c = mapper.goldenToCompanion(original);
      expect(c.id.value, 'g-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.agentId.value, 'agent-1');
      expect(c.recordingId.value, 'rec-1');
      expect(c.mode.value, 'live');
      expect(c.name.value, 'baseline');
      expect(c.enabled.value, isTrue);
      expect(c.lastStatus.value, 'pass');
      expect(c.lastScorecardJson.value, '{"score": 0.9}');
      expect(c.blessedBy.value, 'sam');
      expect(c.blessedAt.value, blessedAt);
    });

    test('round-trip preserves every field', () {
      final original = mapper.goldenFromRow(row);
      final rebuilt = mapper.goldenToCompanion(original).toData();
      expect(rebuilt, row);
    });
  });

  group('EvalsMapper eval suites', () {
    final createdAt = DateTime.utc(2026, 5, 1);
    final updatedAt = DateTime.utc(2026, 5, 2);

    final row = EvalSuitesTableData(
      id: 's-1',
      workspaceId: 'ws-1',
      name: 'regression',
      description: 'main suite',
      taskJson: '{"tasks": []}',
      fixtureRef: 'fixture://ref',
      fixtureSha: 'sha-abc',
      gradersJson: '[{"g": 1}]',
      defaultBatchSize: 4,
      isStarter: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('suiteFromRow maps every field verbatim', () {
      final s = mapper.suiteFromRow(row);
      expect(s.id, 's-1');
      expect(s.workspaceId, 'ws-1');
      expect(s.name, 'regression');
      expect(s.description, 'main suite');
      expect(s.taskJson, '{"tasks": []}');
      expect(s.fixtureRef, 'fixture://ref');
      expect(s.fixtureSha, 'sha-abc');
      expect(s.gradersJson, '[{"g": 1}]');
      expect(s.defaultBatchSize, 4);
      expect(s.isStarter, isTrue);
      expect(s.createdAt, createdAt);
      expect(s.updatedAt, updatedAt);
    });

    test('suiteFromRow tolerates null optional fields', () {
      final sparse = EvalSuitesTableData(
        id: 's-2',
        workspaceId: 'ws-1',
        name: 'bare',
        description: '',
        taskJson: '{}',
        gradersJson: '[]',
        defaultBatchSize: 1,
        isStarter: false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final s = mapper.suiteFromRow(sparse);
      expect(s.fixtureRef, isNull);
      expect(s.fixtureSha, isNull);
    });

    test('suiteToCompanion carries every field as a Value', () {
      final original = mapper.suiteFromRow(row);
      final c = mapper.suiteToCompanion(original);
      expect(c.id.value, 's-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.name.value, 'regression');
      expect(c.description.value, 'main suite');
      expect(c.taskJson.value, '{"tasks": []}');
      expect(c.fixtureRef.value, 'fixture://ref');
      expect(c.fixtureSha.value, 'sha-abc');
      expect(c.gradersJson.value, '[{"g": 1}]');
      expect(c.defaultBatchSize.value, 4);
      expect(c.isStarter.value, isTrue);
      expect(c.createdAt.value, createdAt);
      expect(c.updatedAt.value, updatedAt);
    });

    test('round-trip preserves every field', () {
      final original = mapper.suiteFromRow(row);
      final rebuilt = mapper.suiteToCompanion(original).toData();
      expect(rebuilt, row);
    });
  });

  group('EvalsMapper eval runs', () {
    final createdAt = DateTime.utc(2026, 4, 1);
    final startedAt = DateTime.utc(2026, 4, 1, 1);
    final finishedAt = DateTime.utc(2026, 4, 1, 2);

    final row = EvalRunsTableData(
      id: 'run-1',
      workspaceId: 'ws-1',
      suiteId: 's-1',
      configHash: 'hash-1',
      batchSize: 8,
      scorecardJson: '{"pass": 0.75}',
      passRate: 0.75,
      status: 'done',
      costCents: 100,
      triggeredBy: 'ci',
      jobId: 'job-1',
      createdAt: createdAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    test('runFromRow maps every field verbatim', () {
      final r = mapper.runFromRow(row);
      expect(r.id, 'run-1');
      expect(r.workspaceId, 'ws-1');
      expect(r.suiteId, 's-1');
      expect(r.configHash, 'hash-1');
      expect(r.batchSize, 8);
      expect(r.scorecardJson, '{"pass": 0.75}');
      expect(r.passRate, 0.75);
      expect(r.status, 'done');
      expect(r.costCents, 100);
      expect(r.triggeredBy, 'ci');
      expect(r.jobId, 'job-1');
      expect(r.createdAt, createdAt);
      expect(r.startedAt, startedAt);
      expect(r.finishedAt, finishedAt);
    });

    test('runFromRow tolerates null optional fields', () {
      final sparse = EvalRunsTableData(
        id: 'run-2',
        workspaceId: 'ws-1',
        suiteId: 's-1',
        configHash: 'hash-2',
        batchSize: 1,
        passRate: 0,
        status: 'queued',
        costCents: 0,
        triggeredBy: 'manual',
        createdAt: createdAt,
      );
      final r = mapper.runFromRow(sparse);
      expect(r.scorecardJson, isNull);
      expect(r.jobId, isNull);
      expect(r.startedAt, isNull);
      expect(r.finishedAt, isNull);
    });

    test('runToCompanion carries every field as a Value', () {
      final original = mapper.runFromRow(row);
      final c = mapper.runToCompanion(original);
      expect(c.id.value, 'run-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.suiteId.value, 's-1');
      expect(c.configHash.value, 'hash-1');
      expect(c.batchSize.value, 8);
      expect(c.scorecardJson.value, '{"pass": 0.75}');
      expect(c.passRate.value, 0.75);
      expect(c.status.value, 'done');
      expect(c.costCents.value, 100);
      expect(c.triggeredBy.value, 'ci');
      expect(c.jobId.value, 'job-1');
      expect(c.createdAt.value, createdAt);
      expect(c.startedAt.value, startedAt);
      expect(c.finishedAt.value, finishedAt);
    });

    test('round-trip preserves every field', () {
      final original = mapper.runFromRow(row);
      final rebuilt = mapper.runToCompanion(original).toData();
      expect(rebuilt, row);
    });
  });

  group('EvalsMapper agent config versions', () {
    final createdAt = DateTime.utc(2026, 3, 1);
    final promotedAt = DateTime.utc(2026, 3, 2);

    final row = AgentConfigVersionsTableData(
      id: 'v-1',
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      configHash: 'hash-1',
      hashVersion: 3,
      configJson: '{"model": "x"}',
      status: 'live',
      scorecardJson: '{"ok": true}',
      promotedBy: 'sam',
      promotedAt: promotedAt,
      createdAt: createdAt,
    );

    test('configVersionFromRow maps every field verbatim', () {
      final v = mapper.configVersionFromRow(row);
      expect(v.id, 'v-1');
      expect(v.workspaceId, 'ws-1');
      expect(v.agentId, 'agent-1');
      expect(v.configHash, 'hash-1');
      expect(v.hashVersion, 3);
      expect(v.configJson, '{"model": "x"}');
      expect(v.status, 'live');
      expect(v.scorecardJson, '{"ok": true}');
      expect(v.promotedBy, 'sam');
      expect(v.promotedAt, promotedAt);
      expect(v.createdAt, createdAt);
    });

    test('configVersionFromRow tolerates null optional fields', () {
      final sparse = AgentConfigVersionsTableData(
        id: 'v-2',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        configHash: 'hash-2',
        hashVersion: 1,
        configJson: '{}',
        status: 'live',
        createdAt: createdAt,
      );
      final v = mapper.configVersionFromRow(sparse);
      expect(v.scorecardJson, isNull);
      expect(v.promotedBy, isNull);
      expect(v.promotedAt, isNull);
    });

    test('configVersionToCompanion carries every field as a Value', () {
      final original = mapper.configVersionFromRow(row);
      final c = mapper.configVersionToCompanion(original);
      expect(c.id.value, 'v-1');
      expect(c.workspaceId.value, 'ws-1');
      expect(c.agentId.value, 'agent-1');
      expect(c.configHash.value, 'hash-1');
      expect(c.hashVersion.value, 3);
      expect(c.configJson.value, '{"model": "x"}');
      expect(c.status.value, 'live');
      expect(c.scorecardJson.value, '{"ok": true}');
      expect(c.promotedBy.value, 'sam');
      expect(c.promotedAt.value, promotedAt);
      expect(c.createdAt.value, createdAt);
    });

    test('round-trip preserves every field', () {
      final original = mapper.configVersionFromRow(row);
      final rebuilt = mapper.configVersionToCompanion(original).toData();
      expect(rebuilt, row);
    });
  });
}

/// Rebuilds a [SessionRecordingsTableData] from a companion (round-trip check).
extension on SessionRecordingsTableCompanion {
  SessionRecordingsTableData toData() => SessionRecordingsTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    runLogId: runLogId.value,
    agentId: agentId.present ? agentId.value : null,
    conversationId: conversationId.present ? conversationId.value : null,
    configHash: configHash.value,
    hashVersion: hashVersion.value,
    eventsRef: eventsRef.present ? eventsRef.value : null,
    cassetteRef: cassetteRef.present ? cassetteRef.value : null,
    fixtureRef: fixtureRef.present ? fixtureRef.value : null,
    eventCount: eventCount.value,
    title: title.value,
    createdAt: createdAt.value,
  );
}

/// Rebuilds a [GoldenSessionsTableData] from a companion (round-trip check).
extension on GoldenSessionsTableCompanion {
  GoldenSessionsTableData toData() => GoldenSessionsTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    agentId: agentId.value,
    recordingId: recordingId.value,
    mode: mode.value,
    name: name.value,
    enabled: enabled.value,
    lastStatus: lastStatus.value,
    lastScorecardJson: lastScorecardJson.present
        ? lastScorecardJson.value
        : null,
    blessedBy: blessedBy.present ? blessedBy.value : null,
    blessedAt: blessedAt.value,
  );
}

/// Rebuilds an [EvalSuitesTableData] from a companion (round-trip check).
extension on EvalSuitesTableCompanion {
  EvalSuitesTableData toData() => EvalSuitesTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    name: name.value,
    description: description.value,
    taskJson: taskJson.value,
    fixtureRef: fixtureRef.present ? fixtureRef.value : null,
    fixtureSha: fixtureSha.present ? fixtureSha.value : null,
    gradersJson: gradersJson.value,
    defaultBatchSize: defaultBatchSize.value,
    isStarter: isStarter.value,
    createdAt: createdAt.value,
    updatedAt: updatedAt.value,
  );
}

/// Rebuilds an [EvalRunsTableData] from a companion (round-trip check).
extension on EvalRunsTableCompanion {
  EvalRunsTableData toData() => EvalRunsTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    suiteId: suiteId.value,
    configHash: configHash.value,
    batchSize: batchSize.value,
    scorecardJson: scorecardJson.present ? scorecardJson.value : null,
    passRate: passRate.value,
    status: status.value,
    costCents: costCents.value,
    triggeredBy: triggeredBy.value,
    jobId: jobId.present ? jobId.value : null,
    createdAt: createdAt.value,
    startedAt: startedAt.present ? startedAt.value : null,
    finishedAt: finishedAt.present ? finishedAt.value : null,
  );
}

/// Rebuilds an [AgentConfigVersionsTableData] from a companion (round-trip).
extension on AgentConfigVersionsTableCompanion {
  AgentConfigVersionsTableData toData() => AgentConfigVersionsTableData(
    id: id.value,
    workspaceId: workspaceId.value,
    agentId: agentId.value,
    configHash: configHash.value,
    hashVersion: hashVersion.value,
    configJson: configJson.value,
    status: status.value,
    scorecardJson: scorecardJson.present ? scorecardJson.value : null,
    promotedBy: promotedBy.present ? promotedBy.value : null,
    promotedAt: promotedAt.present ? promotedAt.value : null,
    createdAt: createdAt.value,
  );
}
