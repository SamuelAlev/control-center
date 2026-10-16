import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late HttpServer github;
  late _LoopbackHttpClient http;
  late UserCredentialsStore users;
  late ProviderOAuthService oauth;
  late DateTime now;
  late String tokenOutcome;
  late int attempts;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cc_device_login_');
    final secrets = FileSecretsStore(dataDir: dir.path);
    users = UserCredentialsStore(secrets);
    final apps = ProviderAppSettings(secrets: secrets);
    await apps.save(ProviderApp.github, clientId: 'public-client');
    now = DateTime.now().toUtc();
    tokenOutcome = 'authorization_pending';
    attempts = 0;
    github = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    github.listen((request) async {
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      final Object body = switch (request.uri.path) {
        '/login/device/code' => {
          'device_code': 'private-device-${++attempts}',
          'user_code': 'ABCD-1234',
          'verification_uri': 'https://github.com/login/device',
          'expires_in': 900,
          'interval': 1,
        },
        '/login/oauth/access_token' =>
          tokenOutcome == 'approved'
              ? {'access_token': 'new-user-token'}
              : {'error': tokenOutcome},
        '/user' => {'login': 'octocat'},
        _ => throw StateError('Unexpected GitHub path ${request.uri.path}'),
      };
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    http = _LoopbackHttpClient(github.port);
    oauth = ProviderOAuthService(
      apps: apps,
      users: users,
      httpClient: http,
      now: () => now,
    );
  });

  tearDown(() async {
    http.close(force: true);
    await github.close(force: true);
    await dir.delete(recursive: true);
  });

  Future<DeviceLoginPrompt> begin() => oauth.beginDeviceLogin(
    provider: ProviderApp.github,
    userId: 'alice',
    workspaceId: 'ws-a',
  );

  DeviceLoginStatus status(DeviceLoginPrompt prompt) => oauth.deviceLoginStatus(
    loginId: prompt.loginId,
    userId: 'alice',
    workspaceId: 'ws-a',
  );

  Future<DeviceLoginStatus> finish(DeviceLoginPrompt prompt) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (status(prompt) == DeviceLoginStatus.pending) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Device login never reached a terminal outcome');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return status(prompt);
  }

  test(
    'first approval persists the account before reporting success',
    () async {
      final prompt = await begin();
      expect(status(prompt), DeviceLoginStatus.pending);
      tokenOutcome = 'approved';
      expect(await finish(prompt), DeviceLoginStatus.succeeded);

      final persisted = UserCredentialsStore(
        FileSecretsStore(dataDir: dir.path),
      );
      final credential = await persisted.forgeToken(
        'alice',
        ForgeHost.github,
        workspaceId: 'ws-a',
      );
      expect(credential?.accessToken, 'new-user-token');
      expect(credential?.accountLogin, 'octocat');
      final connections = await ForgeCredentials(
        env: (_) => null,
        users: persisted,
      ).connections(userId: 'alice', workspaceId: 'ws-a');
      expect(connections.first.authenticated, isTrue);
      expect(connections.first.username, 'octocat');
      expect(await persisted.forgeToken('alice', ForgeHost.github), isNull);
      expect(
        await persisted.forgeToken(
          'bob',
          ForgeHost.github,
          workspaceId: 'ws-a',
        ),
        isNull,
      );
    },
  );

  test('an existing credential cannot complete a new attempt', () async {
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      const ProviderToken(accessToken: 'old-token', accountLogin: 'octocat'),
      workspaceId: 'ws-a',
    );
    final prompt = await begin();
    expect(status(prompt), DeviceLoginStatus.pending);
    tokenOutcome = 'approved';
    expect(await finish(prompt), DeviceLoginStatus.succeeded);
    expect(
      (await users.forgeToken(
        'alice',
        ForgeHost.github,
        workspaceId: 'ws-a',
      ))?.accessToken,
      'new-user-token',
    );
  });

  test('attempt status is private to its user and workspace', () async {
    final prompt = await begin();
    for (final scope in [
      (user: 'bob', workspace: 'ws-a'),
      (user: 'alice', workspace: 'ws-b'),
      (user: 'alice', workspace: null),
    ]) {
      expect(
        () => oauth.deviceLoginStatus(
          loginId: prompt.loginId,
          userId: scope.user,
          workspaceId: scope.workspace,
        ),
        throwsA(isA<AuthException>()),
      );
    }
    tokenOutcome = 'access_denied';
    expect(await finish(prompt), DeviceLoginStatus.failed);
  });

  test('refusal terminates without replacing an existing credential', () async {
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      const ProviderToken(accessToken: 'old-token'),
      workspaceId: 'ws-a',
    );
    final prompt = await begin();
    tokenOutcome = 'access_denied';
    expect(await finish(prompt), DeviceLoginStatus.failed);
    expect(
      (await users.forgeToken(
        'alice',
        ForgeHost.github,
        workspaceId: 'ws-a',
      ))?.accessToken,
      'old-token',
    );
  });

  test('starting again terminates only the superseded attempt', () async {
    final previous = await begin();
    final current = await begin();
    expect(status(previous), DeviceLoginStatus.failed);
    expect(status(current), DeviceLoginStatus.pending);
    tokenOutcome = 'approved';
    expect(await finish(current), DeviceLoginStatus.succeeded);
    expect(status(previous), DeviceLoginStatus.failed);
  });

  test('expiry terminates a pending attempt without a credential', () async {
    final prompt = await begin();
    now = now.add(const Duration(minutes: 16));
    expect(status(prompt), DeviceLoginStatus.failed);
    expect(
      await users.forgeToken('alice', ForgeHost.github, workspaceId: 'ws-a'),
      isNull,
    );
  });
}

/// Exercise real HTTP parsing and persistence without contacting GitHub.
class _LoopbackHttpClient implements HttpClient {
  _LoopbackHttpClient(this.port);

  final int port;
  final _inner = HttpClient();

  Uri _local(Uri uri) => uri.replace(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: port,
  );

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _inner.postUrl(_local(url));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _inner.getUrl(_local(url));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
