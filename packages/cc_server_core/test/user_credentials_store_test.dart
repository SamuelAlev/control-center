import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late UserCredentialsStore store;

  const alice = 'user-alice';
  const bob = 'user-bob';

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_user_creds_');
    secrets = FileSecretsStore(dataDir: dir.path);
    store = UserCredentialsStore(secrets);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('isolation', () {
    test('one user cannot read another\'s credential', () async {
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'alice-token'),
      );

      expect(await store.forgeToken(bob, ForgeHost.github), isNull);
      expect(await store.hasForgeToken(bob, ForgeHost.github), isFalse);
    });

    test('deleting one user\'s credential leaves the other\'s', () async {
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'a'),
      );
      await store.setForgeToken(
        bob,
        ForgeHost.github,
        const ProviderToken(accessToken: 'b'),
      );

      await store.clearForgeToken(alice, ForgeHost.github);

      expect(await store.forgeToken(alice, ForgeHost.github), isNull);
      expect((await store.forgeToken(bob, ForgeHost.github))?.accessToken, 'b');
    });

    test('a forge key cannot collide with a device id', () async {
      // Both live in ONE secrets file; a collision would let a paired device
      // read a credential or vice versa.
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'secret'),
      );
      final raw = jsonDecode(
        File('${dir.path}/secrets.json').readAsStringSync(),
      ) as Map;
      expect(raw.keys.single, 'user_forge_github_$alice');
    });

    test('ticketing and forge credentials do not collide', () async {
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'forge'),
      );
      await store.setTicketToken(
        alice,
        TicketProvider.linear,
        const ProviderToken(accessToken: 'ticket'),
      );

      expect(
        (await store.forgeToken(alice, ForgeHost.github))?.accessToken,
        'forge',
      );
      expect(
        (await store.ticketToken(alice, TicketProvider.linear))?.accessToken,
        'ticket',
      );
    });
  });

  group('the token envelope', () {
    test('round-trips everything a refresh needs', () async {
      final expiry = DateTime.utc(2026, 6, 1, 12);
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        ProviderToken(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: expiry,
          source: ForgeCredentialSource.oauth,
          accountLogin: 'octocat',
        ),
      );

      final stored = (await store.forgeToken(alice, ForgeHost.github))!;
      expect(stored.accessToken, 'access');
      expect(stored.refreshToken, 'refresh');
      expect(stored.expiresAt, expiry);
      expect(stored.source, ForgeCredentialSource.oauth);
      expect(stored.accountLogin, 'octocat');
    });

    test('an empty token clears rather than storing an empty credential',
        () async {
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: 'x'),
      );
      await store.setForgeToken(
        alice,
        ForgeHost.github,
        const ProviderToken(accessToken: ''),
      );
      expect(await store.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('a corrupt entry reads as no credential, never as one', () async {
      await secrets.writePsk('user_forge_github_$alice', '{not json');
      expect(await store.forgeToken(alice, ForgeHost.github), isNull);
    });

    test('isExpired allows a minute of slack', () {
      final almost = ProviderToken(
        accessToken: 'x',
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );
      // A token that expires mid-flight fails the request it was attached to,
      // and the caller cannot tell that from a revoked credential.
      expect(almost.isExpired, isTrue);

      final fine = ProviderToken(
        accessToken: 'x',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(fine.isExpired, isFalse);
    });

    test('canRefresh is false once the refresh token itself expired', () {
      final token = ProviderToken(
        accessToken: 'x',
        refreshToken: 'r',
        refreshExpiresAt: DateTime.now().toUtc().subtract(
          const Duration(days: 1),
        ),
      );
      expect(token.canRefresh, isFalse);
    });
  });

}
