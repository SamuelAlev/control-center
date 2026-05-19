import 'package:cc_domain/features/dispatch/domain/snapshot/turn_snapshot.dart';
import 'package:test/test.dart';

void main() {
  group('TurnSnapshot', () {
    test('reads start/end from message metadata', () {
      final snap = TurnSnapshot.fromMetadata({
        'snapshot': {'start': 'abc', 'end': 'def'},
      });
      expect(snap, isNotNull);
      expect(snap!.start, 'abc');
      expect(snap.end, 'def');
    });

    test('returns null when no snapshot present', () {
      expect(TurnSnapshot.fromMetadata(null), isNull);
      expect(TurnSnapshot.fromMetadata({'other': 1}), isNull);
      expect(TurnSnapshot.fromMetadata({'snapshot': {}}), isNull);
    });

    test('round-trips toJson', () {
      const snap = TurnSnapshot(start: 'a', end: 'b');
      expect(snap.toJson(), {'start': 'a', 'end': 'b'});
    });
  });

  group('buildForkHandoffReminder', () {
    test('mentions retained context and no directory by default', () {
      final text = buildForkHandoffReminder();
      expect(text, contains('<system-reminder>'));
      expect(text, contains('retained intentionally'));
      expect(text, isNot(contains('current working directory')));
    });

    test('includes the new working directory when forking a worktree', () {
      final text = buildForkHandoffReminder(directory: '/tmp/fork-wt');
      expect(text, contains('/tmp/fork-wt'));
      expect(text, contains('supersedes'));
    });
  });
}
