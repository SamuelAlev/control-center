import 'dart:io';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/composite_provider_credential_store.dart';
import 'package:cc_harness_runtime/src/env_provider_credential_store.dart';
import 'package:cc_harness_runtime/src/file_provider_credential_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileProviderCredentialStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('harness_creds_');
    store = FileProviderCredentialStore(dataDir: dir.path);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('saves and reads back an API key credential', () async {
    await store.save(
      const ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-abc',
        accountLabel: 'Personal',
      ),
    );
    final active = await store.activeCredential('anthropic');
    expect(active?.apiKey, 'sk-abc');
    expect(active?.method, HarnessAuthMethod.apiKey);
    final all = await store.credentialsFor('anthropic');
    expect(all, hasLength(1));
  });

  test('persists across store instances (file-backed)', () async {
    await store.save(
      const ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-xyz',
      ),
    );
    final reopened = FileProviderCredentialStore(dataDir: dir.path);
    expect((await reopened.activeCredential('openai'))?.apiKey, 'sk-xyz');
  });

  test('a new active credential deactivates its siblings', () async {
    await store.save(
      const ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'first',
        accountLabel: 'a@x.com',
        email: 'a@x.com',
      ),
    );
    await store.save(
      const ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'second',
        accountLabel: 'b@x.com',
        email: 'b@x.com',
      ),
    );
    final active = await store.activeCredential('anthropic');
    expect(active?.apiKey, 'second');
    expect(await store.credentialsFor('anthropic'), hasLength(2));
  });

  test('remove deletes the provider credentials', () async {
    await store.save(
      const ProviderCredential(
        providerId: 'groq',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'k',
      ),
    );
    await store.remove('groq');
    expect(await store.activeCredential('groq'), isNull);
  });

  test(
    'unknown providers resolve to null (no synthesized credential)',
    () async {
      expect(await store.activeCredential('ollama'), isNull);
    },
  );

  test(
    'customProviders lists stored definitions (dialect-carrying entries)',
    () async {
      await store.save(
        const ProviderCredential(
          providerId: 'custom-ollama',
          method: HarnessAuthMethod.none,
          baseUrl: 'http://localhost:11434/v1',
          dialect: CustomProviderDialect.openai,
          displayName: 'Ollama',
        ),
      );
      await store.save(
        const ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-1',
        ),
      );
      final defs = await store.customProviders();
      expect(defs.map((d) => d.providerId), ['custom-ollama']);
      expect(defs.single.dialect, CustomProviderDialect.openai);
      expect(defs.single.displayName, 'Ollama');
      // The definition doubles as the active credential for dispatch.
      final active = await store.activeCredential('custom-ollama');
      expect(active?.method, HarnessAuthMethod.none);
      expect(active?.baseUrl, 'http://localhost:11434/v1');
    },
  );

  test('softDisable hides a credential from resolution', () async {
    await store.save(
      const ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'k',
        accountLabel: 'acc',
      ),
    );
    await store.softDisable('openai', cause: 'invalid_grant');
    expect(await store.activeCredential('openai'), isNull);
  });

  group('CompositeProviderCredentialStore', () {
    test('file wins over env; env is the fallback', () async {
      final env = EnvProviderCredentialStore(
        environment: {'ANTHROPIC_API_KEY': 'from-env'},
      );
      final composite = CompositeProviderCredentialStore([store, env]);

      // Nothing stored → env fallback.
      expect(
        (await composite.activeCredential('anthropic'))?.apiKey,
        'from-env',
      );

      // Stored key wins.
      await store.save(
        const ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'from-file',
        ),
      );
      expect(
        (await composite.activeCredential('anthropic'))?.apiKey,
        'from-file',
      );
    });

    test('writes target the file store (env is read-only)', () async {
      final composite = CompositeProviderCredentialStore([
        store,
        EnvProviderCredentialStore(environment: const {}),
      ]);
      await composite.save(
        const ProviderCredential(
          providerId: 'xai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'k',
        ),
      );
      expect((await store.activeCredential('xai'))?.apiKey, 'k');
    });
  });
}
