import 'package:cc_persistence/database/tables/transcript_segments_table.dart';
import 'package:cc_persistence/database/tables/transcripts_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'run_transcript_dao.g.dart';

/// Rows of one segment insert: each binds three variables, and a statement
/// stays well under SQLite's variable limit.
const _segmentsPerStatement = 300;

/// Data access for agent activity transcripts: a `transcripts` row per
/// timeline and a `transcript_segments` row per segment.
///
/// A transcript is owned by a subagent run or by a space-turn message (see
/// [TranscriptsTable]); every write and read names its owner, never the
/// transcript's own id. The file is one workspace's, so an owner id from
/// another workspace is simply not found.
///
/// Offers no watch: live activity rides the in-memory `ActiveStreamRegistry`,
/// and these rows back crash recovery and replay.
@DriftAccessor(tables: [TranscriptsTable, TranscriptSegmentsTable])
class RunTranscriptDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$RunTranscriptDaoMixin {
  /// Creates a [RunTranscriptDao].
  RunTranscriptDao(super.db);

  /// The run's transcript facts, or null when none was recorded.
  Future<TranscriptsTableData?> getForRun(String runId) => (select(
    transcriptsTable,
  )..where((t) => t.runId.equals(runId))).getSingleOrNull();

  /// The bodies of transcript [transcriptId]'s segments, in order.
  Future<List<String>> segmentBodies(int transcriptId) =>
      (selectOnly(transcriptSegmentsTable)
            ..addColumns([transcriptSegmentsTable.body])
            ..where(transcriptSegmentsTable.transcriptId.equals(transcriptId))
            ..orderBy([OrderingTerm.asc(transcriptSegmentsTable.seq)]))
          .map((row) => row.read(transcriptSegmentsTable.body)!)
          .get();

  /// Writes one flush of a run's transcript: its facts, and only the segment
  /// rows in [changed] (position → encoded segment).
  Future<void> writeRunFlush(
    String runId, {
    required Map<int, String> changed,
    required int segmentCount,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    String? outcome,
    required bool complete,
  }) => transaction(() async {
    final id = await _upsertFacts(
      ownerColumn: 'run_id',
      ownerId: runId,
      segmentCount: segmentCount,
      transcriptChars: transcriptChars,
      updatedAt: updatedAt,
      startedAt: startedAt,
      outcome: outcome,
      complete: complete,
    );
    await _upsertSegments(id, changed);
  });

  /// Writes a space turn's transcript, owned by message [messageId].
  ///
  /// [segments] maps positions to encoded segments. With [replaceAll] it is
  /// the whole transcript and rows past its end are removed; without, it
  /// holds only the segments changed since the last flush. Either way a row
  /// whose body is unchanged is not rewritten.
  ///
  /// [complete] and [outcome] left null keep what is stored.
  Future<void> writeMessageTranscript(
    String messageId, {
    required Map<int, String> segments,
    required int segmentCount,
    required int transcriptChars,
    required bool replaceAll,
    bool? complete,
    String? outcome,
    DateTime? now,
  }) => transaction(() async {
    final id = await _upsertFacts(
      ownerColumn: 'message_id',
      ownerId: messageId,
      segmentCount: segmentCount,
      transcriptChars: transcriptChars,
      updatedAt: now ?? DateTime.now(),
      outcome: outcome,
      complete: complete,
    );
    await _upsertSegments(id, segments);
    if (replaceAll) {
      await customUpdate(
        'DELETE FROM transcript_segments WHERE transcript_id = ? AND seq >= ?',
        variables: [Variable.withInt(id), Variable.withInt(segmentCount)],
        updates: {transcriptSegmentsTable},
        updateKind: UpdateKind.delete,
      );
    }
  });

  /// Inserts or updates the facts row of the transcript [ownerColumn] =
  /// [ownerId] names, and returns its id.
  Future<int> _upsertFacts({
    required String ownerColumn,
    required String ownerId,
    required int segmentCount,
    required int transcriptChars,
    required DateTime updatedAt,
    DateTime? startedAt,
    String? outcome,
    bool? complete,
  }) async {
    final rows = await customWriteReturning(
      'INSERT INTO transcripts ($ownerColumn, segment_count, '
      'transcript_chars, outcome, complete, started_at, updated_at) '
      'VALUES (?1, ?2, ?3, ?4, COALESCE(?5, 0), COALESCE(?6, ?7), ?7) '
      'ON CONFLICT ($ownerColumn) DO UPDATE SET segment_count = ?2, '
      'transcript_chars = ?3, outcome = COALESCE(?4, outcome), '
      'complete = COALESCE(?5, complete), updated_at = ?7 '
      'RETURNING id',
      variables: [
        Variable.withString(ownerId),
        Variable.withInt(segmentCount),
        Variable.withInt(transcriptChars),
        Variable<String>(outcome),
        Variable<bool>(complete),
        Variable<DateTime>(startedAt),
        Variable<DateTime>(updatedAt),
      ],
      updates: {transcriptsTable},
    );
    return rows.single.read<int>('id');
  }

  /// Inserts the segments of [bodies] that transcript [transcriptId] does not
  /// hold yet and updates those whose body differs. A row whose body is the
  /// same is not written.
  Future<void> _upsertSegments(
    int transcriptId,
    Map<int, String> bodies,
  ) async {
    final entries = bodies.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (var start = 0; start < entries.length;) {
      final end = start + _segmentsPerStatement < entries.length
          ? start + _segmentsPerStatement
          : entries.length;
      final chunk = entries.sublist(start, end);
      await customUpdate(
        'INSERT INTO transcript_segments (transcript_id, seq, body) VALUES '
        '${List.filled(chunk.length, '(?, ?, ?)').join(', ')} '
        'ON CONFLICT (transcript_id, seq) DO UPDATE SET body = excluded.body '
        'WHERE body IS NOT excluded.body',
        variables: [
          for (final entry in chunk) ...[
            Variable.withInt(transcriptId),
            Variable.withInt(entry.key),
            Variable.withString(entry.value),
          ],
        ],
        updates: {transcriptSegmentsTable},
        updateKind: UpdateKind.insert,
      );
      start = end;
    }
  }

  /// Statement behind [segmentBodiesForMessages], for [count] message ids.
  ///
  /// Each message is one probe of `idx_transcripts_message_id` and a range
  /// of the segments' primary key. A message without a transcript yields no
  /// row; one whose transcript has no segment yet yields a NULL body.
  static String messageSegmentsSql(int count) =>
      'SELECT t.message_id AS message_id, s.body AS body '
      'FROM transcripts t '
      'LEFT JOIN transcript_segments s ON s.transcript_id = t.id '
      'WHERE t.message_id IN (${List.filled(count, '?').join(', ')}) '
      'ORDER BY t.message_id, s.seq';

  /// The segment bodies of each of [messageIds] that has a transcript, in
  /// order. A message with no transcript is absent from the result.
  Future<Map<String, List<String>>> segmentBodiesForMessages(
    Iterable<String> messageIds,
  ) async {
    final ids = messageIds.toSet().toList();
    final result = <String, List<String>>{};
    for (var start = 0; start < ids.length; start += 500) {
      final chunk = ids.sublist(
        start,
        start + 500 < ids.length ? start + 500 : ids.length,
      );
      final rows = await customSelect(
        messageSegmentsSql(chunk.length),
        variables: [for (final id in chunk) Variable.withString(id)],
        readsFrom: {transcriptsTable, transcriptSegmentsTable},
      ).get();
      for (final row in rows) {
        final bodies = result.putIfAbsent(
          row.read<String>('message_id'),
          () => <String>[],
        );
        final body = row.readNullable<String>('body');
        if (body != null) {
          bodies.add(body);
        }
      }
    }
    return result;
  }

  /// Gives message [toMessageId] a copy of [fromMessageId]'s transcript, when
  /// it has one. A fork copies a branch's messages with fresh ids, and a
  /// copied turn keeps its tool calls.
  Future<void> copyMessageTranscript(
    String fromMessageId,
    String toMessageId,
  ) => transaction(() async {
    final source = await (select(
      transcriptsTable,
    )..where((t) => t.messageId.equals(fromMessageId))).getSingleOrNull();
    if (source == null) {
      return;
    }
    final copyId = await into(transcriptsTable).insert(
      TranscriptsTableCompanion.insert(
        messageId: Value(toMessageId),
        segmentCount: Value(source.segmentCount),
        transcriptChars: Value(source.transcriptChars),
        outcome: Value(source.outcome),
        complete: Value(source.complete),
        startedAt: Value(source.startedAt),
        updatedAt: Value(source.updatedAt),
      ),
    );
    await customInsert(
      'INSERT INTO transcript_segments (transcript_id, seq, body) '
      'SELECT ?, seq, body FROM transcript_segments WHERE transcript_id = ?',
      variables: [Variable.withInt(copyId), Variable.withInt(source.id)],
      updates: {transcriptSegmentsTable},
    );
  });

  /// Deletes the run's transcript and, by cascade, its segments. Returns the
  /// transcripts deleted.
  Future<int> deleteForRun(String runId) =>
      (delete(transcriptsTable)..where((t) => t.runId.equals(runId))).go();

  /// Statement behind [pruneCompletedBefore]. Its terms repeat the `WHERE`
  /// of `idx_transcripts_run_sweep`, so the sweep reads only that index.
  static const pruneSql =
      'DELETE FROM transcripts '
      'WHERE run_id IS NOT NULL AND complete = 1 AND updated_at < ?';

  /// Deletes finalized run transcripts last touched before [cutoff]; their
  /// segments go with them.
  ///
  /// Retention for this workspace's subagent transcripts. A space turn's
  /// transcript is not swept: it belongs to its message and lives as long as
  /// the chat does. Unfinished recordings are spared so a long-running job is
  /// never pruned mid-flight.
  Future<int> pruneCompletedBefore(DateTime cutoff) => customUpdate(
    pruneSql,
    variables: [Variable<DateTime>(cutoff)],
    updates: {transcriptsTable, transcriptSegmentsTable},
    updateKind: UpdateKind.delete,
  );
}
