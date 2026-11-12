import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/transcripts_table.dart';
import 'package:drift/drift.dart';

/// One segment of a transcript (reasoning, a tool call with its result, a run
/// of answer text, an error), keyed by its position.
///
/// A flush inserts the segments it has not written yet and updates only the
/// rows whose content changed (a tool call that finished, a text segment that
/// grew); every other row is left as it was. The primary key
/// `(transcript_id, seq)` is the only index the table needs: every read takes
/// one transcript's rows in order.
class TranscriptSegmentsTable extends Table {
  /// The transcript this segment belongs to. `ON DELETE CASCADE`: a segment
  /// is part of its transcript.
  IntColumn get transcriptId => integer().references(
    TranscriptsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Position in the transcript, from 0. Positions never move: a segment that
  /// is withdrawn is blanked, not removed.
  IntColumn get seq => integer()();

  /// The segment as `TranscriptSegment.toJson` encodes it.
  // ignore: recursive_getters
  TextColumn get body => text().check(isJsonObject(body))();

  @override
  String get tableName => 'transcript_segments';

  @override
  Set<Column> get primaryKey => {transcriptId, seq};
}
