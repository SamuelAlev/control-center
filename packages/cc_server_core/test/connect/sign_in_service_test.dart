import 'dart:async';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:test/test.dart';

/// Connect with GitHub and Slack lanes whose claim answers are scripted.
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
  final List<SealRequest> slackRevokes = [];

  @override
  Future<void> slackRevoke(SealRequest request) async =>
      slackRevokes.add(request);

  @override
  Future<ConnectConfig?> usableConfig() async => ConnectConfig(
    epoch: 1,
    issuedAt: DateTime.utc(2026, 11, 8),
    github: const GitHubLaneConfig(
      appId: 1,
      clientId: 'Iv1test',
      appSlug: 'cc-test',
    ),
    slack: const SlackLaneConfig(appId: 'A1', clientId: 'slack.client'),
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
  _Lane([this.lane = ConnectOAuthLane.github]);

  final List<SignInResult> stored = [];

  @override
  final ConnectOAuthLane lane;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => null;

  @override
  Future<bool> allowsConnect(String? workspaceId) async => true;

  @override
  Future<String?> slotFor(String? workspaceId) async => workspaceId;

  @override
  Future<SignInIdentity> identify(String accessToken) =>
      throw UnimplementedError();

  /// When set, storing throws it.
  Object? storeError;

  @override
  Future<void> store(SignInResult result) async {
    final error = storeError;
    if (error != null) {
      throw error;
    }
    stored.add(result);
  }

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
    'a mistyped code can be retried (Connect answers code_mismatch)',
    () async {
      final attempt = await begin();
      connect.claims
        ..add(() => throw const ConnectException(ConnectErrorCode.codeMismatch))
        ..add(_grant);

      final wrong = await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'AAAAAAAA',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
      expect(wrong.status, SignInStatus.pending);
      expect(wrong.codeError, SignInFailure.codeMismatch);
      expect(wrong.toJson()['code_error'], 'code_mismatch');

      final done = await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'BBBBBBBB',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
      expect(done.status, SignInStatus.succeeded);
      expect(done.codeError, isNull);
      expect(lane.stored.single.token.seal, 'v1.sealed');
    },
  );

  test(
    'a provider refusal after the code matched is not a wrong code',
    () async {
      final attempt = await begin();
      connect.claims.add(
        () => throw const ConnectException(ConnectErrorCode.needsSignIn),
      );

      final failed = await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'AAAAAAAA',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
      expect(failed.status, SignInStatus.failed);
      expect(failed.error, SignInFailure.needsSignIn);
      expect(failed.codeError, isNull);
    },
  );

  test('five wrong codes end the attempt as invalid_code', () async {
    final attempt = await begin();
    for (var i = 0; i < 5; i++) {
      connect.claims.add(
        () => throw const ConnectException(ConnectErrorCode.codeMismatch),
      );
    }
    for (var i = 0; i < 5; i++) {
      await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'AAAAAAAA',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
    }
    expect(attempt.status, SignInStatus.failed);
    expect(attempt.error, SignInFailure.invalidCode);
  });

  test(
    'a grant the server cannot store fails the attempt, never pending',
    () async {
      final attempt = await begin();
      lane.storeError = StateError('disk full');
      connect.claims.add(_grant);

      final failed = await service.complete(
        loginId: attempt.loginId,
        confirmCode: 'AAAAAAAA',
        userId: 'user-1',
        workspaceId: 'ws-1',
      );
      expect(failed.status, SignInStatus.failed);
      expect(failed.error, SignInFailure.storeFailed);
      expect(failed.toJson()['error'], 'store_failed');
      expect(connect.slackRevokes, isEmpty, reason: 'only Slack is revoked');
    },
  );

  test('a Slack install the server cannot store is revoked upstream: it '
      "holds the team's only bot token", () async {
    final slack = _Lane(ConnectOAuthLane.slack)
      ..storeError = StateError('disk full');
    service.register(slack);
    final attempt = await service.begin(
      lane: ConnectOAuthLane.slack,
      userId: 'user-1',
      origin: '',
      workspaceId: 'ws-1',
    );
    connect.claims.add(_grant);

    final failed = await service.complete(
      loginId: attempt.loginId,
      confirmCode: 'AAAAAAAA',
      userId: 'user-1',
      workspaceId: 'ws-1',
    );
    expect(failed.status, SignInStatus.failed);
    expect(failed.error, SignInFailure.storeFailed);
    final revoke = connect.slackRevokes.single;
    expect(revoke.seal, 'v1.sealed');
    expect(revoke.workspaceId, 'ws-1');
    expect(slack.stored, isEmpty);
  });

  test('a malformed grant fails the attempt as provider_unavailable', () async {
    final attempt = await begin();
    connect.claims.add(() => {'nonsense': true});

    final failed = await service.complete(
      loginId: attempt.loginId,
      confirmCode: 'AAAAAAAA',
      userId: 'user-1',
      workspaceId: 'ws-1',
    );
    expect(failed.status, SignInStatus.failed);
    expect(failed.error, SignInFailure.providerUnavailable);
  });

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
