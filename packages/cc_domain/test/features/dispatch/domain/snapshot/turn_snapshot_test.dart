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

    test('returns null when snapshot raw is not a Map', () {
      expect(TurnSnapshot.fromMetadata({'snapshot': 'garbage'}), isNull);
      expect(TurnSnapshot.fromMetadata({'snapshot': 42}), isNull);
    });

    test('isEmpty + partial snapshots', () {
      expect(const TurnSnapshot().isEmpty, isTrue);
      expect(const TurnSnapshot(start: 'a').isEmpty, isFalse);
      expect(const TurnSnapshot(start: 'a').toJson(), {'start': 'a'});
    });

    test('equality + hashCode by start/end', () {
      const a = TurnSnapshot(start: 's', end: 'e');
      const b = TurnSnapshot(start: 's', end: 'e');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const TurnSnapshot(start: 's')));
    });
  });
}
