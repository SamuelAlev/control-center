import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketStatus.fromStorage', () {
    test('maps canonical statuses', () {
      expect(TicketStatus.fromStorage('open'), TicketStatus.open);
      expect(TicketStatus.fromStorage('done'), TicketStatus.done);
      expect(TicketStatus.fromStorage('inProgress'), TicketStatus.inProgress);
      expect(TicketStatus.fromStorage('failed'), TicketStatus.failed);
      expect(TicketStatus.fromStorage('cancelled'), TicketStatus.cancelled);
    });

    test('round-trips canonical statuses', () {
      for (final s in TicketStatus.values) {
        expect(TicketStatus.fromStorage(s.toStorageString()), s);
      }
    });

    test('null falls back to open; unknown / legacy throws', () {
      expect(TicketStatus.fromStorage(null), TicketStatus.open);
      expect(() => TicketStatus.fromStorage('???'), throwsArgumentError);
      expect(() => TicketStatus.fromStorage('pending'), throwsArgumentError);
      expect(() => TicketStatus.fromStorage('completed'), throwsArgumentError);
    });

    test('maps all individual canonical strings', () {
      expect(TicketStatus.fromStorage('backlog'), TicketStatus.backlog);
      expect(TicketStatus.fromStorage('open'), TicketStatus.open);
      expect(TicketStatus.fromStorage('inProgress'), TicketStatus.inProgress);
      expect(TicketStatus.fromStorage('blocked'), TicketStatus.blocked);
      expect(TicketStatus.fromStorage('inReview'), TicketStatus.inReview);
      expect(TicketStatus.fromStorage('done'), TicketStatus.done);
      expect(TicketStatus.fromStorage('failed'), TicketStatus.failed);
      expect(TicketStatus.fromStorage('cancelled'), TicketStatus.cancelled);
    });
  });

  group('toStorageString', () {
    test('returns name for all values', () {
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

  group('terminal semantics', () {
    test('done/failed/cancelled are terminal', () {
      expect(TicketStatus.done.isTerminal, isTrue);
      expect(TicketStatus.failed.isTerminal, isTrue);
      expect(TicketStatus.cancelled.isTerminal, isTrue);
    });

    test('non-terminal states are not terminal', () {
      expect(TicketStatus.backlog.isTerminal, isFalse);
      expect(TicketStatus.open.isTerminal, isFalse);
      expect(TicketStatus.inProgress.isTerminal, isFalse);
      expect(TicketStatus.blocked.isTerminal, isFalse);
      expect(TicketStatus.inReview.isTerminal, isFalse);
    });

    test('success vs failure distinction is preserved', () {
      expect(TicketStatus.done.isSuccess, isTrue);
      expect(TicketStatus.done.isFailure, isFalse);
      expect(TicketStatus.failed.isFailure, isTrue);
      expect(TicketStatus.failed.isSuccess, isFalse);
    });
  });

  group('isActive', () {
    test('only inProgress is active', () {
      expect(TicketStatus.inProgress.isActive, isTrue);
    });

    test('all other states are not active', () {
      expect(TicketStatus.backlog.isActive, isFalse);
      expect(TicketStatus.open.isActive, isFalse);
      expect(TicketStatus.blocked.isActive, isFalse);
      expect(TicketStatus.inReview.isActive, isFalse);
      expect(TicketStatus.done.isActive, isFalse);
      expect(TicketStatus.failed.isActive, isFalse);
      expect(TicketStatus.cancelled.isActive, isFalse);
    });
  });

  group('isOpen extension', () {
    test('non-terminal states are open', () {
      expect(TicketStatus.backlog.isOpen, isTrue);
      expect(TicketStatus.open.isOpen, isTrue);
      expect(TicketStatus.inProgress.isOpen, isTrue);
      expect(TicketStatus.blocked.isOpen, isTrue);
      expect(TicketStatus.inReview.isOpen, isTrue);
    });

    test('terminal states are not open', () {
      expect(TicketStatus.done.isOpen, isFalse);
      expect(TicketStatus.failed.isOpen, isFalse);
      expect(TicketStatus.cancelled.isOpen, isFalse);
    });
  });

  group('canTransitionTo', () {
    test('allows forward progress', () {
      expect(TicketStatus.open.canTransitionTo(TicketStatus.inProgress), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.done), isTrue);
    });

    test('forbids transitions out of terminal states', () {
      expect(TicketStatus.done.canTransitionTo(TicketStatus.open), isFalse);
      expect(TicketStatus.cancelled.canTransitionTo(TicketStatus.inProgress), isFalse);
    });

    test('self-transition is always allowed', () {
      for (final s in TicketStatus.values) {
        expect(s.canTransitionTo(s), isTrue, reason: '$s → $s');
      }
    });

    test('backlog allowed transitions', () {
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.open), isTrue);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.cancelled), isTrue);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.inProgress), isFalse);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.blocked), isFalse);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.inReview), isFalse);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.done), isFalse);
      expect(TicketStatus.backlog.canTransitionTo(TicketStatus.failed), isFalse);
    });

    test('open allowed transitions', () {
      expect(TicketStatus.open.canTransitionTo(TicketStatus.inProgress), isTrue);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.blocked), isTrue);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.cancelled), isTrue);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.backlog), isFalse);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.inReview), isFalse);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.done), isFalse);
      expect(TicketStatus.open.canTransitionTo(TicketStatus.failed), isFalse);
    });

    test('inProgress allowed transitions', () {
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.blocked), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.inReview), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.done), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.failed), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.cancelled), isTrue);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.backlog), isFalse);
      expect(TicketStatus.inProgress.canTransitionTo(TicketStatus.open), isFalse);
    });

    test('blocked allowed transitions', () {
      expect(TicketStatus.blocked.canTransitionTo(TicketStatus.inProgress), isTrue);
      expect(TicketStatus.blocked.canTransitionTo(TicketStatus.cancelled), isTrue);
      expect(TicketStatus.blocked.canTransitionTo(TicketStatus.done), isFalse);
      expect(TicketStatus.blocked.canTransitionTo(TicketStatus.failed), isFalse);
      expect(TicketStatus.blocked.canTransitionTo(TicketStatus.inReview), isFalse);
    });

    test('inReview allowed transitions', () {
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.inProgress), isTrue);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.done), isTrue);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.failed), isTrue);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.cancelled), isTrue);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.blocked), isFalse);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.backlog), isFalse);
      expect(TicketStatus.inReview.canTransitionTo(TicketStatus.open), isFalse);
    });

    test('done has no outgoing transitions except self', () {
      for (final s in TicketStatus.values) {
        if (s == TicketStatus.done) {
          expect(TicketStatus.done.canTransitionTo(s), isTrue);
        } else {
          expect(TicketStatus.done.canTransitionTo(s), isFalse, reason: 'done → $s');
        }
      }
    });

    test('failed has no outgoing transitions except self', () {
      for (final s in TicketStatus.values) {
        if (s == TicketStatus.failed) {
          expect(TicketStatus.failed.canTransitionTo(s), isTrue);
        } else {
          expect(TicketStatus.failed.canTransitionTo(s), isFalse, reason: 'failed → $s');
        }
      }
    });

    test('cancelled has no outgoing transitions except self', () {
      for (final s in TicketStatus.values) {
        if (s == TicketStatus.cancelled) {
          expect(TicketStatus.cancelled.canTransitionTo(s), isTrue);
        } else {
          expect(TicketStatus.cancelled.canTransitionTo(s), isFalse, reason: 'cancelled → $s');
        }
      }
    });
  });
}
