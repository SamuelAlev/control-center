import 'package:cc_domain/core/domain/services/redaction/sensitive_arguments.dart';
import 'package:test/test.dart';

void main() {
  const marker = SensitiveArguments.marker;

  test('matches keys case-insensitively on a fragment', () {
    for (final key in ['api_key', 'X-Api-Key', 'githubToken', 'Body', 'psk']) {
      expect(SensitiveArguments.isSensitiveKey(key), isTrue, reason: key);
    }
    for (final key in ['path', 'query', 'limit', 'id']) {
      expect(SensitiveArguments.isSensitiveKey(key), isFalse, reason: key);
    }
  });

  test('redacts at any depth and keeps the keys', () {
    final redacted = SensitiveArguments.redact({
      'path': 'a.txt',
      'token': 'abc',
      'items': [
        {'password': 'p', 'name': 'n'},
        'plain',
      ],
      'nested': {
        'deeper': {'content': 'secret words', 'line': 3},
      },
      7: 'numeric key',
    });
    expect(redacted, {
      'path': 'a.txt',
      'token': marker,
      'items': [
        {'password': marker, 'name': 'n'},
        'plain',
      ],
      'nested': {
        'deeper': {'content': marker, 'line': 3},
      },
      '7': 'numeric key',
    });
  });

  test('a sensitive key hides a whole structured value', () {
    expect(
      SensitiveArguments.redact({
        'credentials': {'user': 'u', 'pass': 'p'},
      }),
      {'credentials': marker},
    );
  });

  test('scalars and null pass through', () {
    expect(SensitiveArguments.redact('text'), 'text');
    expect(SensitiveArguments.redact(3), 3);
    expect(SensitiveArguments.redact(null), isNull);
  });
}
