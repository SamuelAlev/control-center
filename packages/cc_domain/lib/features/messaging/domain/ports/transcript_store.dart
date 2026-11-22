import 'package:cc_domain/core/domain/entities/message.dart';

/// What a transcript segment that is a row is. Reasoning, violations, blank
/// texts and anything newer are no rows, and no read returns them.
enum TranscriptSegmentKind {
  /// An agent's visible text.
  text,

  /// One tool call with its input and output.
  tool,

  /// An error of the turn (a server row).
  error,
}

/// A place in a conversation's order: a message's stored `created_at`
/// (Unix seconds) and its row id.
typedef TranscriptStorePlace = ({int orderAt, int rowId});

/// One live message of a conversation as the transcript reader pages it:
/// its stored facts, never its content.
class TranscriptStoreMessage {
  /// Creates a message.
  const TranscriptStoreMessage({
    required this.id,
    required this.rowId,
    required this.messageType,
    required this.senderType,
    required this.senderId,
    required this.runId,
    required this.compacted,
    required this.createdAt,
    required this.orderAt,
    required this.hasSegments,
    required this.textLength,
  });

  /// The message id.
  final String id;

  /// Its row's id in its workspace's database: with [createdAt], its place
  /// in the conversation's order, which a revert does not move.
  final int rowId;

  /// Its type.
  final MessageType messageType;

  /// Who sent it.
  final SenderType senderType;

  /// The sender's id.
  final String senderId;

  /// The run that wrote it, when its metadata names one.
  final String? runId;

  /// Folded into a compaction.
  final bool compacted;

  /// When it was written.
  final DateTime createdAt;

  /// Its `created_at` as stored (Unix seconds): with [rowId], its place in
  /// the conversation's order ([TranscriptStorePlace]).
  final int orderAt;

  /// An agent turn whose transcript holds at least one segment: its rows
  /// are its segments. Any other message is one row of its content.
  final bool hasSegments;

  /// Its content's length in characters (Unicode code points).
  final int textLength;
}

/// One stored segment of a turn's or a run's transcript that is a row: its
/// stored facts, never its text.
class TranscriptStoreSegment {
  /// Creates a segment.
  const TranscriptStoreSegment({
    required this.seq,
    required this.kind,
    required this.tool,
    required this.at,
    required this.pruned,
  });

  /// Its place in the transcript; the row id's last part.
  final int seq;

  /// What it is.
  final TranscriptSegmentKind kind;

  /// The tool of a [TranscriptSegmentKind.tool] segment.
  final String? tool;

  /// When it started, when it says.
  final DateTime? at;

  /// A tool output the run pruned.
  final bool pruned;
}

/// A stretch of a row's stored text.
class TranscriptStoreText {
  /// Creates a stretch.
  const TranscriptStoreText({
    required this.text,
    required this.length,
    required this.handleMark,
    required this.lostMark,
  });

  /// The stretch.
  final String text;

  /// The row's whole stored length, in characters (code points).
  final int length;

  /// A tool row whose output was cut when it was recorded, with its original
  /// kept: at most [markChars] characters of the output from its first
  /// `read_output(handle: "`. Null otherwise.
  final String? handleMark;

  /// A tool row whose output says it was cut without a kept original
  /// (`(original not stored)]`, or a script call's `… [N bytes,
  /// truncated]`).
  final bool lostMark;

  /// The most characters of [handleMark].
  static const int markChars = 300;
}

/// Bounded reads of the stored messages and transcripts, behind the
/// transcript reader (`ConversationTranscriptPort`). Every read names its
/// workspace, opens only that workspace's database, and returns at most the
/// rows or characters it is asked for, whatever the conversation's size:
/// lists carry no text, and a text read returns one stretch of one row.
///
/// Characters are Unicode code points here: a stretch never ends inside a
/// character.
abstract interface class TranscriptStore {
  /// How many live messages [conversationId] holds (one count, no rows).
  Future<int> messageCount({
    required String workspaceId,
    required String conversationId,
  });

  /// At most [limit] live messages of [conversationId] in the
  /// conversation's order (oldest first, by `created_at` and row id), from
  /// place [from] on (every message whose pair is not less than it, whether
  /// or not a message still stands there), or from the first message when
  /// [from] is null.
  Future<List<TranscriptStoreMessage>> messages({
    required String workspaceId,
    required String conversationId,
    required TranscriptStorePlace? from,
    required int limit,
  });

  /// At most [limit] row segments of message [messageId]'s transcript, or of
  /// run [runId]'s own (exactly one of the two), with `seq` of [fromSeq] or
  /// more, in order. [kinds] keeps only those kinds; [tools], when not null,
  /// keeps only tool segments of those tools. Both filters are applied in
  /// the query, so every segment returned is a row of the page.
  Future<List<TranscriptStoreSegment>> segments({
    required String workspaceId,
    required String? messageId,
    required String? runId,
    required int fromSeq,
    required int limit,
    required Set<TranscriptSegmentKind> kinds,
    required Set<String>? tools,
  });

  /// [chars] characters from [from] of message [messageId]'s content, when
  /// it is a live message of [conversationId]; null otherwise.
  Future<TranscriptStoreText?> messageText({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required int from,
    required int chars,
  });

  /// [chars] characters from [from] of segment [seq]'s row text (a text
  /// segment's text, a tool call's `input: <json>\noutput: <output>`, an
  /// error's message), of message [messageId] when it is a live message of
  /// [conversationId], or of run [runId]'s own transcript; null when there
  /// is no such segment or it is not a row.
  Future<TranscriptStoreText?> segmentText({
    required String workspaceId,
    required String? conversationId,
    required String? messageId,
    required String? runId,
    required int seq,
    required int from,
    required int chars,
  });

  /// When run [runId]'s own transcript started; null when it has none.
  Future<DateTime?> runStartedAt({
    required String workspaceId,
    required String runId,
  });
}
