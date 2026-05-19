import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/composite_provider_credential_store.dart';
import 'package:test/test.dart';

/// Exercises [CompositeProviderCredentialStore] — the read-first-hit /
/// write-first-writable chain used by the server (file store then env store).
/// Covers: precedence on read, aggregation across stores, write skipping a
/// read-only (UnsupportedError) store, the no-writable-store error on save,
/// and remove behavior.
void main() {
  ProviderCredential cred({
    required String providerId,
    String? apiKey,
    HarnessAuthMethod method = HarnessAuthMethod.apiKey,
    String? label,
  }) => ProviderCredential(
    providerId: providerId,
    method: method,
    apiKey: apiKey,
    accountLabel: label,
  );

  group('CompositeProviderCredentialStore — reads', () {
    test('returns the first store hit (precedence)', () async {
      final composite = CompositeProviderCredentialStore([
        _FakeStore(
          active: {
            'p': cred(providerId: 'p', apiKey: 'file-key', label: 'file'),
          },
        ),
        _FakeStore(
          active: {'p': cred(providerId: 'p', apiKey: 'env-key', label: 'env')},
        ),
      ]);
      final res = await composite.activeCredential('p');
      expect(res?.secret, 'file-key');
      expect(res?.accountLabel, 'file');
    });

    test('falls through to the next store when the first misses', () async {
      final composite = CompositeProviderCredentialStore([
        _FakeStore(active: const {}), // no hit
        _FakeStore(
          active: {'p': cred(providerId: 'p', apiKey: 'env-key')},
        ),
      ]);
      final res = await composite.activeCredential('p');
      expect(res?.secret, 'env-key');
    });

    test('a credential with no secret is treated as a miss', () async {
      // method != none and secret null → skip (continue to next store).
      final composite = CompositeProviderCredentialStore([
        _FakeStore(
          active: {
            'p': cred(
              providerId: 'p',
              apiKey: null,
            ), // null secret, apiKey method
          },
        ),
        _FakeStore(
          active: {'p': cred(providerId: 'p', apiKey: 'real')},
        ),
      ]);
      final res = await composite.activeCredential('p');
      expect(res?.secret, 'real');
    });

    test('a none-method credential with null secret is returned', () async {
      final composite = CompositeProviderCredentialStore([
        _FakeStore(
          active: {
            'ollama': cred(
              providerId: 'ollama',
              method: HarnessAuthMethod.none,
            ),
          },
        ),
      ]);
      final res = await composite.activeCredential('ollama');
      expect(res, isNotNull);
      expect(res!.method, HarnessAuthMethod.none);
    });

    test('returns null when no store has the credential', () async {
      final composite = CompositeProviderCredentialStore([
        _FakeStore(active: const {}),
        _FakeStore(active: const {}),
      ]);
      expect(await composite.activeCredential('p'), isNull);
    });

    test('credentialsFor aggregates across all stores', () async {
      final composite = CompositeProviderCredentialStore([
        _FakeStore(
          all: {
            'p': [cred(providerId: 'p', label: 'a')],
          },
        ),
        _FakeStore(
          all: {
            'p': [cred(providerId: 'p', label: 'b')],
          },
        ),
      ]);
      final list = await composite.credentialsFor('p');
      expect(list.map((c) => c.accountLabel), ['a', 'b']);
    });
  });

  group('CompositeProviderCredentialStore — writes', () {
    test(
      'save skips read-only stores and writes the first writable one',
      () async {
        final writable = _FakeStore();
        final composite = CompositeProviderCredentialStore([
          _ReadOnlyStore(), // throws UnsupportedError → skipped
          writable,
        ]);
        await composite.save(cred(providerId: 'p', apiKey: 'k'));
        expect(writable.saved, hasLength(1));
        expect(writable.saved.single.providerId, 'p');
      },
    );

    test('save throws when no writable store is configured', () {
      final composite = CompositeProviderCredentialStore([
        _ReadOnlyStore(),
        _ReadOnlyStore(),
      ]);
      expect(
        () => composite.save(cred(providerId: 'p', apiKey: 'k')),
        throwsA(isA<StateError>()),
      );
    });

    test('remove targets the first store that does not throw', () async {
      final writable = _FakeStore();
      final composite = CompositeProviderCredentialStore([
        _ReadOnlyStore(),
        writable,
      ]);
      await composite.remove('p', accountLabel: 'x');
      expect(writable.removed, contains('p'));
    });

    test('remove is a no-op when every store is read-only', () async {
      final composite = CompositeProviderCredentialStore([_ReadOnlyStore()]);
      // Should complete without throwing.
      await composite.remove('p');
    });
  });
}

class _FakeStore implements ProviderCredentialStore {
  _FakeStore({this.active = const {}, this.all = const {}});

  final Map<String, ProviderCredential> active;
  final Map<String, List<ProviderCredential>> all;
  final List<ProviderCredential> saved = [];
  final List<String> removed = [];

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      active[providerId];

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async =>
      all[providerId] ?? const [];

  @override
  Future<void> save(ProviderCredential credential) async {
    saved.add(credential);
  }

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {
    removed.add(providerId);
  }
}

class _ReadOnlyStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async => null;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async =>
      const [];

  @override
  Future<void> save(ProviderCredential credential) async =>
      throw UnsupportedError('read-only');

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async => throw UnsupportedError('read-only');
}
