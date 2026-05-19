import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PrUser createUser({
    String login = 'dev',
    String avatarUrl = 'https://avatars.example.com/dev.png',
  }) {
    return PrUser(login: login, avatarUrl: avatarUrl);
  }

  group('PrUser constructor', () {
    test('creates instance with all fields', () {
      const user = PrUser(
        login: 'alice',
        avatarUrl: 'https://avatar.url/alice',
      );
      expect(user.login, 'alice');
      expect(user.avatarUrl, 'https://avatar.url/alice');
    });

    test('stores empty strings', () {
      const user = PrUser(login: '', avatarUrl: '');
      expect(user.login, '');
      expect(user.avatarUrl, '');
    });

    test('is const constructable', () {
      const user = PrUser(login: 'bob', avatarUrl: 'https://x.com/bob');
      expect(user.login, 'bob');
    });
  });

  group('PrUser == and hashCode', () {
    test('identical users are equal', () {
      final a = createUser();
      final b = createUser();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different login makes unequal', () {
      final a = createUser(login: 'alice');
      final b = createUser(login: 'bob');
      expect(a, isNot(equals(b)));
    });

    test('same login but different avatarUrl are equal (identity by login)', () {
      final a = createUser(login: 'dev', avatarUrl: 'https://a.com/dev1.png');
      final b = createUser(login: 'dev', avatarUrl: 'https://a.com/dev2.png');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createUser();
      expect(a, equals(a));
    });

    test('hashCode is consistent with ==', () {
      final a = createUser(login: 'alice');
      final b = createUser(login: 'alice');
      final c = createUser(login: 'bob');
      expect(a.hashCode, equals(b.hashCode));
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });
  });
}
