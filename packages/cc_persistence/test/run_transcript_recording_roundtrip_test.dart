import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The write half of a subagent's activity, against a REAL database.
///
/// The recorder lives in cc_infra and cannot import Drift, so its unit tests run
/// against an in-memory fake. That leaves the actual storage contract — foreign
/// keys, the workspace scoping and re-reading after the run ends — untested,
/// which is precisely where "it streamed live but the tab is empty after a
/// reopen" hides.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// `ws-1`'s own database file — the workspace under test.
  late WorkspaceDatabase db;
  late DaoRunTranscriptRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    db = dbs.of('ws-1');
    repo = DaoRunTranscriptRepository(dbs);
    await db
        .into(db.agentsTable)
        .insert(
          AgentsTableCompanion.insert(
            id: 'agent-1',
            name: 'ceo',
            title: 'CEO',
            agentMdPath: '/agents/ceo.md',
            workspaceId: 'ws-1',
            skills: 'dart',
          ),
        );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> seedRun(String id, {String? parentRunId}) => db
      .into(db.agentRunLogsTable)
      .insert(
        AgentRunLogsTableCompanion.insert(
          id: id,
          agentId: 'agent-1',
          workspaceId: const Value('ws-1'),
          startedAt: Value(DateTime.utc(2026, 7, 26)),
          status: const Value('running'),
          agentRole: Value(parentRunId == null ? 'main' : 'sub'),
          parentRunId: Value(parentRunId),
        ),
      );

  final segments = <TranscriptSegment>[
    TextSegment(text: 'planning', startedAt: DateTime.utc(2026, 7, 26)),
    ToolSegment(
      toolName: 'Read',
      toolCallId: 'c1',
      outputs: 'file body',
      status: ToolSegmentStatus.ok,
      startedAt: DateTime.utc(2026, 7, 26),
    ),
  ];

  Future<void> record(
    String runId, {
    required bool complete,
    TurnOutcome? outcome,
  }) => repo.upsert(
    runId: runId,
    workspaceId: 'ws-1',
    segmentsJson: encodeTranscript(segments),
    transcriptChars: 20,
    startedAt: DateTime.utc(2026, 7, 26),
    updatedAt: DateTime.utc(2026, 7, 26, 0, 1),
    outcome: outcome,
    complete: complete,
  );

  test('a subagent run\'s transcript survives to a later read', () async {
    await seedRun('run-parent');
    await seedRun('run-child', parentRunId: 'run-parent');

    // Mid-run flush, then the finalizing write — the recorder's two shapes.
    await record('run-child', complete: false);
    await record('run-child', complete: true, outcome: TurnOutcome.completed);

    final read = await repo.getForRun('ws-1', 'run-child');

    expect(read, isNotNull, reason: 'reopening the tab must find the record');
    expect(read!.segments, hasLength(2));
    expect(read.complete, isTrue);
  });

  test('a mid-run flush before the run row exists FAILS loudly', () async {
    // The recorder opens its recording before the child run-log row is written.
    // If a flush ever beat that write, the foreign key would reject it — and a
    // swallowed failure is exactly the silent data loss to guard against.
    await expectLater(
      record('run-never-seeded', complete: false),
      throwsA(anything),
    );
  });

  test('a transcript for a run in another workspace is not readable', () async {
    await seedRun('run-child');
    await record('run-child', complete: true, outcome: TurnOutcome.completed);

    expect(await repo.getForRun('ws-2', 'run-child'), isNull);
    expect(await repo.getForRun('ws-1', 'run-child'), isNotNull);
  });

  test(
    'deleting the parent run does not orphan-delete the child transcript',
    () async {
      await seedRun('run-parent');
      await seedRun('run-child', parentRunId: 'run-parent');
      await record('run-child', complete: true, outcome: TurnOutcome.completed);

      // `parentRunId` is a plain column, not an FK, so the child row (and its
      // transcript) outlives the parent.
      await db.customStatement(
        "DELETE FROM agent_run_logs_table WHERE id = 'run-parent'",
      );

      expect(await repo.getForRun('ws-1', 'run-child'), isNotNull);
    },
  );
}
