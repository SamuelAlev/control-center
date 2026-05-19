import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketProvider', () {
    group('fromStorage', () {
      test('maps all canonical names', timeout: const Timeout.factor(2), () {
        for (final p in TicketProvider.values) {
          expect(TicketProvider.fromStorage(p.name), p);
        }
      });

      test('returns local for null', timeout: const Timeout.factor(2), () {
        expect(TicketProvider.fromStorage(null), TicketProvider.local);
      });

      test('returns local for unknown string', timeout: const Timeout.factor(2), () {
        expect(TicketProvider.fromStorage('unknown'), TicketProvider.local);
        expect(TicketProvider.fromStorage(''), TicketProvider.local);
      });
    });

    group('toStorageString', () {
      test('returns the enum name', timeout: const Timeout.factor(2), () {
        expect(TicketProvider.local.toStorageString(), 'local');
        expect(TicketProvider.linear.toStorageString(), 'linear');
        expect(TicketProvider.jira.toStorageString(), 'jira');
        expect(TicketProvider.clickup.toStorageString(), 'clickup');
      });

      test('round-trips through fromStorage', timeout: const Timeout.factor(2), () {
        for (final p in TicketProvider.values) {
          expect(TicketProvider.fromStorage(p.toStorageString()), p);
        }
      });
    });

    group('isRemote', () {
      test('local is not remote', timeout: const Timeout.factor(2), () {
        expect(TicketProvider.local.isRemote, isFalse);
      });

      test('linear, jira, clickup are remote', timeout: const Timeout.factor(2), () {
        expect(TicketProvider.linear.isRemote, isTrue);
        expect(TicketProvider.jira.isRemote, isTrue);
        expect(TicketProvider.clickup.isRemote, isTrue);
      });
    });

    test('has exactly four values', timeout: const Timeout.factor(2), () {
      expect(TicketProvider.values, hasLength(4));
    });
  });
}
