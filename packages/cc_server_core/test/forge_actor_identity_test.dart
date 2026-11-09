import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show ForgeHttpClientFactory;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The value of a header, case-insensitively.
String? _header(HttpHeaders? headers, String name) {
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final entry in headers.toMapList().entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value.isEmpty ? null : entry.value.first;
    }
  }
  return null;
}

/// The runtime's per-actor forge composition, reproduced: a factory per acting
/// user whose lookup binds THAT user, so the credential resolved on the wire is
/// the caller's. The factory's real auth interceptor is exercised — through its
/// injectable client builder, so no wire request is dialed — and the outgoing
/// `Authorization` is read off the request it produced.
class _ActorForgeClient {
  _ActorForgeClient(this._creds, this._userId);

  final ForgeCredentials _creds;
  final String? _userId;

  late final ForgeHttpClientFactory _factory = ForgeHttpClientFactory(
    tokenLookup: (forge) => _creds.tokenFor(forge, userId: _userId),
    bitbucketUsername: () => _creds.bitbucketEmail,
    buildClient: (baseUrl, settings, interceptors) {
      _interceptors = interceptors;
      // The transport is never reached — the interceptor above is driven
      // directly — so a canned client only satisfies the return type.
      return TestHttpClient(
        settings: settings,
        handler: (request) => httpTextResponse(request, '{}'),
      );
    },
  );

  List<Interceptor> _interceptors = const [];

  /// The `Authorization` the factory would put on a `GET /user`, resolved by
  /// running the factory's own interceptor against the runtime-bound lookup.
  Future<String?> authorizationForGetUser() async {
    // Building the client captures the interceptor list the factory wires.
    _factory.of(ForgeHost.github);
    var request = HttpRequest(url: 'https://api.github.com/user');
    for (final interceptor in _interceptors) {
      final result = await interceptor.beforeRequest(request);
      request = result.value ?? request;
    }
    return _header(request.headers, 'Authorization');
  }
}

ProviderToken _signIn(String access) => ProviderToken(
  accessToken: access,
  refreshToken: 'ghr_refresh',
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
  source: ForgeCredentialSource.oauth,
  appId: 'Iv1.app',
);

void main() {
  group('per-actor forge identity', () {
    late Directory dir;
    late UserCredentialsStore users;
    late ForgeCredentials creds;

    const alice = 'user-alice';
    const bob = 'user-bob';

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cc_forge_actor_');
      users = UserCredentialsStore(FileSecretsStore(dataDir: dir.path));
      creds = ForgeCredentials(
        env: (name) => const {'GITHUB_TOKEN': 'server-env-token'}[name],
        users: users,
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test("two members carry two identities, never each other's", () async {
      await creds.storeSignIn(ForgeHost.github, alice, _signIn('ghu_alice'));
      await creds.storeSignIn(ForgeHost.github, bob, _signIn('ghu_bob'));

      expect(
        await _ActorForgeClient(creds, alice).authorizationForGetUser(),
        'Bearer ghu_alice',
      );
      expect(
        await _ActorForgeClient(creds, bob).authorizationForGetUser(),
        'Bearer ghu_bob',
      );
    });

    test(
      'no actor sends no GitHub credential (never the host token)',
      () async {
        await creds.storeSignIn(ForgeHost.github, alice, _signIn('ghu_alice'));

        expect(
          await _ActorForgeClient(creds, null).authorizationForGetUser(),
          isNull,
        );
      },
    );

    test('signing in mid-session applies to the next request, not the next '
        'restart', () async {
      // The runtime memoizes one factory per actor. That is only safe because
      // the credential is read per request, never captured at construction.
      final client = _ActorForgeClient(creds, alice);
      expect(await client.authorizationForGetUser(), isNull);

      await creds.storeSignIn(ForgeHost.github, alice, _signIn('ghu_alice'));
      expect(await client.authorizationForGetUser(), 'Bearer ghu_alice');

      await creds.clearToken(ForgeHost.github, userId: alice);
      expect(await client.authorizationForGetUser(), isNull);
    });
  });
}
