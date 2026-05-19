import 'package:cc_harness/provider.dart';

/// Chains several [ProviderCredentialStore]s: reads consult each store in order
/// and return the first hit; writes go to the first store that accepts them.
///
/// The server wires this as `[FileProviderCredentialStore, EnvProviderCredentialStore]`
/// so a UI-saved key (file) wins, with the process environment as a read-only
/// fallback. `save` / `remove` target the file store — the env store throws
/// `UnsupportedError`, which the composite skips.
class CompositeProviderCredentialStore
    implements ProviderCredentialStore, CustomProviderLister {
  /// Creates a composite over [stores], consulted in order.
  CompositeProviderCredentialStore(this.stores);

  /// The backing stores, highest precedence first.
  final List<ProviderCredentialStore> stores;

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async {
    for (final store in stores) {
      final cred = await store.activeCredential(providerId);
      if (cred != null &&
          (cred.secret != null || cred.method == HarnessAuthMethod.none)) {
        return cred;
      }
    }
    return null;
  }

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async {
    final all = <ProviderCredential>[];
    for (final store in stores) {
      all.addAll(await store.credentialsFor(providerId));
    }
    return all;
  }

  @override
  Future<List<ProviderCredential>> customProviders() async {
    // Highest-precedence store wins per provider id.
    final byId = <String, ProviderCredential>{};
    for (final store in stores) {
      if (store is! CustomProviderLister) {
        continue;
      }
      for (final def
          in await (store as CustomProviderLister).customProviders()) {
        byId.putIfAbsent(def.providerId, () => def);
      }
    }
    return byId.values.toList();
  }

  @override
  Future<void> save(ProviderCredential credential) async {
    for (final store in stores) {
      try {
        await store.save(credential);
        return;
      } on UnsupportedError {
        // Read-only store (env) — try the next one.
      }
    }
    throw StateError('No writable credential store is configured.');
  }

  @override
  Future<void> remove(String providerId, {String? accountLabel}) async {
    for (final store in stores) {
      try {
        await store.remove(providerId, accountLabel: accountLabel);
        return;
      } on UnsupportedError {
        // Read-only store (env) — try the next one.
      }
    }
  }
}
