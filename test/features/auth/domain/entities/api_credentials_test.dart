import 'package:control_center/features/auth/domain/entities/api_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiCredentials constructor', () {
    test('creates with empty defaults', () {
      const creds = ApiCredentials();
      expect(creds.githubToken, '');
      expect(creds.ticketingApiKey, '');
      expect(creds.ticketingProviderId, 'local');
    });

    test('creates with custom tokens', () {
      const creds = ApiCredentials(
        githubToken: 'gh_token_123',
        ticketingApiKey: 'tk_key_456',
        ticketingProviderId: 'linear',
      );
      expect(creds.githubToken, 'gh_token_123');
      expect(creds.ticketingApiKey, 'tk_key_456');
      expect(creds.ticketingProviderId, 'linear');
    });

    test('creates with only github token', () {
      const creds = ApiCredentials(githubToken: 'gh_token');
      expect(creds.githubToken, 'gh_token');
      expect(creds.ticketingApiKey, '');
    });
  });

  group('ApiCredentialsHelpers extension', () {
    test('hasGitHubToken returns true when token present', () {
      const creds = ApiCredentials(githubToken: 'gh_token');
      expect(creds.hasGitHubToken, isTrue);
    });

    test('hasGitHubToken returns false when empty', () {
      const creds = ApiCredentials();
      expect(creds.hasGitHubToken, isFalse);
    });

    test('hasTicketingCredentials reflects the ticketing key', () {
      expect(
        const ApiCredentials(ticketingApiKey: 'tk').hasTicketingCredentials,
        isTrue,
      );
      expect(const ApiCredentials().hasTicketingCredentials, isFalse);
    });

    test('isConfigured requires only GitHub (ticketing optional)', () {
      expect(const ApiCredentials(githubToken: 'gh').isConfigured, isTrue);
      expect(const ApiCredentials().isConfigured, isFalse);
      expect(
        const ApiCredentials(ticketingApiKey: 'tk').isConfigured,
        isFalse,
      );
    });
  });

  group('ApiCredentials == and hashCode', () {
    test('identical credentials are equal', () {
      const a = ApiCredentials(githubToken: 'gh', ticketingApiKey: 'tk');
      const b = ApiCredentials(githubToken: 'gh', ticketingApiKey: 'tk');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different github token makes unequal', () {
      const a = ApiCredentials(githubToken: 'gh1');
      const b = ApiCredentials(githubToken: 'gh2');
      expect(a, isNot(equals(b)));
    });

    test('different ticketing key makes unequal', () {
      const a = ApiCredentials(ticketingApiKey: 'tk1');
      const b = ApiCredentials(ticketingApiKey: 'tk2');
      expect(a, isNot(equals(b)));
    });
  });

  group('ApiCredentials copyWith', () {
    test('returns new instance with updated githubToken', () {
      const creds = ApiCredentials();
      final updated = creds.copyWith(githubToken: 'new_gh');
      expect(updated.githubToken, 'new_gh');
      expect(updated.ticketingApiKey, '');
    });

    test('returns new instance with updated ticketingApiKey', () {
      const creds = ApiCredentials();
      final updated = creds.copyWith(ticketingApiKey: 'new_tk');
      expect(updated.ticketingApiKey, 'new_tk');
    });

    test('copyWith without changes returns equal credentials', () {
      const creds = ApiCredentials(githubToken: 'gh');
      final updated = creds.copyWith();
      expect(updated, equals(creds));
    });
  });

  group('ApiCredentials toString', () {
    test('masks tokens', () {
      const creds = ApiCredentials(
        githubToken: 'secret_gh',
        ticketingApiKey: 'secret_tk',
      );
      final str = creds.toString();
      expect(str, contains('Token(****)'));
      expect(str, contains('ApiCredentials'));
    });
  });
}
