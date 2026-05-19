import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime(2025, 1, 1);

  TicketCollaborator make({
    String id = 'c1',
    String ticketId = 't1',
    String agentId = 'agent-1',
    TicketCollaboratorRole role = TicketCollaboratorRole.collaborator,
  }) {
    return TicketCollaborator(
      id: id,
      ticketId: ticketId,
      agentId: agentId,
      role: role,
      joinedAt: ts,
    );
  }

  group('TicketCollaborator', () {
    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final c = make();
      expect(c.id, 'c1');
      expect(c.ticketId, 't1');
      expect(c.agentId, 'agent-1');
      expect(c.role, TicketCollaboratorRole.collaborator);
      expect(c.joinedAt, ts);
    });

    test('asserts agentId is not empty', timeout: const Timeout.factor(2), () {
      expect(
        () => make(agentId: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('userSentinel is "user"', timeout: const Timeout.factor(2), () {
      expect(TicketCollaborator.userSentinel, 'user');
    });

    test('isUser returns true when agentId is userSentinel', timeout: const Timeout.factor(2), () {
      expect(make(agentId: TicketCollaborator.userSentinel).isUser, isTrue);
      expect(make(agentId: 'some-agent').isUser, isFalse);
    });

    test('equality based on id, ticketId, agentId, role', timeout: const Timeout.factor(2), () {
      final a = make(id: 'x', ticketId: 't', agentId: 'a', role: TicketCollaboratorRole.assignee);
      final b = make(id: 'x', ticketId: 't', agentId: 'a', role: TicketCollaboratorRole.assignee);
      expect(a, equals(b));
    });

    test('inequality when fields differ', timeout: const Timeout.factor(2), () {
      final base = make(id: 'x');
      expect(base, isNot(equals(make(id: 'y'))));
      expect(base, isNot(equals(make(ticketId: 'other'))));
      expect(base, isNot(equals(make(agentId: 'other'))));
      expect(base, isNot(equals(make(role: TicketCollaboratorRole.reviewer))));
    });

    test('hashCode consistent with equality', timeout: const Timeout.factor(2), () {
      final a = make(id: 'x', ticketId: 't', agentId: 'a');
      final b = make(id: 'x', ticketId: 't', agentId: 'a');
      expect(a.hashCode, b.hashCode);
    });

    test('joinedAt difference does not affect equality', timeout: const Timeout.factor(2), () {
      final a = TicketCollaborator(
        id: 'c', ticketId: 't', agentId: 'a',
        joinedAt: DateTime(2025, 1, 1),
      );
      final b = TicketCollaborator(
        id: 'c', ticketId: 't', agentId: 'a',
        joinedAt: DateTime(2025, 12, 31),
      );
      expect(a, equals(b));
    });
  });

  group('TicketCollaboratorRole', () {
    test('has expected values', timeout: const Timeout.factor(2), () {
      expect(TicketCollaboratorRole.values, [
        TicketCollaboratorRole.assignee,
        TicketCollaboratorRole.collaborator,
        TicketCollaboratorRole.reviewer,
      ]);
    });

    group('fromStorage', () {
      test('maps canonical names', timeout: const Timeout.factor(2), () {
        for (final r in TicketCollaboratorRole.values) {
          expect(TicketCollaboratorRole.fromStorage(r.name), r);
        }
      });

      test('returns collaborator for null', timeout: const Timeout.factor(2), () {
        expect(TicketCollaboratorRole.fromStorage(null), TicketCollaboratorRole.collaborator);
      });

      test('throws on an unknown role string', timeout: const Timeout.factor(2), () {
        // Loud-fail hardening: a corrupt role must surface, not silently
        // downgrade to collaborator (which could grant wrong permissions).
        expect(
          () => TicketCollaboratorRole.fromStorage('unknown'),
          throwsArgumentError,
        );
      });
    });

    group('toStorageString', () {
      test('returns enum name', timeout: const Timeout.factor(2), () {
        expect(TicketCollaboratorRole.assignee.toStorageString(), 'assignee');
        expect(TicketCollaboratorRole.collaborator.toStorageString(), 'collaborator');
        expect(TicketCollaboratorRole.reviewer.toStorageString(), 'reviewer');
      });

      test('round-trips through fromStorage', timeout: const Timeout.factor(2), () {
        for (final r in TicketCollaboratorRole.values) {
          expect(TicketCollaboratorRole.fromStorage(r.toStorageString()), r);
        }
      });
    });
  });
}
