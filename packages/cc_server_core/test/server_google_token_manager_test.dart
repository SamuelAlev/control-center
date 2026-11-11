import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:test/test.dart';

/// The calendar token manager: only a refused grant clears a credential, an
/// outage keeps it and sends nothing expired, and a credential that is no
/// longer this server's (a seal for another install id, a grant of a replaced
/// own app, an older build's shape) reads as "connect again".
void main() {
  const accountId = 'google:ws-1:user-1:me@example.com';
  const installId = 'install-current';
  const ownClientId = 'own.apps.googleusercontent.com';

  late Directory dir;
  late FileSecretsStore secrets;
  late FileGoogleCredentialsStore store;
  late List<String> flagged;
  late List<ProviderToken> refreshCalls;
  late FutureOr<RefreshOutcome> Function(ProviderToken) onRefresh;
  late Future<String?> Function() currentOwnClientId;
  // The install id the workspace's current Connect knows this server by;
  // null while the workspace uses no Connect or another one.
  late String? currentInstallId;

  ServerGoogleTokenManager manager() => ServerGoogleTokenManager(
    store: store,
    refresh: (token, workspaceId) async {
      expect(workspaceId, 'ws-1');
      refreshCalls.add(token);
      return onRefresh(token);
    },
    installId: (origin, workspaceId) async {
      expect(workspaceId, 'ws-1');
      return origin == 'https://connect.example' ? currentInstallId : null;
    },
    ownClientId: (workspaceId) {
      expect(workspaceId, 'ws-1');
      return currentOwnClientId();
    },
    onInvalidGrant: (id) async => flagged.add(id),
  );

  final future = DateTime.now().toUtc().add(const Duration(hours: 1));
  final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));

  ProviderToken own({
    required DateTime expiresAt,
    String appId = ownClientId,
  }) => ProviderToken(
    accessToken: 'own-access',
    refreshToken: 'own-refresh',
    expiresAt: expiresAt,
    source: ForgeCredentialSource.oauth,
    accountLogin: 'me@example.com',
    appId: appId,
  );

  ProviderToken sealed({String sealInstallId = installId}) => ProviderToken(
    accessToken: 'sealed-access',
    expiresAt: future,
    source: ForgeCredentialSource.connect,
    accountLogin: 'me@example.com',
    seal: 'seal-1',
    sealInstallId: sealInstallId,
    connectOrigin: 'https://connect.example',
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_google_tokens_');
    secrets = FileSecretsStore(dataDir: dir.path);
    store = FileGoogleCredentialsStore(secrets);
    flagged = [];
    refreshCalls = [];
    onRefresh = (_) => const RefreshUnavailable();
    currentOwnClientId = () async => ownClientId;
    currentInstallId = installId;
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a live own-app token is used without a refresh', () async {
    await store.save(accountId, own(expiresAt: future));
    expect(await manager().accessTokenFor(accountId), 'own-access');
    expect(refreshCalls, isEmpty);
  });

  test('an expired token is refreshed and the renewal stored', () async {
    await store.save(accountId, own(expiresAt: past));
    onRefresh = (expired) =>
        Refreshed(expired.copyWith(accessToken: 'renewed', expiresAt: future));
    expect(await manager().accessTokenFor(accountId), 'renewed');
    expect((await store.load(accountId))!.accessToken, 'renewed');
    expect(flagged, isEmpty);
  });

  test(
    'a refused refresh clears the credential and flags the account',
    () async {
      await store.save(accountId, own(expiresAt: past));
      onRefresh = (_) => const RefreshRejected();
      expect(await manager().accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNull);
      expect(flagged, [accountId]);
    },
  );

  test(
    'an unavailable refresh keeps everything and sends nothing expired',
    () async {
      await store.save(accountId, own(expiresAt: past));
      onRefresh = (_) => const RefreshUnavailable();
      final tokens = manager();
      expect(await tokens.accessTokenFor(accountId), isNull);
      expect(await tokens.forceRefresh(accountId), isNull);
      expect((await store.load(accountId))!.refreshToken, 'own-refresh');
      expect(flagged, isEmpty);
    },
  );

  test('a throwing refresh is an outage, not a sign-out', () async {
    await store.save(accountId, own(expiresAt: past));
    onRefresh = (_) => throw const SocketException('down');
    expect(await manager().accessTokenFor(accountId), isNull);
    expect(await store.raw(accountId), isNotNull);
    expect(flagged, isEmpty);
  });

  test('concurrent callers share one refresh', () async {
    await store.save(accountId, own(expiresAt: past));
    final gate = Completer<RefreshOutcome>();
    onRefresh = (_) => gate.future;
    final tokens = manager();
    final calls = [
      tokens.accessTokenFor(accountId),
      tokens.accessTokenFor(accountId),
      tokens.forceRefresh(accountId),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 50));
    gate.complete(
      Refreshed(own(expiresAt: future).copyWith(accessToken: 'once')),
    );
    expect(await Future.wait(calls), ['once', 'once', 'once']);
    expect(refreshCalls, hasLength(1));
  });

  group('sealed (Connect) credentials', () {
    test('store only the seal; the access token lives in memory', () async {
      final tokens = manager();
      final token = sealed();
      await store.save(accountId, token);
      tokens.remember(accountId, token);

      final onDisk = jsonDecode((await store.raw(accountId))!) as Map;
      expect(onDisk.containsKey('access'), isFalse);
      expect(onDisk['seal'], 'seal-1');
      expect(await tokens.accessTokenFor(accountId), 'sealed-access');
      expect(refreshCalls, isEmpty);
    });

    test('after a restart the first call refreshes through the seal', () async {
      await store.save(accountId, sealed());
      onRefresh = (expired) {
        expect(expired.seal, 'seal-1');
        return Refreshed(
          expired.copyWith(
            accessToken: 'fresh',
            expiresAt: future,
            seal: 'seal-2',
          ),
        );
      };
      expect(await manager().accessTokenFor(accountId), 'fresh');
      final onDisk = (await store.load(accountId))!;
      expect(onDisk.seal, 'seal-2');
      expect(onDisk.accessToken, isEmpty);
    });

    test('a seal for another install id reads as "connect again"', () async {
      final tokens = manager();
      final token = sealed(sealInstallId: 'install-before-rotation');
      await store.save(accountId, token);
      tokens.remember(accountId, token);

      expect(await tokens.accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNull);
      expect(flagged, [accountId]);
      expect(refreshCalls, isEmpty);
    });

    test('Connect being off or pointed elsewhere keeps the seal', () async {
      final tokens = ServerGoogleTokenManager(
        store: store,
        refresh: (token, workspaceId) async => onRefresh(token),
        installId: (_, _) async => null,
        ownClientId: (_) => currentOwnClientId(),
        onInvalidGrant: (id) async => flagged.add(id),
      );
      await store.save(accountId, sealed());

      expect(await tokens.accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNotNull);
      expect(flagged, isEmpty);
      expect(refreshCalls, isEmpty);
    });
  });

  group('own-app credentials', () {
    test('a grant of a replaced own app is dropped', () async {
      await store.save(accountId, own(expiresAt: future, appId: 'old-app'));
      expect(await manager().accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNull);
      expect(flagged, [accountId]);
    });

    test('a grant whose own app was removed is dropped', () async {
      await store.save(accountId, own(expiresAt: future));
      currentOwnClientId = () async => null;
      expect(await manager().accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNull);
    });

    test('a half-edited own app signs nobody out', () async {
      await store.save(accountId, own(expiresAt: future));
      currentOwnClientId = () async =>
          throw const OwnAppIncomplete(ProviderApp.google);
      expect(await manager().accessTokenFor(accountId), 'own-access');
      expect(flagged, isEmpty);
    });
  });

  test('an older build\'s credential shape is dropped', () async {
    await secrets.writePsk(
      'google_$accountId',
      jsonEncode({
        'accessToken': 'legacy',
        'refreshToken': 'legacy-refresh',
        'expiresAt': future.toIso8601String(),
        'clientId': '',
        'clientSecret': '',
        'usesBuiltinClient': true,
      }),
    );
    expect(await manager().accessTokenFor(accountId), isNull);
    expect(await store.raw(accountId), isNull);
    expect(flagged, [accountId]);
  });

  test('no credential is quietly nothing', () async {
    expect(await manager().accessTokenFor(accountId), isNull);
    expect(flagged, isEmpty);
  });

  group('a workspace on its own Google client', () {
    test('parks a Connect seal: unusable, kept, and usable again once the '
        'workspace returns to that Connect', () async {
      currentInstallId = null;
      await store.save(accountId, sealed());
      expect(await manager().accessTokenFor(accountId), isNull);
      expect(await store.raw(accountId), isNotNull);
      expect(flagged, isEmpty);
      expect(refreshCalls, isEmpty);

      currentInstallId = installId;
      onRefresh = (token) =>
          Refreshed(token.copyWith(accessToken: 'renewed', expiresAt: future));
      expect(await manager().accessTokenFor(accountId), 'renewed');
      expect(refreshCalls, hasLength(1));
    });

    test('revalidateWorkspace drops grants of the previous client only in '
        'that workspace', () async {
      const otherAccount = 'google:ws-2:user-1:me@example.com';
      await store.save(accountId, own(expiresAt: future, appId: 'old-client'));
      await store.save(otherAccount, own(expiresAt: future));
      await manager().revalidateWorkspace('ws-1');
      expect(await store.raw(accountId), isNull);
      expect(await store.raw(otherAccount), isNotNull);
      expect(flagged, [accountId]);
    });
  });
}
