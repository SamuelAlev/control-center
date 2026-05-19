import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';
import 'package:cc_infra/src/messaging/messaging_service.dart';
import 'package:test/test.dart';

/// In-memory [MessagingRepository] covering what `compactConversation` and the
/// compaction pass touch, recording mutations so refusal paths can prove
/// nothing was written.
class _FakeRepo implements MessagingRepository {
  final List<ChannelMessage> messages = [];
  final List<List<String>> markCompactedCalls = [];

  /// Workspaces the compaction pass wrote through, in call order.
  final List<String> markCompactedWorkspaceIds = [];

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => messages
      .where((m) => m.conversationId == (conversationId ?? channelId))
      .toList();

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {
    markCompactedWorkspaceIds.add(workspaceId);
    markCompactedCalls.add(ids);
    for (var i = 0; i < messages.length; i++) {
      if (ids.contains(messages[i].id)) {
        messages[i] = messages[i].copyWith(compacted: true);
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
    final newId = id ?? 'gen${messages.length}';
    messages.add(
      ChannelMessage(
        id: newId,
        channelId: channelId,
        conversationId: conversationId ?? channelId,
        senderId: senderId,
        senderType: ChannelSenderType.agent,
        content: content,
        messageType: messageType == 'compaction'
            ? ChannelMessageType.compaction
            : ChannelMessageType.text,
        metadata: metadata,
        createdAt: DateTime.utc(2026, 1, 1, 0, 1),
      ),
    );
    return newId;
  }

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeDispatch implements AgentDispatchService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeStreamProcessor implements AgentStreamProcessor {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ChannelMessage _msg(
  String id,
  String channelId,
  String conversationId,
  ChannelSenderType sender,
  int sec,
) => ChannelMessage(
  id: id,
  channelId: channelId,
  conversationId: conversationId,
  senderId: sender == ChannelSenderType.user ? 'user' : 'agent',
  senderType: sender,
  content: 'content of $id',
  messageType: ChannelMessageType.text,
  createdAt: DateTime.utc(2026, 1, 1, 0, 0, sec),
);

MessagingService _service(
  _FakeRepo repo,
  ActiveStreamRegistry registry, {
  ConversationCompactionService? compaction,
}) => MessagingService(
  repo,
  agentDispatchService: _FakeDispatch(),
  streamRegistry: registry,
  streamProcessor: _FakeStreamProcessor(),
  compactionService: compaction,
);

ConversationCompactionService _compaction(_FakeRepo repo) =>
    ConversationCompactionService(
      repo: repo,
      summarizer: const StructuralConversationSummarizer(),
      config: const CompactionConfig(keepTurns: 2, buffer: 100, prune: false),
      now: () => DateTime.utc(2026, 1, 2),
    );

void main() {
  const ws = 'ws-1';

  group('MessagingService.compactConversation', () {
    late _FakeRepo repo;
    late ActiveStreamRegistry registry;

    setUp(() {
      repo = _FakeRepo();
      registry = ActiveStreamRegistry();
    });

    test(
      'a foreign conversation id is denied loudly and mutates nothing',
      () async {
        // The DAO filters messages by conversation alone; a caller-ownable
        // channel id must not authorize compacting ANOTHER channel's thread.
        repo.messages.addAll([
          _msg('x0', 'other-channel', 'foreign', ChannelSenderType.user, 0),
          _msg('x1', 'other-channel', 'foreign', ChannelSenderType.agent, 1),
        ]);
        final service = _service(repo, registry, compaction: _compaction(repo));

        await expectLater(
          service.compactConversation(
            workspaceId: ws,
            channelId: 'c',
            conversationId: 'foreign',
          ),
          throwsA(isA<WorkspaceMismatchException>()),
        );
        expect(repo.markCompactedCalls, isEmpty);
        expect(
          repo.messages.any(
            (m) => m.messageType == ChannelMessageType.compaction,
          ),
          isFalse,
        );
      },
    );

    test('an in-flight turn in the channel refuses with agentBusy', () async {
      registry.register('m-live', channelId: 'c');
      final service = _service(repo, registry, compaction: _compaction(repo));

      final result = await service.compactConversation(
        workspaceId: ws,
        channelId: 'c',
      );

      expect(result.status, ConversationCompactionStatus.agentBusy);
      expect(repo.markCompactedCalls, isEmpty);
    });

    test('no compaction service wired reports unavailable', () async {
      final service = _service(repo, registry);

      final result = await service.compactConversation(
        workspaceId: ws,
        channelId: 'c',
      );

      expect(result.status, ConversationCompactionStatus.unavailable);
    });

    test(
      'forces a fold on the requested conversation and reports it',
      () async {
        var sec = 0;
        for (var i = 0; i < 6; i++) {
          repo.messages.addAll([
            _msg('u$i', 'c', 'thread-1', ChannelSenderType.user, sec++),
            _msg('a$i', 'c', 'thread-1', ChannelSenderType.agent, sec++),
          ]);
        }
        final service = _service(repo, registry, compaction: _compaction(repo));

        final result = await service.compactConversation(
          workspaceId: ws,
          channelId: 'c',
          conversationId: 'thread-1',
        );

        expect(result.status, ConversationCompactionStatus.compacted);
        expect(result.compactedMessageCount, greaterThan(0));
        final summary = repo.messages.firstWhere(
          (m) => m.messageType == ChannelMessageType.compaction,
        );
        expect(summary.conversationId, 'thread-1');
        expect(summary.metadata?['compactionReason'], 'manual');
        expect(repo.markCompactedWorkspaceIds, everyElement(ws));
      },
    );

    test('a short conversation reports nothingToCompact', () async {
      repo.messages.addAll([
        _msg('u0', 'c', 'c', ChannelSenderType.user, 0),
        _msg('a0', 'c', 'c', ChannelSenderType.agent, 1),
      ]);
      final service = _service(repo, registry, compaction: _compaction(repo));

      final result = await service.compactConversation(
        workspaceId: ws,
        channelId: 'c',
      );

      expect(result.status, ConversationCompactionStatus.nothingToCompact);
      expect(repo.markCompactedCalls, isEmpty);
    });
  });
}
