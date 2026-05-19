import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationSound values', () {
    test('none has no asset', () {
      expect(NotificationSound.none.name, equals('none'));
      expect(NotificationSound.none.assetPath, isNull);
      expect(NotificationSound.none.group, equals('Standard'));
    });

    test('ping has correct properties', () {
      expect(NotificationSound.ping.name, equals('ping'));
      expect(NotificationSound.ping.assetPath, isNotNull);
      expect(NotificationSound.ping.group, equals('Standard'));
    });

    test('chime has correct properties', () {
      expect(NotificationSound.chime.name, equals('chime'));
      expect(NotificationSound.chime.assetPath, isNotNull);
      expect(NotificationSound.chime.group, equals('Standard'));
    });

    test('pop has correct properties', () {
      expect(NotificationSound.pop.name, equals('pop'));
      expect(NotificationSound.pop.assetPath, isNotNull);
      expect(NotificationSound.pop.group, equals('Standard'));
    });

    test('ding has correct properties', () {
      expect(NotificationSound.ding.name, equals('ding'));
      expect(NotificationSound.ding.assetPath, isNotNull);
      expect(NotificationSound.ding.group, equals('Standard'));
    });

    test('whoosh has correct properties', () {
      expect(NotificationSound.whoosh.name, equals('whoosh'));
      expect(NotificationSound.whoosh.assetPath, isNotNull);
      expect(NotificationSound.whoosh.group, equals('Standard'));
    });

    test('migrosSoft has correct properties', () {
      expect(NotificationSound.migrosSoft.name, equals('migros-soft'));
      expect(NotificationSound.migrosSoft.assetPath, isNotNull);
      expect(NotificationSound.migrosSoft.group, equals('Schwiizer Tönli'));
    });

    test('migrosHard has correct properties', () {
      expect(NotificationSound.migrosHard.name, equals('migros-hard'));
      expect(NotificationSound.migrosHard.assetPath, isNotNull);
      expect(NotificationSound.migrosHard.group, equals('Schwiizer Tönli'));
    });

    test('sbb has correct properties', () {
      expect(NotificationSound.sbb.name, equals('sbb'));
      expect(NotificationSound.sbb.assetPath, isNotNull);
      expect(NotificationSound.sbb.group, equals('Schwiizer Tönli'));
    });

    test('cff has correct properties', () {
      expect(NotificationSound.cff.name, equals('cff'));
      expect(NotificationSound.cff.assetPath, isNotNull);
      expect(NotificationSound.cff.group, equals('Schwiizer Tönli'));
    });

    test('ffs has correct properties', () {
      expect(NotificationSound.ffs.name, equals('ffs'));
      expect(NotificationSound.ffs.assetPath, isNotNull);
      expect(NotificationSound.ffs.group, equals('Schwiizer Tönli'));
    });

    test('post has correct properties', () {
      expect(NotificationSound.post.name, equals('post'));
      expect(NotificationSound.post.assetPath, isNotNull);
      expect(NotificationSound.post.group, equals('Schwiizer Tönli'));
    });
  });

  group('groups', () {
    test('standardGroup constant', () {
      const group = NotificationSound.standardGroup;
      expect(group, equals('Standard'));
    });

    test('swissGroup constant', () {
      const group = NotificationSound.swissGroup;
      expect(group, equals('Schwiizer Tönli'));
    });

    test('groups returns unique groups in order', () {
      final groups = NotificationSound.groups;
      expect(groups, equals(['Standard', 'Schwiizer Tönli']));
    });
  });

  group('forGroup', () {
    test('returns 6 Standard sounds', () {
      final sounds = NotificationSound.forGroup('Standard');
      expect(sounds.length, equals(6));
      expect(sounds, containsAll([
        NotificationSound.none,
        NotificationSound.ping,
        NotificationSound.chime,
        NotificationSound.pop,
        NotificationSound.ding,
        NotificationSound.whoosh,
      ]));
    });

    test('returns 6 Schwiizer Tönli sounds', () {
      final sounds = NotificationSound.forGroup('Schwiizer Tönli');
      expect(sounds.length, equals(6));
      expect(sounds, containsAll([
        NotificationSound.migrosSoft,
        NotificationSound.migrosHard,
        NotificationSound.sbb,
        NotificationSound.cff,
        NotificationSound.ffs,
        NotificationSound.post,
      ]));
    });

    test('returns empty list for unknown group', () {
      final sounds = NotificationSound.forGroup('Unknown');
      expect(sounds, isEmpty);
    });
  });

  group('fromName', () {
    test('returns correct sound for "ping"', () {
      expect(NotificationSound.fromName('ping'), equals(NotificationSound.ping));
    });

    test('returns correct sound for "chime"', () {
      expect(NotificationSound.fromName('chime'), equals(NotificationSound.chime));
    });

    test('returns correct sound for "none"', () {
      expect(NotificationSound.fromName('none'), equals(NotificationSound.none));
    });

    test('returns correct sound for "migros-soft"', () {
      expect(NotificationSound.fromName('migros-soft'), equals(NotificationSound.migrosSoft));
    });

    test('returns correct sound for "sbb"', () {
      expect(NotificationSound.fromName('sbb'), equals(NotificationSound.sbb));
    });

    test('returns correct sound for "post"', () {
      expect(NotificationSound.fromName('post'), equals(NotificationSound.post));
    });

    test('returns ping for null name', () {
      expect(NotificationSound.fromName(null), equals(NotificationSound.ping));
    });

    test('returns ping for unknown name', () {
      expect(NotificationSound.fromName('unknown-sound'), equals(NotificationSound.ping));
    });

    test('returns ping for empty string', () {
      expect(NotificationSound.fromName(''), equals(NotificationSound.ping));
    });
  });
}
