import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Ticket makeTicket({
    String id = 't1',
    String workspaceId = 'ws1',
    String title = 'Test ticket',
    TicketStatus status = TicketStatus.open,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketOriginKind originKind = TicketOriginKind.manual,
    List<String> labels = const [],
    int version = 0,
    ConversationMode mode = ConversationMode.chat,
    String? externalKey,
    String? url,
    String? description,
    String? rawStatus,
  }) {
    return Ticket(
      id: id,
      workspaceId: workspaceId,
      title: title,
      status: status,
      provider: provider,
      priority: priority,
      originKind: originKind,
      labels: labels,
      version: version,
      mode: mode,
      externalKey: externalKey,
      url: url,
      description: description,
      rawStatus: rawStatus,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 2),
    );
  }

  group('Ticket construction', () {
    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      expect(t.id, 't1');
      expect(t.workspaceId, 'ws1');
      expect(t.title, 'Test ticket');
      expect(t.status, TicketStatus.open);
      expect(t.provider, TicketProvider.local);
      expect(t.priority, TicketPriority.none);
      expect(t.originKind, TicketOriginKind.manual);
      expect(t.version, 0);
      expect(t.mode, ConversationMode.chat);
    });

    test('asserts title is not empty', timeout: const Timeout.factor(2), () {
      expect(
        () => makeTicket(title: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('defaults nullable fields to null', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      expect(t.externalKey, isNull);
      expect(t.url, isNull);
      expect(t.description, isNull);
      expect(t.rawStatus, isNull);
      expect(t.parentTicketId, isNull);
      expect(t.projectId, isNull);
      expect(t.assignedAgentId, isNull);
      expect(t.assignedTeamId, isNull);
      expect(t.delegatedByAgentId, isNull);
      expect(t.channelId, isNull);
      expect(t.pipelineRunId, isNull);
      expect(t.pipelineStepId, isNull);
      expect(t.expectedOutputSchema, isNull);
      expect(t.outputJson, isNull);
      expect(t.errorMessage, isNull);
      expect(t.startedAt, isNull);
      expect(t.blockedAt, isNull);
      expect(t.cancelledAt, isNull);
      expect(t.completedAt, isNull);
      expect(t.finishedAt, isNull);
      expect(t.checkoutRunId, isNull);
      expect(t.executionLockedAt, isNull);
      expect(t.checkoutAgentId, isNull);
      expect(t.executionPolicyJson, isNull);
      expect(t.executionStateJson, isNull);
      expect(t.recoveryActionsJson, isNull);
    });

    test('defaults collection fields to empty', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      expect(t.labels, isEmpty);
      expect(t.linkedPrIds, isEmpty);
      expect(t.metadata, isEmpty);
      expect(t.collaborators, isEmpty);
    });
  });

  group('computed properties', () {
    test('isTerminal delegates to status', timeout: const Timeout.factor(2), () {
      expect(makeTicket(status: TicketStatus.done).isTerminal, isTrue);
      expect(makeTicket(status: TicketStatus.failed).isTerminal, isTrue);
      expect(makeTicket(status: TicketStatus.cancelled).isTerminal, isTrue);
      expect(makeTicket(status: TicketStatus.open).isTerminal, isFalse);
      expect(makeTicket(status: TicketStatus.inProgress).isTerminal, isFalse);
    });

    test('isRemote delegates to provider', timeout: const Timeout.factor(2), () {
      expect(makeTicket(provider: TicketProvider.local).isRemote, isFalse);
      expect(makeTicket(provider: TicketProvider.linear).isRemote, isTrue);
      expect(makeTicket(provider: TicketProvider.jira).isRemote, isTrue);
      expect(makeTicket(provider: TicketProvider.clickup).isRemote, isTrue);
    });

    test('displayKey returns externalKey when present', timeout: const Timeout.factor(2), () {
      final t = makeTicket(externalKey: 'LIN-42');
      expect(t.displayKey, 'LIN-42');
    });

    test('displayKey falls back to id', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      expect(t.displayKey, 't1');
    });
  });

  group('copyWith', () {
    test('returns new instance with updated fields', timeout: const Timeout.factor(2), () {
      final original = makeTicket();
      final copy = original.copyWith(
        title: 'Updated',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        version: 3,
      );
      expect(copy.title, 'Updated');
      expect(copy.status, TicketStatus.inProgress);
      expect(copy.priority, TicketPriority.high);
      expect(copy.version, 3);
      // id and workspaceId preserved
      expect(copy.id, original.id);
      expect(copy.workspaceId, original.workspaceId);
    });

    test('removes nullable field with remove flag', timeout: const Timeout.factor(2), () {
      final t = makeTicket(externalKey: 'LIN-1');
      expect(t.externalKey, 'LIN-1');
      final cleared = t.copyWith(removeExternalKey: true);
      expect(cleared.externalKey, isNull);
    });

    test('clears description via removeDescription', timeout: const Timeout.factor(2), () {
      final t = makeTicket(description: 'some desc');
      expect(t.description, 'some desc');
      final cleared = t.copyWith(removeDescription: true);
      expect(cleared.description, isNull);
    });

    test('clears multiple nullable fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 6, 1);
      final t = Ticket(
        id: 't1',
        workspaceId: 'ws1',
        title: 'Test',
        status: TicketStatus.open,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        url: 'https://example.com',
        rawStatus: 'In Progress',
        parentTicketId: 'parent-1',
        projectId: 'proj-1',
        assignedAgentId: 'agent-1',
        assignedTeamId: 'team-1',
        delegatedByAgentId: 'delegator-1',
        channelId: 'ch-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
        expectedOutputSchema: {'type': 'object'},
        outputJson: {'result': 42},
        errorMessage: 'oops',
        startedAt: now,
        blockedAt: now,
        cancelledAt: now,
        completedAt: now,
        finishedAt: now,
        checkoutRunId: 'cr-1',
        executionLockedAt: now,
        checkoutAgentId: 'ca-1',
        executionPolicyJson: '{}',
        executionStateJson: '{}',
        recoveryActionsJson: '[]',
      );
      final cleared = t.copyWith(
        removeUrl: true,
        removeRawStatus: true,
        removeParentTicketId: true,
        removeProjectId: true,
        removeAssignedAgentId: true,
        removeAssignedTeamId: true,
        removeDelegatedByAgentId: true,
        removeChannelId: true,
        removePipelineRunId: true,
        removePipelineStepId: true,
        removeExpectedOutputSchema: true,
        removeOutputJson: true,
        removeErrorMessage: true,
        removeStartedAt: true,
        removeBlockedAt: true,
        removeCancelledAt: true,
        removeCompletedAt: true,
        removeFinishedAt: true,
        removeCheckoutRunId: true,
        removeExecutionLockedAt: true,
        removeCheckoutAgentId: true,
        removeExecutionPolicyJson: true,
        removeExecutionStateJson: true,
        removeRecoveryActionsJson: true,
      );
      expect(cleared.url, isNull);
      expect(cleared.rawStatus, isNull);
      expect(cleared.parentTicketId, isNull);
      expect(cleared.projectId, isNull);
      expect(cleared.assignedAgentId, isNull);
      expect(cleared.assignedTeamId, isNull);
      expect(cleared.delegatedByAgentId, isNull);
      expect(cleared.channelId, isNull);
      expect(cleared.pipelineRunId, isNull);
      expect(cleared.pipelineStepId, isNull);
      expect(cleared.expectedOutputSchema, isNull);
      expect(cleared.outputJson, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.startedAt, isNull);
      expect(cleared.blockedAt, isNull);
      expect(cleared.cancelledAt, isNull);
      expect(cleared.completedAt, isNull);
      expect(cleared.finishedAt, isNull);
      expect(cleared.checkoutRunId, isNull);
      expect(cleared.executionLockedAt, isNull);
      expect(cleared.checkoutAgentId, isNull);
      expect(cleared.executionPolicyJson, isNull);
      expect(cleared.executionStateJson, isNull);
      expect(cleared.recoveryActionsJson, isNull);
    });

    test('preserves fields when no arguments given', timeout: const Timeout.factor(2), () {
      final original = makeTicket(
        title: 'Keep me',
        description: 'desc',
        version: 5,
      );
      final copy = original.copyWith();
      expect(copy.title, original.title);
      expect(copy.description, original.description);
      expect(copy.version, original.version);
      expect(copy.id, original.id);
    });

    test('replaces collection fields', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      final copy = t.copyWith(
        labels: ['bug', 'urgent'],
        linkedPrIds: ['pr-1'],
        metadata: {'key': 'value'},
      );
      expect(copy.labels, ['bug', 'urgent']);
      expect(copy.linkedPrIds, ['pr-1']);
      expect(copy.metadata, {'key': 'value'});
    });
  });

  group('equality', () {
    test('equal when id, status, updatedAt match', timeout: const Timeout.factor(2), () {
      final a = makeTicket(id: 'x', status: TicketStatus.open, version: 0);
      // updatedAt is in the constructor; same id/status/updatedAt → equal
      final b = makeTicket(id: 'x', status: TicketStatus.open, version: 0);
      expect(a, equals(b));
    });

    test('not equal when id differs', timeout: const Timeout.factor(2), () {
      final a = makeTicket(id: 'a');
      final b = makeTicket(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('not equal when status differs', timeout: const Timeout.factor(2), () {
      final a = makeTicket(status: TicketStatus.open);
      final b = makeTicket(status: TicketStatus.done);
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', timeout: const Timeout.factor(2), () {
      final a = makeTicket(id: 'x', status: TicketStatus.open, version: 0);
      final b = makeTicket(id: 'x', status: TicketStatus.open, version: 0);
      expect(a.hashCode, b.hashCode);
    });

    test('identical instance is equal', timeout: const Timeout.factor(2), () {
      final t = makeTicket();
      expect(t, equals(t));
    });
  });
}
