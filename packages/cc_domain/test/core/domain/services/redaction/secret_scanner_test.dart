import 'package:cc_domain/core/domain/services/redaction/secret_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('SecretScanner pattern detection', () {
    const scanner = SecretScanner();

    test('flags a bearer token', () {
      final findings = scanner.scan({
        'authorization': 'Bearer abcdef0123456789abcdef0123',
      });
      expect(findings, hasLength(1));
      expect(findings.single.reason, 'bearer token');
      expect(findings.single.path, r'$.authorization');
    });

    test('flags an Anthropic key (more specific than generic sk-)', () {
      final findings = scanner.scan('sk-ant-api03-aaaaaaaaaaaaaaaaaaaaaaaa');
      expect(findings.map((f) => f.reason), contains('Anthropic API key'));
    });

    test('flags GitHub, Google, AWS tokens and PEM blocks', () {
      expect(
        scanner.scan('ghp_${'a' * 24}').map((f) => f.reason),
        contains('GitHub token'),
      );
      expect(
        scanner.scan('AIza${'b' * 35}').map((f) => f.reason),
        contains('Google API key'),
      );
      expect(
        scanner.scan('AKIAIOSFODNN7EXAMPLE').map((f) => f.reason),
        contains('AWS access key'),
      );
      expect(
        scanner.scan('-----BEGIN RSA PRIVATE KEY-----').map((f) => f.reason),
        contains('private key'),
      );
    });

    test('flags every GitHub token shape, the stateless installation token '
        'included', () {
      // `ghs_<appId>_<JWT>`: dots and hyphens, about 520 characters.
      final stateless =
          'ghs_123456_e-J0eXAiOiJKV1QifQ.${'aB3-_' * 40}.${'Zz9_-' * 50}';
      for (final token in [
        'ghp_${'a' * 36}',
        'gho_${'b' * 36}',
        'ghu_${'c' * 36}',
        'ghr_${'d' * 76}',
        'ghs_${'e' * 36}',
        stateless,
      ]) {
        expect(
          scanner.scan('token=$token.').map((f) => f.reason),
          contains('GitHub token'),
          reason: token.substring(0, 12),
        );
      }
      expect(scanner.scan('the ghs_ prefix alone, or gh_pages'), isEmpty);
    });

    test('flags Slack, Linear and Google OAuth tokens', () {
      for (final (value, reason) in [
        ('xoxb-1234567890-AbCdEfGhIjKl', 'Slack token'),
        ('xoxe.xoxb-1-MS0yLTEyMzQ1Njc4', 'Slack token'),
        ('xoxe-1-My0xLTEyMzQ1Njc4OTA', 'Slack token'),
        ('xapp-1-A0123456789-123456', 'Slack token'),
        ('lin_oauth_${'0f1e2d3c' * 4}', 'Linear token'),
        ('lin_api_${'a1B2' * 5}', 'Linear token'),
        ('ya29.a0AfH6SMBxAbcDefGhiJklMno', 'Google OAuth token'),
        ('1//0gAbCdEfGhIjKlMnOpQrStUv', 'Google OAuth token'),
        ('github_pat_11ABCDEFG0_${'x' * 30}', 'GitHub token'),
      ]) {
        expect(
          scanner.scan(value).map((f) => f.reason),
          contains(reason),
          reason: value,
        );
      }
    });

    test('walks nested maps and lists, reporting paths', () {
      final findings = scanner.scan({
        'a': [
          {'token': 'ghp_${'z' * 30}'},
        ],
      });
      expect(findings, hasLength(1));
      expect(findings.single.path, r'$.a[0].token');
    });

    test('clean values produce no findings', () {
      expect(scanner.scan({'name': 'octocat', 'count': 3}), isEmpty);
    });
  });

  group('environment-secret detection', () {
    test('flags a value matching a secret-named env var', () {
      const scanner = SecretScanner(
        environment: {'OPENAI_API_KEY': 'super-secret-value-1234'},
      );
      final findings = scanner.scan({'body': 'x=super-secret-value-1234'});
      expect(findings, hasLength(1));
      expect(findings.single.reason, 'environment secret OPENAI_API_KEY');
    });

    test('ignores non-secret env names and short / safe values', () {
      const scanner = SecretScanner(
        environment: {
          'HOME': '/Users/somebody-with-a-long-path',
          'API_KEY': 'fixture',
          'SHORT_TOKEN': 'abc',
        },
      );
      expect(
        scanner.scan({'body': '/Users/somebody-with-a-long-path'}),
        isEmpty,
      );
      expect(scanner.scan({'body': 'fixture'}), isEmpty);
      expect(scanner.scan({'body': 'abc'}), isEmpty);
    });
  });
}
