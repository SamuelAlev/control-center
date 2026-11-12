import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Future<void> _seedAgent(WorkspaceDatabase db, String id, String workspaceId) =>
    db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: id,
            name: 'agent-$id',
            title: 'Agent $id',
            agentMdPath: '/agents/$id.md',
            workspaceId: workspaceId,
            skills: 'dart',
          ),
        );

Future<void> _seedRun(
  WorkspaceDatabase db,
  String id, {
  required String workspaceId,
  String agentId = 'agent-1',
}) => db
    .into(db.agentRunLogsTable)
    .insert(
      AgentRunLogsTableCompanion.insert(
        id: id,
        agentId: agentId,
        workspaceId: workspaceId,
        startedAt: Value(DateTime.utc(2026, 7, 26)),
        status: const Value('running'),
      ),
    );

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// `ws-1`'s own database file — the workspace under test. `ws-2` gets a
  /// separate file, which is what the isolation group now leans on.
  late WorkspaceDatabase db;
  late DaoRunTranscriptRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    db = dbs.of('ws-1');
    repo = DaoRunTranscriptRepository(dbs);
    await _seedAgent(db, 'agent-1', 'ws-1');
    await _seedRun(db, 'run-1', workspaceId: 'ws-1');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  final segments = <TranscriptSegment>[
    TextSegment(text: 'planning', startedAt: DateTime.utc(2026, 7, 26)),
    ToolSegment(
      toolName: 'Read',
      toolCallId: 'call-1',
      outputs: 'file body',
      status: ToolSegmentStatus.ok,
      startedAt: DateTime.utc(2026, 7, 26, 0, 0, 1),
      durationMs: 12,
    ),
  ];

  List<Map<String, dynamic>> json(List<TranscriptSegment> list) => [
    for (final segment in list) segment.toJson(),
  ];

  Map<int, Map<String, dynamic>> all(List<TranscriptSegment> list) => {
    for (var i = 0; i < list.length; i++) i: list[i].toJson(),
  };

  Future<void> writeRun1({
    bool complete = true,
    TurnOutcome? outcome = TurnOutcome.completed,
    DateTime? updatedAt,
  }) => repo.write(
    runId: 'run-1',
    workspaceId: 'ws-1',
    changedSegments: all(segments),
    segmentCount: segments.length,
    transcriptChars: 42,
    startedAt: DateTime.utc(2026, 7, 26),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 26, 0, 1),
    outcome: outcome,
    complete: complete,
  );

  Future<int> segmentRows() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM transcript_segments')
              .getSingle())
          .read<int>('n');

  group('round trip', () {
    test('persists and decodes the ordered transcript', () async {
      await writeRun1();

      final read = await repo.getForRun('ws-1', 'run-1');

      expect(read, isNotNull);
      expect(read!.runId, 'run-1');
      expect(read.workspaceId, 'ws-1');
      expect(read.transcriptChars, 42);
      expect(read.outcome, TurnOutcome.completed);
      expect(read.complete, isTrue);
      expect(json(read.segments), json(segments));
      expect(await segmentRows(), 2);
    });

    test('returns null for a run with no recorded transcript', () async {
      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
    });

    test('an unfinished recording reads back complete: false', () async {
      await writeRun1(complete: false, outcome: null);

      final read = await repo.getForRun('ws-1', 'run-1');

      expect(read!.complete, isFalse);
      expect(read.outcome, isNull);
    });

    test('a flush writes the segments it names and keeps the others', () async {
      await writeRun1(complete: false, outcome: null);
      final finished = (segments[1] as ToolSegment).copyWith(
        outputs: 'longer body',
      );
      final appended = TextSegment(
        text: 'done',
        startedAt: DateTime.utc(2026, 7, 26, 0, 0, 2),
      );
      await repo.write(
        runId: 'run-1',
        workspaceId: 'ws-1',
        changedSegments: {1: finished.toJson(), 2: appended.toJson()},
        segmentCount: 3,
        transcriptChars: 50,
        startedAt: DateTime.utc(2026, 7, 26),
        updatedAt: DateTime.utc(2026, 7, 26, 0, 2),
        outcome: TurnOutcome.failed,
        complete: true,
      );

      final read = await repo.getForRun('ws-1', 'run-1');

      expect(json(read!.segments), json([segments[0], finished, appended]));
      expect(read.transcriptChars, 50);
      expect(read.outcome, TurnOutcome.failed);
      expect(read.complete, isTrue);
    });

    test('the schema refuses a segment that is not a JSON object', () async {
      await writeRun1();
      final transcript = await db.runTranscriptDao.getForRun('run-1');

      await expectLater(
        db.customStatement(
          'INSERT INTO transcript_segments (transcript_id, seq, body) '
          "VALUES (${transcript!.id}, 9, '[1]')",
        ),
        throwsA(anything),
      );
    });

    test('the schema refuses a transcript with no owner', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO transcripts (segment_count) VALUES (0)',
        ),
        throwsA(anything),
      );
    });
  });

  group('workspace isolation', () {
    test('a foreign workspace cannot read the transcript', () async {
      await writeRun1();

      expect(await repo.getForRun('ws-2', 'run-1'), isNull);
    });

    test('a foreign workspace cannot delete the transcript', () async {
      await writeRun1();

      expect(await repo.deleteForRun('ws-2', 'run-1'), 0);
      expect(await repo.getForRun('ws-1', 'run-1'), isNotNull);
    });

    test('the owning workspace can delete the transcript', () async {
      await writeRun1();

      expect(await repo.deleteForRun('ws-1', 'run-1'), 1);
      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
      expect(await segmentRows(), 0);
    });
  });

  group('lifecycle', () {
    test('deleting the run log cascades its transcript and segments', () async {
      await writeRun1();

      await db.customStatement("DELETE FROM agent_run_logs WHERE id = 'run-1'");

      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
      expect(await segmentRows(), 0);
    });

    test('pruneCompletedBefore drops finalized rows past the cutoff', () async {
      await writeRun1(updatedAt: DateTime.utc(2026, 1, 1));

      final pruned = await RunTranscriptDao(
        db,
      ).pruneCompletedBefore(DateTime.utc(2026, 6, 1));

      expect(pruned, 1);
      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
      expect(await segmentRows(), 0);
    });

    test('pruneCompletedBefore spares an unfinished recording', () async {
      await writeRun1(
        complete: false,
        outcome: null,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final pruned = await RunTranscriptDao(
        db,
      ).pruneCompletedBefore(DateTime.utc(2026, 6, 1));

      expect(pruned, 0);
      expect(await repo.getForRun('ws-1', 'run-1'), isNotNull);
    });

    test('the sweep reads only its partial index', () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${RunTranscriptDao.pruneSql}',
            variables: [Variable<DateTime>(DateTime.utc(2026))],
          )
          .get();

      expect(
        plan.map((r) => r.data.values.join(' ')).join('\n'),
        contains('idx_transcripts_run_sweep'),
      );
    });
  });
}
