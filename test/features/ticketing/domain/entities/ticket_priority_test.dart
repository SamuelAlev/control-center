import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketPriority', () {
    group('fromStorage', () {
      test('maps known integer values', timeout: const Timeout.factor(2), () {
        expect(TicketPriority.fromStorage(0), TicketPriority.none);
        expect(TicketPriority.fromStorage(1), TicketPriority.urgent);
        expect(TicketPriority.fromStorage(2), TicketPriority.high);
        expect(TicketPriority.fromStorage(3), TicketPriority.medium);
        expect(TicketPriority.fromStorage(4), TicketPriority.low);
      });

      test('returns none for null', timeout: const Timeout.factor(2), () {
        expect(TicketPriority.fromStorage(null), TicketPriority.none);
      });

      test('returns none for unknown values', timeout: const Timeout.factor(2), () {
        expect(TicketPriority.fromStorage(-1), TicketPriority.none);
        expect(TicketPriority.fromStorage(5), TicketPriority.none);
        expect(TicketPriority.fromStorage(99), TicketPriority.none);
      });
    });

    group('toStorageInt', () {
      test('returns index matching fromStorage round-trip', timeout: const Timeout.factor(2), () {
        for (final p in TicketPriority.values) {
          expect(TicketPriority.fromStorage(p.toStorageInt()), p);
        }
      });

      test('index values match Linear 0..4 scale', timeout: const Timeout.factor(2), () {
        expect(TicketPriority.none.toStorageInt(), 0);
        expect(TicketPriority.urgent.toStorageInt(), 1);
        expect(TicketPriority.high.toStorageInt(), 2);
        expect(TicketPriority.medium.toStorageInt(), 3);
        expect(TicketPriority.low.toStorageInt(), 4);
      });
    });

    test('values are in correct order', timeout: const Timeout.factor(2), () {
      expect(
        TicketPriority.values,
        [TicketPriority.none, TicketPriority.urgent, TicketPriority.high, TicketPriority.medium, TicketPriority.low],
      );
    });
  });
}
