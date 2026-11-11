import 'package:cc_domain/core/domain/services/redaction/secret_scanner.dart';
import 'package:cc_domain/core/domain/services/redaction/token_patterns.dart';
import 'package:test/test.dart';

/// Synthetic credentials of every shape the table knows; none is real.
final Map<String, String> _synthetic = {
  'bearer token': 'Bearer ${'a' * 24}',
  'Anthropic API key': 'sk-ant-${'a' * 24}',
  'API key': 'sk-${'a' * 24}',
  'Google API key': 'AIza${'a' * 24}',
  'AWS access key': 'AKIA${'A' * 16}',
  'GitHub token': 'ghs_${'a' * 30}.${'b' * 10}',
  'GitLab token': 'glpat-${'a' * 20}',
  'Atlassian token': 'ATATT${'a' * 24}',
  'Slack token': 'xoxb-${'1' * 12}-${'a' * 12}',
  'Linear token': 'lin_oauth_${'a' * 24}',
  'Google OAuth token': 'ya29.${'a' * 24}',
  'JSON web token': 'eyJ${'a' * 10}.eyJ${'b' * 10}.${'c' * 10}',
  'private key':
      '-----BEGIN PRIVATE KEY-----\n${'A' * 40}\n-----END PRIVATE KEY-----',
};

void main() {
  test('every label in the table has a synthetic example here', () {
    expect({for (final p in kTokenPatterns) p.label}, _synthetic.keys.toSet());
  });

  for (final MapEntry(key: label, value: token) in _synthetic.entries) {
    test('$label is redacted and flagged', () {
      final line = 'calling with $token, then done.';
      final redacted = redactTokens(line);
      expect(redacted, isNot(contains(token)));
      expect(redacted, startsWith('calling with '));
      expect(redacted, endsWith(', then done.'));
      expect(
        const SecretScanner().scan(line).map((f) => f.reason),
        contains(label),
      );
    });
  }

  test('an sk- key is caught from 20 characters, not below', () {
    final shortest = 'sk-${'a' * 20}';
    expect(redactTokens('key $shortest.'), isNot(contains(shortest)));
    final tooShort = 'sk-${'a' * 19}';
    expect(redactTokens('key $tooShort.'), contains(tooShort));
  });

  test('ordinary text is untouched', () {
    const text = 'gh pr view 42 --json title; see https://1.example/path';
    expect(redactTokens(text), text);
    expect(const SecretScanner().scan(text), isEmpty);
  });
}
