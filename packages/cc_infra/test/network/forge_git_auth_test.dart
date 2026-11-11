import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/forge_git_auth.dart';
import 'package:cc_infra/src/network/forge_http_client_factory.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// One reading of a stored Bitbucket credential for REST and git alike.
void main() {
  group('BitbucketCredential', () {
    test('an API token with its email is basic auth and '
        'x-bitbucket-api-token-auth over git', () {
      final c = BitbucketCredential.parse('jdoe@example.com:ATATT3x');
      expect(c.isApiToken, isTrue);
      expect(c.email, 'jdoe@example.com');
      expect(c.token, 'ATATT3x');
      expect(
        c.authorizationHeader,
        'Basic ${base64Encode(utf8.encode('jdoe@example.com:ATATT3x'))}',
      );
      expect(c.gitAuth, (
        username: 'x-bitbucket-api-token-auth',
        password: 'ATATT3x',
      ));
    });

    test('a bare access token is bearer and x-token-auth over git', () {
      final c = BitbucketCredential.parse('ATCTT3xFfGN0');
      expect(c.isApiToken, isFalse);
      expect(c.authorizationHeader, 'Bearer ATCTT3xFfGN0');
      expect(c.gitAuth, (username: 'x-token-auth', password: 'ATCTT3xFfGN0'));
    });

    test('only the first colon splits, and only after an email', () {
      // A colon later in the token stays part of it.
      final c = BitbucketCredential.parse('a@b.co:tok:en');
      expect(c.email, 'a@b.co');
      expect(c.token, 'tok:en');
      // No `@` before the colon: not an email, so the whole text is one
      // (bare) token rather than a username the forge would reject.
      final odd = BitbucketCredential.parse('user:secret');
      expect(odd.isApiToken, isFalse);
      expect(odd.token, 'user:secret');
      expect(odd.gitAuth.username, 'x-token-auth');
      // A leading colon is no email either.
      expect(BitbucketCredential.parse(':x').isApiToken, isFalse);
    });
  });

  test('every forge maps to the username its git host expects', () {
    expect(
      forgeGitHttpAuth(ForgeHost.github, 'ghs_x').username,
      'x-access-token',
    );
    expect(forgeGitHttpAuth(ForgeHost.gitlab, 'glpat').username, 'oauth2');
    expect(forgeGitHttpAuth(ForgeHost.bitbucket, 'me@x.io:tok'), (
      username: 'x-bitbucket-api-token-auth',
      password: 'tok',
    ));
    expect(forgeGitHttpAuth(ForgeHost.bitbucket, 'access'), (
      username: 'x-token-auth',
      password: 'access',
    ));
  });

  test('the REST header agrees with the git mapping', () {
    expect(forgeAuthorizationHeader(ForgeHost.gitlab, 't'), 'Bearer t');
    expect(forgeAuthorizationHeader(ForgeHost.bitbucket, 't'), 'Bearer t');
    expect(
      forgeAuthorizationHeader(ForgeHost.bitbucket, 'me@x.io:t'),
      startsWith('Basic '),
    );
  });

  test('a missing automation token fails locally with its own code', () {
    final failure = const ForgeCredentialUnavailable.automationTokenMissing(
      'No automation token for group/api.',
    ).asStatusFailure(HttpRequest(method: HttpMethod.get, url: '/projects'));
    final mapped = mapHttpException(failure);
    expect(mapped.code, kAutomationTokenMissingCode);
    expect(mapped.statusCode, 401);
    expect(mapped.message, 'No automation token for group/api.');
    // A person's missing sign-in keeps its own code.
    final signIn = mapHttpException(
      const ForgeCredentialUnavailable.needsSignIn(
        'gitlab',
        'Connect GitLab.',
      ).asStatusFailure(HttpRequest(method: HttpMethod.get, url: '/user')),
    );
    expect(signIn.code, kNeedsSignInCode);
  });

  group('forgeGitAuthConfigParameter', () {
    String header(String parameter) {
      final match = RegExp(
        r"^'http\.https://([^/]+)/\.extraHeader=Authorization: Basic (.+)'$",
      ).firstMatch(parameter)!;
      return '${match[1]} ${utf8.decode(base64Decode(match[2]!))}';
    }

    test('each forge gets its own host and username', () {
      expect(
        header(forgeGitAuthConfigParameter(ForgeHost.github, 'ghs_abc')),
        'github.com x-access-token:ghs_abc',
      );
      expect(
        header(forgeGitAuthConfigParameter(ForgeHost.gitlab, 'glpat-abc')),
        'gitlab.com oauth2:glpat-abc',
      );
      expect(
        header(
          forgeGitAuthConfigParameter(
            ForgeHost.bitbucket,
            'ada@example.com:ATATT3x',
          ),
        ),
        'bitbucket.org x-bitbucket-api-token-auth:ATATT3x',
      );
    });

    test('a stateless installation token (dotted, ~520 characters) is '
        'carried whole', () {
      final token = 'ghs_4242_${'eyJhbGciOiJSUzI1NiJ9.' * 24}sig-_x';
      expect(token.length, greaterThan(500));
      expect(
        header(forgeGitAuthConfigParameter(ForgeHost.github, token)),
        'github.com x-access-token:$token',
      );
    });
  });

  test('the Basic header git sends is the one the config parameter '
      'carries', () {
    for (final (forge, token) in [
      (ForgeHost.github, 'ghs_abc'),
      (ForgeHost.gitlab, 'glpat-abc'),
      (ForgeHost.bitbucket, 'ada@example.com:ATATT3x'),
    ]) {
      final basic = forgeGitBasicAuthorization(forge, token);
      final auth = forgeGitHttpAuth(forge, token);
      final pair = utf8.encode('${auth.username}:${auth.password}');
      expect(basic, 'Basic ${base64Encode(pair)}');
      expect(forgeGitAuthConfigParameter(forge, token), contains(basic));
    }
  });
}
