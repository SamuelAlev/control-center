import 'dart:convert';
import 'dart:io';

import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:path/path.dart' as p;

/// The server's ONE secrets file, and the file-backed [PairedDeviceSecretsPort].
///
/// Despite the port's name this is not a device-PSK store: it is a flat
/// `key → secret` map that every server-side secret shares, namespaced by its
/// owner so nothing can collide with a device id.
///
///  * `<deviceId>` — paired-device PSKs (the original, and once only, tenant).
///  * `provider_app_*` — the server's own GitHub/Linear app identity
///    (`ProviderAppSettings`), the GitHub App private key among them.
///  * `user_forge_*` / `user_ticket_*` — per-user provider credentials
///    (`UserCredentialsStore`).
///  * `google_*` — Google Calendar OAuth credentials
///    (`FileGoogleCredentialsStore`).
///  * `oidc_client_secret` / `scim_token` — SSO (`SsoSettingsService`).
///
/// One file rather than one per tenant is deliberate: one on-disk map, one
/// in-memory cache, one trust boundary. That boundary is the HOST FILESYSTEM,
/// not cryptography — the JSON is plaintext, written `0600` where the platform
/// supports it, sitting beside the SQLite database on a single-tenant box.
class FileSecretsStore implements PairedDeviceSecretsPort {
  /// Creates a store rooted at [dataDir]; secrets live in `secrets.json`.
  FileSecretsStore({required String dataDir})
    : _file = File(p.join(dataDir, fileName));

  /// The secrets file's name under the data dir.
  static const fileName = 'secrets.json';

  final File _file;
  Map<String, String>? _cache;

  /// `(mtimeMs, length)` of the file [_cache] was built from — null when it did
  /// not exist. Re-checked on every read (one `stat`) so a write from ANOTHER
  /// process invalidates the cache instead of surviving until a restart.
  ///
  /// `cc_server pair` and `calendar connect` run in their own process against a
  /// live server's data dir, and a `pair` writes BOTH a `paired_devices` row
  /// and this file. The row is read on demand (fresh), so the cached map was
  /// the only reason a freshly paired device authenticated as
  /// `psk=missing` — and the only reason the server had to be restarted to see
  /// it. A same-second rewrite that lands on the same byte length is the one
  /// case a stamp cannot see; a MISS re-reads unconditionally (see
  /// [readFresh]), so that residue only affects ROTATING an existing key.
  (int, int)? _cacheStamp;

  /// Keys mutated since the last successful flush — `key → value`, or
  /// `key → null` for a delete. Applied ON TOP of the file's current contents
  /// at flush time (see [_flushNow]), and retained until a write succeeds so a
  /// failed flush is retried by the next one rather than silently dropped.
  final Map<String, String?> _pending = {};

  Future<void> _flushChain = Future<void>.value();

  Future<Map<String, String>> _load() async {
    final cached = _cache;
    if (cached != null && _stamp() == _cacheStamp) {
      return cached;
    }
    return _cache = _applyPending(await _readFromDisk());
  }

  /// Identity of the file on disk right now, or null when it is absent.
  ///
  /// Best-effort: a `stat` that throws reports "unchanged" rather than forcing
  /// a re-read loop on a directory we cannot inspect.
  (int, int)? _stamp() {
    try {
      final stat = _file.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
        return null;
      }
      return (stat.modified.millisecondsSinceEpoch, stat.size);
    } on Object {
      return _cacheStamp;
    }
  }

  /// Overlays this process's unflushed mutations on [fresh], so a re-read never
  /// resurrects a key we deleted or reverts one we just wrote.
  Map<String, String> _applyPending(Map<String, String> fresh) {
    _pending.forEach((key, value) {
      if (value == null) {
        fresh.remove(key);
      } else {
        fresh[key] = value;
      }
    });
    return fresh;
  }

  Future<Map<String, String>> _readFromDisk() async {
    // Stamped BEFORE the read: a write that lands between the two makes the
    // stamp look older than the bytes we return, which costs one redundant
    // re-read — the opposite order would cache the new stamp against the old
    // bytes and never re-read at all.
    _cacheStamp = _stamp();
    if (!_file.existsSync()) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('secrets file is not a JSON object');
      }
      return decoded.map((k, v) => MapEntry('$k', '$v'));
    } on Object catch (e) {
      _quarantineCorruptFile(e);
      return <String, String>{};
    }
  }

  /// Renames a secrets file we could not parse to `<name>.corrupt-<ts>`.
  ///
  /// A CORRUPT file is not an empty one. Reading it as empty meant the next
  /// write flushed that emptiness over the file — every device PSK, the GitHub
  /// App private key and every user's provider token gone, with no error and no
  /// copy. Quarantining keeps the bytes recoverable and puts the cause in the
  /// logs. (`FileProviderCredentialStore` reached the same conclusion first.)
  void _quarantineCorruptFile(Object error) {
    try {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final quarantined = '${_file.path}.corrupt-$stamp';
      _file.renameSync(quarantined);
      CcHostLog.warning(
        'secrets: ${_file.path} could not be parsed ($error) — moved to '
        '$quarantined. Paired devices must re-pair and provider credentials '
        'must be reconnected; the original bytes are still in that file.',
      );
    } on Object {
      // If even the rename fails there is nothing further to try; the empty
      // cache the caller returns still keeps the process usable.
    }
  }

  /// Serializes flushes. Two concurrent writes used to race here: both build
  /// the SAME `<file>.tmp` path and the second `rename` then throws on a file
  /// the first already moved away.
  Future<void> _flush() {
    final queued = _flushChain.then((_) => _flushNow());
    _flushChain = queued.catchError((Object _) {});
    return queued;
  }

  Future<void> _flushNow() async {
    if (_pending.isEmpty) {
      return;
    }
    final pending = Map<String, String?>.from(_pending);
    // Re-read before writing rather than dumping the cache. `cc_server pair`
    // and `calendar connect` mutate this file from their OWN processes while
    // the server runs, so a whole-map write from a cache read at boot would
    // silently drop whatever they added. Merging per key also keeps a delete a
    // delete instead of resurrecting the key from disk.
    final merged = await _readFromDisk();
    pending.forEach((key, value) {
      if (value == null) {
        merged.remove(key);
      } else {
        merged[key] = value;
      }
    });
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(merged));
    await tmp.rename(_file.path);
    await _restrictPerms(_file);
    _cache = merged;
    // Re-stamp against what we just wrote; `_readFromDisk` above stamped the
    // PRE-write file, which would make our own flush look like a foreign write.
    _cacheStamp = _stamp();
    // Only entries this flush actually wrote, and only if they were not
    // re-mutated while it ran.
    pending.forEach((key, value) {
      if (_pending.containsKey(key) && _pending[key] == value) {
        _pending.remove(key);
      }
    });
  }

  /// Tightens the secrets file to owner-only (0600) where `chmod` exists. The
  /// server runs on macOS/Linux; Windows uses ACLs and is out of scope. The
  /// class doc promised `0600` — `writeAsString` honors the umask (often 0644),
  /// so this enforces it explicitly (data-protection note). Best-effort: a
  /// chmod failure never blocks the write (the umask still applies).
  Future<void> _restrictPerms(File f) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      await Process.run('chmod', ['600', f.path]);
    } catch (_) {
      // Best-effort — secrets are still written; the host umask applies.
    }
  }

  /// Reads the PSK for [deviceId], seeing a device paired by another process.
  ///
  /// Goes through [readFresh] rather than the cache alone: `cc_server pair`
  /// against a RUNNING server adds a key this process has never seen, and a
  /// plain cached lookup returned null for it until the server restarted.
  @override
  Future<String?> readPsk(String deviceId) => readFresh(deviceId);

  /// Reads [key], re-reading the file when the cache does not hold it.
  ///
  /// `cc_server pair` and `calendar connect` write from their OWN process while
  /// the server runs, so a server that cached this map at boot (often empty)
  /// would never see a freshly paired device or a freshly connected account
  /// until it restarted. [_load] already re-reads when the file CHANGED on
  /// disk; this additionally covers a miss, which is the case a stamp with
  /// filesystem-granularity timestamps could conceivably miss.
  Future<String?> readFresh(String key) async {
    final cached = await _load();
    if (cached.containsKey(key)) {
      return cached[key];
    }
    // Anything this process wrote but has not flushed yet still wins.
    final fresh = _applyPending(await _readFromDisk());
    return (_cache = fresh)[key];
  }

  @override
  Future<bool> writePsk(String deviceId, String psk) async {
    (await _load())[deviceId] = psk;
    _pending[deviceId] = psk;
    await _flush();
    return true;
  }

  @override
  Future<void> deletePsk(String deviceId) async {
    (await _load()).remove(deviceId);
    _pending[deviceId] = null;
    await _flush();
  }
}
