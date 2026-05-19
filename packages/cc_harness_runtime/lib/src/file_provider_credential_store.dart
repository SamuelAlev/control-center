import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/provider.dart';
import 'package:path/path.dart' as p;

/// A file-backed [ProviderCredentialStore] for the headless server.
///
/// Stores LLM provider credentials (API keys and OAuth tokens) in a JSON file
/// under the server's data dir — the pure-Dart counterpart to the desktop's OS
/// keychain and the shape/behavior mirrors the reference agent-CLI auth store:
/// **multiple credentials per provider** with soft-disable and identity-based
/// dedup. The file is written `0600` where the platform supports it and updated
/// atomically (temp file + rename). This is the server-owned "brain" for
/// credentials — every client reaches it over the `providers.*` RPC ops.
class FileProviderCredentialStore
    implements ProviderCredentialStore, CustomProviderLister {
  /// Creates a store rooted at [dataDir]; credentials live in
  /// `harness_credentials.json`.
  FileProviderCredentialStore({required String dataDir, this.onWarning})
    : _file = File(p.join(dataDir, 'harness_credentials.json'));

  final File _file;

  /// Reports a recoverable problem (today: a corrupt credentials file that was
  /// quarantined). Injected because this package has no logging seam of its
  /// own; the server wires it to its logger.
  final void Function(String message)? onWarning;

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
    } on Object catch (e) {
      // A CORRUPT file is not an empty one. Returning empty here meant the very
      // next `save()` overwrote it — every stored token gone, no error, no
      // copy. Quarantine it instead so the user can recover (or hand it to
      // support) and so the cause is visible in the logs.
      _quarantineCorruptFile(e);
      return _cache = <String, List<Map<String, dynamic>>>{};
    }
  }

  /// Renames a credentials file we could not parse to `<name>.corrupt-<ts>`.
  void _quarantineCorruptFile(Object error) {
    try {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final quarantined = '${_file.path}.corrupt-$stamp';
      _file.renameSync(quarantined);
      onWarning?.call(
        'provider credentials at ${_file.path} could not be parsed ($error) — '
        'moved to $quarantined; you will need to sign in again.',
      );
    } on Object {
      // If even the rename fails there is nothing further to try; the empty
      // cache below still keeps the process usable.
    }
  }

  /// Serializes flushes. Two concurrent `save()`s used to interleave here and
  /// the LAST rename won — with a snapshot that could predate the other's
  /// change, silently losing a credential.
  Future<void> _flushChain = Future<void>.value();

  Future<void> _flush() {
    final queued = _flushChain.then((_) => _flushNow());
    _flushChain = queued.catchError((Object _) {});
    return queued;
  }

  Future<void> _flushNow() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'version': 1, 'providers': _cache ?? const {}}),
    );
    // Tighten the TEMP file BEFORE the rename: chmod'ing after it means the
    // secret exists at the real path, world-readable per the umask, for the
    // window in between.
    await _restrictPerms(tmp);
    await tmp.rename(_file.path);
    // Belt and braces — some filesystems reset mode on rename.
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
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {
    final store = await _load();
    if (accountLabel == null && credentialId == null) {
      store.remove(providerId);
    } else {
      final list = store[providerId];
      if (list != null) {
        list.removeWhere((json) {
          final cred = ProviderCredential.fromJson(json);
          return (credentialId != null && cred.credentialId == credentialId) ||
              (accountLabel != null &&
                  (cred.accountLabel == accountLabel ||
                      cred.identityKey == accountLabel));
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

  // Dedup by [ProviderCredential.credentialId]: OAuth accounts by identity, so
  // a token refresh replaces in place; API keys by secret, so saving a NEW key
  // appends a rotation entry while re-saving the same key updates it.
  static String _dedupKey(ProviderCredential c) => c.credentialId;
}
