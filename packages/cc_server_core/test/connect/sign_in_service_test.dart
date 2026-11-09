import 'dart:async';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:test/test.dart';

/// Connect with a GitHub lane whose claim answers are scripted.
final class _FakeConnect extends ConnectClient {
  _FakeConnect(FileSecretsStore secrets)
    : super(
        settings: ConnectSettings(
          secrets: secrets,
          environment: const {'CC_CONNECT_URL': 'https://connect.example'},
        ),
      );

  final List<FutureOr<Map<String, Object?>> Function()> claims = [];
  int claimCalls = 0;

  @override
  Future<ConnectConfig?> usableConfig() async => ConnectConfig(
    epoch: 1,
    issuedAt: DateTime.utc(2026, 11, 8),
    github: const GitHubLaneConfig(
      appId: 1,
      clientId: 'Iv1test',
      appSlug: 'cc-test',
    ),
  );

  @override
  Future<OAuthStartResponse> startOAuth(
    ConnectOAuthLane lane,
    OAuthStartRequest request, {
    required String expectedClientId,
  }) async => OAuthStartResponse(
    loginId: newLoginId(),
    authorizeUrl: Uri.https('github.com', '/login/oauth/authorize'),
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
  );

  @override
  Future<Map<String, Object?>> claim(
    ConnectOAuthLane lane,
    OAuthClaimRequest request,
  ) async => claims[claimCalls++]();
}

final class _Lane implements SignInLaneBinding {
  final List<SignInResult> stored = [];

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => null;

  @override
  Future<bool> allowsConnect(String? workspaceId) async => true;

  @override
  Future<String?> slotFor(String? workspaceId) async => workspaceId;

  @override
  Future<SignInIdentity> identify(String accessToken) =>
      throw UnimplementedError();

  @override
  Future<void> store(SignInResult result) async => stored.add(result);

  @override
  Future<LaneConnection?> connection(
    String userId,
    String? workspaceId,
  ) async => null;

  @override
  Future<void> disconnect(String userId, String? workspaceId) async {}
}

Map<String, Object?> _grant() => SealedGrant(
  seal: 'v1.sealed',
  accessToken: 'ghu_live',
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
  accountId: '1001',
  accountLogin: 'octo',
  appId: '1',
).toJson();

void main() {
  late Directory dir;
  late _FakeConnect connect;
  late _Lane lane;
  late ProviderSignInService service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_sign_in_service_');
    connect = _FakeConnect(FileSecretsStore(dataDir: dir.path));
    lane = _Lane();
    service = ProviderSignInService(connect: connect)..register(lane);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<SignInAttempt> begin() => service.begin(
    lane: ConnectOAuthLane.github,
    userId: 'user-1',
    origin: '',
    workspaceId: 'ws-1',
  );

  test(
    'a mistyped code can be retried (Connect answers it access_denied)',
    () async {
      final attempt = await begin();
      connect.claims
        ..add(() => throw const ConnectException(ConnectErrorCode.accessDenied))
        ..add(_grant);

      await expectLater(
        service.complete(
          loginId: attempt.loginId,
          confirmCode: 'AAAAAAAA',
          userId: 'user-1',
          workspaceId: 'ws-1',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(attempt.status, SignInStatus.pending);

      final done = await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'BBBBBBBB',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
      expect(done.status, SignInStatus.succeeded);
      expect(lane.stored.single.token.seal, 'v1.sealed');
    },
  );

  test('a second completion while the first claims does not fail it', () async {
    final attempt = await begin();
    final gate = Completer<Map<String, Object?>>();
    connect.claims.add(() => gate.future);

    final first = service.complete(
      loginId: attempt.loginId,
      confirmCode: 'AAAAAAAA',
      userId: 'user-1',
      workspaceId: 'ws-1',
    );
    final second = await service.complete(
      loginId: attempt.loginId,
      confirmCode: 'AAAAAAAA',
      userId: 'user-1',
      workspaceId: 'ws-1',
    );
    expect(second.status, SignInStatus.pending);
    gate.complete(_grant());
    expect((await first).status, SignInStatus.succeeded);
    expect(connect.claimCalls, 1);
  });
}
