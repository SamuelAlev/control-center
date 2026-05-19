import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A server's last-known tool list, remembered across restarts.
///
/// This is what makes the startup gate more than a timeout. Dialling an
/// external MCP server means spawning a process (or a TLS round-trip) and
/// waiting for `initialize` + `tools/list`; a server that takes seconds used
/// to contribute nothing until it finished, so an agent run starting in that
/// window simply could not see its tools. With a cache, a still-connecting
/// server contributes its previous tools immediately and the first CALL waits
/// for the connection instead — the wait moves off the startup path and onto
/// the one request that actually needs it.
///
/// The cache is keyed by `(serverName, fingerprint)` where the fingerprint
/// covers everything that could change the tool list. A config edit therefore
/// misses rather than serving tools the new server may not have.
abstract interface class McpToolListCache {
  /// The tools last seen for [serverName] under [fingerprint], or null on a
  /// miss (unknown server, changed config, unreadable store).
  List<McpRemoteTool>? read(String serverName, String fingerprint);

  /// Records [tools] as the current list for [serverName]/[fingerprint].
  void write(String serverName, String fingerprint, List<McpRemoteTool> tools);

  /// Forgets [serverName]. Called when a server is removed or fails to
  /// connect — advertising tools for a server that just failed would hand the
  /// model a menu of calls that cannot succeed.
  void evict(String serverName);
}

/// Identity of everything that could change a server's tool list.
///
/// Deliberately includes `env` and `headers`: the same command with a
/// different `MODE` or a different bearer token is routinely a different tool
/// surface, and serving the previous one would be worse than a cache miss.
/// Excludes `enabled` and `timeout`, which cannot change what the server
/// advertises.
String mcpToolCacheFingerprint(McpServerConfig config) {
  final sortedEnv = config.env.keys.toList()..sort();
  final sortedHeaders = config.headers.keys.toList()..sort();
  final material = jsonEncode({
    'transport': config.transport.wire,
    'command': config.command,
    'args': config.args,
    'cwd': config.cwd,
    'url': config.url,
    'auth': config.auth.wire,
    'scopes': [...config.oauthScopes]..sort(),
    'env': {for (final k in sortedEnv) k: config.env[k]},
    // Header VALUES are secrets (bearer tokens); hash the pair rather than
    // storing it, so the fingerprint still changes when a token rotates but
    // the token never lands in the cache file.
    'headers': [
      for (final k in sortedHeaders)
        '$k=${sha256.convert(utf8.encode(config.headers[k] ?? '')).toString().substring(0, 16)}',
    ],
  });
  return sha256.convert(utf8.encode(material)).toString().substring(0, 32);
}

/// A [McpToolListCache] that never hits. The default, so a host that has not
/// wired a store still gets the startup gate's timeout half.
class NoopMcpToolListCache implements McpToolListCache {
  /// Creates a [NoopMcpToolListCache].
  const NoopMcpToolListCache();

  @override
  List<McpRemoteTool>? read(String serverName, String fingerprint) => null;

  @override
  void write(String serverName, String fingerprint, List<McpRemoteTool> tools) {
  }

  @override
  void evict(String serverName) {}
}

/// A [McpToolListCache] backed by one JSON file under the host's data dir.
///
/// Reads are served from memory (the file is loaded once at construction) so
/// the connect path never blocks on disk. Writes are debounced through a dirty
/// flag and flushed synchronously — the whole file is a few KB, and a partial
/// write is avoided by writing to a temp path and renaming.
class FileMcpToolListCache implements McpToolListCache {
  /// Creates a [FileMcpToolListCache] storing at [path], loading any existing
  /// contents. A corrupt or unreadable file starts empty rather than throwing:
  /// a bad cache must degrade to a cold start, never to a failed boot.
  FileMcpToolListCache(this.path) {
    _load();
  }

  /// Absolute path of the JSON store.
  final String path;

  final Map<String, _CacheEntry> _entries = {};

  @override
  List<McpRemoteTool>? read(String serverName, String fingerprint) {
    final entry = _entries[serverName];
    if (entry == null || entry.fingerprint != fingerprint) {
      return null;
    }
    return entry.tools;
  }

  @override
  void write(String serverName, String fingerprint, List<McpRemoteTool> tools) {
    final existing = _entries[serverName];
    if (existing != null &&
        existing.fingerprint == fingerprint &&
        _sameNames(existing.tools, tools)) {
      return; // No change — don't churn the file on every reconnect.
    }
    _entries[serverName] = _CacheEntry(fingerprint: fingerprint, tools: tools);
    _flush();
  }

  @override
  void evict(String serverName) {
    if (_entries.remove(serverName) != null) {
      _flush();
    }
  }

  static bool _sameNames(List<McpRemoteTool> a, List<McpRemoteTool> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) {
        return false;
      }
    }
    return true;
  }

  void _load() {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return;
      }
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is! Map) {
        return;
      }
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is! Map) {
          continue;
        }
        final fingerprint = value['fingerprint'];
        final tools = value['tools'];
        if (fingerprint is! String || tools is! List) {
          continue;
        }
        _entries[entry.key as String] = _CacheEntry(
          fingerprint: fingerprint,
          tools: [
            for (final t in tools)
              if (t is Map) McpRemoteTool.fromJson(t.cast<String, dynamic>()),
          ],
        );
      }
    } on Object {
      _entries.clear();
    }
  }

  void _flush() {
    try {
      final dir = Directory(p.dirname(path));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final tmp = File('$path.tmp');
      tmp.writeAsStringSync(
        jsonEncode({
          for (final e in _entries.entries)
            e.key: {
              'fingerprint': e.value.fingerprint,
              'tools': [for (final t in e.value.tools) t.toJson()],
            },
        }),
      );
      tmp.renameSync(path);
    } on Object {
      // A cache that cannot be written is a cold start next boot, not an
      // error worth failing a connect over.
    }
  }
}

class _CacheEntry {
  _CacheEntry({required this.fingerprint, required this.tools});
  final String fingerprint;
  final List<McpRemoteTool> tools;
}
