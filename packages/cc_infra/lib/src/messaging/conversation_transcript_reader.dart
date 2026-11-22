import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/transcript_store.dart';

/// [ConversationTranscriptPort] over the stored messages and their turn
/// transcripts, paged in the database ([TranscriptStore]).
///
/// What the stores hold, and so what a row can say:
///
/// - A top-level tool call's output is stored as the run received it. When
///   the loop cut an over-long observation and kept the original, the stored
///   output holds `[output omitted …; resume with read_output(handle:
///   "…", …)]`: the row carries [TranscriptRow.outputHandle]. A cut
///   without a kept original (`(original not stored)`), a script call's
///   preview cut at 8 KiB (`… [N bytes, truncated]`, never kept) and a
///   pruned output (`prunedAt`) carry [TranscriptRow.outputLost].
/// - A turn's reasoning is not a row, nor is a blank text.
/// - A conversation compaction folds messages (`compacted`) and inserts a
///   `compaction` row; both are rows, the folded ones marked. A compaction
///   inside one run (the harness loop's) is not recorded and has no row.
///
/// What one read costs, whatever the conversation's size: one count, one
/// window of at most [ConversationTranscriptPort.maxScanMessages] messages'
/// stored facts (no content) and one more message's, read only for where
/// the next page starts, at most `limit` row segments' facts over the
/// window's agent turns, and one text read per row returned, each at most
/// [ConversationTranscriptPort.maxRowChars] characters, stopping once the
/// page passes [ConversationTranscriptPort.maxPageBytes]. Texts are cut by
/// the database by code point, so no row ends inside a character.
///
/// Places: a page of a conversation starts at a [TranscriptCursor], the
/// stored `(created_at, row id)` of a message and a segment of it. The next
/// page starts at the first live message at or after that pair, so a
/// message reverted or hard-deleted between two pages neither skips nor
/// repeats a row, and resumes inside the message only while it is still the
/// one the cursor names (a new message that took a deleted one's row id
/// starts whole). A run's own transcript is one message: a place there is
/// the segment's `seq`.
class ConversationTranscriptReader implements ConversationTranscriptPort {
  /// Creates the reader over [_store].
  ConversationTranscriptReader(this._store);

  final TranscriptStore _store;

  static final RegExp _handle = RegExp(r'read_output\(handle: "([^"]+)"');

  @override
  Future<TranscriptPage> page({
    required String workspaceId,
    required String conversationId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    _checkLimit(limit);
    final from = start == null ? null : TranscriptCursor.tryParse(start);
    if (start != null && from == null) {
      throw ArgumentError.value(start, 'start', "is not a page's next_start");
    }
    final count = await _store.messageCount(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    final read = await _store.messages(
      workspaceId: workspaceId,
      conversationId: conversationId,
      from: from == null ? null : (orderAt: from.orderAt, rowId: from.rowId),
      limit: ConversationTranscriptPort.maxScanMessages + 1,
    );
    // The one past the window only says where the next page starts.
    final peek = read.length > ConversationTranscriptPort.maxScanMessages
        ? read.last
        : null;
    final window = peek == null ? read : read.sublist(0, read.length - 1);
    final kinds = _kinds(roles, tools);
    final found = <_Found>[];
    for (final message in window) {
      if (found.length == limit) {
        break;
      }
      // Resume inside the cursor's message only while it is still that
      // message (reverted or deleted since, it is not in the window; a new
      // message that took its row id starts whole).
      final fromSeq =
          from != null &&
              message.rowId == from.rowId &&
              message.id == from.messageId
          ? from.seq
          : 0;
      if (!message.hasSegments) {
        final role = _messageRole(message);
        if (fromSeq == 0 &&
            (roles == null || roles.contains(role)) &&
            (tools == null)) {
          found.add(_Found(message, null, 0, role));
        }
        continue;
      }
      final segments = await _store.segments(
        workspaceId: workspaceId,
        messageId: message.id,
        runId: null,
        fromSeq: fromSeq,
        limit: limit - found.length,
        kinds: kinds,
        tools: tools,
      );
      for (final segment in segments) {
        found.add(_Found(message, segment, segment.seq, _role(segment)));
      }
    }
    // Where scanning stopped when every row found is returned: after the
    // last row of a full page, or at the message past the window when the
    // window ended first.
    final scanEnd = found.length == limit
        ? found.last.place(after: true)
        : (peek == null
              ? null
              : TranscriptCursor(
                  orderAt: peek.orderAt,
                  rowId: peek.rowId,
                  seq: 0,
                  messageId: peek.id,
                ).encode());
    return _texts(
      found,
      scanEnd: scanEnd,
      messageCount: count,
      text: (f, from) => f.segment == null
          ? _store.messageText(
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: f.message!.id,
              from: from,
              chars: ConversationTranscriptPort.maxRowChars,
            )
          : _store.segmentText(
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: f.message!.id,
              runId: null,
              seq: f.segment!.seq,
              from: from,
              chars: ConversationTranscriptPort.maxRowChars,
            ),
      build: (f, text) => _row(
        f,
        text,
        id: f.segment == null
            ? f.message!.id
            : '${f.message!.id}:${f.segment!.seq}',
        messageId: f.message!.id,
        runId: f.message!.runId,
        author: f.message!.senderType == SenderType.system
            ? null
            : f.message!.senderId,
        folded: f.message!.compacted,
        at: f.segment?.at ?? f.message!.createdAt,
      ),
    );
  }

  @override
  Future<TranscriptSlice?> slice({
    required String workspaceId,
    required String conversationId,
    required String rowId,
    required int offset,
  }) async {
    if (offset < 0) {
      return null;
    }
    final colon = rowId.lastIndexOf(':');
    final seq = colon > 0 ? int.tryParse(rowId.substring(colon + 1)) : null;
    final text = seq != null && seq >= 0
        ? await _store.segmentText(
            workspaceId: workspaceId,
            conversationId: conversationId,
            messageId: rowId.substring(0, colon),
            runId: null,
            seq: seq,
            from: offset,
            chars: ConversationTranscriptPort.maxRowChars,
          )
        : await _store.messageText(
            workspaceId: workspaceId,
            conversationId: conversationId,
            messageId: rowId,
            from: offset,
            chars: ConversationTranscriptPort.maxRowChars,
          );
    return _sliceOf(rowId, offset, text);
  }

  @override
  Future<TranscriptPage> pageRun({
    required String workspaceId,
    required String runId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    _checkLimit(limit);
    final fromSeq = start == null ? 0 : TranscriptCursor.tryParseRun(start);
    if (fromSeq == null) {
      throw ArgumentError.value(start, 'start', "is not a page's next_start");
    }
    final segments = await _store.segments(
      workspaceId: workspaceId,
      messageId: null,
      runId: runId,
      fromSeq: fromSeq,
      limit: limit,
      kinds: _kinds(roles, tools),
      tools: tools,
    );
    final found = [
      for (final segment in segments)
        _Found(null, segment, segment.seq, _role(segment)),
    ];
    DateTime? startedAt;
    if (found.any((f) => f.segment!.at == null)) {
      startedAt = await _store.runStartedAt(
        workspaceId: workspaceId,
        runId: runId,
      );
    }
    return _texts(
      found,
      scanEnd: found.length == limit ? found.last.place(after: true) : null,
      messageCount: null,
      text: (f, from) => _store.segmentText(
        workspaceId: workspaceId,
        conversationId: null,
        messageId: null,
        runId: runId,
        seq: f.segment!.seq,
        from: from,
        chars: ConversationTranscriptPort.maxRowChars,
      ),
      build: (f, text) => _row(
        f,
        text,
        id: '$runId:${f.segment!.seq}',
        messageId: runId,
        runId: runId,
        author: null,
        folded: false,
        at:
            f.segment!.at ??
            startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  @override
  Future<TranscriptSlice?> sliceRun({
    required String workspaceId,
    required String runId,
    required String rowId,
    required int offset,
  }) async {
    final prefix = '$runId:';
    final seq = rowId.startsWith(prefix)
        ? int.tryParse(rowId.substring(prefix.length))
        : null;
    if (offset < 0 || seq == null || seq < 0) {
      return null;
    }
    final text = await _store.segmentText(
      workspaceId: workspaceId,
      conversationId: null,
      messageId: null,
      runId: runId,
      seq: seq,
      from: offset,
      chars: ConversationTranscriptPort.maxRowChars,
    );
    return _sliceOf(rowId, offset, text);
  }

  static void _checkLimit(int limit) {
    if (limit < 1 || limit > ConversationTranscriptPort.maxPageRows) {
      throw ArgumentError.value(
        limit,
        'limit',
        'must be 1 to ${ConversationTranscriptPort.maxPageRows}',
      );
    }
  }

  /// Reads the text of each row [found], in order, until the page passes
  /// [ConversationTranscriptPort.maxPageBytes] (a page holds at least one
  /// row): the page's next start is the first row not returned, or
  /// [scanEnd] when every row found is.
  static Future<TranscriptPage> _texts(
    List<_Found> found, {
    required String? scanEnd,
    required int? messageCount,
    required Future<TranscriptStoreText?> Function(_Found, int from) text,
    required TranscriptRow Function(_Found, TranscriptStoreText) build,
  }) async {
    final rows = <TranscriptRow>[];
    var bytes = 0;
    for (final f in found) {
      final stored = await text(f, 0);
      if (stored == null) {
        // Reverted or rewritten between the two reads: not a row now.
        continue;
      }
      final size = utf8.encode(stored.text).length;
      if (rows.isNotEmpty &&
          bytes + size > ConversationTranscriptPort.maxPageBytes) {
        return TranscriptPage(
          rows: rows,
          messageCount: messageCount,
          nextStart: f.place(),
        );
      }
      rows.add(build(f, stored));
      bytes += size;
    }
    return TranscriptPage(
      rows: rows,
      messageCount: messageCount,
      nextStart: scanEnd,
    );
  }

  static TranscriptRow _row(
    _Found f,
    TranscriptStoreText text, {
    required String id,
    required String messageId,
    required String? runId,
    required String? author,
    required bool folded,
    required DateTime at,
  }) {
    final segment = f.segment;
    final isTool = segment?.kind == TranscriptSegmentKind.tool;
    final handle = isTool && text.handleMark != null
        ? _handle.firstMatch(text.handleMark!)?.group(1)
        : null;
    final cut = text.length > ConversationTranscriptPort.maxRowChars;
    return TranscriptRow(
      id: id,
      messageId: messageId,
      role: f.role,
      authorId: author,
      runId: runId,
      tool: isTool ? segment!.tool : null,
      text: text.text,
      folded: folded,
      cut: cut,
      fullLength: cut ? text.length : null,
      outputHandle: handle,
      outputLost:
          isTool && handle == null && (segment!.pruned || text.lostMark),
      at: at,
    );
  }

  static TranscriptSlice? _sliceOf(
    String rowId,
    int offset,
    TranscriptStoreText? text,
  ) {
    if (text == null || offset >= text.length && offset > 0) {
      return null;
    }
    final end = offset + text.text.runes.length;
    return TranscriptSlice(
      rowId: rowId,
      offset: offset,
      text: text.text,
      fullLength: text.length,
      nextOffset: end < text.length ? end : null,
    );
  }

  static TranscriptRole _messageRole(TranscriptStoreMessage m) =>
      m.messageType == MessageType.compaction
      ? TranscriptRole.compaction
      : switch (m.senderType) {
          SenderType.user => TranscriptRole.person,
          SenderType.agent => TranscriptRole.agent,
          _ => TranscriptRole.system,
        };

  static TranscriptRole _role(TranscriptStoreSegment s) => switch (s.kind) {
    TranscriptSegmentKind.text => TranscriptRole.agent,
    TranscriptSegmentKind.tool => TranscriptRole.tool,
    TranscriptSegmentKind.error => TranscriptRole.system,
  };

  /// The segment kinds whose rows pass [roles] and [tools].
  static Set<TranscriptSegmentKind> _kinds(
    Set<TranscriptRole>? roles,
    Set<String>? tools,
  ) => {
    for (final kind in TranscriptSegmentKind.values)
      if ((tools == null || kind == TranscriptSegmentKind.tool) &&
          (roles == null ||
              roles.contains(switch (kind) {
                TranscriptSegmentKind.text => TranscriptRole.agent,
                TranscriptSegmentKind.tool => TranscriptRole.tool,
                TranscriptSegmentKind.error => TranscriptRole.system,
              })))
        kind,
  };
}

/// A row found by a page's scan, before its text is read.
class _Found {
  _Found(this.message, this.segment, this.seq, this.role);

  /// Its message; null on a run's own transcript.
  final TranscriptStoreMessage? message;

  /// Its segment; null for a whole message.
  final TranscriptStoreSegment? segment;

  /// Its segment's `seq`; 0 for a whole message.
  final int seq;

  final TranscriptRole role;

  /// Where a page that starts at this row starts, or, when [after], one
  /// that starts just past it (a whole message's next segment is past its
  /// end, so that page starts at the next message).
  String place({bool after = false}) {
    final at = seq + (after ? 1 : 0);
    final m = message;
    return m == null
        ? '$at'
        : TranscriptCursor(
            orderAt: m.orderAt,
            rowId: m.rowId,
            seq: at,
            messageId: m.id,
          ).encode();
  }
}
