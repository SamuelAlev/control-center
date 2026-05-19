import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_infra/src/pr_review/review_finalizer.dart';
import 'package:cc_mcp/src/tools/finalize_review_tool.dart';
import 'package:test/test.dart';

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this._messages);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {}

  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => const Stream.empty();
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;
  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => Stream.value((messages: const <Message>[], hasMore: false));
  final List<Message> _messages;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? conversationId,
  }) async {
    sent.add({
      'spaceId': spaceId,
      'content': content,
      'senderId': senderId,
      'messageType': messageType,
      'metadata': metadata,
    });
    return '';
  }

  @override
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 20,
  }) async => const [];

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => _messages.where((m) => m.spaceId == spaceId).toList();

  @override
  Stream<List<Space>> watchSpaces() => Stream.value([]);
  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) async => null;

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => const {};

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {}

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => Stream.value(_messages);
  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => Stream.value([]);
  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async {}

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) => throw UnimplementedError();
  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {}
  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;
  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => [];
  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {}
  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) async {}
  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {}
  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {}
  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) async {}
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) async {}
  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) async {}
  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async => [];
  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async => [];

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      null;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async => MessagePage.empty;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => const [];

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async => const [];

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeReviewSpaces implements ReviewSpaceRepository {
  _FakeReviewSpaces(this.association);
  ReviewSpaceAssociation association;
  final List<({String id, ReviewSpaceStatus status})> statusUpdates = [];

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    association.workspaceId == workspaceId && association.spaceId == spaceId
        ? association
        : null,
  );

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    association.workspaceId == workspaceId && association.spaceId == spaceId
        ? [association]
        : const [],
  );

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(null);

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) async {
    if (association.workspaceId != workspaceId || association.id != id) {
      return;
    }
    statusUpdates.add((id: id, status: status));
    association = association.copyWith(status: status);
  }
}

class _FakeAxisRepo implements ReviewAxisResultRepository {
  _FakeAxisRepo(this._results);
  final List<ReviewAxisResult> _results;
  final List<ReviewAxisResult> upserts = [];

  @override
  Future<List<ReviewAxisResult>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => _results;
  @override
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(_results);
  @override
  Future<void> upsert(
    String workspaceId,
    String prExternalId,
    ReviewAxisResult result,
  ) async {
    upserts.add(result);
  }
}

Message _node({
  required String id,
  required String spaceId,
  required String authorId,
  required String kind,
  String content = 'finding',
  List<String> confirmedBy = const [],
}) {
  return Message(
    id: id,
    spaceId: spaceId,
    conversationId: spaceId,
    senderId: authorId,
    senderType: SenderType.agent,
    content: content,
    messageType: MessageType.reviewNode,
    metadata: {
      'nodeType': kind,
      'priority': 'p1',
      'confidence': 0.85,
      'status': 'open',
      'confirmedBy': confirmedBy,
    },
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  group('FinalizeReviewTool consensus', () {
    test(
      'classifies as consensus-ready when a peer (not the author) confirms',
      () async {
        final assoc = ReviewSpaceAssociation(
          id: 'r-1',
          spaceId: 'ch-1',
          workspaceId: 'ws',
          prExternalId: 'pr-1',
          prNumber: 42,
          repoFullName: 'org/repo',
          status: ReviewSpaceStatus.inProgress,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final messaging = _FakeMessaging([
          _node(
            id: 'n-1',
            spaceId: 'ch-1',
            authorId: 'security',
            kind: 'bug',
            confirmedBy: ['backend'],
          ),
          _node(
            id: 'n-2',
            spaceId: 'ch-1',
            authorId: 'frontend',
            kind: 'suggestion',
          ),
        ]);
        final reviews = _FakeReviewSpaces(assoc);
        final tool = FinalizeReviewTool(
          finalizer: ReviewFinalizer(
            messaging: messaging,
            reviewSpaces: reviews,
          ),
        );

        final result = await tool.call({
          'workspace_id': 'ws',
          'space_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        expect(result.isError, isFalse);
        final json =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(json['consensus_ready'], 1);
        expect(json['needs_adjudication'], 1);
        expect(json['status'], 'awaiting_approval');
        expect(
          reviews.statusUpdates.last.status,
          ReviewSpaceStatus.awaitingApproval,
        );
      },
    );

    test(
      'a node confirmed only by its own author is NOT consensus-ready',
      () async {
        final assoc = ReviewSpaceAssociation(
          id: 'r-1',
          spaceId: 'ch-1',
          workspaceId: 'ws',
          prExternalId: 'pr-1',
          prNumber: 42,
          repoFullName: 'org/repo',
          status: ReviewSpaceStatus.inProgress,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final messaging = _FakeMessaging([
          _node(
            id: 'n-1',
            spaceId: 'ch-1',
            authorId: 'security',
            kind: 'bug',
            confirmedBy: ['security'], // self-confirmation, should be stripped
          ),
        ]);
        final tool = FinalizeReviewTool(
          finalizer: ReviewFinalizer(
            messaging: messaging,
            reviewSpaces: _FakeReviewSpaces(assoc),
          ),
        );

        final result = await tool.call({
          'workspace_id': 'ws',
          'space_id': 'ch-1',
          'finalizer_id': 'ceo',
        });

        final json =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(json['consensus_ready'], 0);
        expect(json['needs_adjudication'], 1);
      },
    );

    test('errors when space is not linked to a review', () async {
      final assoc = ReviewSpaceAssociation(
        id: 'r-1',
        spaceId: 'ch-OTHER',
        workspaceId: 'ws',
        prExternalId: 'pr-1',
        prNumber: 42,
        repoFullName: 'org/repo',
        status: ReviewSpaceStatus.inProgress,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final tool = FinalizeReviewTool(
        finalizer: ReviewFinalizer(
          messaging: _FakeMessaging([]),
          reviewSpaces: _FakeReviewSpaces(assoc),
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws',
        'space_id': 'ch-1',
        'finalizer_id': 'ceo',
      });
      expect(result.isError, isTrue);
    });

    test('a gated failing axis escalates the finding verdict to block', () async {
      final assoc = ReviewSpaceAssociation(
        id: 'r-1',
        spaceId: 'ch-1',
        workspaceId: 'ws',
        prExternalId: 'pr-1',
        prNumber: 42,
        repoFullName: 'org/repo',
        status: ReviewSpaceStatus.inProgress,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      // Only p1 findings → the finding-only verdict is HOLD (no p0).
      final messaging = _FakeMessaging([
        _node(id: 'n-1', spaceId: 'ch-1', authorId: 'a', kind: 'suggestion'),
      ]);
      // A gated, failing contract axis (deterministic engine) must escalate the
      // authoritative verdict to BLOCK.
      final axes = _FakeAxisRepo([
        const ReviewAxisResult(
          axis: ReviewAxis.apiContract,
          verdict: ReviewAxisVerdict.fail,
          findingsCount: 1,
          gated: true,
          confidence: 0.9,
        ),
      ]);
      final tool = FinalizeReviewTool(
        finalizer: ReviewFinalizer(
          messaging: messaging,
          reviewSpaces: _FakeReviewSpaces(assoc),
          reviewAxisResults: axes,
        ),
      );

      final result = await tool.call({
        'workspace_id': 'ws',
        'space_id': 'ch-1',
        'finalizer_id': 'ceo',
      });

      expect(result.isError, isFalse);
      final summary = messaging.sent.firstWhere(
        (m) => m['messageType'] == 'review_summary',
      );
      final metadata = summary['metadata'] as Map<String, dynamic>;
      expect(metadata['verdict'], 'block');
    });
  });
}
