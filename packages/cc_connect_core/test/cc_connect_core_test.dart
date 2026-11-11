import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

Uint8List _seed(int fill) => Uint8List.fromList(List.filled(32, fill));

void main() {
  group('callback segments', () {
    test('every lane has a first hop and only Slack a bot hop', () {
      for (final lane in ConnectOAuthLane.values) {
        expect(lane.callbackSegment(ConnectCallbackHop.first), isNotNull);
        expect(
          lane.callbackSegment(ConnectCallbackHop.bot) != null,
          lane == ConnectOAuthLane.slack,
        );
      }
      expect(ConnectOAuthLane.slack.firstCallbackSegment, 'slack_oidc');
    });

    test('a segment maps back to exactly its lane and hop', () {
      expect(ConnectOAuthLane.fromCallbackSegment('slack'), (
        lane: ConnectOAuthLane.slack,
        hop: ConnectCallbackHop.bot,
      ));
      expect(ConnectOAuthLane.fromCallbackSegment('linear_app'), (
        lane: ConnectOAuthLane.linearApp,
        hop: ConnectCallbackHop.first,
      ));
      expect(ConnectOAuthLane.fromCallbackSegment('setup'), isNull);
    });
  });

  group('SignInFailure', () {
    test(
      'round-trips its wire spelling and reads unknown codes as unknown',
      () {
        for (final failure in SignInFailure.values) {
          if (failure != SignInFailure.unknown) {
            expect(SignInFailure.fromWire(failure.wire), failure);
          }
        }
        expect(SignInFailure.fromWire('nope'), SignInFailure.unknown);
        expect(SignInFailure.fromWire(''), isNull);
      },
    );

    test('a wrong code and a provider refusal stay distinct', () {
      expect(
        SignInFailure.fromConnect(ConnectErrorCode.codeMismatch),
        SignInFailure.codeMismatch,
      );
      expect(
        SignInFailure.fromConnect(ConnectErrorCode.needsSignIn),
        SignInFailure.needsSignIn,
      );
    });
  });

  group('claimedInstallId', () {
    test('names the keyid install before verification, or null', () async {
      final identity = await ConnectInstallIdentity.derive(
        masterSeed: _seed(7),
        connectUrl: 'https://connect.test',
      );
      final headers = await ConnectRequestSigner(identity).sign(
        method: 'GET',
        targetUri: Uri.parse('https://connect.test/v1/config'),
        body: const [],
      );
      expect(claimedInstallId(headers['signature-input']), identity.installId);
      expect(claimedInstallId('garbage'), isNull);
      expect(claimedInstallId(null), isNull);
    });
  });

  group('OAuthStartRequest', () {
    test('refuses any purpose, even sign_in', () {
      final base = const OAuthStartRequest(
        workspaceId: 'ws1',
        codeChallenge: 'c',
      ).toJson();
      expect(base.containsKey('purpose'), isFalse);
      expect(OAuthStartRequest.fromJson(base).workspaceId, 'ws1');
      expect(
        () => OAuthStartRequest.fromJson({...base, 'purpose': 'sign_in'}),
        throwsFormatException,
      );
      expect(
        () => OAuthStartRequest.fromJson({
          ...base,
          'purpose': 'authorize_server',
        }),
        throwsFormatException,
      );
      expect(
        () => OAuthStartRequest.fromJson({...base, 'installation_id': 1}),
        throwsFormatException,
      );
    });
  });

  group('canonicalConnectOrigin', () {
    test('drops default ports, paths and case', () {
      expect(
        canonicalConnectOrigin('HTTPS://Connect.Example:443/x/y?z'),
        'https://connect.example',
      );
      expect(
        canonicalConnectOrigin('http://127.0.0.1:8790/'),
        'http://127.0.0.1:8790',
      );
    });

    test('base urls keep a mount prefix', () {
      expect(
        canonicalConnectBaseUrl('https://cc.acme.internal/connect/'),
        'https://cc.acme.internal/connect',
      );
      for (final url in [
        'https://x.example/a/../b',
        'https://x.example/connect/%2e%2e',
        'https://x.example/connect/%2E%2E/',
        'https://x.example/connect/%2e',
        'https://x.example/a%2Fb',
        'https://x.example/a%zz',
      ]) {
        expect(
          () => canonicalConnectBaseUrl(url),
          throwsFormatException,
          reason: url,
        );
      }
    });

    test('a trailing root dot names the same host', () {
      expect(
        canonicalConnectOrigin('https://Connect.Example./'),
        'https://connect.example',
      );
      expect(
        canonicalConnectBaseUrl('https://connect.example.:8443/connect'),
        'https://connect.example:8443/connect',
      );
    });

    test('refuses non-http and credentials', () {
      expect(() => canonicalConnectOrigin('ftp://x'), throwsFormatException);
      expect(
        () => canonicalConnectOrigin('https://u:p@x.example'),
        throwsFormatException,
      );
    });

    test('loopback means a loopback address, not a name that starts like '
        'one', () {
      expect(isLoopbackOrigin('http://127.0.0.1:8790'), isTrue);
      expect(isLoopbackOrigin('http://127.1.2.3'), isTrue);
      expect(isLoopbackOrigin('http://localhost:8790'), isTrue);
      expect(isLoopbackOrigin('http://[::1]:8790'), isTrue);
      expect(isLoopbackOrigin('http://127.evil.example'), isFalse);
      expect(isLoopbackOrigin('http://127.0.0.1.evil.example'), isFalse);
    });
  });

  group('ConnectInstallIdentity', () {
    test('is deterministic per origin and unlinkable across origins', () async {
      final a1 = await ConnectInstallIdentity.derive(
        masterSeed: _seed(7),
        connectUrl: 'https://connect.usectrl.dev',
      );
      final a2 = await ConnectInstallIdentity.derive(
        masterSeed: _seed(7),
        connectUrl: 'https://CONNECT.usectrl.dev:443/',
      );
      final b = await ConnectInstallIdentity.derive(
        masterSeed: _seed(7),
        connectUrl: 'https://connect.acme.internal',
      );
      expect(a1.installId, a2.installId);
      expect(a1.installId, isNot(b.installId));
      expect(isInstallId(a1.installId), isTrue);
      expect(installIdForKeyId(a1.keyId), a1.installId);
    });

    test('rejects a key id that is not an Ed25519 SPKI', () {
      expect(installIdForKeyId(b64url(List.filled(44, 1))), isNull);
      expect(installIdForKeyId('***'), isNull);
    });
  });

  group('RFC 9421 signatures', () {
    late ConnectInstallIdentity identity;
    final now = DateTime.utc(2026, 11, 8, 10);
    final target = Uri.parse('https://connect.example/v1/oauth/github/start');
    final body = utf8.encode('{"workspace_id":"global"}');

    setUp(() async {
      identity = await ConnectInstallIdentity.derive(
        masterSeed: _seed(3),
        connectUrl: 'https://connect.example',
      );
    });

    Future<Map<String, String>> sign() => ConnectRequestSigner(
      identity,
      now: () => now,
    ).sign(method: 'post', targetUri: target, body: body);

    test('round-trips and recomputes the install id', () async {
      final headers = await sign();
      final verified = await verifyConnectRequest(
        method: 'POST',
        targetUri: target,
        header: (name) => headers[name],
        body: body,
        now: () => now.add(const Duration(seconds: 30)),
      );
      expect(verified.installId, identity.installId);
    });

    test('a different target uri fails', () async {
      final headers = await sign();
      expect(
        () => verifyConnectRequest(
          method: 'POST',
          targetUri: Uri.parse('https://evil.example/v1/oauth/github/start'),
          header: (name) => headers[name],
          body: body,
          now: () => now,
        ),
        throwsA(isA<ConnectSignatureException>()),
      );
    });

    test('a tampered body fails on digest', () async {
      final headers = await sign();
      await expectLater(
        verifyConnectRequest(
          method: 'POST',
          targetUri: target,
          header: (name) => headers[name],
          body: utf8.encode('{"workspace_id":"other"}'),
          now: () => now,
        ),
        throwsA(
          isA<ConnectSignatureException>().having(
            (e) => e.failure,
            'failure',
            ConnectSignatureFailure.digest,
          ),
        ),
      );
    });

    test('an old signature is stale', () async {
      final headers = await sign();
      await expectLater(
        verifyConnectRequest(
          method: 'POST',
          targetUri: target,
          header: (name) => headers[name],
          body: body,
          now: () => now.add(const Duration(minutes: 5)),
        ),
        throwsA(
          isA<ConnectSignatureException>().having(
            (e) => e.failure,
            'failure',
            ConnectSignatureFailure.stale,
          ),
        ),
      );
    });

    test('a reduced component list is refused', () async {
      final headers = await sign();
      final weakened = Map.of(headers)
        ..['signature-input'] = headers['signature-input']!.replaceFirst(
          ' "content-digest"',
          '',
        );
      await expectLater(
        verifyConnectRequest(
          method: 'POST',
          targetUri: target,
          header: (name) => weakened[name],
          body: body,
          now: () => now,
        ),
        throwsA(isA<ConnectSignatureException>()),
      );
    });

    test('another key cannot reuse the signature', () async {
      final headers = await sign();
      final other = await ConnectInstallIdentity.derive(
        masterSeed: _seed(4),
        connectUrl: 'https://connect.example',
      );
      final forged = Map.of(headers)
        ..['signature-input'] = headers['signature-input']!.replaceFirst(
          identity.keyId,
          other.keyId,
        );
      await expectLater(
        verifyConnectRequest(
          method: 'POST',
          targetUri: target,
          header: (name) => forged[name],
          body: body,
          now: () => now,
        ),
        throwsA(
          isA<ConnectSignatureException>().having(
            (e) => e.failure,
            'failure',
            ConnectSignatureFailure.signature,
          ),
        ),
      );
    });

    test(
      'a created far outside the clock range is stale, not a crash',
      () async {
        final headers = await sign();
        final far = Map.of(headers)
          ..['signature-input'] = headers['signature-input']!.replaceFirst(
            RegExp(r';created=\d+'),
            ';created=99999999999999',
          );
        await expectLater(
          verifyConnectRequest(
            method: 'POST',
            targetUri: target,
            header: (name) => far[name],
            body: body,
            now: () => now,
          ),
          throwsA(
            isA<ConnectSignatureException>().having(
              (e) => e.failure,
              'failure',
              ConnectSignatureFailure.stale,
            ),
          ),
        );
      },
    );
  });

  group('signed /v1/config', () {
    test('verifies, and any edit breaks it', () async {
      final seed = _seed(9);
      final root = await configPublicKeyForSeed(seed);
      final config = ConnectConfig(
        epoch: 4,
        issuedAt: DateTime.utc(2026, 11, 8, 10),
        github: const GitHubLaneConfig(
          appId: 123456,
          clientId: 'Iv23li',
          appSlug: 'control-center',
        ),
        klipy: const KlipyLaneConfig(mode: KlipyLaneMode.proxy),
      );
      final signature = await signConnectConfig(config.payload(), seed);
      final json = {...config.payload(), 'signature': signature};
      expect(
        await verifyConnectConfigSignature(json, trustedKeys: [root]),
        isTrue,
      );
      final edited = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
      (edited['github']! as Map)['client_id'] = 'Iv23evil';
      expect(
        await verifyConnectConfigSignature(edited, trustedKeys: [root]),
        isFalse,
      );
      expect(await verifyConnectConfigSignature(json), isFalse);
      final parsed = ConnectConfig.fromJson(json);
      expect(parsed.epoch, 4);
      expect(parsed.github!.appSlug, 'control-center');
      expect(parsed.google, isNull);
    });

    test('canonical JSON sorts keys at every depth', () {
      expect(
        canonicalJson({
          'b': 1,
          'a': {'z': true, 'c': null},
          'l': [3, 'x'],
        }),
        '{"a":{"c":null,"z":true},"b":1,"l":[3,"x"]}',
      );
    });
  });

  group('authorize url validation', () {
    final pkce = PkcePair.generate();
    Uri github({Map<String, String> override = const {}}) =>
        Uri.https('github.com', '/login/oauth/authorize', {
          'client_id': 'Iv23li',
          'redirect_uri': 'https://connect.example/oauth/github/callback',
          'response_type': 'code',
          'state': 'x' * 43,
          'code_challenge': pkce.challenge,
          'code_challenge_method': 'S256',
          'prompt': 'select_account',
          ...override,
        });

    void check(Uri url) => validateAuthorizeUrl(
      lane: ConnectOAuthLane.github,
      url: url,
      connectBaseUrl: 'https://connect.example',
      expectedClientId: 'Iv23li',
      codeChallenge: pkce.challenge,
    );

    test('accepts the exact shape', () {
      check(github());
    });

    test('refuses another client, callback or challenge', () {
      expect(
        () => check(github(override: {'client_id': 'other'})),
        throwsA(isA<AuthorizeUrlRejected>()),
      );
      expect(
        () => check(
          github(override: {'redirect_uri': 'https://evil.example/cb'}),
        ),
        throwsA(isA<AuthorizeUrlRejected>()),
      );
      expect(
        () => check(github(override: {'code_challenge': 'a' * 43})),
        throwsA(isA<AuthorizeUrlRejected>()),
      );
      expect(
        () => check(github(override: {'scope': 'repo'})),
        throwsA(isA<AuthorizeUrlRejected>()),
      );
    });

    test('github asks for the documented account picker only', () {
      for (final prompt in ['consent', 'none', '']) {
        expect(
          () => check(github(override: {'prompt': prompt})),
          throwsA(isA<AuthorizeUrlRejected>()),
          reason: prompt,
        );
      }
    });

    test('google scope must match exactly', () {
      Uri google(String scope) =>
          Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
            'client_id': 'g',
            'redirect_uri': 'https://connect.example/oauth/google/callback',
            'response_type': 'code',
            'state': 'y' * 43,
            'code_challenge': pkce.challenge,
            'code_challenge_method': 'S256',
            'scope': scope,
            'access_type': 'offline',
            'prompt': 'consent select_account',
          });
      void checkGoogle(Uri url) => validateAuthorizeUrl(
        lane: ConnectOAuthLane.google,
        url: url,
        connectBaseUrl: 'https://connect.example',
        expectedClientId: 'g',
        codeChallenge: pkce.challenge,
      );
      checkGoogle(google(googleConnectScopes.join(' ')));
      expect(
        () => checkGoogle(
          google(
            '${googleConnectScopes.join(' ')} '
            'https://www.googleapis.com/auth/calendar',
          ),
        ),
        throwsA(isA<AuthorizeUrlRejected>()),
      );
    });
  });

  group('handoff', () {
    test('confirm codes normalise look-alikes', () {
      final code = newConfirmCode();
      expect(code, hasLength(confirmCodeLength));
      expect(normaliseConfirmCode(code.toLowerCase()), code);
      expect(
        normaliseConfirmCode('oiL0-1234'),
        '0110'
        '1234',
      );
      expect(normaliseConfirmCode('short'), isNull);
    });

    test('deep link round-trips', () {
      final loginId = newLoginId();
      final link = oauthDoneDeepLink(loginId: loginId, code: 'ABCD1234');
      expect(link.scheme, 'control-center');
      expect(parseOauthDoneDeepLink(link), (
        loginId: loginId,
        code: 'ABCD1234',
      ));
      expect(parseOauthDoneDeepLink(Uri.parse('https://x/oauth-done')), isNull);
    });

    test('pkce challenge is S256 of the verifier', () {
      final pair = PkcePair.generate();
      expect(isPkceVerifier(pair.verifier), isTrue);
      expect(isPkceChallenge(pair.challenge), isTrue);
      expect(pkceChallengeFor(pair.verifier), pair.challenge);
    });
  });

  group('github scope clamping', () {
    test('writes need push; public reads need triage', () {
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.write,
          role: GitHubRepoRole.push,
          repoIsPublic: false,
        ),
        GitHubTokenScope.write,
      );
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.write,
          role: GitHubRepoRole.pull,
          repoIsPublic: false,
        ),
        GitHubTokenScope.read,
      );
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.read,
          role: GitHubRepoRole.pull,
          repoIsPublic: true,
        ),
        isNull,
      );
      expect(
        GitHubRepoRole.fromPermissions({'pull': true, 'push': true}),
        GitHubRepoRole.push,
      );
    });

    test('the sandbox scope reads only, so a reader keeps it', () {
      expect(GitHubTokenScope.review.writes, isFalse);
      expect(GitHubTokenScope.review.permissions.values.toSet(), {'read'});
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.review,
          role: GitHubRepoRole.pull,
          repoIsPublic: false,
        ),
        GitHubTokenScope.review,
      );
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.bot,
          role: GitHubRepoRole.pull,
          repoIsPublic: false,
        ),
        GitHubTokenScope.read,
      );
    });

    test('a shared App\'s bot holds nothing that writes beyond issues', () {
      expect(GitHubTokenScope.read.connectBotMayHold, isTrue);
      expect(GitHubTokenScope.review.connectBotMayHold, isTrue);
      expect(GitHubTokenScope.comment.connectBotMayHold, isTrue);
      expect(GitHubTokenScope.bot.connectBotMayHold, isFalse);
      expect(GitHubTokenScope.write.connectBotMayHold, isFalse);
      for (final scope in GitHubTokenScope.values) {
        final writesCode =
            scope.permissions['pull_requests'] == 'write' ||
            scope.permissions['contents'] == 'write';
        expect(scope.connectBotMayHold, !writesCode, reason: scope.wire);
      }
      expect(
        [
          for (final scope in GitHubTokenScope.values)
            if (scope.connectBotNeedsListing) scope,
        ],
        [GitHubTokenScope.bot],
      );
    });

    test('comment writes issues only, so it needs push', () {
      expect(GitHubTokenScope.comment.permissions, {
        'metadata': 'read',
        'issues': 'write',
      });
      expect(GitHubTokenScope.fromWire('comment'), GitHubTokenScope.comment);
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.comment,
          role: GitHubRepoRole.triage,
          repoIsPublic: false,
        ),
        GitHubTokenScope.read,
      );
      expect(
        clampGitHubScope(
          requested: GitHubTokenScope.comment,
          role: GitHubRepoRole.push,
          repoIsPublic: false,
        ),
        GitHubTokenScope.comment,
      );
    });

    test('a mint answer proves its selection, permissions and repository', () {
      final permissions = GitHubTokenScope.read.permissions;
      Map<String, Object?> answer({
        Object? selection = 'selected',
        Object? repositories = const [
          {'id': 7},
        ],
        Map<String, String>? granted,
      }) => {
        'permissions': granted ?? permissions,
        'repository_selection': ?selection,
        'repositories': ?repositories,
      };
      bool matches(Map<String, Object?> json, {bool require = true}) =>
          scopedTokenMatches(
            json,
            repoId: 7,
            permissions: permissions,
            requireRepositories: require,
          );

      expect(matches(answer()), isTrue);
      expect(matches(answer(selection: null)), isFalse);
      expect(matches(answer(selection: 'all')), isFalse);
      expect(matches(answer(repositories: null)), isFalse);
      expect(matches(answer(repositories: null), require: false), isTrue);
      expect(
        matches(
          answer(
            repositories: const [
              {'id': 8},
            ],
          ),
        ),
        isFalse,
      );
      expect(
        matches(
          answer(
            repositories: const [
              {'id': 7},
              {'id': 8},
            ],
          ),
        ),
        isFalse,
      );
      expect(
        matches(answer(granted: GitHubTokenScope.write.permissions)),
        isFalse,
      );
    });

    test('segments refuse traversal', () {
      expect(isGitHubSegment('.github'), isTrue);
      expect(isGitHubSegment('a..b'), isFalse);
      expect(isGitHubSegment('a/b'), isFalse);
      expect(isGitHubSegment('%2e'), isFalse);
    });
  });

  group('shared sign-in names', () {
    test('account_already_bound is its own failure', () {
      expect(
        SignInFailure.fromWire('account_already_bound'),
        SignInFailure.accountAlreadyBound,
      );
      expect(SignInFailure.accountAlreadyBound.wire, 'account_already_bound');
    });

    test('SignInUnavailableReason keeps its wire spellings', () {
      expect(
        {for (final r in SignInUnavailableReason.values) r: r.wire},
        {
          SignInUnavailableReason.notConfigured: 'not_configured',
          SignInUnavailableReason.misconfigured: 'misconfigured',
          SignInUnavailableReason.ownAppMissing: 'own_app_missing',
          SignInUnavailableReason.connectUnprovisioned: 'connect_unprovisioned',
          SignInUnavailableReason.connectPinsPending: 'connect_pins_pending',
          SignInUnavailableReason.connectUnreachable: 'connect_unreachable',
          SignInUnavailableReason.connectUrlInvalid: 'connect_url_invalid',
          SignInUnavailableReason.blockedByEnvironment:
              'blocked_by_environment',
          SignInUnavailableReason.laneNotOffered: 'lane_not_offered',
        },
      );
      for (final reason in SignInUnavailableReason.values) {
        expect(SignInUnavailableReason.fromWire(reason.wire), reason);
      }
      expect(SignInUnavailableReason.fromWire(null), isNull);
      expect(SignInUnavailableReason.fromWire(''), isNull);
      expect(SignInUnavailableReason.fromWire(7), isNull);
      expect(
        SignInUnavailableReason.fromWire('something_new'),
        SignInUnavailableReason.notConfigured,
      );
    });

    test('SignInAttemptStatus reads anything unknown as failed', () {
      for (final status in SignInAttemptStatus.values) {
        expect(status.wire, status.name);
        expect(SignInAttemptStatus.fromWire(status.wire), status);
      }
      expect(SignInAttemptStatus.fromWire('done'), SignInAttemptStatus.failed);
      expect(SignInAttemptStatus.fromWire(null), SignInAttemptStatus.failed);
      expect(SignInAttemptStatus.pending.isTerminal, isFalse);
      expect(SignInAttemptStatus.succeeded.isTerminal, isTrue);
      expect(SignInAttemptStatus.failed.isTerminal, isTrue);
    });

    test('the refresh-rejection table is the three dead-credential codes', () {
      expect(oauthRefreshRejectedErrors, {
        'invalid_grant',
        'bad_refresh_token',
        'unauthorized_client',
      });
    });

    test('isConnectSecretEnvKey: secrets and their rotations, any case; '
        'never identifiers, flags or file paths', () {
      for (final key in connectSecretEnvKeys) {
        expect(isConnectSecretEnvKey(key), isTrue, reason: key);
        expect(isConnectSecretEnvKey(key.toLowerCase()), isTrue, reason: key);
        expect(isConnectSecretEnvKey('${key}_FILE'), isFalse, reason: key);
      }
      expect(isConnectSecretEnvKey('connect_github_client_secret'), isTrue);
      expect(isConnectSecretEnvKey('CONNECT_KLIPY_APP_KEY_PREVIOUS'), isTrue);
      for (final key in [
        'CONNECT_GITHUB_CLIENT_ID',
        'CONNECT_GITHUB_APP_ID',
        'CONNECT_GITHUB_SECRET_GENERATION',
        'CONNECT_SLACK_APP_ID',
        'CONNECT_ALLOWED_INSTALLS',
        'CONNECT_SIGNED_CONFIG',
        'CONNECT_CONFIG_PUBLIC_KEYS',
        'CONNECT_REDIS_CA_FILE',
        'CONNECT_SEAL_KEYS_FILE',
        'CONNECT_KMS_KEY',
        'CONNECT_PUBLIC_URL',
        'GITHUB_CLIENT_SECRET',
        '',
      ]) {
        expect(isConnectSecretEnvKey(key), isFalse, reason: key);
      }
    });
  });

  group('wire', () {
    test('unknown error codes read as provider_unavailable', () {
      expect(ConnectErrorCode.fromWire('???'), isA<ConnectErrorCode>());
      expect(
        ConnectErrorCode.fromWire('???'),
        ConnectErrorCode.providerUnavailable,
      );
      expect(ConnectErrorCode.providerUnavailable.clearsGrant, isFalse);
      expect(ConnectErrorCode.needsSignIn.clearsGrant, isTrue);
    });

    test('only needs_sign_in drops a grant; rate_limited never does', () {
      expect(
        [
          for (final code in ConnectErrorCode.values)
            if (code.clearsGrant) code,
        ],
        [ConnectErrorCode.needsSignIn],
      );
      expect(
        SignInFailure.fromConnect(ConnectErrorCode.rateLimited),
        SignInFailure.rateLimited,
      );
      expect(ConnectErrorCode.rateLimited.httpStatus, 429);
    });

    test('klipy items off the CDN are dropped', () {
      final item = {
        'id': '1',
        'title': 't',
        'width': 10,
        'height': 10,
        'preview_url': 'https://static.klipy.com/a.gif',
        'gif_url': 'https://static.klipy.com/b.gif',
      };
      expect(KlipyGif.tryParse(item), isNotNull);
      expect(
        KlipyGif.tryParse({...item, 'gif_url': 'https://evil.example/b.gif'}),
        isNull,
      );
    });

    test('slack response urls are pinned to hooks.slack.com', () {
      expect(isSlackResponseUrl('https://hooks.slack.com/commands/x'), isTrue);
      expect(isSlackResponseUrl('https://hooks.slack.com.evil/x'), isFalse);
      expect(isSlackResponseUrl('http://hooks.slack.com/x'), isFalse);
    });

    test('a scope request names who the token is for, and must', () {
      const request = GitHubScopeRequest(
        seal: 'seal',
        workspaceId: 'ws1',
        repoId: 9001,
        repoOwner: 'acme',
        repoName: 'api',
        scope: 'bot',
        actor: GitHubMintActor.app,
      );
      final json = request.toJson();
      expect(json['as'], 'app');
      expect(GitHubScopeRequest.fromJson(json).actor, GitHubMintActor.app);
      expect(
        GitHubScopeRequest.fromJson({...json, 'as': 'user'}).actor,
        GitHubMintActor.user,
      );
      expect(
        () => GitHubScopeRequest.fromJson({...json}..remove('as')),
        throwsFormatException,
      );
      expect(
        () => GitHubScopeRequest.fromJson({...json, 'as': 'server'}),
        throwsFormatException,
      );
    });

    test('an installation token carries the coverage the server checks', () {
      final token = GitHubScopedToken(
        accessToken: 'ghs_x',
        grantedScope: 'read',
        expiresAt: DateTime.utc(2030),
        installationId: 77,
        repositorySelection: 'selected',
        repositoryIds: const [9001],
        permissions: const {'metadata': 'read', 'contents': 'read'},
      );
      final parsed = GitHubScopedToken.fromJson(token.toJson());
      expect(parsed.repositoryIds, [9001]);
      expect(parsed.repositorySelection, 'selected');
      expect(
        scopedTokenMatches(
          parsed.coverage,
          repoId: 9001,
          permissions: const {'metadata': 'read', 'contents': 'read'},
        ),
        isTrue,
      );
      expect(
        scopedTokenMatches(
          GitHubScopedToken.fromJson({
            ...token.toJson(),
            'repositories': [9001, 9002],
          }).coverage,
          repoId: 9001,
          permissions: const {'metadata': 'read', 'contents': 'read'},
        ),
        isFalse,
      );
      // A user child carries none of it.
      final child = GitHubScopedToken.fromJson(
        GitHubScopedToken(
          accessToken: 'ghu_x',
          grantedScope: 'read',
          expiresAt: DateTime.utc(2030),
        ).toJson(),
      );
      expect(child.repositoryIds, isEmpty);
      expect(child.toJson().containsKey('repositories'), isFalse);
    });

    test('repo_not_selected reads as its own code', () {
      expect(
        ConnectErrorCode.fromWire('repo_not_selected'),
        ConnectErrorCode.repoNotSelected,
      );
    });
  });
}
