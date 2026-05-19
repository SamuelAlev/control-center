import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [FlutterSecureStorage] fake (mirrors the auth repo test fake),
/// exposing the backing store so tests can assert key naming.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  final Map<String, String> store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AppleOptions? mOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value != null) {
      store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AppleOptions? mOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      store[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AppleOptions? mOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    store.remove(key);
  }
}

void main() {
  group('GoogleCredentialsRepository', () {
    late _FakeSecureStorage storage;
    late GoogleCredentialsRepository repo;

    final creds = GoogleCredentials(
      accessToken: 'at-1',
      refreshToken: 'rt-1',
      expiresAt: DateTime.utc(2030, 1, 1, 12),
      accountEmail: 'a@example.com',
      scope: 'calendar.readonly',
    );

    setUp(() {
      storage = _FakeSecureStorage();
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

    test('keys are suffixed with the workspace id', () async {
      await repo.save('ws-A', creds);
      expect(storage.store.containsKey('${googleAccessTokenKey}__ws-A'), isTrue);
      expect(
        storage.store.containsKey('${googleRefreshTokenKey}__ws-A'),
        isTrue,
      );
      // No un-suffixed (global) key is ever written.
      expect(storage.store.containsKey(googleAccessTokenKey), isFalse);
    });

    test('load for a different workspace never sees another\'s tokens', () async {
      await repo.save('ws-A', creds);
      expect(await repo.load('ws-B'), isNull);
    });

    test('load returns null when refresh token is missing', () async {
      await storage.write(
        key: '${googleAccessTokenKey}__ws-A',
        value: 'orphan',
      );
      expect(await repo.load('ws-A'), isNull);
    });

    test('updateAccessToken rewrites only token + expiry', () async {
      await repo.save('ws-A', creds);
      final newExpiry = DateTime.utc(2031, 6, 1);
      await repo.updateAccessToken(
        'ws-A',
        accessToken: 'at-2',
        expiresAt: newExpiry,
      );
      final loaded = await repo.load('ws-A');
      expect(loaded!.accessToken, 'at-2');
      expect(loaded.expiresAt, newExpiry);
      // Preserved.
      expect(loaded.refreshToken, 'rt-1');
      expect(loaded.accountEmail, 'a@example.com');
      expect(loaded.scope, 'calendar.readonly');
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
