import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_infra/src/pr_review/review_finding_status_service.dart';
import 'package:test/test.dart';

const _ws = 'ws';
const _space = 'space-1';

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this.messages);

  final List<Message> messages;
  final List<Map<String, dynamic>> sent = [];
  final Map<String, Map<String, dynamic>> updatedMetadata = {};

  @override
  Future<List<Message>> getSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async => messages;

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    if (metadata != null) {
      updatedMetadata[messageId] = metadata;
    }
  }

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    sent.add({
      'content': content,
      'conversationId': conversationId,
      'messageType': messageType,
    });
    return 'msg-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  final ReviewSpaceAssociation? association;

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(association);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSnapshots implements ReviewRunSnapshotRepository {
  final applied = <(String, String, ReviewNodeStatus)>[];

  @override
  Future<int> applyFindingStatus(
    String workspaceId,
    String prExternalId,
    String nodeMessageId,
    ReviewNodeStatus status,
  ) async {
    applied.add((prExternalId, nodeMessageId, status));
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFacts implements MemoryFactRepository {
  final List<MemoryFact> stored = [];

  @override
  Future<void> upsert(MemoryFact fact) async => stored.add(fact);

  @override
  Future<List<MemoryFact>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) async => stored.where((f) => f.topic == topic).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDomains implements MemoryDomainRepository {
  final List<MemoryDomain> stored = [];

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) async {
    for (final d in stored) {
      if (d.name == name) {
        return d;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(MemoryDomain domain) async => stored.add(domain);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGrants implements MemoryAccessGrantRepository {
  @override
  Future<void> upsert(MemoryAccessGrant grant) async {}

  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Message _finding({
  String id = 'find-1',
  String conversationId = 'conv-reviewer-qa',
  ReviewNodeStatus status = ReviewNodeStatus.open,
  String? filePath = 'lib/a.dart',
  String content = 'Guard the null case\n\nMechanism…',
}) => Message(
  id: id,
  spaceId: _space,
  conversationId: conversationId,
  senderId: 'qa',
  senderType: SenderType.agent,
  content: content,
  messageType: MessageType.reviewNode,
  metadata: ReviewNodePayload(
    kind: ReviewNodeKind.bug,
    priority: ReviewNodePriority.p1,
    confidence: 0.9,
    anchor: ReviewNodeAnchor(filePath: filePath, lineNumber: 12),
    status: status,
  ).toMetadata(),
  createdAt: DateTime.utc(2026),
);

ReviewSpaceAssociation _assoc() => ReviewSpaceAssociation(
  id: 'assoc-1',
  spaceId: _space,
  workspaceId: _ws,
  prExternalId: 'acme/widget#42',
  prNumber: 42,
  repoFullName: 'acme/widget',
  status: ReviewSpaceStatus.awaitingApproval,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('ReviewFindingStatusService', () {
    late _FakeMessaging messaging;
    late _FakeSnapshots snapshots;
    late _FakeFacts facts;
    late _FakeDomains domains;

    ReviewFindingStatusService build({
      List<Message>? messages,
      bool inReviewSpace = true,
      bool withMemory = true,
    }) {
      messaging = _FakeMessaging(messages ?? [_finding()]);
      snapshots = _FakeSnapshots();
      facts = _FakeFacts();
      domains = _FakeDomains();
      return ReviewFindingStatusService(
        messaging: messaging,
        reviewSpaces: _FakeReviewSpaces(inReviewSpace ? _assoc() : null),
        runSnapshots: snapshots,
        memoryFacts: withMemory ? facts : null,
        resolveDomain: withMemory
            ? ResolveOrCreateDomainUseCase(
                domainRepository: domains,
                grantRepository: _FakeGrants(),
              )
            : null,
      );
    }

    Future<ReviewFindingStatusChange> set(
      ReviewFindingStatusService s,
      ReviewNodeStatus status, {
      String id = 'find-1',
      String? reason,
    }) => s.setStatus(
      workspaceId: _ws,
      spaceId: _space,
      nodeMessageId: id,
      status: status,
      actorLabel: 'Sam',
      reason: reason,
    );

    test('resolving writes a status the parser can read back', () async {
      // The point of the typed write: `actionRate` counts resolved findings,
      // and a status pasted into the raw map is one `fromMetadata` may not
      // return — which is how the metric read structurally zero before.
      final s = build();
      final change = await set(s, ReviewNodeStatus.resolved);

      expect(change.previousStatus, ReviewNodeStatus.open);
      expect(change.status, ReviewNodeStatus.resolved);
      expect(change.suppressionRecorded, isFalse);

      final written = ReviewNodePayload.fromMetadata(
        messaging.updatedMetadata['find-1'],
      );
      expect(written, isNotNull);
      expect(written!.status, ReviewNodeStatus.resolved);
      // Everything else survives the round-trip.
      expect(written.priority, ReviewNodePriority.p1);
      expect(written.kind, ReviewNodeKind.bug);
      expect(written.anchor.filePath, 'lib/a.dart');
      expect(written.anchor.lineNumber, 12);
    });

    test('the decision reaches the finalized pass, not just the bubble', () async {
      // A pass freezes its findings' statuses when it ends and a person always
      // decides afterwards. Without this write-back `actionRate` has a
      // structurally zero numerator and the suppression memory never sees a
      // dismissal — which was exactly the state before this surface existed.
      final s = build();
      await set(s, ReviewNodeStatus.resolved);

      expect(snapshots.applied, hasLength(1));
      expect(
        snapshots.applied.single,
        ('acme/widget#42', 'find-1', ReviewNodeStatus.resolved),
      );
    });

    test('nothing is written back outside a review space', () async {
      final s = build(inReviewSpace: false);
      await set(s, ReviewNodeStatus.resolved);
      expect(snapshots.applied, isEmpty);
    });

    test('the trace lands in the reviewer stream that filed it', () async {
      // Not the standing conversation: a trace in a thread nobody reading the
      // finding is looking at explains nothing.
      final s = build();
      await set(s, ReviewNodeStatus.resolved);

      expect(messaging.sent, hasLength(1));
      expect(messaging.sent.single['conversationId'], 'conv-reviewer-qa');
      expect(messaging.sent.single['messageType'], 'system');
      expect(messaging.sent.single['content'], contains('Sam'));
    });

    test('a no-op status change leaves no trace', () async {
      // Two clicks on "Fixed" is one fact, not two lines in the room.
      final s = build(
        messages: [_finding(status: ReviewNodeStatus.resolved)],
      );
      final change = await set(s, ReviewNodeStatus.resolved);

      expect(change.previousStatus, ReviewNodeStatus.resolved);
      expect(messaging.sent, isEmpty);
    });

    test('dismissing records a suppression fact carrying the reason', () async {
      final s = build();
      final change = await set(
        s,
        ReviewNodeStatus.dismissed,
        reason: 'That path is unreachable — the caller validates first.',
      );

      expect(change.suppressionRecorded, isTrue);
      expect(facts.stored, hasLength(1));
      final fact = facts.stored.single;
      expect(fact.domain, ReviewFindingStatusService.suppressionDomain);
      expect(fact.topic, contains('lib/a.dart'));
      expect(fact.content, contains('unreachable'));
      expect(fact.content, contains('do not re-flag'));
      // Soft: one dismissal is a preference, not a rule.
      expect(fact.confidence, lessThan(1.0));
      expect(fact.authoredByRole, AgentRole.reviewer);
      expect(domains.stored.single.name, 'review-suppressions');
    });

    test('an identical dismissal does not double-count', () async {
      // The matcher reads repetition as strength; a duplicate would inflate it
      // without anyone having dismissed the pattern twice.
      final s = build();
      await set(s, ReviewNodeStatus.dismissed, reason: 'By design.');
      await set(s, ReviewNodeStatus.dismissed, reason: 'By design.');
      expect(facts.stored, hasLength(1));
    });

    test('resolving records nothing to suppress', () async {
      // "Fixed" says the finding was right. Teaching reviewers to stop
      // reporting it would suppress the one kind of finding that worked.
      final s = build();
      await set(s, ReviewNodeStatus.resolved);
      expect(facts.stored, isEmpty);
    });

    test('a dismissal still lands when the memory lane is absent', () async {
      // Losing the lesson is bad; losing the dismissal because the lesson
      // failed to save is worse.
      final s = build(withMemory: false);
      final change = await set(s, ReviewNodeStatus.dismissed, reason: 'No.');

      expect(change.status, ReviewNodeStatus.dismissed);
      expect(change.suppressionRecorded, isFalse);
      expect(messaging.updatedMetadata, contains('find-1'));
    });

    test('an unknown finding is refused, not silently ignored', () async {
      final s = build();
      await expectLater(
        set(s, ReviewNodeStatus.resolved, id: 'nope'),
        throwsA(isA<ReviewFindingNotFound>()),
      );
      expect(messaging.updatedMetadata, isEmpty);
    });

    test('a message that is not a finding is refused', () async {
      // Id collisions across message types would otherwise let a status write
      // land on an ordinary chat bubble.
      final s = build(
        messages: [
          Message(
            id: 'find-1',
            spaceId: _space,
            conversationId: 'conv-1',
            senderId: 'sam',
            senderType: SenderType.user,
            content: 'looks good',
            messageType: MessageType.text,
            createdAt: DateTime.utc(2026),
          ),
        ],
      );
      await expectLater(
        set(s, ReviewNodeStatus.resolved),
        throwsA(isA<ReviewFindingNotFound>()),
      );
    });

    test('reopening moves back to open and says so', () async {
      final s = build(
        messages: [_finding(status: ReviewNodeStatus.dismissed)],
      );
      final change = await set(s, ReviewNodeStatus.open);

      expect(change.previousStatus, ReviewNodeStatus.dismissed);
      expect(change.status, ReviewNodeStatus.open);
      expect(
        ReviewNodePayload.fromMetadata(
          messaging.updatedMetadata['find-1'],
        )!.status,
        ReviewNodeStatus.open,
      );
      expect(messaging.sent.single['content'], contains('reopened'));
    });

    test('a dismissal outside a review space still lands', () async {
      final s = build(inReviewSpace: false);
      final change = await set(s, ReviewNodeStatus.dismissed, reason: 'n/a');
      expect(change.status, ReviewNodeStatus.dismissed);
      expect(change.suppressionRecorded, isFalse);
      expect(facts.stored, isEmpty);
    });

    test('a finding with no file path still yields a usable topic', () async {
      final s = build(
        messages: [_finding(filePath: null, content: 'Broad design concern')],
      );
      await set(s, ReviewNodeStatus.dismissed, reason: 'Known.');
      expect(facts.stored.single.topic, contains('Broad design concern'));
    });
  });
}
