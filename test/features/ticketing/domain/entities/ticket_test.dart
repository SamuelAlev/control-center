import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
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
    String? externalKey,
    String? url,
    String? description,
    String? rawStatus,
    String? channelId,
    String? assignedAgentId,
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
      externalKey: externalKey,
      url: url,
      description: description,
      rawStatus: rawStatus,
      channelId: channelId,
      assignedAgentId: assignedAgentId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('Ticket (dumb issue artifact)', () {
    test('rejects an empty title', () {
      expect(
        () => Ticket(
          id: 't',
          workspaceId: 'ws',
          title: '',
          status: TicketStatus.open,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isTerminal reflects status', () {
      expect(makeTicket(status: TicketStatus.open).isTerminal, isFalse);
      expect(makeTicket(status: TicketStatus.done).isTerminal, isTrue);
      expect(makeTicket(status: TicketStatus.failed).isTerminal, isTrue);
      expect(makeTicket(status: TicketStatus.cancelled).isTerminal, isTrue);
    });

    test('displayKey falls back to id when no external key', () {
      expect(makeTicket(externalKey: null).displayKey, 't1');
      expect(makeTicket(externalKey: 'LIN-1').displayKey, 'LIN-1');
    });

    test('copyWith updates kept fields', () {
      final t = makeTicket();
      final updated = t.copyWith(
        title: 'New',
        status: TicketStatus.inProgress,
        assignedAgentId: 'a1',
        channelId: 'chan-1',
        priority: TicketPriority.high,
      );
      expect(updated.title, 'New');
      expect(updated.status, TicketStatus.inProgress);
      expect(updated.assignedAgentId, 'a1');
      expect(updated.channelId, 'chan-1');
      expect(updated.priority, TicketPriority.high);
      // Untouched fields are preserved.
      expect(updated.id, t.id);
      expect(updated.workspaceId, t.workspaceId);
    });

    test('copyWith clear-flags null out nullable fields', () {
      final t = makeTicket(assignedAgentId: 'a1', channelId: 'chan-1');
      final updated = t.copyWith(
        removeAssignedAgentId: true,
        removeChannelId: true,
      );
      expect(updated.assignedAgentId, isNull);
      expect(updated.channelId, isNull);
    });

    test('equality keys on id, status, updatedAt', () {
      final a = makeTicket();
      final b = makeTicket();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      // A status or updatedAt change breaks equality.
      expect(a == makeTicket(status: TicketStatus.done), isFalse);
    });
  });
}
