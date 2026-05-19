import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 1);

  group('EventPayloadMapper', () {
    // ── toPayload ───────────────────────────────────────────────────────

    test('toPayload maps ExternalPrDetected',
        timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'acme',
        repoName: 'app',
        prNumber: 42,
        prTitle: 'Fix bug',
        author: 'octocat',
        workspaceId: null,
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['repoOwner'], 'acme');
      expect(payload['repoName'], 'app');
      expect(payload['prNumber'], 42);
      expect(payload['prTitle'], 'Fix bug');
      expect(payload['author'], 'octocat');
    });

    test('toPayload maps PullRequestPublished',
        timeout: const Timeout.factor(2), () {
      final event = PullRequestPublished(
        prId: 'pr-123',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'app',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['prId'], 'pr-123');
      expect(payload['workspaceId'], 'ws-1');
      expect(payload['repoOwner'], 'acme');
      expect(payload['repoName'], 'app');
    });

    test('toPayload maps PrMerged', timeout: const Timeout.factor(2), () {
      final event = PrMerged(
        prId: 'pr-123',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['prId'], 'pr-123');
      expect(payload['workspaceId'], 'ws-1');
      expect(payload['agentId'], 'agent-1');
    });

    test('toPayload maps PullRequestStatusChanged',
        timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'merged',
        occurredAt: now,
        prId: 'pr-123',
        workspaceId: 'ws-1',
        repoFullName: 'acme/app',
        prNumber: 42,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['status'], 'merged');
      expect(payload['prId'], 'pr-123');
      expect(payload['workspaceId'], 'ws-1');
      expect(payload['repoFullName'], 'acme/app');
      expect(payload['prNumber'], 42);
    });

    test('toPayload maps PullRequestStatusChanged with null optional fields',
        timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'opened',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['status'], 'opened');
      expect(payload.containsKey('prId'), isFalse);
      expect(payload.containsKey('workspaceId'), isFalse);
    });

    test('toPayload maps MessageReceived', timeout: const Timeout.factor(2), () {
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'Alice',
        contentPreview: 'hello',
        isAgentMessage: false,
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['channelId'], 'ch-1');
      expect(payload['messageId'], 'msg-1');
      expect(payload['senderName'], 'Alice');
      expect(payload['contentPreview'], 'hello');
      expect(payload['isAgentMessage'], isFalse);
    });

    test('toPayload maps TicketCompleted', timeout: const Timeout.factor(2), () {
      final event = TicketCompleted(
        ticketId: 't-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['ticketId'], 't-1');
    });

    test('toPayload maps TicketFailed', timeout: const Timeout.factor(2), () {
      final event = TicketFailed(
        ticketId: 't-1',
        errorMessage: 'boom',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['ticketId'], 't-1');
      expect(payload['errorMessage'], 'boom');
    });

    test('toPayload maps TicketCancelled', timeout: const Timeout.factor(2), () {
      final event = TicketCancelled(
        ticketId: 't-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['ticketId'], 't-1');
    });

    test('toPayload maps BudgetThresholdCrossed',
        timeout: const Timeout.factor(2), () {
      final event = BudgetThresholdCrossed(
        scopeType: 'workspace',
        scopeId: 'ws-1',
        spentCents: 1000,
        budgetCents: 5000,
        isHardStop: false,
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['scopeType'], 'workspace');
      expect(payload['scopeId'], 'ws-1');
      expect(payload['spentCents'], 1000);
      expect(payload['budgetCents'], 5000);
      expect(payload['isHardStop'], isFalse);
    });

    test('toPayload maps TicketAssigned', timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Fix bug',
        ticketBody: 'Description',
        ticketUrl: 'https://example.com/t/1',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['ticketId'], 't-1');
      expect(payload['ticketTitle'], 'Fix bug');
      expect(payload['ticketBody'], 'Description');
      expect(payload['ticketUrl'], 'https://example.com/t/1');
      expect(payload['workspaceId'], 'ws-1');
    });

    test('toPayload maps TicketAssigned with null optionals',
        timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Bug',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['ticketId'], 't-1');
      expect(payload.containsKey('ticketBody'), isFalse);
      expect(payload.containsKey('ticketUrl'), isFalse);
    });

    test('toPayload maps RepoAdded', timeout: const Timeout.factor(2), () {
      final event = RepoAdded(
        repoId: 'r-1',
        path: '/path/to/repo',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['repoId'], 'r-1');
      expect(payload['repoLocalPath'], '/path/to/repo');
      expect(payload['workspaceId'], 'ws-1');
    });

    test('toPayload maps MeetingRecordingStopped',
        timeout: const Timeout.factor(2), () {
      final event = MeetingRecordingStopped(
        workspaceId: 'ws-1',
        meetingId: 'meet-42',
        title: 'Sprint review',
        userNotes: 'Discuss blockers',
        transcript: 'Alice: hello\nBob: hi',
        occurredAt: now,
      );
      final payload = EventPayloadMapper.toPayload(event)!;
      expect(payload['workspaceId'], 'ws-1');
      expect(payload['meetingId'], 'meet-42');
      expect(payload['title'], 'Sprint review');
      expect(payload['userNotes'], 'Discuss blockers');
      expect(payload['transcript'], 'Alice: hello\nBob: hi');
    });

    test('toPayload returns null for unmapped event',
        timeout: const Timeout.factor(2), () {
      final event = TicketCreated(ticketId: 't-1', occurredAt: now);
      expect(EventPayloadMapper.toPayload(event), isNull);
    });

    test('toPayload returns null for TicketDelegated', () {
      final event = TicketDelegated(
        ticketId: 't-1',
        parentTicketId: 't-2',
        occurredAt: now,
      );
      expect(EventPayloadMapper.toPayload(event), isNull);
    });

    // ── typeName ────────────────────────────────────────────────────────

    test('typeName returns runtime type name',
        timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'a',
        repoName: 'b',
        prNumber: 1,
        prTitle: 't',
        author: 'u',
        workspaceId: null,
        occurredAt: now,
      );
      expect(EventPayloadMapper.typeName(event), 'ExternalPrDetected');
    });

    test('typeName returns MeetingRecordingStopped for meeting events', () {
      final event = MeetingRecordingStopped(
        workspaceId: 'ws',
        meetingId: 'm',
        title: 't',
        userNotes: '',
        transcript: '',
        occurredAt: now,
      );
      expect(
        EventPayloadMapper.typeName(event), 'MeetingRecordingStopped');
    });

    // ── knownEventTypes ─────────────────────────────────────────────────

    test('knownEventTypes contains expected types',
        timeout: const Timeout.factor(2), () {
      expect(EventPayloadMapper.knownEventTypes, containsAll([
        'ExternalPrDetected',
        'PullRequestPublished',
        'PullRequestStatusChanged',
        'PrMerged',
        'MessageReceived',
        'TicketCompleted',
        'TicketFailed',
        'TicketCancelled',
        'BudgetThresholdCrossed',
        'TicketAssigned',
        'RepoAdded',
        'MeetingRecordingStopped',
      ]));
    });

    test('knownEventTypes is non-empty list of strings', () {
      expect(EventPayloadMapper.knownEventTypes, isNotEmpty);
      for (final type in EventPayloadMapper.knownEventTypes) {
        expect(type, isA<String>());
        expect(type, isNotEmpty);
      }
    });
  });

  group('EventPayloadMapper.dedupKeyFor', () {
    test('ExternalPrDetected dedup key', timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'acme',
        repoName: 'app',
        prNumber: 42,
        prTitle: '',
        author: '',
        workspaceId: null,
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'acme/app#42');
    });

    test('PullRequestPublished dedup key', timeout: const Timeout.factor(2), () {
      final event = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws',
        repoOwner: 'a',
        repoName: 'b',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'pr-1');
    });

    test('PrMerged dedup key', timeout: const Timeout.factor(2), () {
      final event = PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws',
        agentId: 'a',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'pr-1');
    });

    test('PullRequestStatusChanged dedup key with prId',
        timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'merged',
        occurredAt: now,
        prId: 'pr-1',
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'pr-1:merged');
    });

    test('PullRequestStatusChanged dedup key with repo + number',
        timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'closed',
        occurredAt: now,
        repoFullName: 'acme/app',
        prNumber: 5,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'acme/app#5:closed');
    });

    test('PullRequestStatusChanged dedup key with neither prId nor repo info returns null',
        () {
      final event = PullRequestStatusChanged(
        status: 'opened',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), isNull);
    });

    test('MessageReceived dedup key', timeout: const Timeout.factor(2), () {
      final event = MessageReceived(
        channelId: 'ch',
        messageId: 'msg-1',
        senderName: '',
        contentPreview: '',
        isAgentMessage: false,
        workspaceId: null,
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'msg-1');
    });

    test('TicketCompleted dedup key', timeout: const Timeout.factor(2), () {
      final event = TicketCompleted(ticketId: 't-1', occurredAt: now);
      expect(EventPayloadMapper.dedupKeyFor(event), 't-1');
    });

    test('TicketFailed dedup key', timeout: const Timeout.factor(2), () {
      final event = TicketFailed(
        ticketId: 't-1',
        errorMessage: 'err',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 't-1');
    });

    test('TicketCancelled dedup key', timeout: const Timeout.factor(2), () {
      final event = TicketCancelled(ticketId: 't-1', occurredAt: now);
      expect(EventPayloadMapper.dedupKeyFor(event), 't-1');
    });

    test('BudgetThresholdCrossed dedup key', timeout: const Timeout.factor(2), () {
      final event = BudgetThresholdCrossed(
        scopeType: 'workspace',
        scopeId: 'ws-1',
        spentCents: 100,
        budgetCents: 500,
        isHardStop: false,
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'workspace/ws-1');
    });

    test('TicketAssigned dedup key', timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: '',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 't-1');
    });

    test('RepoAdded dedup key includes workspace',
        timeout: const Timeout.factor(2), () {
      final event = RepoAdded(
        repoId: 'r-1',
        path: '/p',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'ws-1:r-1');
    });

    test('MeetingRecordingStopped dedup key is meetingId', () {
      final event = MeetingRecordingStopped(
        workspaceId: 'ws-1',
        meetingId: 'meet-42',
        title: 't',
        userNotes: '',
        transcript: '',
        occurredAt: now,
      );
      expect(EventPayloadMapper.dedupKeyFor(event), 'meet-42');
    });

    test('unmapped event returns null dedup key',
        timeout: const Timeout.factor(2), () {
      final event = TicketCreated(ticketId: 't-1', occurredAt: now);
      expect(EventPayloadMapper.dedupKeyFor(event), isNull);
    });

    test('TicketStarted returns null dedup key', () {
      final event = TicketStarted(ticketId: 't-1', occurredAt: now);
      expect(EventPayloadMapper.dedupKeyFor(event), isNull);
    });
  });
}
