import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeCredentialSource;
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart'
    show forgeAuditForbiddenFields;
import 'package:cc_server_core/src/identity/provider_token.dart';
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
  final List<GitHubRevokeRequest> githubRevokes = [];

  @override
  Future<void> slackRevoke(ConnectTarget target, SealRequest request) async =>
      slackRevokes.add(request);

  @override
  Future<void> githubRevoke(
    ConnectTarget target,
    GitHubRevokeRequest request,
  ) async => githubRevokes.add(request);

  @override
  Future<ConnectConfig?> usableConfig(ConnectTarget target) async =>
      ConnectConfig(
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
    ConnectTarget target,
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
    ConnectTarget target,
    ConnectOAuthLane lane,
    OAuthClaimRequest request,
  ) async => claims[claimCalls++]();

  /// What a sealed refresh throws.
  ConnectException? refreshError;

  @override
  Future<SealedGrant> refresh(
    ConnectTarget target,
    ConnectProvider provider,
    SealRequest request,
  ) async => throw refreshError!;
}

/// A lane whose own app, identity answer and stored grants are scripted.
final class _Lane implements SignInLaneBinding {
  _Lane([this.lane = ConnectOAuthLane.github]);

  final List<SignInResult> stored = [];
  final List<ProviderToken> revoked = [];

  /// The own app, when the lane runs one.
  OwnOAuthApp? own;

  /// Who [identify] says a token belongs to.
  SignInIdentity identity = (id: '1001', login: 'octo');

  /// Account id → users already holding it.
  final Map<String, Set<String>> holders = {};

  @override
  final ConnectOAuthLane lane;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => own;

  @override
  Future<bool> allowsConnect(String? workspaceId) async => true;

  @override
  Future<String?> slotFor(String? workspaceId) async => workspaceId;

  @override
  Future<SignInIdentity> identify(String accessToken) async => identity;

  @override
  Future<Set<String>> accountHolders(String accountId) async => {
    ...?holders[accountId],
  };

  @override
  Future<void> revokeOwnGrant(ProviderToken token, String? slot) async =>
      revoked.add(token);

  /// When set, storing throws it.
  Object? storeError;

  /// When set, storing waits for it.
  Completer<void>? storeGate;

  @override
  Future<void> store(SignInResult result) async {
    await storeGate?.future;
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

  @override
  Future<int> offboard({String? userId, String? workspaceId}) async => 0;

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) async => const [];
}

Map<String, Object?> _grant({String accountId = '1001'}) => SealedGrant(
  seal: 'v1.sealed',
  accessToken: 'ghu_live',
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
  accountId: accountId,
  accountLogin: 'octo',
  appId: '1',
).toJson();

/// A provider token endpoint on loopback.
final class _TokenEndpoint {
  _TokenEndpoint._(this._server) {
    _server.listen(_handle);
  }

  static Future<_TokenEndpoint> start() async =>
      _TokenEndpoint._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;

  /// Every form posted, in order.
  final List<Map<String, String>> forms = [];

  /// The next answer.
  Map<String, Object?> answer = {
    'access_token': 'ghu_fresh',
    'refresh_token': 'ghr_fresh',
    'expires_in': 28800,
  };

  Uri get uri =>
      Uri.parse('http://${_server.address.address}:${_server.port}/token');

  Future<void> _handle(HttpRequest request) async {
    forms.add(Uri.splitQueryString(await utf8.decoder.bind(request).join()));
    request.response
      ..headers.contentType = ContentType.json
      ..headers.set('x-github-request-id', 'ABCD:1234')
      ..write(jsonEncode(answer));
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}

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

  Future<SignInAttempt> begin({String user = 'user-1'}) => service.begin(
    lane: ConnectOAuthLane.github,
    userId: user,
    origin: 'https://cc.example',
    workspaceId: 'ws-1',
  );

  Future<SignInAttempt> complete(
    SignInAttempt attempt,
    String code, {
    String user = 'user-1',
    String? workspaceId = 'ws-1',
  }) => service.complete(
    loginId: attempt.loginId,
    confirmCode: code,
    userId: user,
    workspaceId: workspaceId,
  );

  SignInAttempt now(SignInAttempt attempt) =>
      service.lookup(
        loginId: attempt.loginId,
        userId: attempt.userId,
        workspaceId: attempt.workspaceId,
      ) ??
      (throw StateError('gone'));

  group('Connect', () {
    test(
      'a mistyped code can be retried (Connect answers code_mismatch)',
      () async {
        final attempt = await begin();
        connect.claims
          ..add(
            () => throw const ConnectException(ConnectErrorCode.codeMismatch),
          )
          ..add(_grant);

        final wrong = await complete(attempt, 'AAAAAAAA');
        expect(wrong.status, SignInAttemptStatus.pending);
        expect(wrong.codeError, SignInFailure.codeMismatch);
        expect(wrong.toJson()['code_error'], 'code_mismatch');

        final done = await complete(attempt, 'BBBBBBBB');
        expect(done.status, SignInAttemptStatus.succeeded);
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

        final failed = await complete(attempt, 'AAAAAAAA');
        expect(failed.status, SignInAttemptStatus.failed);
        expect(failed.error, SignInFailure.needsSignIn);
        expect(failed.codeError, isNull);
      },
    );

    test('a rate_limited claim stays pending, counts no wrong code and can '
        'be sent again', () async {
      final attempt = await begin();
      for (var i = 0; i < 6; i++) {
        connect.claims.add(
          () => throw const ConnectException(
            ConnectErrorCode.rateLimited,
            reason: 'slack_exchange_busy',
          ),
        );
      }
      connect.claims.add(_grant);

      for (var i = 0; i < 6; i++) {
        final busy = await complete(attempt, 'AAAAAAAA');
        expect(busy.status, SignInAttemptStatus.pending);
        expect(busy.codeError, SignInFailure.rateLimited);
        expect(busy.toJson()['code_error'], 'rate_limited');
        expect(busy.wrongCodes, 0);
      }

      final done = await complete(attempt, 'AAAAAAAA');
      expect(done.status, SignInAttemptStatus.succeeded);
      expect(done.codeError, isNull);
      expect(lane.stored, hasLength(1));
    });

    test('a rate_limited claim whose login Connect already took ends on the '
        'retry', () async {
      final attempt = await begin();
      connect.claims
        ..add(() => throw const ConnectException(ConnectErrorCode.rateLimited))
        ..add(
          () => throw const ConnectException(ConnectErrorCode.staleRequest),
        );

      expect(
        (await complete(attempt, 'AAAAAAAA')).status,
        SignInAttemptStatus.pending,
      );
      final over = await complete(attempt, 'AAAAAAAA');
      expect(over.status, SignInAttemptStatus.failed);
      // Over budget after the exchange: try again later, not "start over".
      expect(over.error, SignInFailure.rateLimited);
      expect(over.toJson()['error'], 'rate_limited');
      expect(lane.stored, isEmpty);
    });

    test('a spent login with no rate limit before it is stale', () async {
      final attempt = await begin();
      connect.claims.add(
        () => throw const ConnectException(ConnectErrorCode.staleRequest),
      );

      final over = await complete(attempt, 'AAAAAAAA');
      expect(over.error, SignInFailure.staleRequest);
    });

    test('five wrong codes end the attempt as invalid_code', () async {
      final attempt = await begin();
      for (var i = 0; i < 5; i++) {
        connect.claims.add(
          () => throw const ConnectException(ConnectErrorCode.codeMismatch),
        );
      }
      for (var i = 0; i < 5; i++) {
        await complete(attempt, 'AAAAAAAA');
      }
      expect(now(attempt).status, SignInAttemptStatus.failed);
      expect(now(attempt).error, SignInFailure.invalidCode);
    });

    test(
      'a grant the server cannot store fails the attempt and is revoked',
      () async {
        final attempt = await begin();
        lane.storeError = StateError('disk full');
        connect.claims.add(_grant);

        final failed = await complete(attempt, 'AAAAAAAA');
        expect(failed.status, SignInAttemptStatus.failed);
        expect(failed.error, SignInFailure.storeFailed);
        expect(failed.toJson()['error'], 'store_failed');
        expect(connect.githubRevokes.single.seal, 'v1.sealed');
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

      final failed = await complete(attempt, 'AAAAAAAA');
      expect(failed.status, SignInAttemptStatus.failed);
      expect(failed.error, SignInFailure.storeFailed);
      final revoke = connect.slackRevokes.single;
      expect(revoke.seal, 'v1.sealed');
      expect(revoke.workspaceId, 'ws-1');
      expect(slack.stored, isEmpty);
    });

    test(
      'a malformed grant fails the attempt as provider_unavailable',
      () async {
        final attempt = await begin();
        connect.claims.add(() => {'nonsense': true});

        final failed = await complete(attempt, 'AAAAAAAA');
        expect(failed.status, SignInAttemptStatus.failed);
        expect(failed.error, SignInFailure.providerUnavailable);
      },
    );

    test(
      'a second completion while the first claims does not fail it',
      () async {
        final attempt = await begin();
        final gate = Completer<Map<String, Object?>>();
        connect.claims.add(() => gate.future);

        final first = complete(attempt, 'AAAAAAAA');
        final second = await complete(attempt, 'AAAAAAAA');
        expect(second.status, SignInAttemptStatus.pending);
        gate.complete(_grant());
        expect((await first).status, SignInAttemptStatus.succeeded);
        expect(connect.claimCalls, 1);
      },
    );

    test('a grant whose account the provider does not confirm is refused and '
        'revoked', () async {
      final attempt = await begin();
      lane.identity = (id: '2002', login: 'someone-else');
      connect.claims.add(_grant);

      final failed = await complete(attempt, 'AAAAAAAA');
      expect(failed.status, SignInAttemptStatus.failed);
      expect(failed.error, SignInFailure.exchangeFailed);
      expect(lane.stored, isEmpty);
      expect(connect.githubRevokes.single.seal, 'v1.sealed');
    });

    test('a GitHub token that is not an App user token is refused', () async {
      final attempt = await begin();
      connect.claims.add(
        () => SealedGrant(
          seal: 'v1.sealed',
          accessToken: 'gho_classic',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
          accountId: '1001',
          accountLogin: 'octo',
          appId: '1',
        ).toJson(),
      );

      final failed = await complete(attempt, 'AAAAAAAA');
      expect(failed.status, SignInAttemptStatus.failed);
      expect(failed.error, SignInFailure.exchangeFailed);
      expect(lane.stored, isEmpty);
    });
  });

  group('own app', () {
    late _TokenEndpoint endpoint;

    setUp(() async {
      endpoint = await _TokenEndpoint.start();
      lane.own = OwnOAuthApp(
        authorize: Uri.https('github.com', '/login/oauth/authorize'),
        token: endpoint.uri,
        clientId: 'Iv1own',
        clientSecret: 'own-secret',
        scopes: const [],
        extraAuthorizeParams: const {'prompt': 'select_account'},
      );
    });

    tearDown(() => endpoint.close());

    Uri callback(SignInAttempt attempt, {String code = 'provider-code'}) =>
        Uri.parse(
          'https://cc.example/oauth/github/callback'
          '?state=${attempt.url.queryParameters['state']}&code=$code',
        );

    test('the authorize URL carries the account chooser', () async {
      final attempt = await begin();
      expect(attempt.url.queryParameters['prompt'], 'select_account');
      expect(attempt.mode, SignInLaneMode.own);
    });

    test('the callback alone stores nothing and exchanges nothing', () async {
      final attempt = await begin();
      final page = service.handleCallback(callback(attempt));

      expect(page.loginId, attempt.loginId);
      expect(normaliseConfirmCode(page.confirmCode), page.confirmCode);
      expect(parseOauthDoneDeepLink(page.link), (
        loginId: attempt.loginId,
        code: page.confirmCode,
      ));
      expect(now(attempt).status, SignInAttemptStatus.pending);
      expect(endpoint.forms, isEmpty);
      expect(lane.stored, isEmpty);
      expect(jsonEncode(now(attempt).toJson()), isNot(contains('provider')));
    });

    test('a replayed callback is refused', () async {
      final attempt = await begin();
      service.handleCallback(callback(attempt));
      expect(
        () => service.handleCallback(callback(attempt)),
        throwsA(isA<AuthException>()),
      );
    });

    test('the confirmation code from the session that began it stores the '
        'grant exactly once', () async {
      final attempt = await begin();
      final page = service.handleCallback(callback(attempt));

      final done = await complete(attempt, page.confirmCode);
      expect(done.status, SignInAttemptStatus.succeeded);
      expect(done.account, 'octo');
      expect(lane.stored, hasLength(1));
      final token = lane.stored.single.token;
      expect(token.accessToken, 'ghu_fresh');
      expect(token.accountId, '1001');
      expect(token.appId, 'Iv1own');
      expect(endpoint.forms.single['code'], 'provider-code');
      expect(endpoint.forms.single['code_verifier'], attempt.verifier);

      final again = await complete(attempt, page.confirmCode);
      expect(again.status, SignInAttemptStatus.succeeded);
      expect(lane.stored, hasLength(1));
      expect(endpoint.forms, hasLength(1));
    });

    test(
      'a wrong code stores nothing and the fifth ends the attempt',
      () async {
        final attempt = await begin();
        final page = service.handleCallback(callback(attempt));
        final wrong = page.confirmCode == 'AAAAAAAA' ? 'BBBBBBBB' : 'AAAAAAAA';

        for (var i = 0; i < 4; i++) {
          final pending = await complete(attempt, wrong);
          expect(pending.status, SignInAttemptStatus.pending);
          expect(pending.codeError, SignInFailure.codeMismatch);
        }
        final over = await complete(attempt, wrong);
        expect(over.status, SignInAttemptStatus.failed);
        expect(over.error, SignInFailure.invalidCode);

        final late = await complete(attempt, page.confirmCode);
        expect(late.status, SignInAttemptStatus.failed);
        expect(lane.stored, isEmpty);
        expect(endpoint.forms, isEmpty);
      },
    );

    test('a code typed before the browser came back counts as wrong', () async {
      final attempt = await begin();
      final early = await complete(attempt, 'AAAAAAAA');
      expect(early.status, SignInAttemptStatus.pending);
      expect(early.codeError, SignInFailure.codeMismatch);
      expect(endpoint.forms, isEmpty);
    });

    test(
      'another person cannot finish the attempt, even with the code',
      () async {
        final attempt = await begin();
        final page = service.handleCallback(callback(attempt));

        await expectLater(
          complete(attempt, page.confirmCode, user: 'user-2'),
          throwsA(isA<AuthException>()),
        );
        expect(lane.stored, isEmpty);
        expect(now(attempt).status, SignInAttemptStatus.pending);
      },
    );

    test('the same person cannot finish it from another workspace', () async {
      final attempt = await begin();
      final page = service.handleCallback(callback(attempt));

      await expectLater(
        complete(attempt, page.confirmCode, workspaceId: 'ws-2'),
        throwsA(isA<AuthException>()),
      );
      expect(lane.stored, isEmpty);
    });

    test(
      'an account another person already holds is refused and revoked',
      () async {
        lane.holders['1001'] = {'user-2'};
        final attempt = await begin();
        final page = service.handleCallback(callback(attempt));

        final refused = await complete(attempt, page.confirmCode);
        expect(refused.status, SignInAttemptStatus.failed);
        expect(refused.error, SignInFailure.accountAlreadyBound);
        expect(refused.toJson()['error'], 'account_already_bound');
        expect(refused.message, contains('another person'));
        expect(lane.stored, isEmpty);
        expect(lane.revoked.single.accessToken, 'ghu_fresh');
      },
    );

    test('the same person signing in again is not refused', () async {
      lane.holders['1001'] = {'user-1'};
      final attempt = await begin();
      final page = service.handleCallback(callback(attempt));
      expect(
        (await complete(attempt, page.confirmCode)).status,
        SignInAttemptStatus.succeeded,
      );
    });

    test(
      'an attempt that expired while the browser was out is never stored',
      () async {
        var clock = DateTime.utc(2026, 11, 10, 12);
        service = ProviderSignInService(connect: connect, now: () => clock)
          ..register(lane);
        final attempt = await begin();
        final page = service.handleCallback(callback(attempt));
        clock = clock.add(const Duration(minutes: 11));

        expect(now(attempt).status, SignInAttemptStatus.failed);
        final late = await complete(attempt, page.confirmCode);
        expect(late.status, SignInAttemptStatus.failed);
        expect(late.error, SignInFailure.expired);
        expect(lane.stored, isEmpty);
      },
    );

    test('no event carries a token, code, verifier, state or seal', () async {
      final lines = <String>[];
      final previous = CcHostLog.sink;
      CcHostLog.sink = (level, message, [error, stack]) => lines.add(message);
      addTearDown(() => CcHostLog.sink = previous);

      final attempt = await begin();
      final state = attempt.url.queryParameters['state']!;
      final page = service.handleCallback(callback(attempt));
      final wrong = page.confirmCode == 'AAAAAAAA' ? 'BBBBBBBB' : 'AAAAAAAA';
      await complete(attempt, wrong);
      await complete(attempt, page.confirmCode);
      expect(
        () => service.handleCallback(callback(attempt)),
        throwsA(isA<AuthException>()),
      );
      lane.own = null;
      final sealed = await begin(user: 'user-2');
      expect(sealed.mode, SignInLaneMode.connect);
      connect.claims.add(_grant);
      await complete(sealed, 'CCCCCCCC', user: 'user-2');

      final events = lines.where((l) => l.startsWith('forge.audit ')).toList();
      expect(
        events.map(
          (l) => (jsonDecode(l.substring(12)) as Map<String, Object?>)['event'],
        ),
        containsAll(<String>[
          'signin.begun',
          'signin.code_rejected',
          'signin.completed',
          'signin.callback_refused',
        ]),
      );
      for (final line in lines) {
        for (final secret in [
          'ghu_fresh',
          'ghr_fresh',
          'ghu_live',
          'v1.sealed',
          'provider-code',
          'own-secret',
          attempt.verifier,
          state,
          page.confirmCode,
          wrong,
          'CCCCCCCC',
        ]) {
          expect(line, isNot(contains(secret)), reason: line);
        }
      }
      for (final line in events) {
        final fields = jsonDecode(line.substring(12)) as Map<String, Object?>;
        expect(
          fields.keys.toSet().intersection(forgeAuditForbiddenFields),
          isEmpty,
          reason: line,
        );
      }
    });
  });

  group('attempt store', () {
    test('a person holds at most four pending attempts', () async {
      final attempts = [for (var i = 0; i < 5; i++) await begin()];
      expect(
        service.lookup(
          loginId: attempts.first.loginId,
          userId: 'user-1',
          workspaceId: 'ws-1',
        ),
        isNull,
      );
      for (final kept in attempts.skip(1)) {
        expect(now(kept).status, SignInAttemptStatus.pending);
      }
    });

    test("one person's attempts never evict another's", () async {
      final other = await begin(user: 'user-2');
      for (var i = 0; i < 8; i++) {
        await begin();
      }
      expect(now(other).status, SignInAttemptStatus.pending);
    });
  });

  group('refresh', () {
    late _TokenEndpoint endpoint;

    setUp(() async {
      endpoint = await _TokenEndpoint.start();
      lane.own = OwnOAuthApp(
        authorize: Uri.https('github.com', '/login/oauth/authorize'),
        token: endpoint.uri,
        clientId: 'Iv1own',
        clientSecret: 'own-secret',
        scopes: const [],
      );
    });

    tearDown(() => endpoint.close());

    const expired = ProviderToken(
      accessToken: 'ghu_old',
      refreshToken: 'ghr_old',
      source: ForgeCredentialSource.oauth,
      appId: 'Iv1own',
    );

    for (final error in [
      'invalid_grant',
      'bad_refresh_token',
      'unauthorized_client',
    ]) {
      test('$error needs a new sign-in', () async {
        endpoint.answer = {'error': error};
        expect(
          await service.refresh(ConnectOAuthLane.github, expired),
          isA<RefreshRejected>(),
        );
      });
    }

    group('a sealed grant', () {
      Future<ProviderToken> sealed() async => ProviderToken(
        accessToken: 'ghu_old',
        source: ForgeCredentialSource.connect,
        seal: 'v1.sealed',
        sealInstallId: (await connect.identity(
          await connect.targetFor(null),
        ))!.installId,
        connectOrigin: 'https://connect.example',
      );

      test('is kept when Connect answers rate_limited', () async {
        connect.refreshError = const ConnectException(
          ConnectErrorCode.rateLimited,
          reason: 'github_ceiling',
        );
        expect(
          await service.refresh(ConnectOAuthLane.github, await sealed()),
          isA<RefreshUnavailable>(),
        );
      });

      test('is kept when Connect answers install_blocked', () async {
        connect.refreshError = const ConnectException(
          ConnectErrorCode.installBlocked,
        );
        expect(
          await service.refresh(ConnectOAuthLane.github, await sealed()),
          isA<RefreshUnavailable>(),
        );
      });

      test('needs a new sign-in only on needs_sign_in', () async {
        connect.refreshError = const ConnectException(
          ConnectErrorCode.needsSignIn,
        );
        expect(
          await service.refresh(ConnectOAuthLane.github, await sealed()),
          isA<RefreshRejected>(),
        );
      });
    });

    test('any other refusal is transient', () async {
      endpoint.answer = {'error': 'slow_down'};
      expect(
        await service.refresh(ConnectOAuthLane.github, expired),
        isA<RefreshUnavailable>(),
      );
    });

    test('a renewed grant keeps its account', () async {
      final outcome = await service.refresh(
        ConnectOAuthLane.github,
        expired.copyWith(accountId: '1001', accountLogin: 'octo'),
      );
      final token = (outcome as Refreshed).token;
      expect(token.accessToken, 'ghu_fresh');
      expect(token.refreshToken, 'ghr_fresh');
      expect(token.accountId, '1001');
      expect(endpoint.forms.single['grant_type'], 'refresh_token');
    });
  });
}
