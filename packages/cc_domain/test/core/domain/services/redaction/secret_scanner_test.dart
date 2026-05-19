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
