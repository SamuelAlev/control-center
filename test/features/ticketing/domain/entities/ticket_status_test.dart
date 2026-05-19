import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketStatus', () {
    group('fromStorage', () {
      test('maps all canonical names', timeout: const Timeout.factor(2), () {
        for (final s in TicketStatus.values) {
          expect(TicketStatus.fromStorage(s.toStorageString()), s);
        }
      });

      test('returns open for null', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.fromStorage(null), TicketStatus.open);
      });

      test('throws on an unknown / legacy status string',
          timeout: const Timeout.factor(2), () {
        // Loud-fail hardening: a corrupt status must surface, not coerce to
        // open. Legacy `pending`/`completed` aliases were dropped (clean DB).
        expect(() => TicketStatus.fromStorage('unknown'), throwsArgumentError);
        expect(() => TicketStatus.fromStorage('pending'), throwsArgumentError);
        expect(() => TicketStatus.fromStorage('completed'), throwsArgumentError);
        expect(() => TicketStatus.fromStorage(''), throwsArgumentError);
      });
    });

    group('toStorageString', () {
      test('returns the enum name', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.backlog.toStorageString(), 'backlog');
        expect(TicketStatus.open.toStorageString(), 'open');
        expect(TicketStatus.inProgress.toStorageString(), 'inProgress');
        expect(TicketStatus.blocked.toStorageString(), 'blocked');
        expect(TicketStatus.inReview.toStorageString(), 'inReview');
        expect(TicketStatus.done.toStorageString(), 'done');
        expect(TicketStatus.failed.toStorageString(), 'failed');
        expect(TicketStatus.cancelled.toStorageString(), 'cancelled');
      });
    });

    group('isTerminal', () {
      test('terminal states', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.done.isTerminal, isTrue);
        expect(TicketStatus.failed.isTerminal, isTrue);
        expect(TicketStatus.cancelled.isTerminal, isTrue);
      });

      test('non-terminal states', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.backlog.isTerminal, isFalse);
        expect(TicketStatus.open.isTerminal, isFalse);
        expect(TicketStatus.inProgress.isTerminal, isFalse);
        expect(TicketStatus.blocked.isTerminal, isFalse);
        expect(TicketStatus.inReview.isTerminal, isFalse);
      });
    });

    group('isSuccess / isFailure', () {
      test('only done is success', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.done.isSuccess, isTrue);
        for (final s in TicketStatus.values) {
          if (s != TicketStatus.done) {
            expect(s.isSuccess, isFalse, reason: '$s should not be success');
          }
        }
      });

      test('only failed is failure', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.failed.isFailure, isTrue);
        for (final s in TicketStatus.values) {
          if (s != TicketStatus.failed) {
            expect(s.isFailure, isFalse, reason: '$s should not be failure');
          }
        }
      });
    });

    group('isActive', () {
      test('only inProgress is active', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.inProgress.isActive, isTrue);
        for (final s in TicketStatus.values) {
          if (s != TicketStatus.inProgress) {
            expect(s.isActive, isFalse, reason: '$s should not be active');
          }
        }
      });
    });

    group('canTransitionTo', () {
      test('same status is always allowed', timeout: const Timeout.factor(2), () {
        for (final s in TicketStatus.values) {
          expect(s.canTransitionTo(s), isTrue, reason: '$s → $s');
        }
      });

      test('backlog can go to open or cancelled', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.backlog.canTransitionTo(TicketStatus.open), isTrue);
        expect(TicketStatus.backlog.canTransitionTo(TicketStatus.cancelled), isTrue);
        expect(TicketStatus.backlog.canTransitionTo(TicketStatus.inProgress), isFalse);
        expect(TicketStatus.backlog.canTransitionTo(TicketStatus.done), isFalse);
      });

      test('open can go to inProgress, blocked, cancelled', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.open.canTransitionTo(TicketStatus.inProgress), isTrue);
        expect(TicketStatus.open.canTransitionTo(TicketStatus.blocked), isTrue);
        expect(TicketStatus.open.canTransitionTo(TicketStatus.cancelled), isTrue);
        expect(TicketStatus.open.canTransitionTo(TicketStatus.done), isFalse);
        expect(TicketStatus.open.canTransitionTo(TicketStatus.backlog), isFalse);
      });

      test('inProgress can go to blocked, inReview, done, failed, cancelled', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.blocked), isTrue);
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.inReview), isTrue);
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.done), isTrue);
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.failed), isTrue);
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.cancelled), isTrue);
        expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.open), isFalse);
      });

      test('blocked can go to inProgress or cancelled', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.blocked.canTransitionTo(TicketStatus.inProgress), isTrue);
        expect(TicketStatus.blocked.canTransitionTo(TicketStatus.cancelled), isTrue);
        expect(TicketStatus.blocked.canTransitionTo(TicketStatus.done), isFalse);
      });

      test('inReview can go to inProgress, done, failed, cancelled', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.inReview.canTransitionTo(TicketStatus.inProgress), isTrue);
        expect(TicketStatus.inReview.canTransitionTo(TicketStatus.done), isTrue);
        expect(TicketStatus.inReview.canTransitionTo(TicketStatus.failed), isTrue);
        expect(TicketStatus.inReview.canTransitionTo(TicketStatus.cancelled), isTrue);
        expect(TicketStatus.inReview.canTransitionTo(TicketStatus.open), isFalse);
      });

      test('terminal states allow no transitions out', timeout: const Timeout.factor(2), () {
        for (final terminal in [TicketStatus.done, TicketStatus.failed, TicketStatus.cancelled]) {
          for (final target in TicketStatus.values) {
            if (target == terminal) {
              continue;
            }
            expect(terminal.canTransitionTo(target), isFalse,
                reason: '$terminal → $target should be forbidden');
          }
        }
      });
    });

    group('TicketStatusX', () {
      test('isOpen is true for non-terminal states', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.backlog.isOpen, isTrue);
        expect(TicketStatus.open.isOpen, isTrue);
        expect(TicketStatus.inProgress.isOpen, isTrue);
        expect(TicketStatus.blocked.isOpen, isTrue);
        expect(TicketStatus.inReview.isOpen, isTrue);
      });

      test('isOpen is false for terminal states', timeout: const Timeout.factor(2), () {
        expect(TicketStatus.done.isOpen, isFalse);
        expect(TicketStatus.failed.isOpen, isFalse);
        expect(TicketStatus.cancelled.isOpen, isFalse);
      });
    });
  });
}
