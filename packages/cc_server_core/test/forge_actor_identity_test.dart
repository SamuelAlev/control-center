import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show ForgeHttpClientFactory;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
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
    tokenLookup: (forge) => _creds.tokenForActor(forge, _userId),
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

void main() {
  group('per-actor forge identity', () {
    late Directory dir;
    late ForgeCredentials creds;

    const alice = 'user-alice';
    const bob = 'user-bob';

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cc_forge_actor_');
      final secrets = FileSecretsStore(dataDir: dir.path);
      creds = ForgeCredentials(
        env: (name) => const {'GITHUB_TOKEN': 'server-env-token'}[name],
        users: UserCredentialsStore(secrets),
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('two members carry two identities, never each other\'s', () async {
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      expect(
        await _ActorForgeClient(creds, alice).authorizationForGetUser(),
        'Bearer alice-token',
      );
      expect(
        await _ActorForgeClient(creds, bob).authorizationForGetUser(),
        'Bearer bob-token',
      );
    });

    test(
      'background work with no actor stays on the server credential',
      () async {
        await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

        expect(
          await _ActorForgeClient(creds, null).authorizationForGetUser(),
          'Bearer server-env-token',
        );
      },
    );

    test('signing in mid-session applies to the next request, not the next '
        'restart', () async {
      // The runtime memoizes one factory per actor. That is only safe because
      // the credential is read per request, never captured at construction.
      final client = _ActorForgeClient(creds, alice);
      expect(await client.authorizationForGetUser(), 'Bearer server-env-token');

      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      expect(await client.authorizationForGetUser(), 'Bearer alice-token');

      await creds.clearToken(ForgeHost.github, userId: alice);
      expect(await client.authorizationForGetUser(), 'Bearer server-env-token');
    });
  });
}
