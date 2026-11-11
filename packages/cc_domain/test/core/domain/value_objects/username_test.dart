import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:test/test.dart';

void main() {
  group('Username.check', () {
    test('accepts the documented shape', () {
      for (final ok in [
        'ab',
        'sam',
        'ada.lovelace',
        'priya_r',
        'maya-ok',
        'a1',
        '0x',
        'a' * 32,
        'a.-_b',
      ]) {
        expect(Username.check(ok), isNull, reason: ok);
      }
    });

    test('refuses everything else as invalid', () {
      for (final bad in [
        '',
        'a',
        'a' * 33,
        'Sam',
        '-sam',
        'sam-',
        '.sam',
        'sam.',
        '_sam',
        'sam_',
        'sam smith',
        'sam@x',
        'sám',
        'sam\u200b',
        'sa\nm',
        '١٢',
      ]) {
        expect(Username.check(bad), UsernameRefusal.invalid, reason: bad);
      }
    });

    test('refuses every reserved name', () {
      expect(Username.reserved, {
        'system',
        'agent',
        'everyone',
        'here',
        'channel',
        'usectrl',
        'me',
      });
      for (final name in Username.reserved) {
        expect(Username.check(name), UsernameRefusal.reserved, reason: name);
      }
    });

    test('the pattern alone carries the length limits', () {
      expect(Username.pattern.hasMatch('a' * Username.minLength), isTrue);
      expect(Username.pattern.hasMatch('a' * (Username.minLength - 1)), false);
      expect(Username.pattern.hasMatch('a' * Username.maxLength), isTrue);
      expect(Username.pattern.hasMatch('a' * (Username.maxLength + 1)), false);
    });
  });

  group('Username.parse', () {
    test('trims and lowercases what a person typed, nothing else', () {
      expect(Username.parse('  Sam ').value, 'sam');
      expect(Username.normalizeInput(' Ada.Lovelace '), 'ada.lovelace');
      expect(Username.normalizeInput('sam smith'), 'sam smith');
    });

    test('throws a typed refusal', () {
      expect(
        () => Username.parse('sam smith'),
        throwsA(
          isA<UsernameRefusedException>()
              .having((e) => e.reason, 'reason', UsernameRefusal.invalid)
              .having((e) => e, 'is validation', isA<ValidationException>()),
        ),
      );
      expect(
        () => Username.parse('EVERYONE'),
        throwsA(
          isA<UsernameRefusedException>().having(
            (e) => e.reason,
            'reason',
            UsernameRefusal.reserved,
          ),
        ),
      );
    });

    test('refusal kinds are the RPC data.kind spellings', () {
      expect(UsernameRefusal.values.map((r) => r.errorKind), [
        'username_invalid',
        'username_reserved',
        'username_taken',
      ]);
      expect(UsernameRefusal.values.map((r) => r.wire), [
        'invalid',
        'reserved',
        'taken',
      ]);
    });
  });

  group('Username.fromFreeText', () {
    Username derive(String text) =>
        Username.fromFreeText(text, fallback: 'member');

    test('derives a valid name from an account, claim or address', () {
      expect(derive('samuel.alev').value, 'samuel.alev');
      expect(derive('Ada Lovelace').value, 'ada-lovelace');
      expect(derive('first.last@corp.example').value, 'first.last');
      expect(derive('@sam').value, 'sam');
      expect(derive(r'DOMAIN\jdoe').value, 'domain-jdoe');
    });

    test('hostile input always ends valid', () {
      for (final text in [
        '',
        '   ',
        '\u0000\u0000',
        '---',
        '..__..',
        'a',
        'é',
        '\u202esam\u202c',
        'sam\u200bsmith',
        '<script>alert(1)</script>',
        "'; DROP TABLE users; --",
        '../../etc/passwd',
        'x' * 10000,
        '${'a' * 31}-${'b' * 10}',
        'SYSTEM',
        'Me',
        '🙂🙂',
      ]) {
        expect(Username.isValid(derive(text).value), isTrue, reason: text);
      }
    });

    test('truncates to the limit and never ends on punctuation', () {
      expect(derive('${'a' * 31}-bbb').value, 'a' * 31);
      expect(derive('x' * 10000).value, 'x' * 32);
    });

    test('falls back when nothing usable or reserved is left', () {
      expect(derive('').value, 'member');
      expect(derive('a').value, 'member');
      expect(derive('System').value, 'member');
      expect(Username.fromFreeText('é', fallback: 'owner').value, 'owner');
    });

    test('an invalid fallback is a programming error', () {
      expect(
        () => Username.fromFreeText('', fallback: 'x'),
        throwsA(isA<UsernameRefusedException>()),
      );
    });
  });

  group('Username.candidates', () {
    test('base first, then numbered', () {
      expect(
        Username.candidates(Username.parse('sam')).take(4).map((u) => u.value),
        ['sam', 'sam2', 'sam3', 'sam4'],
      );
    });

    test('every candidate stays within the limit and valid', () {
      final base = Username.parse('a' * 32);
      final some = Username.candidates(base).take(120).toList();
      expect(some[1].value, '${'a' * 31}2');
      expect(some[99].value, '${'a' * 29}100');
      for (final c in some) {
        expect(Username.isValid(c.value), isTrue, reason: c.value);
      }
      expect(some.map((c) => c.value).toSet(), hasLength(120));
    });
  });

  group('User', () {
    User user(String handle) => User(
      id: 'u-1',
      handle: handle,
      displayName: 'Sam',
      createdAt: DateTime.utc(2026),
    );

    test('holds only a valid username', () {
      expect(user('sam').handle, 'sam');
      for (final bad in ['', 'Sam', 'a', 'system', 'sam smith']) {
        expect(() => user(bad), throwsArgumentError, reason: bad);
      }
    });

    test('a rename through copyWith is validated too', () {
      expect(() => user('sam').copyWith(handle: 'me'), throwsArgumentError);
    });
  });
}
