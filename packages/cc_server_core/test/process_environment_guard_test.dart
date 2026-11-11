import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

void main() {
  group('refuseExportedProviderSecrets', () {
    test('refuses every exported provider secret, naming only the keys', () {
      const env = {
        'PATH': '/usr/bin',
        'GITHUB_APP_PRIVATE_KEY': '-----BEGIN RSA PRIVATE KEY-----',
        'GITHUB_CLIENT_SECRET': 'shh',
        'GOOGLE_OAUTH_CLIENT_SECRET': 'shh',
        'SLACK_SIGNING_SECRET': 'shh',
        'SLACK_CLIENT_SECRET': 'shh',
        'LINEAR_API_KEY': 'lin_api_x',
      };
      expect(
        () => refuseExportedProviderSecrets(env),
        throwsA(
          isA<ProviderSecretInEnvironmentException>()
              .having((e) => e.keys, 'keys', [
                'GITHUB_APP_PRIVATE_KEY',
                'GITHUB_CLIENT_SECRET',
                'GOOGLE_OAUTH_CLIENT_SECRET',
                'LINEAR_API_KEY',
                'SLACK_CLIENT_SECRET',
                'SLACK_SIGNING_SECRET',
              ])
              .having((e) => e.message, 'message', contains('.env'))
              .having((e) => e.message, 'message', contains('Settings'))
              .having((e) => e.message, 'message', isNot(contains('shh'))),
        ),
      );
    });

    test('a single exported secret is refused on its own', () {
      expect(
        () =>
            refuseExportedProviderSecrets(const {'GITHUB_CLIENT_SECRET': 'x'}),
        throwsA(isA<ProviderSecretInEnvironmentException>()),
      );
    });

    test('public identifiers, empty values and other Slack keys boot', () {
      expect(
        () => refuseExportedProviderSecrets(const {
          'PATH': '/usr/bin',
          'GITHUB_APP_ID': '42',
          'GITHUB_CLIENT_ID': 'Iv1',
          'GOOGLE_OAUTH_CLIENT_ID': 'id',
          'SLACK_CLIENT_ID': 'id',
          'LINEAR_CLIENT_ID': 'id',
          // `KEY=` in a copied template reads as absent, as in `.env`.
          'GITHUB_CLIENT_SECRET': '',
        }),
        returnsNormally,
      );
    });

    test("an embedded Connect's secrets are refused, its identifiers, "
        'flags and file paths are not', () {
      for (final key in [
        'CONNECT_GITHUB_APP_PRIVATE_KEY',
        'CONNECT_GITHUB_CLIENT_SECRET',
        'CONNECT_GITHUB_CLIENT_SECRET_PREVIOUS',
        'CONNECT_GOOGLE_CLIENT_SECRET',
        'CONNECT_SLACK_CLIENT_SECRET',
        'CONNECT_SLACK_SIGNING_SECRET',
        'CONNECT_KLIPY_APP_KEY',
        'CONNECT_SEAL_KEYS',
        'CONNECT_LOG_HMAC_KEY',
        'CONNECT_REDIS_URL',
        // A DSN carries Sentry's ingest key.
        'CONNECT_SENTRY_DSN',
        'connect_sentry_dsn',
        // The five secrets Connect reads a previous generation of.
        'CONNECT_GOOGLE_CLIENT_SECRET_PREVIOUS',
        'CONNECT_SLACK_CLIENT_SECRET_PREVIOUS',
        'CONNECT_SLACK_SIGNING_SECRET_PREVIOUS',
        'CONNECT_KLIPY_APP_KEY_PREVIOUS',
      ]) {
        expect(isRefusedProcessSecret(key), isTrue, reason: key);
      }
      for (final key in [
        'CONNECT_GITHUB_APP_ID',
        'CONNECT_GITHUB_CLIENT_ID',
        'CONNECT_GITHUB_SECRET_GENERATION',
        'CONNECT_SEAL_KEYS_FILE',
        'CONNECT_GITHUB_CLIENT_SECRET_FILE',
        'CONNECT_PUBLIC_URL',
        'CONNECT_ALLOWED_INSTALLS',
        'CONNECT_KMS_KEY',
        // Connect reads no previous generation of these, so the name is
        // nothing it would ever take a secret from.
        'CONNECT_GITHUB_APP_PRIVATE_KEY_PREVIOUS',
        'CONNECT_SEAL_KEYS_PREVIOUS',
        'CONNECT_REDIS_URL_PREVIOUS',
        'CONNECT_SENTRY_DSN_FILE',
      ]) {
        expect(isRefusedProcessSecret(key), isFalse, reason: key);
      }
    });

    test('isRefusedProcessSecret matches Slack secrets by shape', () {
      expect(isRefusedProcessSecret('SLACK_APP_SECRET_TOKEN'), isTrue);
      expect(isRefusedProcessSecret('slack_signing_secret'), isTrue);
      expect(isRefusedProcessSecret('SLACK_BOT_TOKEN'), isFalse);
    });
  });
}
