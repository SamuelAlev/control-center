import 'dart:async';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/sandboxing/env_credential_broker.dart';
import 'package:cc_infra/src/sandboxing/env_credentials_repository.dart';
import 'package:test/test.dart';

/// Covers both env-backed credential pieces:
///  - [EnvCredentialsRepository] — a read-only repo sourcing GitHub/ticketing
///    keys from an injected environment map; all mutators throw.
///  - [EnvCredentialBroker] — hands the environment's GitHub token to the
///    sandbox (GH_TOKEN + GITHUB_TOKEN) whatever the scope, with a note for
///    the UI.
void main() {
  group('EnvCredentialsRepository.loadCredentials', () {
    test('prefers GITHUB_TOKEN over GH_TOKEN', () async {
      final repo = EnvCredentialsRepository(
        environment: {'GITHUB_TOKEN': 'primary', 'GH_TOKEN': 'secondary'},
      );
      expect((await repo.loadCredentials()).githubToken, 'primary');
    });

    test('falls back to GH_TOKEN when GITHUB_TOKEN is absent', () async {
      final repo = EnvCredentialsRepository(environment: {'GH_TOKEN': 'gh'});
      expect((await repo.loadCredentials()).githubToken, 'gh');
    });

    test('no ticketing key configured reads as local', () async {
      final creds = await EnvCredentialsRepository(
        environment: {},
      ).loadCredentials();
      expect(creds.githubToken, '');
      expect(creds.ticketingApiKey, '');
      expect(creds.ticketingProviderId, 'local');
    });

    test('reads the ticketing key from its VENDOR variable', () async {
      // The same name the rest of the server (and `.env.template`) uses —
      // there is no vendor-neutral duplicate to keep in step.
      final repo = EnvCredentialsRepository(
        environment: {'LINEAR_API_KEY': 'lin_key'},
      );
      final creds = await repo.loadCredentials();
      expect(creds.ticketingApiKey, 'lin_key');
      expect(creds.ticketingProviderId, 'linear');
    });

    test('each supported vendor is recognised', () async {
      for (final (variable, vendor) in const [
        ('JIRA_API_TOKEN', 'jira'),
        ('CLICKUP_API_TOKEN', 'clickup'),
      ]) {
        final creds = await EnvCredentialsRepository(
          environment: {variable: 'k'},
        ).loadCredentials();
        expect(creds.ticketingApiKey, 'k', reason: variable);
        expect(creds.ticketingProviderId, vendor, reason: variable);
      }
    });

    test('with two vendors configured, the first wins', () async {
      // An agent gets ONE `TICKETING_API_KEY`, so this is a documented
      // precedence rather than a merge.
      final creds = await EnvCredentialsRepository(
        environment: {'LINEAR_API_KEY': 'lin', 'JIRA_API_TOKEN': 'jira'},
      ).loadCredentials();
      expect(creds.ticketingProviderId, 'linear');
    });
  });

  group('EnvCredentialsRepository mutators throw (read-only)', () {
    late EnvCredentialsRepository repo;
    setUp(() => repo = EnvCredentialsRepository(environment: const {}));

    test('saveCredentials throws UnsupportedError', () {
      expect(
        () => repo.saveCredentials(const ApiCredentials()),
        throwsA(isA<UnsupportedError>()),
      );
    });
    test('clearCredentials throws', () {
      expect(() => repo.clearCredentials(), throwsA(isA<UnsupportedError>()));
    });
    test('setGitHubToken throws', () {
      expect(() => repo.setGitHubToken('x'), throwsA(isA<UnsupportedError>()));
    });
    test('setTicketingApiKey throws', () {
      expect(
        () => repo.setTicketingApiKey('x'),
        throwsA(isA<UnsupportedError>()),
      );
    });
    test('setTicketingProvider throws', () {
      expect(
        () => repo.setTicketingProvider('linear'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('EnvCredentialBroker.mint', () {
    for (final scope in ForgeTokenScope.values) {
      test(
        'injects GH_TOKEN + GITHUB_TOKEN for a ${scope.name} scope',
        () async {
          final broker = EnvCredentialBroker(
            _FakeCreds(const ApiCredentials(githubToken: 'ghp_x')),
          );
          final sc = await broker.mint(conversationId: 'c1', scope: scope);
          expect(sc.environment['GH_TOKEN'], 'ghp_x');
          expect(sc.environment['GITHUB_TOKEN'], 'ghp_x');
          // One server-wide token cannot be narrowed — the note says so.
          expect(sc.notes.single, contains('fine-grained tokens'));
          expect(sc.handle, startsWith('c1-'));
        },
      );
    }

    test('never injects the ticketing API key', () async {
      final broker = EnvCredentialBroker(
        _FakeCreds(
          const ApiCredentials(githubToken: 'g', ticketingApiKey: 't'),
        ),
      );
      final sc = await broker.mint(
        conversationId: 'c1',
        scope: ForgeTokenScope.read,
      );
      expect(sc.environment.containsKey('TICKETING_API_KEY'), isFalse);
    });

    test('NO token injects nothing', () async {
      final broker = EnvCredentialBroker(_FakeCreds(const ApiCredentials()));
      final sc = await broker.mint(
        conversationId: 'c1',
        scope: ForgeTokenScope.write,
      );
      expect(sc.environment, isEmpty);
      expect(sc.notes, isEmpty);
    });

    test('mint produces unique handles per call', () async {
      final broker = EnvCredentialBroker(_FakeCreds(const ApiCredentials()));
      final a = await broker.mint(
        conversationId: 'c',
        scope: ForgeTokenScope.read,
      );
      // Same conversation, but ms + counter differ — wait a tick to be safe.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final b = await broker.mint(
        conversationId: 'c',
        scope: ForgeTokenScope.read,
      );
      expect(a.handle, isNot(b.handle));
    });
  });

  group('EnvCredentialBroker.revoke', () {
    test('is idempotent and does not throw on unknown handles', () async {
      final broker = EnvCredentialBroker(_FakeCreds(const ApiCredentials()));
      await expectLater(broker.revoke('never-minted'), completes);
    });

    test('revokes a previously-minted handle without error', () async {
      final broker = EnvCredentialBroker(_FakeCreds(const ApiCredentials()));
      final sc = await broker.mint(
        conversationId: 'c',
        scope: ForgeTokenScope.read,
      );
      await expectLater(broker.revoke(sc.handle), completes);
    });
  });
}

class _FakeCreds implements CredentialsRepository {
  _FakeCreds(this._creds);
  final ApiCredentials _creds;

  @override
  Future<ApiCredentials> loadCredentials() async => _creds;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('unexpected: ${invocation.memberName}');
}
