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

    test('a too-short GitHub PAT body is NOT redacted (guard threshold)', () {
      // ghp_ + 32 chars < {36,} → no match, kept verbatim.
      expect(
        redactSecrets('leak ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        'leak ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
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

  group('redactSecretsFromJson', () {
    test('redacts string values under secret-shaped keys', () {
      final out = redactSecretsFromJson('{"token": "ghp_x", "name": "sam"}');
      // jsonEncode emits compact JSON (no space after the colon).
      expect(out, contains('"token":"***REDACTED***"'));
      expect(out, contains('"sam"'));
    });

    test('recurses into nested maps', () {
      final out = redactSecretsFromJson('{"outer": {"api_key": "v", "ok": 1}}');
      expect(out, contains('"api_key":"***REDACTED***"'));
      expect(out, contains('"ok":1'));
    });

    test(
      'redacts a value that looks like a secret even under a benign key',
      () {
        final out = redactSecretsFromJson('{"random": "$ghp36"}');
        expect(out, contains('"***REDACTED***"'));
      },
    );

    test('leaves short non-secret values alone', () {
      final out = redactSecretsFromJson('{"title": "hi"}');
      expect(out, contains('"hi"'));
    });

    test('falls back to redactSecrets on invalid JSON', () {
      const line = 'not-json --token=$ghp36';
      expect(redactSecretsFromJson(line), 'not-json ***REDACTED***');
    });

    test('preserves list values (passed through)', () {
      final out = redactSecretsFromJson('{"tags": ["a", "b"]}');
      expect(out, contains('["a","b"]'));
    });
  });
}
