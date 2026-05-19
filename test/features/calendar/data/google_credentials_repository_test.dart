import 'dart:convert';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCredentialsRepository', () {
    late InMemoryStorage backing;
    late SecureStore storage;
    late GoogleCredentialsRepository repo;

    final creds = GoogleCredentials(
      accessToken: 'at-1',
      refreshToken: 'rt-1',
      expiresAt: DateTime.utc(2030, 1, 1, 12),
      accountEmail: 'a@example.com',
      scope: 'calendar.readonly',
    );

    setUp(() {
      backing = InMemoryStorage();
      storage = SecureStore(backing);
      repo = GoogleCredentialsRepository(storage);
    });

    test('save then load round-trips all fields', () async {
      await repo.save('ws-A', creds);
      final loaded = await repo.load('ws-A');
      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'at-1');
      expect(loaded.refreshToken, 'rt-1');
      expect(loaded.expiresAt, DateTime.utc(2030, 1, 1, 12));
      expect(loaded.accountEmail, 'a@example.com');
      expect(loaded.scope, 'calendar.readonly');
    });

    test('serves later reads from the in-memory cache, not the keychain',
        () async {
      await repo.save('ws-A', creds);
      expect(await repo.load('ws-A'), isNotNull); // primes the cache

      // Wipe the backing store out from under the repo. A cached read still
      // succeeds; an uncached path would now return null — and on macOS would
      // re-prompt for keychain access on every request. This is the spam fix.
      backing.clear();

      final cached = await repo.load('ws-A');
      expect(cached, isNotNull);
      expect(cached!.accessToken, 'at-1');
      expect(cached.refreshToken, 'rt-1');
    });

    test('re-saving after a refresh swaps token + expiry, keeps the rest',
        () async {
      await repo.save('ws-A', creds);
      await repo.load('ws-A'); // prime the cache
      final newExpiry = DateTime.utc(2032);
      // The refresh path re-saves the full blob via copyWithAccessToken.
      await repo.save(
        'ws-A',
        creds.copyWithAccessToken(accessToken: 'at-2', expiresAt: newExpiry),
      );
      // Even with the backing store wiped, the cache reflects the new token.
      backing.clear();
      final loaded = await repo.load('ws-A');
      expect(loaded!.accessToken, 'at-2');
      expect(loaded.expiresAt, newExpiry);
      // Preserved across the refresh.
      expect(loaded.refreshToken, 'rt-1');
      expect(loaded.accountEmail, 'a@example.com');
      expect(loaded.scope, 'calendar.readonly');
    });

    test('clear evicts the cache so a disconnected account stays gone',
        () async {
      await repo.save('ws-A', creds);
      await repo.load('ws-A'); // prime the cache
      await repo.clear('ws-A');
      expect(await repo.load('ws-A'), isNull);
    });

    test('stores one blob under a single workspace-suffixed key', () async {
      await repo.save('ws-A', creds);
      // Exactly one keychain item per account — this is what caps the macOS
      // prompt at one per account instead of one per field.
      expect(backing.size, 1);
      expect(backing.contains('${googleCredentialsKey}__ws-A'), isTrue);
      // No un-suffixed (global) key is ever written.
      expect(backing.contains(googleCredentialsKey), isFalse);
      // The single item is a JSON blob carrying every field.
      final blob = jsonDecode(backing.get('${googleCredentialsKey}__ws-A'))
          as Map<String, dynamic>;
      expect(blob['accessToken'], 'at-1');
      expect(blob['refreshToken'], 'rt-1');
      expect(blob['accountEmail'], 'a@example.com');
      expect(blob['scope'], 'calendar.readonly');
    });

    test('load for a different workspace never sees another\'s tokens', () async {
      await repo.save('ws-A', creds);
      expect(await repo.load('ws-B'), isNull);
    });

    test('load returns null for a blob missing the refresh token', () async {
      await storage.write(
        key: '${googleCredentialsKey}__ws-A',
        value: jsonEncode({'accessToken': 'orphan'}),
      );
      expect(await repo.load('ws-A'), isNull);
    });

    test('load returns null for a malformed (non-JSON) blob', () async {
      await storage.write(
        key: '${googleCredentialsKey}__ws-A',
        value: 'not json',
      );
      expect(await repo.load('ws-A'), isNull);
    });

    test('clear removes only the target workspace credentials', () async {
      await repo.save('ws-A', creds);
      await repo.save('ws-B', creds);
      await repo.clear('ws-A');
      expect(await repo.load('ws-A'), isNull);
      expect(await repo.load('ws-B'), isNotNull);
    });

    test('isExpired reflects the expiry minus skew', () {
      final fresh = creds.copyWithAccessToken(
        accessToken: 'x',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final stale = creds.copyWithAccessToken(
        accessToken: 'x',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );
      expect(fresh.isExpired(), isFalse);
      expect(stale.isExpired(), isTrue);
    });
  });
}
