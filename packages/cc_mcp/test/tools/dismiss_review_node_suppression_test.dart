import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_mcp/src/tools/dismiss_review_node_tool.dart';
import 'package:test/test.dart';

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this._messages);
  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async =>
      null;
  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <ChannelMessage>[], hasMore: false));
  final Map<String, ChannelMessage> _messages;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => _messages.values.where((m) => m.channelId == channelId).toList();

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    final existing = _messages[messageId];
    if (existing != null && metadata != null) {
      _messages[messageId] = existing.copyWith(
        metadata: {...?existing.metadata, ...metadata},
      );
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
    sent.add({'content': content});
    return '';
  }

  @override
  Stream<List<Channel>> watchChannels() => const Stream.empty();
  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => const Stream.empty();
  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => const Stream.empty();
  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}
  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String> repoIds = const [],
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
  }) => throw UnimplementedError();
  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}
  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;
  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => [];
  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}
  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}
  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) async {}
  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}
  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}
  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) async => [];
  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];
  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async => null;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async => const [];
}

class _FakeReviewChannels implements ReviewChannelRepository {
  _FakeReviewChannels(this.association);
  final ReviewChannelAssociation? association;

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    association != null &&
            association!.workspaceId == workspaceId &&
            association!.channelId == channelId
        ? association
        : null,
  );
  @override
  Stream<List<ReviewChannelAssociation>> watchAllByChannel(
    String workspaceId,
    String channelId,
  ) => Stream.value(
    association != null &&
            association!.workspaceId == workspaceId &&
            association!.channelId == channelId
        ? [association!]
        : const [],
  );
  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(null);
  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);
  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async => throw UnimplementedError();
  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewChannelStatus status,
  ) async {}
}

class _FakeMemoryFacts implements MemoryFactRepository {
  final List<MemoryFact> upserted = [];

  @override
  Future<void> upsert(MemoryFact fact) async => upserted.add(fact);

  @override
  Future<List<MemoryFact>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) async => upserted
      .where((f) => f.workspaceId == workspaceId && f.topic == topic)
      .toList();

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => [];
  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async => null;
  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    int limit = 10,
    Float32List? queryEmbedding,
  }) async => [];
  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async => [];
  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async => [];
  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) async {}
  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => [];
  @override
  Future<void> delete(String workspaceId, String id) async {}
}

class _FakeDomainRepo implements MemoryDomainRepository {
  final List<MemoryDomain> domains = [];

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) async =>
      domains
          .where((d) => d.workspaceId == workspaceId && d.name == name)
          .firstOrNull;

  @override
  Future<void> upsert(MemoryDomain domain) async => domains.add(domain);

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) async => [];
}

class _FakeGrantRepo implements MemoryAccessGrantRepository {
  @override
  Future<void> upsert(MemoryAccessGrant grant) async {}
  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) async {}
  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) async =>
      [];
  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
}

ChannelMessage _node({
  String id = 'msg-1',
  String channelId = 'ch-1',
  String content = 'Possible null dereference on the new path.',
  String? filePath = 'lib/foo.dart',
  int? lineNumber = 12,
}) {
  return ChannelMessage(
    id: id,
    channelId: channelId,
    conversationId: channelId,
    senderId: 'qa',
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.reviewNode,
    metadata: {
      'nodeType': 'bug',
      'priority': 'p1',
      'confidence': 0.8,
      'status': 'open',
      'filePath': ?filePath,
      'lineNumber': ?lineNumber,
    },
    createdAt: DateTime.utc(2026),
  );
}

ReviewChannelAssociation _assoc() => ReviewChannelAssociation(
  id: 'r-1',
  channelId: 'ch-1',
  workspaceId: 'ws',
  prExternalId: 'pr-node',
  prNumber: 7,
  repoFullName: 'org/repo',
  status: ReviewChannelStatus.inProgress,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('DismissReviewNodeTool suppression learning', () {
    test(
      'records a suppression fact in the review-suppressions domain',
      () async {
        final facts = _FakeMemoryFacts();
        final tool = DismissReviewNodeTool(
          repository: _FakeMessaging({'msg-1': _node()}),
          reviewChannels: _FakeReviewChannels(_assoc()),
          memoryFacts: facts,
          resolveDomain: ResolveOrCreateDomainUseCase(
            domainRepository: _FakeDomainRepo(),
            grantRepository: _FakeGrantRepo(),
          ),
        );

        final result = await tool.call({
          'workspace_id': 'ws',
          'channel_id': 'ch-1',
          'node_message_id': 'msg-1',
          'agent_id': 'arch',
          'reason': 'Guarded earlier; not reachable.',
        });

        expect(result.isError, isFalse);
        final json =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(json['status'], 'dismissed');
        expect(json['suppression_recorded'], isTrue);

        expect(facts.upserted, hasLength(1));
        final fact = facts.upserted.single;
        expect(fact.workspaceId, 'ws');
        expect(fact.domain, DismissReviewNodeTool.suppressionDomain);
        expect(fact.topic, contains('lib/foo.dart'));
        expect(fact.content, contains('Guarded earlier; not reachable.'));
        expect(fact.content, contains('lib/foo.dart'));
      },
    );

    test('does not duplicate an identical suppression on re-dismiss', () async {
      final facts = _FakeMemoryFacts();
      final resolve = ResolveOrCreateDomainUseCase(
        domainRepository: _FakeDomainRepo(),
        grantRepository: _FakeGrantRepo(),
      );
      DismissReviewNodeTool tool() => DismissReviewNodeTool(
        repository: _FakeMessaging({'msg-1': _node()}),
        reviewChannels: _FakeReviewChannels(_assoc()),
        memoryFacts: facts,
        resolveDomain: resolve,
      );

      await tool().call({
        'workspace_id': 'ws',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'arch',
        'reason': 'Intentional.',
      });
      await tool().call({
        'workspace_id': 'ws',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'arch',
        'reason': 'Intentional.',
      });

      expect(facts.upserted, hasLength(1));
    });

    test('skips recording when memory collaborators are absent', () async {
      final tool = DismissReviewNodeTool(
        repository: _FakeMessaging({'msg-1': _node()}),
      );

      final result = await tool.call({
        'workspace_id': 'ws',
        'channel_id': 'ch-1',
        'node_message_id': 'msg-1',
        'agent_id': 'arch',
        'reason': 'n/a',
      });

      final json =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['suppression_recorded'], isFalse);
    });
  });
}
