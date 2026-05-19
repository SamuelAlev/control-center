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

  test('two unlabeled keys append instead of replacing', () async {
    // Multi-key rotation: a second key is a NEW rotation entry, not a
    // replacement — dedup is by secret, not by "the one default key".
    await store.save(
      const ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-first',
      ),
    );
    await store.save(
      const ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-second',
      ),
    );
    final all = await store.credentialsFor('openai');
    expect(all, hasLength(2));
    expect(all.map((c) => c.apiKey), containsAll(['sk-first', 'sk-second']));
    // The newly saved key takes over as the active (primary) credential.
    expect((await store.activeCredential('openai'))?.apiKey, 'sk-second');
  });

  test(
    're-saving the same secret updates in place, keeping its label',
    () async {
      await store.save(
        const ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-same',
          accountLabel: 'Personal',
        ),
      );
      await store.save(
        const ProviderCredential(
          providerId: 'openai',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-same',
          accountLabel: 'Team',
        ),
      );
      final all = await store.credentialsFor('openai');
      expect(all, hasLength(1));
      expect(all.single.accountLabel, 'Team');
    },
  );

  test('remove by credentialId drops exactly that key', () async {
    const first = ProviderCredential(
      providerId: 'openai',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'sk-first',
    );
    const second = ProviderCredential(
      providerId: 'openai',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'sk-second',
    );
    await store.save(first);
    await store.save(second);
    await store.remove('openai', credentialId: first.credentialId);
    final all = await store.credentialsFor('openai');
    expect(all.map((c) => c.apiKey), ['sk-second']);
    // The removed key's sibling took over as active.
    expect((await store.activeCredential('openai'))?.apiKey, 'sk-second');
  });

  test('credentialId is stable across reloads', () async {
    const cred = ProviderCredential(
      providerId: 'openai',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'sk-stable',
    );
    await store.save(cred);
    final reopened = FileProviderCredentialStore(dataDir: dir.path);
    final reloaded = (await reopened.credentialsFor('openai')).single;
    expect(reloaded.credentialId, cred.credentialId);
    // And never contains the raw secret.
    expect(reloaded.credentialId, isNot(contains('sk-stable')));
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

  group('durability', () {
    ProviderCredential key(String id, String value) => ProviderCredential(
      providerId: id,
      method: HarnessAuthMethod.apiKey,
      apiKey: value,
    );

    test('a corrupt file is quarantined, not silently overwritten', () async {
      // Returning an empty map on a parse failure meant the NEXT save wiped
      // the file — every stored token gone, with no error and no copy.
      final file = File('${dir.path}/harness_credentials.json')
        ..writeAsStringSync('{not json at all');
      final warnings = <String>[];
      final fresh = FileProviderCredentialStore(
        dataDir: dir.path,
        onWarning: warnings.add,
      );

      expect(await fresh.credentialsFor('anthropic'), isEmpty);
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('could not be parsed'));

      final quarantined = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.corrupt-'))
          .toList();
      expect(quarantined, hasLength(1));
      expect(quarantined.single.readAsStringSync(), '{not json at all');
      expect(file.existsSync(), isFalse);
    });

    test('concurrent saves do not lose a credential', () async {
      // Two `save()`s used to interleave inside `_flush`: both wrote a temp
      // file and the LAST rename won, with a snapshot that could predate the
      // other's change.
      await Future.wait([
        store.save(key('anthropic', 'sk-a')),
        store.save(key('openai', 'sk-o')),
        store.save(key('gemini', 'sk-g')),
      ]);

      final reopened = FileProviderCredentialStore(dataDir: dir.path);
      expect((await reopened.credentialsFor('anthropic')).single.apiKey, 'sk-a');
      expect((await reopened.credentialsFor('openai')).single.apiKey, 'sk-o');
      expect((await reopened.credentialsFor('gemini')).single.apiKey, 'sk-g');
    });

    test('the credentials file is owner-only where chmod exists', () async {
      await store.save(key('anthropic', 'sk-abc'));
      if (Platform.isWindows) {
        return;
      }
      final mode = Process.runSync('stat', [
        '-f',
        '%Lp',
        '${dir.path}/harness_credentials.json',
      ]);
      // macOS `stat -f`; on Linux the flag differs, so only assert when it
      // produced a mode at all.
      final printed = '${mode.stdout}'.trim();
      if (mode.exitCode == 0 && printed.isNotEmpty) {
        expect(printed, '600');
      }
    });
  });
}
