import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketStatus.fromStorage', () {
    test('maps legacy task statuses', () {
      expect(TicketStatus.fromStorage('pending'), TicketStatus.open);
      expect(TicketStatus.fromStorage('completed'), TicketStatus.done);
      expect(TicketStatus.fromStorage('inProgress'), TicketStatus.inProgress);
      expect(TicketStatus.fromStorage('failed'), TicketStatus.failed);
      expect(TicketStatus.fromStorage('cancelled'), TicketStatus.cancelled);
    });

    test('round-trips canonical statuses', () {
      for (final s in TicketStatus.values) {
        expect(TicketStatus.fromStorage(s.toStorageString()), s);
      }
    });

    test('unknown falls back to open', () {
      expect(TicketStatus.fromStorage('???'), TicketStatus.open);
      expect(TicketStatus.fromStorage(null), TicketStatus.open);
    });
  });

  group('terminal semantics', () {
    test('done/failed/cancelled are terminal', () {
      expect(TicketStatus.done.isTerminal, isTrue);
      expect(TicketStatus.failed.isTerminal, isTrue);
      expect(TicketStatus.cancelled.isTerminal, isTrue);
    });

    test('non-terminal states are not terminal', () {
      expect(TicketStatus.open.isTerminal, isFalse);
      expect(TicketStatus.inProgress.isTerminal, isFalse);
      expect(TicketStatus.inReview.isTerminal, isFalse);
    });

    test('success vs failure distinction is preserved', () {
      expect(TicketStatus.done.isSuccess, isTrue);
      expect(TicketStatus.done.isFailure, isFalse);
      expect(TicketStatus.failed.isFailure, isTrue);
      expect(TicketStatus.failed.isSuccess, isFalse);
    });
  });

  group('canTransitionTo', () {
    test('allows forward progress', () {
      expect(TicketStatus.open.canTransitionTo(TicketStatus.inProgress), isTrue);
      expect(
        TicketStatus.inProgress.canTransitionTo(TicketStatus.done),
        isTrue,
      );
    });

    test('forbids transitions out of terminal states', () {
      expect(TicketStatus.done.canTransitionTo(TicketStatus.open), isFalse);
      expect(
        TicketStatus.cancelled.canTransitionTo(TicketStatus.inProgress),
        isFalse,
      );
    });
  });
}
