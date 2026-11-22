/// Who wrote a transcript row.
enum TranscriptRole {
  /// A person's message (a steer included).
  person,

  /// An agent's text.
  agent,

  /// One tool call of an agent's turn: its input, then its output.
  tool,

  /// A server row (a notice, a refusal, an error segment of a turn).
  system,

  /// A compaction's summary, shown where the compaction happened.
  compaction;

  /// Wire name.
  String get wire => name;

  /// Parses a wire name; null for anything else.
  static TranscriptRole? tryParse(Object? raw) =>
      TranscriptRole.values.where((r) => r.name == raw).firstOrNull;
}

/// One row of a conversation's transcript.
///
/// Wire form ([toJson]): `{id, message_id, role, author_id, run_id, tool,
/// text, folded, cut, full_length, output_handle, output_lost, at}`, the
/// null and false members omitted.
class TranscriptRow {
  /// Creates a row.
  const TranscriptRow({
    required this.id,
    required this.messageId,
    required this.role,
    required this.authorId,
    required this.runId,
    required this.tool,
    required this.text,
    required this.folded,
    required this.cut,
    required this.fullLength,
    required this.outputHandle,
    required this.outputLost,
    required this.at,
  });

  /// The row's id: the message id, or `<messageId>:<n>` for the n-th
  /// segment of an agent's turn.
  final String id;

  /// The message the row comes from.
  final String messageId;

  /// Who wrote it.
  final TranscriptRole role;

  /// The sender's id (a user or an agent); null for a server row.
  final String? authorId;

  /// The run that wrote it, when the turn recorded one.
  final String? runId;

  /// The tool of a [TranscriptRole.tool] row.
  final String? tool;

  /// The row's text, at most `ConversationTranscriptPort.maxRowChars`
  /// characters (Unicode code points; never half of one). A tool row is
  /// `input: <json>\noutput: <text>`.
  final String text;

  /// The message was folded into a compaction (no longer in the model's
  /// window); the compaction's own row stands where it happened.
  final bool folded;

  /// [text] is shorter than what is stored: the reader cut it (read the
  /// rest with `slice`, [fullLength] is the stored length).
  final bool cut;

  /// The stored text's length in characters when [cut].
  final int? fullLength;

  /// The stored tool output was itself cut when it was recorded and its
  /// original kept: `read_output(handle: <this>)` reads it.
  final String? outputHandle;

  /// The stored tool output was cut when it was recorded and its original
  /// was not kept (a script call's preview, a pruned output, a store that
  /// declined it): what [text] shows is all there is.
  final bool outputLost;

  /// When it was written.
  final DateTime at;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'id': id,
    'message_id': messageId,
    'role': role.wire,
    'author_id': ?authorId,
    'run_id': ?runId,
    'tool': ?tool,
    'text': text,
    if (folded) 'folded': true,
    if (cut) 'cut': true,
    'full_length': ?fullLength,
    'output_handle': ?outputHandle,
    if (outputLost) 'output_lost': true,
    'at': at.toUtc().toIso8601String(),
  };
}

/// One page of a transcript. Wire form: `{rows, message_count, next_start}`.
class TranscriptPage {
  /// Creates a page.
  const TranscriptPage({
    required this.rows,
    required this.messageCount,
    required this.nextStart,
  });

  /// The rows, oldest first.
  final List<TranscriptRow> rows;

  /// How many live messages the conversation holds (not rows: a turn is
  /// several rows, and filters are not counted); null for a run's own
  /// transcript.
  final int? messageCount;

  /// Where the next page starts (an opaque place: pass it back as `start`),
  /// or null after the last. Set whenever there is more to read, even when
  /// [rows] is empty because the read's scan window ended first. In a
  /// conversation it is a [TranscriptCursor]; in a run's own transcript, the
  /// next segment's `seq` in decimal.
  final String? nextStart;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'rows': [for (final row in rows) row.toJson()],
    'message_count': ?messageCount,
    'next_start': nextStart,
  };
}

/// Where a page of a conversation starts: a place in the conversation's
/// order (`created_at`, row id) and, inside the message there, a segment.
///
/// It carries what it needs to be found again, so neither a revert nor a
/// hard delete between two pages moves it: a page starts at the first live
/// message at or after ([orderAt], [rowId]), whether or not the message it
/// was taken from still exists. It resumes inside that message, at [seq],
/// only when the message there is still [messageId]; a different message
/// that took its row id since starts whole.
final class TranscriptCursor {
  /// Creates a cursor.
  const TranscriptCursor({
    required this.orderAt,
    required this.rowId,
    required this.seq,
    required this.messageId,
  });

  /// The message's `created_at` as stored (Unix seconds).
  final int orderAt;

  /// The message's row id.
  final int rowId;

  /// The segment of its turn to resume at (0 for the start).
  final int seq;

  /// The message's id.
  final String messageId;

  /// The most characters of an encoded cursor.
  static const int maxChars = 512;

  static final RegExp _form = RegExp(
    r'^(\d{1,15})\.(\d{1,15})\.(\d{1,9})\.(\S+)$',
  );

  static final RegExp _runForm = RegExp(r'^\d{1,9}$');

  /// The form a page's `next_start` takes.
  String encode() => '$orderAt.$rowId.$seq.$messageId';

  /// Reads [encode]'s form, or null for anything else.
  static TranscriptCursor? tryParse(String text) {
    final m = text.length > maxChars ? null : _form.firstMatch(text);
    if (m == null) {
      return null;
    }
    return TranscriptCursor(
      orderAt: int.parse(m.group(1)!),
      rowId: int.parse(m.group(2)!),
      seq: int.parse(m.group(3)!),
      messageId: m.group(4)!,
    );
  }

  /// The `seq` a run's own transcript resumes at, or null for anything
  /// else.
  static int? tryParseRun(String text) =>
      _runForm.hasMatch(text) ? int.parse(text) : null;

  /// Whether [text] is a `next_start` of either kind.
  static bool isWellFormed(String text) =>
      tryParse(text) != null || tryParseRun(text) != null;
}

/// A stretch of one row's stored text. Wire form: `{row_id, offset, text,
/// full_length, next_offset}`.
class TranscriptSlice {
  /// Creates a slice.
  const TranscriptSlice({
    required this.rowId,
    required this.offset,
    required this.text,
    required this.fullLength,
    required this.nextOffset,
  });

  /// The row.
  final String rowId;

  /// Where [text] starts, in characters (code points).
  final int offset;

  /// The stretch.
  final String text;

  /// The row's stored length.
  final int fullLength;

  /// Where the next stretch starts, or null at the end.
  final int? nextOffset;

  /// The wire form.
  Map<String, Object?> toJson() => {
    'row_id': rowId,
    'offset': offset,
    'text': text,
    'full_length': fullLength,
    'next_offset': nextOffset,
  };
}

/// Pages a conversation's transcript across its runs, oldest first: the
/// people's and agents' messages, each tool call of an agent's turn as its
/// own row, folded (compacted) turns included and each compaction's summary
/// in place. Reads are scoped to their `workspaceId`; a conversation that is not
/// in it reads as empty.
///
/// A read costs the same in a conversation of any length: it reads at most
/// [maxScanMessages] messages' stored facts, at most `limit` row segments'
/// facts, and the text of at most `limit` rows (each at most [maxRowChars]
/// characters), stopping at [maxPageBytes]. Filters are applied by the
/// store's queries (a tool filter, the segment kinds a role filter keeps)
/// and, for whole messages, over that window. A window that ends before the
/// page is full returns what it found with [TranscriptPage.nextStart] set.
abstract interface class ConversationTranscriptPort {
  /// The most rows on one page.
  static const int maxPageRows = 50;

  /// The most messages one read scans (one more is read to know where the
  /// next page starts).
  static const int maxScanMessages = 200;

  /// The most UTF-8 bytes of row text on one page. A page always holds at
  /// least one row.
  static const int maxPageBytes = 64 * 1024;

  /// The most characters of one row's text on a page or in a slice.
  static const int maxRowChars = 16 * 1024;

  /// At most [limit] rows (1 to [maxPageRows]) from [start] (null for the
  /// first, or a page's [TranscriptPage.nextStart]). [roles] keeps rows of
  /// those roles; [tools] keeps only tool rows of those tools. Null means no
  /// filter. Throws [ArgumentError] for a [start] that is not a
  /// [TranscriptCursor] or a [limit] out of range.
  Future<TranscriptPage> page({
    required String workspaceId,
    required String conversationId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  });

  /// At most [maxRowChars] characters of row [rowId]'s stored text from
  /// [offset]. Null when the row is not in the conversation, or [offset] is
  /// past its end.
  Future<TranscriptSlice?> slice({
    required String workspaceId,
    required String conversationId,
    required String rowId,
    required int offset,
  });

  /// [page] over one run's own transcript instead of a conversation's: a
  /// subagent's run, whose turns are kept with the run and not in any
  /// conversation (`RunTranscriptRepository`). Row ids are `<runId>:<n>`.
  /// A run that is not in [workspaceId], or recorded nothing, reads as empty.
  /// Its [start] is a `seq` in decimal ([TranscriptCursor.tryParseRun]).
  Future<TranscriptPage> pageRun({
    required String workspaceId,
    required String runId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  });

  /// [slice] of a row of [pageRun]'s run.
  Future<TranscriptSlice?> sliceRun({
    required String workspaceId,
    required String runId,
    required String rowId,
    required int offset,
  });
}
