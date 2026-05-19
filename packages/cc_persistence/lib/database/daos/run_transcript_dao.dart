import 'package:cc_persistence/database/tables/run_transcripts_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'run_transcript_dao.g.dart';

/// Data access for per-run activity transcripts. Every read and mutation
/// filters by BOTH `workspaceId` and `runId` — a run id is a UUID, but an
/// id-only query is still not an isolation boundary, so a foreign run must
/// simply not be found.
///
/// Deliberately offers no `watchForRun`: a Drift watch here would re-ship the
/// whole (potentially multi-hundred-KB) segment blob on every mid-run flush.
/// Live activity rides the in-memory `ActiveStreamRegistry` instead; this table
/// backs crash recovery and replay of finished runs.
@DriftAccessor(tables: [RunTranscriptsTable])
class RunTranscriptDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$RunTranscriptDaoMixin {
  /// Creates a [RunTranscriptDao].
  RunTranscriptDao(super.db);

  /// Returns the run's transcript, or null when none was recorded.
  Future<RunTranscriptsTableData?> getForRun(
    String workspaceId,
    String runId,
  ) =>
      (select(runTranscriptsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.runId.equals(runId),
          ))
          .getSingleOrNull();

  /// Inserts or replaces the run's transcript.
  Future<void> upsert(RunTranscriptsTableCompanion entry) =>
      into(runTranscriptsTable).insertOnConflictUpdate(entry);

  /// Deletes the run's transcript, scoped by workspace + run.
  /// Returns rows deleted (0 when it belongs to another workspace).
  Future<int> deleteForRun(String workspaceId, String runId) =>
      (delete(runTranscriptsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.runId.equals(runId),
          ))
          .go();

  /// Deletes finalized transcripts last touched before [cutoff].
  ///
  /// Retention for this workspace's finished transcripts.
  ///
  /// Unfinished recordings are spared so a long-running job is never pruned
  /// mid-flight. The nightly sweep runs this once per workspace; for a single
  /// run use [deleteForRun].
  Future<int> pruneCompletedBefore(DateTime cutoff) =>
      (delete(runTranscriptsTable)..where(
            (t) =>
                t.complete.equals(true) &
                t.updatedAt.isSmallerThanValue(cutoff),
          ))
          .go();
}
