import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime(2025, 1, 1);

  TicketCollaborator make({
    String id = 'c1',
    String ticketId = 't1',
    String principalId = 'agent-1',
    PrincipalType collaboratorType = PrincipalType.agent,
    TicketCollaboratorRole role = TicketCollaboratorRole.collaborator,
  }) {
    return TicketCollaborator(
      id: id,
      ticketId: ticketId,
      principalId: principalId,
      collaboratorType: collaboratorType,
      role: role,
      joinedAt: ts,
    );
  }

  group('TicketCollaborator', () {
    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final c = make();
      expect(c.id, 'c1');
      expect(c.ticketId, 't1');
      expect(c.principalId, 'agent-1');
      expect(c.collaboratorType, PrincipalType.agent);
      expect(c.role, TicketCollaboratorRole.collaborator);
      expect(c.joinedAt, ts);
    });

    test(
      'asserts principalId is not empty',
      timeout: const Timeout.factor(2),
      () {
        expect(() => make(principalId: ''), throwsA(isA<ArgumentError>()));
      },
    );

    test(
      'collaboratorType defaults to agent',
      timeout: const Timeout.factor(2),
      () {
        expect(make().collaboratorType, PrincipalType.agent);
      },
    );

    test(
      'isUser returns true when collaboratorType is user',
      timeout: const Timeout.factor(2),
      () {
        expect(
          make(
            principalId: 'user-1',
            collaboratorType: PrincipalType.user,
          ).isUser,
          isTrue,
        );
        expect(make(principalId: 'some-agent').isUser, isFalse);
        // Type-driven, never id-driven: an agent whose id happens to be 'user'
        // is still not a human.
        expect(make(principalId: 'user').isUser, isFalse);
      },
    );

    test(
      'equality based on id, ticketId, principalId, type, role',
      timeout: const Timeout.factor(2),
      () {
        final a = make(
          id: 'x',
          ticketId: 't',
          principalId: 'a',
          role: TicketCollaboratorRole.assignee,
        );
        final b = make(
          id: 'x',
          ticketId: 't',
          principalId: 'a',
          role: TicketCollaboratorRole.assignee,
        );
        expect(a, equals(b));
      },
    );

    test('inequality when fields differ', timeout: const Timeout.factor(2), () {
      final base = make(id: 'x');
      expect(base, isNot(equals(make(id: 'y'))));
      expect(base, isNot(equals(make(ticketId: 'other'))));
      expect(base, isNot(equals(make(principalId: 'other'))));
      expect(base, isNot(equals(make(collaboratorType: PrincipalType.user))));
      expect(base, isNot(equals(make(role: TicketCollaboratorRole.reviewer))));
    });

    test(
      'hashCode consistent with equality',
      timeout: const Timeout.factor(2),
      () {
        final a = make(id: 'x', ticketId: 't', principalId: 'a');
        final b = make(id: 'x', ticketId: 't', principalId: 'a');
        expect(a.hashCode, b.hashCode);
      },
    );

    test(
      'joinedAt difference does not affect equality',
      timeout: const Timeout.factor(2),
      () {
        final a = TicketCollaborator(
          id: 'c',
          ticketId: 't',
          principalId: 'a',
          joinedAt: DateTime(2025, 1, 1),
        );
        final b = TicketCollaborator(
          id: 'c',
          ticketId: 't',
          principalId: 'a',
          joinedAt: DateTime(2025, 12, 31),
        );
        expect(a, equals(b));
      },
    );
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

      test(
        'returns collaborator for null',
        timeout: const Timeout.factor(2),
        () {
          expect(
            TicketCollaboratorRole.fromStorage(null),
            TicketCollaboratorRole.collaborator,
          );
        },
      );

      test(
        'throws on an unknown role string',
        timeout: const Timeout.factor(2),
        () {
          // Loud-fail hardening: a corrupt role must surface, not silently
          // downgrade to collaborator (which could grant wrong permissions).
          expect(
            () => TicketCollaboratorRole.fromStorage('unknown'),
            throwsArgumentError,
          );
        },
      );
    });

    group('toStorageString', () {
      test('returns enum name', timeout: const Timeout.factor(2), () {
        expect(TicketCollaboratorRole.assignee.toStorageString(), 'assignee');
        expect(
          TicketCollaboratorRole.collaborator.toStorageString(),
          'collaborator',
        );
        expect(TicketCollaboratorRole.reviewer.toStorageString(), 'reviewer');
      });

      test(
        'round-trips through fromStorage',
        timeout: const Timeout.factor(2),
        () {
          for (final r in TicketCollaboratorRole.values) {
            expect(TicketCollaboratorRole.fromStorage(r.toStorageString()), r);
          }
        },
      );
    });
  });
}
