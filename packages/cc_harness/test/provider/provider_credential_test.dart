import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderCredential', () {
    test('round-trips through JSON', () {
      final cred = ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.oauth,
        accessToken: 'acc',
        refreshToken: 'ref',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
        email: 'me@example.com',
        accountId: 'uuid-1',
        accountLabel: 'Personal',
      );
      final restored = ProviderCredential.fromJson(cred.toJson());
      expect(restored.providerId, 'anthropic');
      expect(restored.method, HarnessAuthMethod.oauth);
      expect(restored.accessToken, 'acc');
      expect(restored.refreshToken, 'ref');
      expect(restored.expiresAt, cred.expiresAt);
      expect(restored.email, 'me@example.com');
      expect(restored.accountId, 'uuid-1');
      expect(restored.secret, 'acc');
      expect(restored.identityKey, 'me@example.com');
    });

    test('secret resolves per auth method', () {
      expect(
        const ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-1',
        ).secret,
        'sk-1',
      );
      expect(
        const ProviderCredential(
          providerId: 'ollama',
          method: HarnessAuthMethod.none,
        ).secret,
        isNull,
      );
    });

    test('credentialId distinguishes keys by secret, accounts by identity', () {
      const keyA = ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-aaa',
      );
      const keyB = ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-bbb',
      );
      // Two keys of one provider are two rotation entries, not one "default".
      expect(keyA.credentialId, isNot(keyB.credentialId));
      // Stable: the same secret hashes to the same address every time.
      expect(keyA.credentialId, keyA.credentialId);
      // The raw secret is never part of the address.
      expect(keyA.credentialId, isNot(contains('sk-aaa')));

      const account = ProviderCredential(
        providerId: 'kimi-code',
        method: HarnessAuthMethod.oauth,
        accessToken: 't',
        email: 'dev@example.com',
      );
      expect(account.credentialId, 'oauth:dev@example.com');
    });

    test('secretHint masks to the tail and withholds short secrets', () {
      expect(
        const ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-abcdefghijkl',
        ).secretHint,
        '…ijkl',
      );
      // A short secret would be identified by its hint — withhold it.
      expect(
        const ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'short',
        ).secretHint,
        isNull,
      );
      expect(
        const ProviderCredential(
          providerId: 'ollama',
          method: HarnessAuthMethod.none,
        ).secretHint,
        isNull,
      );
    });
  });

  group('HarnessProviderInfo', () {
    test('round-trips through the RPC wire shape', () {
      const info = HarnessProviderInfo(
        id: 'anthropic',
        displayName: 'Anthropic',
        authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.oauth,
        hasCredential: true,
        accountLabel: 'me@example.com',
      );
      final restored = HarnessProviderInfo.fromJson(info.toJson());
      expect(restored.id, 'anthropic');
      expect(restored.enabled, HarnessProviderEnabled.oauth);
      expect(restored.supportsOAuth, isTrue);
      expect(restored.supportsApiKey, isTrue);
      expect(restored.connected, isTrue);
      expect(restored.accountLabel, 'me@example.com');
    });
  });

  group('harness provider metadata', () {
    test('every supported id has metadata', () {
      for (final id in harnessSupportedProviderIds) {
        expect(harnessProviderMetas[id], isNotNull, reason: id);
      }
    });

    test('openai supports OAuth; no local built-ins remain', () {
      expect(harnessProviderMetas['openai']!.supportsOAuth, isTrue);
      expect(harnessProviderMetas.containsKey('ollama'), isFalse);
      expect(harnessProviderMetas['groq']!.supportsOAuth, isFalse);
    });

    // The UI offers a "sign in with browser" button off `supportsOAuth`, so
    // this flag IS the surface. Anthropic's browser login only ever worked by
    // minting a token against Claude Code's own OAuth client and sending
    // Claude Code's identity — presenting this app as Claude Code. The
    // subscription is reachable through the `claude-code` adapter instead,
    // which runs the real CLI under its own login.
    test('anthropic is API-key-only — no browser login', () {
      final meta = harnessProviderMetas['anthropic']!;
      expect(meta.supportsOAuth, isFalse);
      expect(meta.supportsApiKey, isTrue);
    });
  });
}
