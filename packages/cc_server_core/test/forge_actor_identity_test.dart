import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show ForgeDioFactory;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Records the `Authorization` header of every request instead of sending it.
class _HeaderRecorder implements HttpClientAdapter {
  final List<String?> authorizations = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizations.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  // The server composes one forge client per ACTING USER. This pins what that
  // buys: the identity on the wire is the caller's, so a review approved or a
  // comment posted through Control Center is attributed on the forge to the
  // person who did it — not to the server's app, and not to whoever happened to
  // open that pull request first.
  group('per-actor forge clients', () {
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

    /// The runtime's per-actor factory, reproduced: the acting user is bound
    /// into the lookup, and the lookup still runs per request.
    ForgeDioFactory factoryFor(String? userId) => ForgeDioFactory(
      tokenLookup: (forge) => creds.tokenForActor(forge, userId),
      bitbucketUsername: () => creds.bitbucketEmail,
      // The runtime declares this at every construction site; without it two
      // members' concurrent GETs to one URL coalesce (see the test below).
      // TEMPORARILY DISABLED to check the premise.
      // identity: userId == null ? 'server' : 'user:\$userId',
    );

    Future<List<String?>> send(ForgeDioFactory factory) async {
      final recorder = _HeaderRecorder();
      final dio = factory.of(ForgeHost.github)
        ..httpClientAdapter = recorder;
      await dio.get<dynamic>('/user');
      return recorder.authorizations;
    }

    // The dedup interceptor coalesces identical concurrent GETs, and its key
    // cannot see `Authorization` (the forge factory sets that header in an
    // interceptor registered AFTER it). What keeps two members apart is
    // therefore NOT the key — it is that each acting user gets their own
    // factory, hence their own client, hence their own in-flight map. That is
    // load-bearing and invisible, so it is pinned here rather than assumed.
    test('two members asking at the SAME MOMENT still get their own answers',
        () async {
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      final aliceRecorder = _HeaderRecorder();
      final bobRecorder = _HeaderRecorder();
      final aliceDio = factoryFor(alice).of(ForgeHost.github)
        ..httpClientAdapter = aliceRecorder;
      final bobDio = factoryFor(bob).of(ForgeHost.github)
        ..httpClientAdapter = bobRecorder;

      await Future.wait([
        aliceDio.get<dynamic>('/user'),
        bobDio.get<dynamic>('/user'),
      ]);

      expect(aliceRecorder.authorizations, ['Bearer alice-token']);
      expect(bobRecorder.authorizations, ['Bearer bob-token']);
    });

    test('two members writing to one repo carry two identities', () async {
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      await creds.setToken(ForgeHost.github, 'bob-token', userId: bob);

      expect(await send(factoryFor(alice)), ['Bearer alice-token']);
      expect(await send(factoryFor(bob)), ['Bearer bob-token']);
    });

    test('background work with no actor stays on the server credential',
        () async {
      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);

      expect(await send(factoryFor(null)), ['Bearer server-env-token']);
    });

    test('signing in mid-session applies to the next request, not the next '
        'restart', () async {
      // The factory is memoized per user by the runtime, so this is the
      // property that keeps that safe: the client is plumbing, the credential
      // is read per call.
      final factory = factoryFor(alice);
      expect(await send(factory), ['Bearer server-env-token']);

      await creds.setToken(ForgeHost.github, 'alice-token', userId: alice);
      expect(await send(factory), ['Bearer alice-token']);

      await creds.clearToken(ForgeHost.github, userId: alice);
      expect(await send(factory), ['Bearer server-env-token']);
    });
  });
}
