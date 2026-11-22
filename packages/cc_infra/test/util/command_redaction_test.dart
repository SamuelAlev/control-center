import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:test/test.dart';

/// Pins the command-line secret redactor (VULN-010 / VULN-012). The redactor
/// scrubs tokens in `--flag=VALUE` and `--flag VALUE` forms, PATs embedded in
/// git URLs, Authorization headers, JSON keys and provider-specific token
/// prefixes. Note: capture-group patterns with a single group replace the
/// whole match wholesale (the source emits a bare `***REDACTED***`); only the
/// two-group JSON-value patterns preserve surrounding quotes. These tests pin
/// the current behavior so a change to the replacement is intentional.
void main() {
  // Tokens long enough to satisfy the {36,} GitHub prefix guards.
  const ghp36 =
      'ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; // 40 total, 36+ body
  const sk40 = 'sk-abcd1234efgh5678ijkl9012mnop3456'; // 24+ body chars

  group('redactSecrets', () {
    test('scrubs Anthropic keys and Claude Code setup tokens', () {
      // The hyphens after `sk-` slip past the generic `sk-` pattern.
      const setup = 'sk-ant-oat01-Ab_cD-ef012345678901234567890';
      const api = 'sk-ant-api03-Ab_cD-ef012345678901234567890';
      expect(redactSecrets('token $setup end'), 'token ***REDACTED*** end');
      expect(redactSecrets(api), '***REDACTED***');
      expect(
        redactSecrets('CLAUDE_CODE_OAUTH_TOKEN=whatever'),
        '***REDACTED***',
      );
    });

    test('leaves innocuous text untouched', () {
      expect(
        redactSecrets('git clone https://github.com/o/r.git main'),
        'git clone https://github.com/o/r.git main',
      );
    });

    test('--flag=VALUE form replaces the whole flag match', () {
      // Single capture group → wholesale ***REDACTED***.
      expect(
        redactSecrets('curl --api-key=$sk40 url'),
        'curl ***REDACTED*** url',
      );
      expect(
        redactSecrets('tool --token=$ghp36 url'),
        'tool ***REDACTED*** url',
      );
      expect(redactSecrets('tool --key=$sk40 url'), 'tool ***REDACTED*** url');
    });

    test('--flag VALUE form (space-separated) replaces the whole match', () {
      expect(redactSecrets('gh --token $ghp36 repo'), 'gh ***REDACTED*** repo');
      expect(
        redactSecrets('curl --api-key ABCD url'),
        'curl ***REDACTED*** url',
      );
    });

    test('Authorization: Bearer / Basic headers', () {
      expect(
        redactSecrets('Authorization: Bearer abc.def.ghi'),
        '***REDACTED***',
      );
      expect(
        redactSecrets('authorization: Basic dXNlcjpwYXNz'),
        '***REDACTED***',
      );
    });

    test('bare provider token prefixes are replaced wholesale', () {
      expect(
        redactSecrets('found $sk40 in logs'),
        'found ***REDACTED*** in logs',
      );
      expect(redactSecrets('leak $ghp36'), 'leak ***REDACTED***');
      // GitHub App tokens (ghs_/ghu_/ghr_) + fine-grained PAT.
      expect(
        redactSecrets('x ghs_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa y'),
        'x ***REDACTED*** y',
      );
      expect(
        redactSecrets('x ghu_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa y'),
        'x ***REDACTED*** y',
      );
      expect(
        redactSecrets('x ghr_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa y'),
        'x ***REDACTED*** y',
      );
      expect(
        redactSecrets('x github_pat_abcdefghijklmnopqrstuvwxyz y'),
        'x ***REDACTED*** y',
      );
      // Linear key prefix.
      expect(
        redactSecrets('x lin_api_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa y'),
        'x ***REDACTED*** y',
      );
    });

    test('a too-short GitHub token body is NOT redacted (guard threshold)', () {
      // ghp_ + 10 chars < the shared table's 20 → no match, kept verbatim.
      expect(redactSecrets('leak ghp_aaaaaaaaaa'), 'leak ghp_aaaaaaaaaa');
    });

    test('every shape of the shared token table, as the scanner sees it', () {
      const tokens = [
        'glpat-aaaaaaaaaaaaaaaaaaaa',
        'ATATTaaaaaaaaaaaaaaaaaaaaaaaa',
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl',
        '-----BEGIN RSA PRIVATE KEY-----\nAAAA\n-----END RSA PRIVATE KEY-----',
        'AIzaaaaaaaaaaaaaaaaaaaaaaaaa',
        'ghu_aaaaaaaaaaaaaaaaaaaaaaaa',
      ];
      for (final token in tokens) {
        final out = redactSecrets('before $token after');
        expect(out, isNot(contains(token)), reason: token);
        expect(out, startsWith('before '), reason: token);
        expect(out, endsWith(' after'), reason: token);
      }
    });

    test('PAT embedded in a git URL (x-access-token scheme)', () {
      expect(
        redactSecrets('https://x-access-token:$ghp36@github.com/o/r'),
        'https://x-access-token:***REDACTED***@github.com/o/r',
      );
    });

    test('credentials embedded in a generic scheme URL', () {
      expect(
        redactSecrets('https://user:p%40ss@host.example.com/path'),
        'https://user:***REDACTED***@host.example.com/path',
      );
    });

    test('a URL with a long scheme is still redacted', () {
      final scheme = 'x' * 40;
      expect(
        redactSecrets('$scheme://user:secret@host'),
        '$scheme://user:***REDACTED***@host',
      );
    });

    test('a long run of letters is scanned in linear time', () {
      // Quadratic before the scheme was bounded: about 25 s for this input.
      final input = 'a' * (64 * 1024);
      final watch = Stopwatch()..start();
      expect(redactSecrets(input), input);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test(
      'env-assignment forms (GH_TOKEN / GITHUB_TOKEN / TICKETING_API_KEY)',
      () {
        expect(redactSecrets('GH_TOKEN=$ghp36'), '***REDACTED***');
        expect(redactSecrets('GITHUB_TOKEN=$ghp36'), '***REDACTED***');
        expect(redactSecrets('TICKETING_API_KEY=lin_secret'), '***REDACTED***');
      },
    );

    test(
      'JSON value forms preserve the surrounding quotes (2-group pattern)',
      () {
        expect(
          redactSecrets('{"api_key": "lin_secret_value"}'),
          '{"api_key": "***REDACTED***"}',
        );
        expect(
          redactSecrets('{"token": "abc"}'),
          '{"token": "***REDACTED***"}',
        );
        expect(
          redactSecrets('{"secret": "shh"}'),
          '{"secret": "***REDACTED***"}',
        );
      },
    );
  });

  group('redactSecrets — provider token shapes', () {
    // A `ghs_<appId>_<JWT>` installation token: underscores, dots and hyphens,
    // about 520 characters.
    final jwt = [
      'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9',
      'eyJpc3MiOiIxMjM0NTYiLCJleHAiOjE3MDAwMDAwMDB9${'x' * 380}',
      'Zm9vYmFy-c2lnbmF0dXJl_dGFpbA',
    ].join('.');
    final longGhs = 'ghs_123456_$jwt';

    test('the long ghs_<appid>_<jwt> installation token, whole', () {
      expect(longGhs.length, greaterThan(500));
      expect(redactSecrets('token $longGhs.'), 'token ***REDACTED***.');
      expect(redactSecrets('Bearer=$longGhs end'), isNot(contains('eyJ')));
    });

    test('every GitHub token prefix', () {
      for (final token in [
        'ghu_${'A1b2' * 10}',
        'ghr_${'A1b2' * 10}',
        'gho_${'A1b2' * 10}',
        'ghp_${'A1b2' * 10}',
        'ghs_${'A1b2' * 10}',
        'github_pat_11ABCDEFG0_${'x9Y8' * 15}',
      ]) {
        expect(
          redactSecrets('x $token y'),
          'x ***REDACTED*** y',
          reason: token,
        );
      }
    });

    test('Slack bot, user, rotating, refresh and app tokens', () {
      for (final token in [
        'xoxb-1234567890-0987654321-AbCdEfGhIjKlMnOpQrStUvWx',
        'xoxp-1234567890-0987654321-1122334455-abcdef0123456789',
        'xoxe.xoxb-1-MS0yLTEyMzQ1Njc4OTAtYWJjZGVm',
        'xoxe.xoxp-1-MS0yLTEyMzQ1Njc4OTAtYWJjZGVm',
        'xoxe-1-My0xLTEyMzQ1Njc4OTAtYWJjZGVmZ2hpams',
        'xapp-1-A0123456789-1234567890123-abcdef0123456789',
      ]) {
        expect(
          redactSecrets('x $token y'),
          'x ***REDACTED*** y',
          reason: token,
        );
      }
    });

    test('Linear API keys and OAuth tokens', () {
      for (final token in [
        'lin_api_${'a1B2' * 10}',
        'lin_oauth_${'0f1e2d3c' * 8}',
      ]) {
        expect(
          redactSecrets('x $token y'),
          'x ***REDACTED*** y',
          reason: token,
        );
      }
    });

    test('Google access and refresh tokens', () {
      expect(
        redactSecrets('x ya29.a0AfH6SMBx-Ab_cDeFgHiJkLmNoPqRsTuVwXyZ0123 y'),
        'x ***REDACTED*** y',
      );
      expect(
        redactSecrets('refresh=1//0gAbCdEfGhIjKlMnOpQrStUvWxYz-_0123456789'),
        'refresh=***REDACTED***',
      );
      // A URL path is not a refresh token.
      const url = 'https://example.com/a/1//AbCdEfGhIjKlMnOpQrStUvWx';
      expect(redactSecrets(url), url);
    });

    test('the Basic x-access-token header git carries in its env', () {
      const b64 = 'eC1hY2Nlc3MtdG9rZW46Z2hzX2FiY2RlZmdoaWprbG1ub3A=';
      const params =
          "GIT_CONFIG_PARAMETERS='http.https://github.com/.extraHeader="
          "Authorization: Basic $b64'";
      final redacted = redactSecrets(params);
      expect(redacted, isNot(contains('eC1hY2Nlc3MtdG9rZW46')));
      expect(redacted, startsWith('GIT_CONFIG_PARAMETERS='));
      // The base64 alone, outside any header, is still credentials.
      expect(
        redactSecrets('header value $b64 end'),
        'header value ***REDACTED*** end',
      );
      expect(redactSecrets('Authorization: token ghs_short'), '***REDACTED***');
    });
  });
}
