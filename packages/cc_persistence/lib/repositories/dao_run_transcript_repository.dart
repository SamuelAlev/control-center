import 'dart:convert';

import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart' as drift;

/// Drift-backed [RunTranscriptRepository] over the per-workspace
/// [RunTranscriptDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).runTranscriptDao` per call: a transcript belongs to
/// the run that produced it, so it lives in that run's workspace database file.
class DaoRunTranscriptRepository implements RunTranscriptRepository {
  /// Creates a [DaoRunTranscriptRepository] over the per-workspace databases.
  DaoRunTranscriptRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  RunTranscriptDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).runTranscriptDao;

  @override
  Future<RunTranscript?> getForRun(String workspaceId, String runId) async {
    final row = await _dao(workspaceId).getForRun(workspaceId, runId);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) => _dao(workspaceId).upsert(
    RunTranscriptsTableCompanion.insert(
      runId: runId,
      workspaceId: workspaceId,
      segmentsJson: drift.Value(jsonEncode(segmentsJson)),
      segmentCount: drift.Value(segmentsJson.length),
      transcriptChars: drift.Value(transcriptChars),
      outcome: drift.Value(
        outcome == null ? null : turnOutcomeToString(outcome),
      ),
      complete: drift.Value(complete),
      startedAt: drift.Value(startedAt),
      updatedAt: drift.Value(updatedAt),
    ),
  );

  @override
  Future<int> deleteForRun(String workspaceId, String runId) =>
      _dao(workspaceId).deleteForRun(workspaceId, runId);

  RunTranscript _toDomain(RunTranscriptsTableData row) => RunTranscript(
    runId: row.runId,
    workspaceId: row.workspaceId,
    segments: decodeTranscript(_decodeJson(row.segmentsJson)),
    transcriptChars: row.transcriptChars,
    outcome: turnOutcomeFromString(row.outcome),
    complete: row.complete,
    startedAt: row.startedAt,
    updatedAt: row.updatedAt,
  );

  /// Tolerates a malformed blob rather than failing the read: a truncated write
  /// should degrade to "nothing recorded", not break the activity view.
  static Object? _decodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return const <Object?>[];
    }
  }
}
