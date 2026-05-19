import 'package:control_center/features/auth/domain/value_objects/token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token', () {
    test('holds the raw value', () async {
      const token = Token('abc123');
      expect(token.value, 'abc123');
    });

    test('isEmpty is true for empty string', () async {
      const token = Token('');
      expect(token.isEmpty, isTrue);
      expect(token.isNotEmpty, isFalse);
    });

    test('isNotEmpty is true for non-empty string', () async {
      const token = Token('secret');
      expect(token.isNotEmpty, isTrue);
      expect(token.isEmpty, isFalse);
    });

    test('toString masks the value', () async {
      const token = Token('super-secret-key');
      expect(token.toString(), 'Token(****)');
    });

    test('toString never contains the raw value', () async {
      const token = Token('my-secret-token');
      expect(token.toString(), isNot(contains('my-secret-token')));
    });

    test('equality is value-based', () async {
      const a = Token('xyz');
      const b = Token('xyz');
      expect(a, equals(b));
    });

    test('inequality for different values', () async {
      const a = Token('abc');
      const b = Token('def');
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal tokens', () async {
      const a = Token('same');
      const b = Token('same');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different tokens', () async {
      const a = Token('one');
      const b = Token('two');
      // Not guaranteed but highly likely for short strings.
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('is not equal to non-Token objects', () async {
      const token = Token('abc');
      // ignore: unrelated_type_equality_checks
      expect(token == 'abc', isFalse);
    });
  });
}
