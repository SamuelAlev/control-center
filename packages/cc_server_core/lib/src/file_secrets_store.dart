import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:path/path.dart' as p;

/// A file-backed [PairedDeviceSecretsPort] for the headless server.
///
/// Stores per-device PSKs in a JSON file under the server's data dir (the
/// pure-Dart counterpart to the desktop's OS keychain). The file is written
/// `0600` where the platform supports it; on a single-tenant server box it sits
/// beside the SQLite database, so it inherits the same host-filesystem trust
/// boundary. Writes are atomic (temp file + rename) so a crash never leaves a
/// half-written secrets map.
class FileSecretsStore implements PairedDeviceSecretsPort {
  /// Creates a store rooted at [dataDir]; secrets live in `paired_device_psks.json`.
  FileSecretsStore({required String dataDir})
    : _file = File(p.join(dataDir, 'paired_device_psks.json'));

  final File _file;
  Map<String, String>? _cache;

  Future<Map<String, String>> _load() async {
    if (_cache != null) {
      return _cache!;
    }
    if (!_file.existsSync()) {
      return _cache = <String, String>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      _cache = decoded is Map
          ? decoded.map((k, v) => MapEntry('$k', '$v'))
          : <String, String>{};
    } on Object {
      _cache = <String, String>{};
    }
    return _cache!;
  }

  Future<void> _flush() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_cache ?? const {}));
    await tmp.rename(_file.path);
    await _restrictPerms(_file);
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

  @override
  Future<String?> readPsk(String deviceId) async => (await _load())[deviceId];

  @override
  Future<bool> writePsk(String deviceId, String psk) async {
    (await _load())[deviceId] = psk;
    await _flush();
    return true;
  }

  @override
  Future<void> deletePsk(String deviceId) async {
    (await _load()).remove(deviceId);
    await _flush();
  }
}
