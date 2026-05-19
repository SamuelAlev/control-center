import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [FlutterSecureStorage] fake (same shape as the credentials-repo
/// test fake) so the manager can load/refresh without a platform channel.
class _FakeSecureStorage extends FlutterSecureStorage {
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
  group('GoogleTokenManager.forceRefresh terminal-failure callback', () {
    const accountId = 'google:ws-A:a@example.com';
    late _FakeSecureStorage storage;
    late GoogleCredentialsRepository repo;

    Future<void> seed() => repo.save(
          accountId,
          GoogleCredentials(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
            accountEmail: 'a@example.com',
            scope: 'calendar.readonly',
          ),
        );

    setUp(() {
      storage = _FakeSecureStorage();
      repo = GoogleCredentialsRepository(storage);
    });

    test('fires onRefreshTokenInvalid exactly once on invalid_grant', () async {
      final flagged = <String>[];
      final manager = GoogleTokenManager(
        repo,
        (_) async => throw const GoogleOAuthException(
          'dead',
          kind: GoogleOAuthFailureKind.invalidGrant,
        ),
        onRefreshTokenInvalid: (id) async => flagged.add(id),
      );
      await seed();

      final token = await manager.forceRefresh(accountId);

      expect(token, isNull, reason: 'a dead refresh token mints nothing');
      expect(flagged, [accountId]);
    });

    test('does NOT fire the callback for a transient failure', () async {
      final flagged = <String>[];
      final manager = GoogleTokenManager(
        repo,
        (_) async => throw const GoogleOAuthException(
          'network blip',
          kind: GoogleOAuthFailureKind.tokenExchangeFailed,
        ),
        onRefreshTokenInvalid: (id) async => flagged.add(id),
      );
      await seed();

      final token = await manager.forceRefresh(accountId);

      expect(token, isNull);
      expect(flagged, isEmpty, reason: 'transient failures self-heal next sync');
    });

    test('the manager does not dedup — each refresh reports the failure', () async {
      // Dedup is the repository/DB layer\'s job (the null→set transition); the
      // manager must report every terminal failure so the flag can be set.
      final flagged = <String>[];
      final manager = GoogleTokenManager(
        repo,
        (_) async => throw const GoogleOAuthException(
          'dead',
          kind: GoogleOAuthFailureKind.invalidGrant,
        ),
        onRefreshTokenInvalid: (id) async => flagged.add(id),
      );
      await seed();

      await manager.forceRefresh(accountId);
      await manager.forceRefresh(accountId);

      expect(flagged, [accountId, accountId]);
    });

    test('a throwing callback never escapes the refresh', () async {
      final manager = GoogleTokenManager(
        repo,
        (_) async => throw const GoogleOAuthException(
          'dead',
          kind: GoogleOAuthFailureKind.invalidGrant,
        ),
        onRefreshTokenInvalid: (_) async => throw StateError('handler boom'),
      );
      await seed();

      // Must resolve to null, not rethrow the handler error.
      expect(await manager.forceRefresh(accountId), isNull);
    });
  });

  group('googleAccountWorkspaceId', () {
    test('recovers the workspace id from a well-formed account id', () {
      final id = googleAccountId('ws-123', 'user@example.com');
      expect(googleAccountWorkspaceId(id), 'ws-123');
    });

    test('handles an email containing extra colons safely', () {
      // The workspace id is always the second segment, regardless of the email.
      expect(
        googleAccountWorkspaceId('google:ws-123:weird:name@example.com'),
        'ws-123',
      );
    });

    test('returns null for malformed ids', () {
      expect(googleAccountWorkspaceId('not-an-id'), isNull);
      expect(googleAccountWorkspaceId('google:'), isNull);
      expect(googleAccountWorkspaceId('github:ws:e@x.com'), isNull);
    });
  });
}
