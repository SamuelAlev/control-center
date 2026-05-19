import 'package:cc_domain/features/messaging/domain/services/poisoned_session_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PoisonedSessionDetector detector;

  setUp(() {
    detector = PoisonedSessionDetector();
  });

  group('PoisonedSessionDetector', () {
    test('returns true for null output', () async {
      expect(detector.isPoisoned(null), isTrue);
    });

    test('returns true for empty output', () async {
      expect(detector.isPoisoned(''), isTrue);
    });

    test('returns false for whitespace-only output', () async {
      expect(detector.isPoisoned('   '), isFalse);
      expect(detector.isPoisoned('\t\n'), isFalse);
    });

    test('returns true for "iteration limit reached"', () async {
      expect(detector.isPoisoned('Error: iteration limit reached'), isTrue);
    });

    test('returns true for "maximum iterations exceeded"', () async {
      expect(detector.isPoisoned('maximum iterations exceeded'), isTrue);
    });

    test('returns true for "too many turns"', () async {
      expect(detector.isPoisoned('too many turns'), isTrue);
    });

    test('returns true for "context window exceeded"', () async {
      expect(detector.isPoisoned('context window exceeded'), isTrue);
    });

    test('returns true for "token limit exceeded"', () async {
      expect(detector.isPoisoned('token limit exceeded'), isTrue);
    });

    test('is case-insensitive', () async {
      expect(detector.isPoisoned('ITERATION LIMIT REACHED'), isTrue);
      expect(detector.isPoisoned('Context Window Exceeded'), isTrue);
      expect(detector.isPoisoned('Token Limit EXCEEDED'), isTrue);
    });

    test('detects signature embedded in larger text', () async {
      expect(
        detector.isPoisoned('Agent stopped because iteration limit reached.'),
        isTrue,
      );
      expect(
        detector.isPoisoned('The context window exceeded its capacity.'),
        isTrue,
      );
    });

    test('returns false for normal output', () async {
      expect(detector.isPoisoned('Hello, world!'), isFalse);
    });

    test('returns false for unrelated error text', () async {
      expect(detector.isPoisoned('file not found'), isFalse);
      expect(detector.isPoisoned('connection refused'), isFalse);
    });

    test('returns false for output containing partial match', () async {
      // "iteration" alone is not a signature
      expect(detector.isPoisoned('iteration count: 5'), isFalse);
      // "token" alone is not a signature
      expect(detector.isPoisoned('token usage: 100'), isFalse);
    });
  });
}
