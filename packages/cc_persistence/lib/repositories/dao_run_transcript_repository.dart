import 'dart:convert';

import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

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
    final dao = _dao(workspaceId);
    final row = await dao.getForRun(runId);
    if (row == null) {
      return null;
    }
    final bodies = await dao.segmentBodies(row.id);
    return RunTranscript(
      runId: runId,
      workspaceId: workspaceId,
      segments: [
        for (final body in bodies)
          if (_decodeSegment(body) case final Map<String, dynamic> json)
            TranscriptSegment.fromJson(json),
      ],
      transcriptChars: row.transcriptChars,
      outcome: turnOutcomeFromString(row.outcome),
      complete: row.complete,
      startedAt: row.startedAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> write({
    required String runId,
    required String workspaceId,
    required Map<int, Map<String, dynamic>> changedSegments,
    required int segmentCount,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) => _dao(workspaceId).writeRunFlush(
    runId,
    changed: {
      for (final MapEntry(:key, :value) in changedSegments.entries)
        key: jsonEncode(value),
    },
    segmentCount: segmentCount,
    transcriptChars: transcriptChars,
    startedAt: startedAt,
    updatedAt: updatedAt,
    outcome: outcome == null ? null : turnOutcomeToString(outcome),
    complete: complete,
  );

  @override
  Future<int> deleteForRun(String workspaceId, String runId) =>
      _dao(workspaceId).deleteForRun(runId);

  /// One stored segment, or null when its body does not decode to an object:
  /// a damaged row costs that segment, not the activity view.
  static Map<String, dynamic>? _decodeSegment(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
