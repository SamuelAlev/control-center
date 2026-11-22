import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/ports/transcript_store.dart';
import 'package:cc_persistence/database/daos/run_transcript_dao.dart';
import 'package:cc_persistence/database/daos/transcript_page_queries.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Drift-backed [TranscriptStore] over the per-workspace databases.
///
/// Resolves `_dbs.of(workspaceId)` per call: a conversation's messages and
/// its turns' transcripts live in its workspace's database, and a run's own
/// transcript in its run's.
class DaoTranscriptStore implements TranscriptStore {
  /// Creates the store over the per-workspace databases.
  DaoTranscriptStore(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  RunTranscriptDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).runTranscriptDao;

  @override
  Future<int> messageCount({
    required String workspaceId,
    required String conversationId,
  }) => _dao(workspaceId).liveMessageCount(conversationId);

  @override
  Future<List<TranscriptStoreMessage>> messages({
    required String workspaceId,
    required String conversationId,
    required TranscriptStorePlace? from,
    required int limit,
  }) async {
    final rows = await _dao(workspaceId).pageMessages(
      conversationId: conversationId,
      agentTurn: MessageType.agentTurn.wire,
      from: from,
      limit: limit,
    );
    return [
      for (final row in rows)
        TranscriptStoreMessage(
          id: row.read<String>('id'),
          rowId: row.read<int>('row_id'),
          messageType: MessageType.fromWire(row.read<String>('message_type')),
          senderType: SenderType.fromWire(row.read<String>('sender_type')),
          senderId: row.read<String>('sender_id'),
          runId: _present(row.data['run_id']),
          compacted: row.read<bool>('compacted'),
          createdAt: row.read<DateTime>('created_at'),
          // The stored value itself, so a page's place compares equal.
          orderAt: row.read<int>('created_at'),
          hasSegments: row.read<bool>('has_segments'),
          textLength: row.read<int>('text_length'),
        ),
    ];
  }

  @override
  Future<List<TranscriptStoreSegment>> segments({
    required String workspaceId,
    required String? messageId,
    required String? runId,
    required int fromSeq,
    required int limit,
    required Set<TranscriptSegmentKind> kinds,
    required Set<String>? tools,
  }) async {
    if (kinds.isEmpty || limit <= 0) {
      return const [];
    }
    final owner = _ownerOf(messageId, runId);
    final rows = await _dao(workspaceId).pageSegments(
      ownerId: owner.id,
      run: owner.run,
      fromSeq: fromSeq,
      limit: limit,
      types: [for (final kind in kinds) kind.name],
      tools: tools?.toList(),
    );
    return [
      for (final row in rows)
        TranscriptStoreSegment(
          seq: row.read<int>('seq'),
          kind: TranscriptSegmentKind.values.byName(row.read<String>('type')),
          tool: _present(row.data['tool']),
          at: switch (row.data['ts']) {
            final int ms => DateTime.fromMillisecondsSinceEpoch(
              ms,
              isUtc: true,
            ),
            _ => null,
          },
          pruned: row.read<bool>('pruned'),
        ),
    ];
  }

  @override
  Future<TranscriptStoreText?> messageText({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required int from,
    required int chars,
  }) async {
    final row = await _dao(workspaceId).messageStretch(
      conversationId: conversationId,
      messageId: messageId,
      from: from,
      chars: chars,
    );
    if (row == null) {
      return null;
    }
    return TranscriptStoreText(
      text: row.read<String>('text'),
      length: row.read<int>('length'),
      handleMark: null,
      lostMark: false,
    );
  }

  @override
  Future<TranscriptStoreText?> segmentText({
    required String workspaceId,
    required String? conversationId,
    required String? messageId,
    required String? runId,
    required int seq,
    required int from,
    required int chars,
  }) async {
    final owner = _ownerOf(messageId, runId);
    final row = await _dao(workspaceId).segmentStretch(
      ownerId: owner.id,
      run: owner.run,
      conversationId: conversationId,
      seq: seq,
      from: from,
      chars: chars,
      markChars: TranscriptStoreText.markChars,
    );
    if (row == null) {
      return null;
    }
    return TranscriptStoreText(
      text: row.read<String>('text'),
      length: row.read<int>('length'),
      handleMark: row.readNullable<String>('handle_mark'),
      lostMark: row.readNullable<bool>('lost_mark') ?? false,
    );
  }

  @override
  Future<DateTime?> runStartedAt({
    required String workspaceId,
    required String runId,
  }) => _dao(workspaceId).runTranscriptStartedAt(runId);

  static ({String id, bool run}) _ownerOf(String? messageId, String? runId) {
    if ((messageId == null) == (runId == null)) {
      throw ArgumentError('Name exactly one of a message and a run.');
    }
    return messageId != null
        ? (id: messageId, run: false)
        : (id: runId!, run: true);
  }

  static String? _present(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
