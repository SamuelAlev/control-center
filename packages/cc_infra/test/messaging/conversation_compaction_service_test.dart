import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';
import 'package:test/test.dart';

/// Minimal in-memory [MessagingRepository] covering only the methods the
/// compaction service touches.
class _FakeRepo implements MessagingRepository {
  _FakeRepo(this._messages);

  final List<ChannelMessage> _messages;
  var _seq = 1000;

  /// Captures the `conversationId` of the last read/summary insert so tests
  /// can assert the manual pass threads the caller's conversation through.
  String? lastReadConversationId;
  String? lastInsertConversationId;

  /// Workspace the last read and the summary insert were scoped to — the
  /// workspace selects the database file, so it must be threaded through.
  String? lastReadWorkspaceId;
  String? lastInsertWorkspaceId;

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async {
    lastReadWorkspaceId = workspaceId;
    lastReadConversationId = conversationId;
    return List.of(_messages);
  }

  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async {
    for (final m in _messages) {
      if (m.id == messageId) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {
    for (var i = 0; i < _messages.length; i++) {
      if (ids.contains(_messages[i].id)) {
        _messages[i] = _messages[i].copyWith(compacted: true);
      }
    }
  }

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    final newId = id ?? 'gen${_seq++}';
    lastInsertWorkspaceId = workspaceId;
    lastInsertConversationId = conversationId;
    _messages.add(
      ChannelMessage(
        id: newId,
        channelId: channelId,
        conversationId: conversationId ?? channelId,
        senderId: senderId,
        senderType: senderType == 'user'
            ? ChannelSenderType.user
            : ChannelSenderType.agent,
        content: content,
        messageType: messageType == 'compaction'
            ? ChannelMessageType.compaction
            : ChannelMessageType.text,
        metadata: metadata,
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, _seq),
      ),
    );
    return newId;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].id == messageId) {
        _messages[i] = _messages[i].copyWith(
          content: content,
          metadata: metadata,
        );
      }
    }
  }

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  // --- Unused by the compaction service ---
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

ChannelMessage _user(String id, String text, int sec) => ChannelMessage(
  id: id,
  channelId: 'c',
  conversationId: 'c',
  senderId: 'user',
  senderType: ChannelSenderType.user,
  content: text,
  messageType: ChannelMessageType.text,
  createdAt: DateTime.utc(2026, 1, 1, 0, 0, sec),
);

ChannelMessage _turn(String id, String answer, int sec, {String fat = ''}) {
  final segs = <TranscriptSegment>[
    if (fat.isNotEmpty)
      ToolSegment(
        toolName: 'bash',
        toolCallId: '$id-t',
        outputs: fat,
        startedAt: DateTime.utc(2026),
        durationMs: 1,
      ),
    TextSegment(text: answer, startedAt: DateTime.utc(2026)),
  ];
  return ChannelMessage(
    id: id,
    channelId: 'c',
    conversationId: 'c',
    senderId: 'agent',
    senderType: ChannelSenderType.agent,
    content: answer,
    messageType: ChannelMessageType.agentTurn,
    metadata: {'segments': encodeTranscript(segs)},
    createdAt: DateTime.utc(2026, 1, 1, 0, 0, sec),
  );
}

void main() {
  const ws = 'ws-1';

  test('maintains: folds older region into a compaction message', () async {
    final messages = <ChannelMessage>[
      _user('u0', 'IMPORTANT: tabs not spaces', 0),
      _turn('a0', 'noted', 1, fat: 'X' * 40000),
    ];
    var sec = 2;
    for (var i = 0; i < 20; i++) {
      messages.add(_user('u${i + 1}', 'step $i', sec++));
      messages.add(_turn('a${i + 1}', 'did step $i', sec++, fat: 'Y' * 40000));
    }

    final repo = _FakeRepo(messages);
    final service = ConversationCompactionService(
      repo: repo,
      summarizer: const StructuralConversationSummarizer(),
      config: const CompactionConfig(keepTurns: 3, buffer: 1000, prune: false),
      now: () => DateTime.utc(2026, 1, 2),
    );

    final outcome = await service.maintain(
      workspaceId: ws,
      channelId: 'c',
      contextWindowTokens: 8000,
      selfAgentName: 'architect',
    );

    expect(outcome.compactionMessageId, isNotNull);
    expect(outcome.compactedMessageCount, greaterThan(0));

    final all = await repo.getMessages(ws, 'c');
    final summary = all.firstWhere((m) => m.isCompaction);
    expect(summary.compactionReason, 'auto');
    expect(summary.compactionTailStartId, isNotNull);
    expect(summary.compactedIds, isNotEmpty);
    // The early decision survives in the anchored summary.
    expect(summary.content, contains('tabs not spaces'));
    // Compacted originals are marked (recoverable, not deleted).
    final compacted = all.where((m) => m.compacted).toList();
    expect(compacted, isNotEmpty);
    expect(all.any((m) => m.id == 'u0' && m.compacted), isTrue);
  });

  test('does nothing under no pressure', () async {
    final repo = _FakeRepo([_user('u0', 'hi', 0), _turn('a0', 'hello', 1)]);
    final service = ConversationCompactionService(
      repo: repo,
      summarizer: const StructuralConversationSummarizer(),
    );
    final outcome = await service.maintain(
      workspaceId: ws,
      channelId: 'c',
      contextWindowTokens: 200000,
      selfAgentName: 'a',
    );
    expect(outcome.didSomething, isFalse);
  });

  test('pruning pass alone can relieve pressure without compacting', () async {
    // One older turn with a huge tool output; pruning it drops below budget.
    final messages = <ChannelMessage>[
      _user('u0', 'go', 0),
      _turn('a0', 'ok', 1, fat: 'Z' * 200000),
      _user('u1', 'more', 2),
      _turn('a1', 'sure', 3),
      _user('u2', 'again', 4),
      _turn('a2', 'yes', 5),
    ];
    final repo = _FakeRepo(messages);
    final service = ConversationCompactionService(
      repo: repo,
      summarizer: const StructuralConversationSummarizer(),
      config: const CompactionConfig(keepTurns: 2, buffer: 500),
      now: () => DateTime.utc(2026, 1, 2),
    );
    final outcome = await service.maintain(
      workspaceId: ws,
      channelId: 'c',
      contextWindowTokens: 20000,
      selfAgentName: 'a',
    );
    expect(outcome.prunedTokens, greaterThan(0));
  });

  test(
    'manual pass threads conversationId to reads and the summary insert',
    () async {
      final messages = <ChannelMessage>[
        _user('u0', 'IMPORTANT: tabs not spaces', 0),
        _turn('a0', 'noted', 1),
      ];
      var sec = 2;
      for (var i = 0; i < 10; i++) {
        messages.add(_user('u${i + 1}', 'step $i', sec++));
        messages.add(_turn('a${i + 1}', 'did step $i', sec++));
      }
      final repo = _FakeRepo(messages);
      final service = ConversationCompactionService(
        repo: repo,
        summarizer: const StructuralConversationSummarizer(),
        config: const CompactionConfig(
          keepTurns: 2,
          buffer: 1000,
          prune: false,
        ),
        now: () => DateTime.utc(2026, 1, 2),
      );

      final outcome = await service.maintain(
        workspaceId: ws,
        channelId: 'c',
        conversationId: 'thread-1',
        contextWindowTokens: 8000,
        selfAgentName: 'architect',
        force: true,
      );

      expect(outcome.compactionMessageId, isNotNull);
      expect(repo.lastReadWorkspaceId, ws);
      expect(repo.lastInsertWorkspaceId, ws);
      expect(repo.lastReadConversationId, 'thread-1');
      expect(repo.lastInsertConversationId, 'thread-1');
      final all = await repo.getMessages(ws, 'c');
      final summary = all.firstWhere((m) => m.isCompaction);
      expect(summary.conversationId, 'thread-1');
      expect(summary.compactionReason, 'manual');
    },
  );
}
