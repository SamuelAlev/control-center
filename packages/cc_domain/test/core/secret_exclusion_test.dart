import 'package:cc_domain/core/domain/services/secret_exclusion.dart';
import 'package:test/test.dart';

void main() {
  group('SecretExclusionPolicy', () {
    test('the default globs block the common credential shapes', () {
      final policy = SecretExclusionPolicy(SecretExclusionPolicy.defaultGlobs);
      for (final path in [
        '.env',
        'apps/web/.env',
        'apps/web/.env.production',
        'certs/server.pem',
        'deploy/signing.key',
        '.ssh/id_rsa',
        '.ssh/id_rsa.pub',
        'gcp/credentials.json',
        'config/secrets.yaml',
      ]) {
        expect(policy.isExcluded(path), isTrue, reason: path);
      }
    });

    test('ordinary source paths pass', () {
      final policy = SecretExclusionPolicy(SecretExclusionPolicy.defaultGlobs);
      for (final path in [
        'lib/main.dart',
        'README.md',
        'environments.md',
        'lib/env_config.dart',
        'keys_view.dart',
      ]) {
        expect(policy.isExcluded(path), isFalse, reason: path);
      }
    });

    test('matching is case-insensitive and separator-normalizing', () {
      final policy = SecretExclusionPolicy(const ['**/.env']);
      expect(policy.isExcluded('Apps/Web/.ENV'), isTrue);
      expect(policy.isExcluded(r'apps\web\.env'), isTrue);
    });

    test('* stays within one path segment; ** crosses segments', () {
      final policy = SecretExclusionPolicy(const ['secrets/*.txt']);
      expect(policy.isExcluded('secrets/a.txt'), isTrue);
      expect(policy.isExcluded('secrets/nested/a.txt'), isFalse);
      final deep = SecretExclusionPolicy(const ['secrets/**/*.txt']);
      expect(deep.isExcluded('secrets/nested/a.txt'), isTrue);
    });

    test('an empty or malformed pattern list excludes nothing', () {
      expect(SecretExclusionPolicy(const []).isExcluded('.env'), isFalse);
      expect(
        SecretExclusionPolicy(const ['   ']).isExcluded('anything'),
        isFalse,
      );
    });
  });
}
