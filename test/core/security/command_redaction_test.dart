import 'package:control_center/core/security/command_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactSecrets', () {
    test(
      'redacts --api-key flag (entire match replaced)',
      timeout: const Timeout.factor(2),
      () {
        const input = 'curl --api-key=sk_live_abcdef1234567890 https://api.example.com';
        final result = redactSecrets(input);
        // Single-capture-group patterns replace the ENTIRE match with ***REDACTED***
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('sk_live_abcdef1234567890')));
        expect(result, contains('https://api.example.com'));
      },
    );

    test(
      'redacts --token flag',
      timeout: const Timeout.factor(2),
      () {
        const input = 'command --token=my_secret_token';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('my_secret_token')));
      },
    );

    test(
      'redacts --key flag',
      timeout: const Timeout.factor(2),
      () {
        const input = 'run --key=my_secret_key_value';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('my_secret_key_value')));
      },
    );

    test(
      'redacts Authorization Bearer header',
      timeout: const Timeout.factor(2),
      () {
        const input = 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('eyJhbGci')));
      },
    );

    test(
      'redacts Authorization Basic header',
      timeout: const Timeout.factor(2),
      () {
        const input = 'Authorization: Basic dXNlcjpwYXNzd29yZA==';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('dXNlcjpwYXNzd29yZA==')));
      },
    );

    test(
      'redacts OpenAI-style sk- tokens with 20+ consecutive alphanums',
      timeout: const Timeout.factor(2),
      () {
        const token = 'sk-abcdefghijklmnopqrst'; // 20 alphanums after sk-
        final result = redactSecrets('key is $token');
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains(token)));
      },
    );

    test(
      'sk- token with fewer than 20 alphanums is not matched',
      timeout: const Timeout.factor(2),
      () {
        const token = 'sk-short123'; // only 8 alphanums after sk-
        final result = redactSecrets('key is $token');
        expect(result, contains(token));
      },
    );

    test(
      'redacts GitHub PAT tokens (ghp_)',
      timeout: const Timeout.factor(2),
      () {
        const token = 'ghp_1234567890abcdef1234567890abcdef1234';
        final result = redactSecrets('token=$token');
        expect(result, isNot(contains(token)));
        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'redacts GitHub OAuth tokens (gho_)',
      timeout: const Timeout.factor(2),
      () {
        const token = 'gho_1234567890abcdef1234567890abcdef1234';
        final result = redactSecrets('token=$token');
        expect(result, isNot(contains(token)));
        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'redacts GitHub fine-grained PAT tokens (github_pat_)',
      timeout: const Timeout.factor(2),
      () {
        const token = 'github_pat_ABCDEFGHIJKLMNOPQRSTUVWXYZabcd';
        final result = redactSecrets('value=$token');
        expect(result, isNot(contains(token)));
        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'redacts Linear API tokens (lin_api_)',
      timeout: const Timeout.factor(2),
      () {
        const token = 'lin_api_abcdefghijklmnopqrstuvwx';
        final result = redactSecrets('key=$token');
        expect(result, isNot(contains(token)));
        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'redacts TICKETING_API_KEY environment variable',
      timeout: const Timeout.factor(2),
      () {
        const input = 'TICKETING_API_KEY=my_secret_key';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('my_secret_key')));
      },
    );

    test(
      'redacts GH_TOKEN environment variable',
      timeout: const Timeout.factor(2),
      () {
        const input = 'GH_TOKEN=ghp_1234567890abcdef1234567890abcdef1234';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('ghp_')));
      },
    );

    test(
      'redacts GITHUB_TOKEN environment variable',
      timeout: const Timeout.factor(2),
      () {
        const input = 'GITHUB_TOKEN=ghp_1234567890abcdef1234567890abcdef1234';
        final result = redactSecrets(input);
        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('ghp_')));
      },
    );

    test(
      'redacts JSON "api_key" value preserving quotes',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"api_key": "my-secret-value"}';
        final result = redactSecrets(input);
        // Two-capture-group patterns preserve prefix + suffix
        expect(result, contains('"api_key": "***REDACTED***"'));
        expect(result, isNot(contains('my-secret-value')));
      },
    );

    test(
      'redacts JSON "token" value preserving quotes',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"token": "tok_value_12345"}';
        final result = redactSecrets(input);
        expect(result, contains('"token": "***REDACTED***"'));
        expect(result, isNot(contains('tok_value_12345')));
      },
    );

    test(
      'redacts JSON "secret" value preserving quotes',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"secret": "s3cr3t_v4lu3"}';
        final result = redactSecrets(input);
        expect(result, contains('"secret": "***REDACTED***"'));
        expect(result, isNot(contains('s3cr3t_v4lu3')));
      },
    );

    test(
      'preserves non-sensitive content',
      timeout: const Timeout.factor(2),
      () {
        const input = 'git clone https://github.com/owner/repo.git --branch main';
        expect(redactSecrets(input), equals(input));
      },
    );

    test(
      'preserves regular command output',
      timeout: const Timeout.factor(2),
      () {
        const input = 'flutter test --coverage';
        expect(redactSecrets(input), equals(input));
      },
    );

    test(
      'handles empty string',
      timeout: const Timeout.factor(2),
      () {
        expect(redactSecrets(''), equals(''));
      },
    );

    test(
      'redacts case-insensitively for flags',
      timeout: const Timeout.factor(2),
      () {
        expect(
          redactSecrets('--API_KEY=secret'),
          contains('***REDACTED***'),
        );
        expect(
          redactSecrets('--Token=abc'),
          contains('***REDACTED***'),
        );
      },
    );
  });

  group('redactSecretsFromJson', () {
    test(
      'redacts JSON values with secret keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"api_key": "my-secret", "name": "test"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('my-secret')));
        expect(result, contains('"test"'));
      },
    );

    test(
      'redacts token keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"token": "abc123", "other": "value"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('abc123')));
        expect(result, contains('"value"'));
      },
    );

    test(
      'redacts secret keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"secret": "s3cr3t", "public": "visible"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, contains('"visible"'));
      },
    );

    test(
      'redacts password keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"password": "hunter2", "username": "admin"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, contains('"admin"'));
      },
    );

    test(
      'redacts credential keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"credentials": "abc", "data": "keep"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, contains('"keep"'));
      },
    );

    test(
      'redacts auth keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"authorization": "Bearer token123", "method": "POST"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, contains('"POST"'));
      },
    );

    test(
      'redacts values that look like known token shapes',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"custom_key": "sk-abcdefghijklmnopqrst"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'handles nested JSON objects',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"config": {"token": "secret123"}, "name": "app"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, contains('"app"'));
      },
    );

    test(
      'handles arrays in JSON',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"items": [1, 2, 3], "token": "abc"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
      },
    );

    test(
      'falls back to redactSecrets for invalid JSON',
      timeout: const Timeout.factor(2),
      () {
        const input = '--token=my_secret not valid json';
        final result = redactSecretsFromJson(input);

        expect(result, contains('***REDACTED***'));
        expect(result, isNot(contains('my_secret')));
      },
    );

    test(
      'preserves non-sensitive JSON values',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"name": "John", "age": 30, "active": true}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('"John"'));
        expect(result, contains('30'));
        expect(result, contains('true'));
        expect(result, isNot(contains('***REDACTED***')));
      },
    );

    test(
      'does not redact short values under 10 chars without secret keys',
      timeout: const Timeout.factor(2),
      () {
        const input = '{"custom": "short"}';
        final result = redactSecretsFromJson(input);

        expect(result, contains('"short"'));
        expect(result, isNot(contains('***REDACTED***')));
      },
    );
  });
}
