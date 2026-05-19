import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/provider.dart';
import 'package:path/path.dart' as p;

/// A file-backed [ProviderCredentialStore] for the headless server.
///
/// Stores LLM provider credentials (API keys and OAuth tokens) in a JSON file
/// under the server's data dir — the pure-Dart counterpart to the desktop's OS
/// keychain, and the shape/behavior mirrors the reference agent-CLI auth store:
/// **multiple credentials per provider** with soft-disable and identity-based
/// dedup. The file is written `0600` where the platform supports it and updated
/// atomically (temp file + rename). This is the server-owned "brain" for
/// credentials — every client reaches it over the `providers.*` RPC ops.
class FileProviderCredentialStore
    implements ProviderCredentialStore, CustomProviderLister {
  /// Creates a store rooted at [dataDir]; credentials live in
  /// `harness_credentials.json`.
  FileProviderCredentialStore({required String dataDir})
    : _file = File(p.join(dataDir, 'harness_credentials.json'));

  final File _file;

  /// providerId → ordered list of credential JSON maps.
  Map<String, List<Map<String, dynamic>>>? _cache;

  Future<Map<String, List<Map<String, dynamic>>>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    if (!_file.existsSync()) {
      return _cache = <String, List<Map<String, dynamic>>>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      final providers = decoded is Map ? decoded['providers'] : null;
      final result = <String, List<Map<String, dynamic>>>{};
      if (providers is Map) {
        providers.forEach((key, value) {
          if (value is List) {
            result['$key'] = [
              for (final entry in value)
                if (entry is Map) entry.cast<String, dynamic>(),
            ];
          }
        });
      }
      return _cache = result;
    } on Object {
      return _cache = <String, List<Map<String, dynamic>>>{};
    }
  }

  Future<void> _flush() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'version': 1, 'providers': _cache ?? const {}}),
    );
    await tmp.rename(_file.path);
    await _restrictPerms(_file);
  }

  /// Tightens the credentials file to owner-only (0600) where `chmod` exists.
  /// Best-effort — a chmod failure never blocks the write (the umask applies).
  Future<void> _restrictPerms(File f) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      await Process.run('chmod', ['600', f.path]);
    } catch (_) {
      // Best-effort — the secret is still written; the host umask applies.
    }
  }

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async {
    final creds = await credentialsFor(providerId);
    if (creds.isEmpty) {
      return null;
    }
    // Prefer the explicitly-active credential, else the first usable one.
    for (final cred in creds) {
      if (cred.isActive) {
        return cred;
      }
    }
    return creds.first;
  }

  @override
  Future<List<ProviderCredential>> customProviders() async {
    final store = await _load();
    final out = <ProviderCredential>[];
    for (final entry in store.entries) {
      for (final json in entry.value) {
        final cred = ProviderCredential.fromJson(json);
        if (cred.isCustomProvider && cred.disabledCause == null) {
          out.add(cred);
          break; // One definition per provider id.
        }
      }
    }
    return out;
  }

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async {
    final store = await _load();
    final list = store[providerId] ?? const [];
    return [
      for (final json in list)
        if (json['disabledCause'] == null) ProviderCredential.fromJson(json),
    ];
  }

  @override
  Future<void> save(ProviderCredential credential) async {
    final store = await _load();
    final list = store.putIfAbsent(credential.providerId, () => []);
    final key = _dedupKey(credential);
    // Replace an existing record with the same (method, identity), else append.
    final existingIndex = list.indexWhere(
      (json) => _dedupKey(ProviderCredential.fromJson(json)) == key,
    );
    final json = credential.toJson();
    if (existingIndex >= 0) {
      list[existingIndex] = json;
    } else {
      list.add(json);
    }
    // A newly-active credential deactivates its siblings so exactly one is
    // active per provider.
    if (credential.isActive) {
      for (var i = 0; i < list.length; i++) {
        if (i == (existingIndex >= 0 ? existingIndex : list.length - 1)) {
          continue;
        }
        list[i]['isActive'] = false;
      }
    }
    await _flush();
  }

  @override
  Future<void> remove(String providerId, {String? accountLabel}) async {
    final store = await _load();
    if (accountLabel == null) {
      store.remove(providerId);
    } else {
      final list = store[providerId];
      if (list != null) {
        list.removeWhere((json) {
          final cred = ProviderCredential.fromJson(json);
          return cred.accountLabel == accountLabel ||
              cred.identityKey == accountLabel;
        });
        if (list.isEmpty) {
          store.remove(providerId);
        }
      }
    }
    await _flush();
  }

  /// Marks the credential matching [accountLabel] (or all for the provider when
  /// null) as soft-disabled with [cause], so it is skipped on resolution but the
  /// record is kept for diagnostics. Used by the auth-retry path.
  Future<void> softDisable(
    String providerId, {
    String? accountLabel,
    required String cause,
  }) async {
    final store = await _load();
    final list = store[providerId];
    if (list == null) {
      return;
    }
    for (final json in list) {
      final cred = ProviderCredential.fromJson(json);
      if (accountLabel == null ||
          cred.accountLabel == accountLabel ||
          cred.identityKey == accountLabel) {
        json['disabledCause'] = cause;
        json['isActive'] = false;
      }
    }
    await _flush();
  }

  static String _dedupKey(ProviderCredential c) =>
      '${c.method.name}:${c.identityKey ?? 'default'}';
}
