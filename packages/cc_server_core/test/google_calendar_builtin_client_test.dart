import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show GoogleOAuthException, WorkspaceMismatchException;
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show GoogleServerCredentials, googleOAuthTokenEndpoint;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Connecting a calendar with Control Center's own Google app.
///
/// The security property under test is narrow and absolute: **the server's own
/// client secret never lands in the secrets file.** An account connected
/// that way stores a marker instead and every later refresh resolves the marker
/// against whatever the server is configured with *now*. That indirection is what
/// makes rotating the shipped secret a matter of releasing a new build rather
/// than stranding every connected account and it means a leaked credentials file
/// gives up one user's refresh token rather than the credential every install
/// shares.
///
/// The bring-your-own path is asserted alongside it, unchanged: a user's own
/// Google Cloud pair is stored literally, because the server has no other way to
/// know it.
void main() {
  late Directory dataDir;
  late FileGoogleCredentialsStore store;
  late _FakeCalendarRepository calendars;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc-google-builtin');
    store = FileGoogleCredentialsStore(dataDir: dataDir.path);
    calendars = _FakeCalendarRepository();
  });

  tearDown(() => dataDir.deleteSync(recursive: true));

  CalendarConnectService service({
    GoogleOAuthClient serverClient = const GoogleOAuthClient.none(),
    _GoogleStub? stub,
  }) => CalendarConnectService(
    store: store,
    calendarRepository: calendars,
    serverClient: serverClient,
    httpClientFactory: stub == null ? null : () => stub.client,
  );

  const builtin = GoogleOAuthClient(
    clientId: 'builtin-id.apps.googleusercontent.com',
    clientSecret: 'builtin-secret',
  );

  group('what the dialog is allowed to offer', () {
    test('a server with a client of its own offers it', () {
      expect(service(serverClient: builtin).builtinAvailable, isTrue);
    });

    test('a server with none does not', () {
      expect(service().builtinAvailable, isFalse);
    });

    test('half a pair is not an offer', () {
      // Google's device-code exchange refuses a client id without its secret, so
      // offering this would produce a dead end after the user had already typed
      // a code into google.com/device.
      expect(
        service(
          serverClient: const GoogleOAuthClient(
            clientId: 'id-only',
            clientSecret: '',
          ),
        ).builtinAvailable,
        isFalse,
      );
    });
  });

  group('begin', () {
    test('refuses use_builtin when nothing is baked in', () async {
      await expectLater(
        service().begin(workspaceId: 'ws-1', useBuiltin: true),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.message,
            'message',
            contains('your own'),
          ),
        ),
      );
    });

    test('refuses an empty bring-your-own pair', () async {
      await expectLater(
        service(serverClient: builtin).begin(workspaceId: 'ws-1'),
        throwsA(isA<GoogleOAuthException>()),
      );
    });

    test('authorizes with the server client and never echoes it back', () async {
      final stub = _GoogleStub();

      final begin = await service(
        serverClient: builtin,
        stub: stub,
      ).begin(workspaceId: 'ws-1', useBuiltin: true);

      expect(begin.userCode, 'WDJB-MJHT');
      expect(begin.verificationUrl, 'https://www.google.com/device');
      expect(stub.deviceCodeRequests.single['client_id'], builtin.clientId);
      // The handle and the display strings are all the client gets — a response
      // carrying the secret would put it on every paired device.
      expect(
        [begin.handle, begin.userCode, begin.verificationUrl].join(),
        isNot(contains('builtin-secret')),
      );
    });
  });

  group('poll stores a marker, not the secret', () {
    test('a built-in connect writes no client credentials at all', () async {
      final stub = _GoogleStub();
      final connect = service(serverClient: builtin, stub: stub);
      final begin = await connect.begin(workspaceId: 'ws-1', useBuiltin: true);

      final poll = await connect.poll(
        workspaceId: 'ws-1',
        handle: begin.handle,
      );

      expect(poll.status, CalendarConnectStatus.connected);
      expect(poll.accountEmail, 'someone@example.com');
      final accountId = serverGoogleAccountId('ws-1', 'someone@example.com');
      final saved = (await store.load(accountId))!;
      expect(saved.usesBuiltinClient, isTrue);
      expect(saved.clientId, isEmpty);
      expect(saved.clientSecret, isEmpty);
      // Belt and braces: the whole file, as bytes on disk.
      final onDisk = File(
        '${dataDir.path}${Platform.pathSeparator}${FileSecretsStore.fileName}',
      ).readAsStringSync();
      expect(onDisk, isNot(contains('builtin-secret')));
      expect(onDisk, isNot(contains(builtin.clientId)));
      // The refresh token — the thing worth protecting — is of course kept.
      expect(saved.refreshToken, '1//refresh');
      expect(calendars.accounts.single.accountEmail, 'someone@example.com');
    });

    test('a bring-your-own connect stores the pair it was given', () async {
      final stub = _GoogleStub();
      final connect = service(serverClient: builtin, stub: stub);
      final begin = await connect.begin(
        workspaceId: 'ws-1',
        clientId: 'mine.apps.googleusercontent.com',
        clientSecret: 'my-secret',
      );

      await connect.poll(workspaceId: 'ws-1', handle: begin.handle);

      // The server has no other copy of a user's own client, so this one must be
      // literal — and it must not be mistaken for a built-in connection later.
      final saved = (await store.load(
        serverGoogleAccountId('ws-1', 'someone@example.com'),
      ))!;
      expect(saved.usesBuiltinClient, isFalse);
      expect(saved.clientId, 'mine.apps.googleusercontent.com');
      expect(saved.clientSecret, 'my-secret');
      expect(stub.deviceCodeRequests.single['client_id'], saved.clientId);
    });

    test('a handle cannot be polled from another workspace', () async {
      final stub = _GoogleStub();
      final connect = service(serverClient: builtin, stub: stub);
      final begin = await connect.begin(workspaceId: 'ws-1', useBuiltin: true);

      await expectLater(
        connect.poll(workspaceId: 'ws-2', handle: begin.handle),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(calendars.accounts, isEmpty);
    });
  });

  group('refresh resolves the marker', () {
    Future<void> saveMarker() => store.save(
      'google:ws-1:someone@example.com',
      GoogleServerCredentials(
        accessToken: 'stale',
        refreshToken: '1//refresh',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        accountEmail: 'someone@example.com',
        scope: 'calendar.readonly',
        clientId: '',
        clientSecret: '',
        usesBuiltinClient: true,
      ),
    );

    test('against the pair the server holds now, so rotation works', () async {
      await saveMarker();
      final stub = _GoogleStub();
      // Deliberately NOT the pair the account was connected under: this stands in
      // for a rotated secret shipped in a later build.
      final tokens = ServerGoogleTokenManager(
        store: store,
        serverClient: const GoogleOAuthClient(
          clientId: 'rotated-id.apps.googleusercontent.com',
          clientSecret: 'rotated-secret',
        ),
        httpClientFactory: () => stub.client,
      );

      final token = await tokens.accessTokenFor(
        'google:ws-1:someone@example.com',
      );

      expect(token, 'fresh-access');
      final refresh = stub.refreshRequests.single;
      expect(refresh['client_id'], 'rotated-id.apps.googleusercontent.com');
      expect(refresh['client_secret'], 'rotated-secret');
      // Refreshing must not turn the marker into a stored copy of the pair.
      final saved = (await store.load('google:ws-1:someone@example.com'))!;
      expect(saved.usesBuiltinClient, isTrue);
      expect(saved.clientId, isEmpty);
      expect(saved.clientSecret, isEmpty);
    });

    test('a server that no longer has one dials nothing', () async {
      await saveMarker();
      final stub = _GoogleStub();
      final tokens = ServerGoogleTokenManager(
        store: store,
        httpClientFactory: () => stub.client,
      );

      // e.g. an account connected on an official build, then moved to a
      // self-hosted server that configures no client. There is nothing to
      // substitute — a refresh with an empty client id would be a guaranteed
      // failure Google counts against us — so the manager logs and stops.
      expect(
        await tokens.forceRefresh('google:ws-1:someone@example.com'),
        isNull,
      );
      // The stale token is still handed out (the expiry check carries a 5-minute
      // skew, so it may yet work); what must not happen is a request.
      expect(
        await tokens.accessTokenFor('google:ws-1:someone@example.com'),
        'stale',
      );
      expect(stub.tokenRequests, isEmpty);
    });

    test("a user's own pair is used as stored, not the server's", () async {
      await store.save(
        'google:ws-1:someone@example.com',
        GoogleServerCredentials(
          accessToken: 'stale',
          refreshToken: '1//refresh',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          accountEmail: 'someone@example.com',
          scope: 'calendar.readonly',
          clientId: 'mine.apps.googleusercontent.com',
          clientSecret: 'my-secret',
        ),
      );
      final stub = _GoogleStub();
      final tokens = ServerGoogleTokenManager(
        store: store,
        serverClient: builtin,
        httpClientFactory: () => stub.client,
      );

      expect(
        await tokens.accessTokenFor('google:ws-1:someone@example.com'),
        'fresh-access',
      );
      // A workspace can hold accounts from several Google projects, so the
      // server's own client must never be substituted for a stored one.
      expect(
        stub.refreshRequests.single['client_id'],
        'mine.apps.googleusercontent.com',
      );
    });
  });

  group('GoogleServerCredentials.asBuiltinClient', () {
    test('drops the pair, keeps everything worth keeping', () {
      final creds = GoogleServerCredentials(
        accessToken: 'access',
        refreshToken: '1//refresh',
        expiresAt: DateTime.utc(2026, 8, 13),
        accountEmail: 'someone@example.com',
        scope: 'calendar.readonly',
        clientId: 'builtin-id',
        clientSecret: 'builtin-secret',
      );

      final marked = creds.asBuiltinClient();

      expect(marked.usesBuiltinClient, isTrue);
      expect(marked.clientId, isEmpty);
      expect(marked.clientSecret, isEmpty);
      expect(marked.refreshToken, '1//refresh');
      expect(marked.accountEmail, 'someone@example.com');
      expect(jsonEncode(marked.toJson()), isNot(contains('builtin-secret')));
    });

    test('the marker survives a store round trip and a token refresh', () {
      final marked = GoogleServerCredentials(
        accessToken: 'access',
        refreshToken: '1//refresh',
        expiresAt: DateTime.utc(2026, 8, 13),
        accountEmail: 'someone@example.com',
        scope: 'calendar.readonly',
        clientId: 'x',
        clientSecret: 'y',
      ).asBuiltinClient();

      final reloaded = GoogleServerCredentials.fromJson(marked.toJson())!;
      expect(reloaded.usesBuiltinClient, isTrue);
      // A refresh replaces only the access token; losing the flag here would make
      // the NEXT refresh look for a stored pair that was never written.
      expect(
        reloaded
            .copyWithAccessToken(
              accessToken: 'fresh',
              expiresAt: DateTime.utc(2026, 8, 14),
            )
            .usesBuiltinClient,
        isTrue,
      );
    });

    test('a file written before the flag existed reads as bring-your-own', () {
      // Accounts connected before this feature stored a literal pair and that
      // is exactly how they must keep refreshing.
      final legacy = GoogleServerCredentials.fromJson(const {
        'accessToken': 'access',
        'refreshToken': '1//refresh',
        'accountEmail': 'someone@example.com',
        'clientId': 'legacy-id',
        'clientSecret': 'legacy-secret',
      })!;

      expect(legacy.usesBuiltinClient, isFalse);
      expect(legacy.clientId, 'legacy-id');
    });
  });
}

/// Answers Google's device-code and token endpoints over a [TestHttpClient],
/// recording the form bodies so a test can assert which client credentials were
/// actually sent.
class _GoogleStub {
  final List<Map<String, String>> deviceCodeRequests = [];
  final List<Map<String, String>> tokenRequests = [];

  /// The token calls that were refreshes rather than device-code exchanges.
  Iterable<Map<String, String>> get refreshRequests =>
      tokenRequests.where((r) => r['grant_type'] == 'refresh_token');

  /// A fresh transport for each `GoogleDeviceAuthClient` the services build.
  TestHttpClient get client => TestHttpClient(handler: _handle);

  /// The path of the token endpoint, so the two hops are told apart by URL
  /// rather than by the order they happen to arrive in.
  static final String _tokenPath = Uri.parse(googleOAuthTokenEndpoint).path;

  HttpResponse _handle(HttpRequest request) {
    final form = switch (request.body) {
      HttpBodyForm(:final form) => form,
      _ => const <String, String>{},
    };
    if (request.method == HttpMethod.post &&
        httpRequestUri(request).path == _tokenPath) {
      tokenRequests.add(form);
      return httpTextResponse(
        request,
        form['grant_type'] == 'refresh_token'
            ? {'access_token': 'fresh-access', 'expires_in': 3600}
            : {
                'access_token': 'access',
                'refresh_token': '1//refresh',
                'expires_in': 3600,
                'id_token': _idTokenFor('someone@example.com'),
                'scope': 'https://www.googleapis.com/auth/calendar.readonly',
              },
      );
    }
    deviceCodeRequests.add(form);
    return httpTextResponse(request, const {
      'device_code': 'device-1',
      'user_code': 'WDJB-MJHT',
      'verification_url': 'https://www.google.com/device',
      'expires_in': 1800,
      'interval': 5,
    });
  }

  /// An unsigned JWT whose payload carries the email — the shape the connect path
  /// reads the account address out of.
  static String _idTokenFor(String email) {
    String segment(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return '${segment(const {'alg': 'none'})}.'
        '${segment({'email': email})}.signature';
  }
}

class _FakeCalendarRepository implements CalendarRepository {
  final List<CalendarAccount> accounts = [];

  @override
  Future<void> upsertAccount(CalendarAccount account) async =>
      accounts.add(account);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
