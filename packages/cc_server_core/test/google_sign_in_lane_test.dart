import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/google_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The Google Calendar sign-in lane: own app from `ProviderApp.google`, a
/// workspace is mandatory, the exact scope set is enforced, and a finished
/// sign-in becomes the member's calendar account in that workspace.
void main() {
  const workspaceId = 'ws-1';
  const clientId = 'own.apps.googleusercontent.com';

  late Directory dir;
  late FileSecretsStore secrets;
  late ProviderAppSettings apps;
  late WorkspaceProviderAppSettings workspaceApps;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager workspaces;
  late DaoCalendarRepository calendar;
  late FileGoogleCredentialsStore store;
  late ServerGoogleTokenManager tokens;
  late CalendarAccountService accounts;
  late List<String> synced;
  late _FakeGoogle google;
  late GoogleSignInLane lane;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_google_lane_');
    secrets = FileSecretsStore(dataDir: dir.path);
    apps = ProviderAppSettings(secrets: secrets);
    workspaceApps = WorkspaceProviderAppSettings(secrets);
    global = createTestGlobalDatabase();
    workspaces = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, workspaces, workspaceId);
    calendar = DaoCalendarRepository(workspaces);
    store = FileGoogleCredentialsStore(secrets);
    tokens = ServerGoogleTokenManager(
      store: store,
      refresh: (_, _) async => const RefreshUnavailable(),
      installId: (origin) async =>
          origin == 'https://connect.example' ? 'inst-1' : '',
      ownClientId: (ws) async =>
          await workspaceApps.ownClientId(ws, WorkspaceAppProvider.google) ??
          (await apps.oauthCredentials(ProviderApp.google))?.clientId,
      allowsConnect: (ws) async =>
          !await workspaceApps.ownsApp(ws, WorkspaceAppProvider.google),
    );
    synced = [];
    accounts = CalendarAccountService(
      store: store,
      tokens: tokens,
      calendarRepository: calendar,
      onConnected: (ws) async => synced.add(ws),
    );
    google = await _FakeGoogle.start();
    lane = GoogleSignInLane(
      apps: apps,
      workspaceApps: workspaceApps,
      accounts: accounts,
      tokenEndpoint: google.uri('/token'),
      userinfoEndpoint: google.uri('/userinfo'),
    );
  });

  tearDown(() async {
    await google.close();
    await workspaces.closeAll();
    await global.close();
    dir.deleteSync(recursive: true);
  });

  group('ownApp', () {
    test('none routes through Connect', () async {
      expect(await lane.ownApp(workspaceId), isNull);
    });

    test('partial is a setup error, never a Connect fallback', () async {
      await apps.save(ProviderApp.google, clientId: clientId);
      expect(
        () => lane.ownApp(workspaceId),
        throwsA(isA<SignInMisconfigured>()),
      );
    });

    test(
      'complete is Google\'s fixed flow with the operator\'s pair',
      () async {
        await apps.save(
          ProviderApp.google,
          clientId: clientId,
          clientSecret: 'shh',
        );
        final own = (await GoogleSignInLane(
          apps: apps,
          workspaceApps: workspaceApps,
          accounts: accounts,
        ).ownApp(workspaceId))!;
        expect(own.authorize, googleAuthorizeEndpoint);
        expect(own.token, googleTokenEndpoint);
        expect(own.clientId, clientId);
        expect(own.clientSecret, 'shh');
        expect(own.scopes, googleConnectScopes);
        expect(own.extraAuthorizeParams, {
          'access_type': 'offline',
          'prompt': 'consent select_account',
        });
      },
    );
  });

  group("a workspace's own Google client", () {
    test(
      'wins over the server client and never routes through Connect',
      () async {
        await apps.save(
          ProviderApp.google,
          clientId: clientId,
          clientSecret: 'server-secret',
        );
        await workspaceApps.save(workspaceId, WorkspaceAppProvider.google, {
          'client_id': 'ws.apps.googleusercontent.com',
          'client_secret': 'ws-secret',
        });
        final own = (await lane.ownApp(workspaceId))!;
        expect(own.clientId, 'ws.apps.googleusercontent.com');
        expect(own.clientSecret, 'ws-secret');
        expect(await lane.allowsConnect(workspaceId), isFalse);
        // Another workspace keeps the server's client and may use Connect.
        expect((await lane.ownApp('ws-2'))!.clientId, clientId);
        expect(await lane.allowsConnect('ws-2'), isTrue);
      },
    );

    test('half-configured is a setup error, not the server client', () async {
      await apps.save(
        ProviderApp.google,
        clientId: clientId,
        clientSecret: 'server-secret',
      );
      await workspaceApps.setMode(
        workspaceId,
        WorkspaceAppProvider.google,
        WorkspaceAppMode.own,
      );
      expect(
        () => lane.ownApp(workspaceId),
        throwsA(isA<SignInMisconfigured>()),
      );
      expect(await lane.allowsConnect(workspaceId), isFalse);
    });

    test('drops grants the previous app issued on revalidation', () async {
      await apps.save(
        ProviderApp.google,
        clientId: clientId,
        clientSecret: 'server-secret',
      );
      final accountId = await accounts.connect(
        workspaceId: workspaceId,
        userId: 'alice',
        email: 'alice@example.com',
        token: ProviderToken(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          source: ForgeCredentialSource.oauth,
          appId: clientId,
        ),
      );
      await workspaceApps.save(workspaceId, WorkspaceAppProvider.google, {
        'client_id': 'ws.apps.googleusercontent.com',
        'client_secret': 'ws-secret',
      });
      await tokens.revalidateWorkspace(workspaceId);
      expect(await store.load(accountId), isNull);
      expect(await tokens.accessTokenFor(accountId), isNull);
    });
  });

  test('a calendar sign-in needs a workspace', () async {
    expect(await lane.allowsConnect(null), isTrue);
    expect(await lane.slotFor(workspaceId), workspaceId);
    expect(() => lane.slotFor(null), throwsA(isA<AuthException>()));
    expect(() => lane.slotFor(''), throwsA(isA<AuthException>()));
  });

  test('identify reads sub and email from userinfo', () async {
    final who = await lane.identify('access-1');
    expect(who.id, 'google-sub-1');
    expect(who.login, 'me@example.com');
    expect(google.userinfoAuth, 'Bearer access-1');
  });

  group('own-app sign-in end to end', () {
    late ProviderSignInService service;

    setUp(() async {
      await apps.save(
        ProviderApp.google,
        clientId: clientId,
        clientSecret: 'shh',
      );
      service = ProviderSignInService(
        connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
      )..register(lane);
    });

    Future<SignInAttempt> begin() => service.begin(
      lane: ConnectOAuthLane.google,
      userId: 'user-1',
      origin: 'https://cc.example',
      workspaceId: workspaceId,
    );

    Uri callback(SignInAttempt attempt) => Uri.parse(
      'https://cc.example/oauth/google/callback'
      '?state=${attempt.url.queryParameters['state']}&code=the-code',
    );

    test('the authorize URL asks for the exact scopes and consent', () async {
      final attempt = await begin();
      final q = attempt.url.queryParameters;
      expect(attempt.url.host, 'accounts.google.com');
      expect(q['client_id'], clientId);
      expect(q['access_type'], 'offline');
      expect(q['prompt'], 'consent select_account');
      expect(splitScopes(q['scope']), googleConnectScopes);
    });

    test('a narrower grant is refused and stores nothing', () async {
      google.grantedScope = 'openid email';
      final attempt = await begin();
      await expectLater(
        service.handleCallback(callback(attempt)),
        throwsA(isA<AuthException>()),
      );
      expect(attempt.error, 'scope_mismatch');
      expect(await calendar.getAccounts(workspaceId), isEmpty);
      expect(
        await store.raw(
          serverGoogleAccountId(
            workspaceId,
            'me@example.com',
            userId: 'user-1',
          ),
        ),
        isNull,
      );
    });

    test('a read-only Calendar grant is refused', () async {
      google.grantedScope =
          'openid email https://www.googleapis.com/auth/calendar.readonly';
      final attempt = await begin();
      await expectLater(
        service.handleCallback(callback(attempt)),
        throwsA(isA<AuthException>()),
      );
      expect(attempt.error, 'scope_mismatch');
    });

    test('a wider grant is refused as firmly', () async {
      google.grantedScope =
          'openid email https://www.googleapis.com/auth/calendar';
      final attempt = await begin();
      await expectLater(
        service.handleCallback(callback(attempt)),
        throwsA(isA<AuthException>()),
      );
      expect(attempt.error, 'scope_mismatch');
    });

    test('the exact grant becomes the member\'s calendar account', () async {
      final attempt = await begin();
      await service.handleCallback(callback(attempt));
      expect(attempt.status, SignInStatus.succeeded);
      expect(attempt.account, 'me@example.com');
      expect(google.tokenForm['client_secret'], 'shh');
      expect(google.tokenForm['code_verifier'], isNotEmpty);

      final id = serverGoogleAccountId(
        workspaceId,
        'me@example.com',
        userId: 'user-1',
      );
      final rows = await calendar.getAccounts(workspaceId);
      expect(rows.single.id, id);
      expect(rows.single.userId, 'user-1');
      final stored = (await store.load(id))!;
      expect(stored.isSealed, isFalse);
      expect(stored.appId, clientId);
      expect(stored.accountId, 'google-sub-1');
      expect(await tokens.accessTokenFor(id), 'google-access');
      expect(synced, [workspaceId]);
    });
  });

  test('a Connect grant keeps only its seal on disk', () async {
    final expires = DateTime.now().toUtc().add(const Duration(hours: 1));
    await lane.store(
      SignInResult(
        lane: ConnectOAuthLane.google,
        userId: 'user-1',
        workspaceId: workspaceId,
        slot: workspaceId,
        token: ProviderToken(
          accessToken: 'connect-access',
          expiresAt: expires,
          source: ForgeCredentialSource.connect,
          accountId: 'google-sub-1',
          seal: 'sealed-refresh',
          sealInstallId: 'inst-1',
          connectOrigin: 'https://connect.example',
        ),
      ),
    );
    // The grant named no email, so the lane asked Google with the access
    // token it had in hand.
    expect(google.userinfoAuth, 'Bearer connect-access');
    final id = serverGoogleAccountId(
      workspaceId,
      'me@example.com',
      userId: 'user-1',
    );
    final raw = jsonDecode((await store.raw(id))!) as Map;
    expect(raw['seal'], 'sealed-refresh');
    expect(raw.containsKey('access'), isFalse);
    expect(jsonEncode(raw), isNot(contains('connect-access')));
    expect(await tokens.accessTokenFor(id), 'connect-access');
  });

  test(
    'the lane reports no grant of its own and disconnects nothing',
    () async {
      expect(await lane.connection('user-1', workspaceId), isNull);
      await lane.disconnect('user-1', workspaceId);
    },
  );

  group('dropLegacy', () {
    test('removes member-less rows and flags old-shape credentials', () async {
      const legacyPool = 'google:ws-1:pool@example.com';
      final member = serverGoogleAccountId(
        workspaceId,
        'old@example.com',
        userId: 'user-1',
      );
      final healthy = serverGoogleAccountId(
        workspaceId,
        'new@example.com',
        userId: 'user-2',
      );
      for (final (id, user, email) in [
        (legacyPool, '', 'pool@example.com'),
        (member, 'user-1', 'old@example.com'),
        (healthy, 'user-2', 'new@example.com'),
      ]) {
        await calendar.upsertAccount(
          CalendarAccount(
            id: id,
            workspaceId: workspaceId,
            userId: user,
            providerId: 'google',
            accountEmail: email,
          ),
        );
      }
      final deviceShape = jsonEncode({
        'accessToken': 'a',
        'refreshToken': 'r',
        'usesBuiltinClient': true,
      });
      await secrets.writePsk('google_$legacyPool', deviceShape);
      await secrets.writePsk('google_$member', deviceShape);
      await store.save(
        healthy,
        const ProviderToken(
          accessToken: 'a',
          refreshToken: 'r',
          source: ForgeCredentialSource.oauth,
          appId: clientId,
        ),
      );

      await accounts.dropLegacy([workspaceId]);

      final rows = {
        for (final a in await calendar.getAccounts(workspaceId)) a.id: a,
      };
      expect(rows.keys, unorderedEquals([member, healthy]));
      expect(rows[member]!.needsReauth, isTrue);
      expect(rows[healthy]!.needsReauth, isFalse);
      expect(await store.raw(legacyPool), isNull);
      expect(await store.raw(member), isNull);
      expect(await store.raw(healthy), isNotNull);
    });
  });
}

/// Google's token and userinfo endpoints on loopback.
class _FakeGoogle {
  _FakeGoogle._(this._server) {
    _server.listen(_handle);
  }

  static Future<_FakeGoogle> start() async =>
      _FakeGoogle._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;

  /// What the token endpoint reports as granted.
  String grantedScope =
      'openid https://www.googleapis.com/auth/userinfo.email '
      '$googleCalendarEventsScope $googleCalendarListScope';

  /// The last token request's form.
  Map<String, String> tokenForm = const {};

  /// The last userinfo request's Authorization header.
  String userinfoAuth = '';

  Uri uri(String path) =>
      Uri.parse('http://${_server.address.address}:${_server.port}$path');

  Future<void> _handle(HttpRequest request) async {
    final response = request.response..headers.contentType = ContentType.json;
    switch (request.uri.path) {
      case '/token':
        tokenForm = Uri.splitQueryString(
          await utf8.decoder.bind(request).join(),
        );
        response.write(
          jsonEncode({
            'access_token': 'google-access',
            'refresh_token': 'google-refresh',
            'expires_in': 3599,
            'scope': grantedScope,
            'token_type': 'Bearer',
          }),
        );
      case '/userinfo':
        userinfoAuth = request.headers.value('authorization') ?? '';
        response.write(
          jsonEncode({'sub': 'google-sub-1', 'email': 'me@example.com'}),
        );
      default:
        response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  Future<void> close() => _server.close(force: true);
}
