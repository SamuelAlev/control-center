import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
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
        workspaceId: Value(workspaceId),
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

  Future<void> writeRun1({
    bool complete = true,
    TurnOutcome? outcome = TurnOutcome.completed,
    DateTime? updatedAt,
  }) => repo.upsert(
    runId: 'run-1',
    workspaceId: 'ws-1',
    segmentsJson: encodeTranscript(segments),
    transcriptChars: 42,
    startedAt: DateTime.utc(2026, 7, 26),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 26, 0, 1),
    outcome: outcome,
    complete: complete,
  );

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
      expect(read.segments, hasLength(2));
      expect((read.segments[0] as TextSegment).text, 'planning');
      final tool = read.segments[1] as ToolSegment;
      expect(tool.toolName, 'Read');
      expect(tool.toolCallId, 'call-1');
      expect(tool.status, ToolSegmentStatus.ok);
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

    test('upsert replaces the prior snapshot rather than appending', () async {
      await writeRun1(complete: false, outcome: null);
      await repo.upsert(
        runId: 'run-1',
        workspaceId: 'ws-1',
        segmentsJson: encodeTranscript([segments.first]),
        transcriptChars: 8,
        startedAt: DateTime.utc(2026, 7, 26),
        updatedAt: DateTime.utc(2026, 7, 26, 0, 2),
        outcome: TurnOutcome.failed,
        complete: true,
      );

      final read = await repo.getForRun('ws-1', 'run-1');

      expect(read!.segments, hasLength(1));
      expect(read.transcriptChars, 8);
      expect(read.outcome, TurnOutcome.failed);
      expect(read.complete, isTrue);
    });

    test('a malformed blob degrades to an empty transcript', () async {
      await db
          .into(db.runTranscriptsTable)
          .insert(
            RunTranscriptsTableCompanion.insert(
              runId: 'run-1',
              workspaceId: 'ws-1',
              segmentsJson: const Value('{not json'),
            ),
          );

      final read = await repo.getForRun('ws-1', 'run-1');

      expect(read, isNotNull);
      expect(read!.segments, isEmpty);
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
    });
  });

  group('lifecycle', () {
    test('deleting the run log cascades its transcript', () async {
      await writeRun1();

      await db.customStatement(
        "DELETE FROM agent_run_logs WHERE id = 'run-1'",
      );

      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
    });

    test('pruneCompletedBefore drops finalized rows past the cutoff', () async {
      await writeRun1(updatedAt: DateTime.utc(2026, 1, 1));

      final pruned = await RunTranscriptDao(
        db,
      ).pruneCompletedBefore(DateTime.utc(2026, 6, 1));

      expect(pruned, 1);
      expect(await repo.getForRun('ws-1', 'run-1'), isNull);
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
  });
}
