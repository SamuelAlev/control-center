import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/src/config/mcp_server_config.dart';
import 'package:path/path.dart' as p;

/// Reads a file's contents, or returns null when it doesn't exist / can't be
/// read. Injected so discovery is unit-testable without touching disk.
typedef ConfigFileReader = Future<String?> Function(String path);

/// One config source to scan: a human label and the absolute file path.
class DiscoverySource {
  /// Creates a [DiscoverySource].
  const DiscoverySource(this.label, this.path);

  /// Human-readable tool name (e.g. `claude`, `cursor`).
  final String label;

  /// Absolute path to the config file.
  final String path;
}

/// Auto-discovers external MCP servers a user already configured for other
/// tools (Claude, Codex, Cursor, Gemini, VS Code, Windsurf, OpenCode) plus a
/// standalone `.mcp.json`, and normalises them down to one canonical
/// [McpServerConfig] list (PRD 01 phase 1.3).
///
/// Both the user home directory and the workspace directory are scanned; a
/// workspace-level config wins over the same-named user-level one. The result
/// is the zero-config starting set the connection manager dials.
class McpConfigDiscovery {
  /// Creates an [McpConfigDiscovery].
  ///
  /// [homeDir] / [workspaceDir] are injected (rather than read from the
  /// environment) so the scan is deterministic and testable. [readFile]
  /// defaults to reading from disk.
  McpConfigDiscovery({
    required this.homeDir,
    this.workspaceDir,
    ConfigFileReader? readFile,
  }) : _readFile = readFile ?? _defaultReadFile;

  /// The user's home directory.
  final String homeDir;

  /// The active workspace directory, if any.
  final String? workspaceDir;

  final ConfigFileReader _readFile;

  /// The ordered set of sources scanned. User-level first, workspace-level
  /// last so the workspace config wins the de-dup by name.
  List<DiscoverySource> sources() {
    final home = homeDir;
    final ws = workspaceDir;
    return [
      // ── User-level ──
      DiscoverySource('claude', p.join(home, '.claude.json')),
      DiscoverySource(
        'claude-desktop',
        p.join(
          home,
          'Library',
          'Application Support',
          'Claude',
          'claude_desktop_config.json',
        ),
      ),
      DiscoverySource('codex', p.join(home, '.codex', 'config.toml')),
      DiscoverySource('cursor', p.join(home, '.cursor', 'mcp.json')),
      DiscoverySource('gemini', p.join(home, '.gemini', 'settings.json')),
      DiscoverySource(
        'windsurf',
        p.join(home, '.codeium', 'windsurf', 'mcp_config.json'),
      ),
      DiscoverySource(
        'opencode',
        p.join(home, '.config', 'opencode', 'opencode.json'),
      ),
      DiscoverySource(
        'vscode-user',
        p.join(
          home,
          'Library',
          'Application Support',
          'Code',
          'User',
          'settings.json',
        ),
      ),
      // ── Workspace-level ──
      if (ws != null) ...[
        DiscoverySource('workspace', p.join(ws, '.mcp.json')),
        DiscoverySource('cursor', p.join(ws, '.cursor', 'mcp.json')),
        DiscoverySource('vscode', p.join(ws, '.vscode', 'mcp.json')),
        DiscoverySource('opencode', p.join(ws, 'opencode.json')),
      ],
    ];
  }

  /// Scans every source and returns the merged canonical config list.
  Future<List<McpServerConfig>> discover() async {
    final byName = <String, McpServerConfig>{};
    for (final source in sources()) {
      final raw = await _readFile(source.path);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }
      final configs = source.path.endsWith('.toml')
          ? parseCodexToml(raw, source: '${source.label}:${source.path}')
          : parseJsonConfig(raw, source: '${source.label}:${source.path}');
      for (final config in configs) {
        // Later (workspace-level) sources override earlier (user-level) ones.
        byName[config.name] = config;
      }
    }
    return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Parses a JSON config blob, extracting servers from any of the known
  /// container keys (`mcpServers`, `servers`, `mcp.servers`, `mcp`).
  static List<McpServerConfig> parseJsonConfig(
    String raw, {
    required String source,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! Map) {
      return const [];
    }
    final container = _serversContainer(decoded.cast<String, dynamic>());
    if (container == null) {
      return const [];
    }
    final result = <McpServerConfig>[];
    for (final entry in container.entries) {
      final value = entry.value;
      if (value is! Map) {
        continue;
      }
      final config = _normalizeEntry(
        entry.key,
        value.cast<String, dynamic>(),
        source,
      );
      if (config != null && config.isValid) {
        result.add(config);
      }
    }
    return result;
  }

  /// Minimal Codex `config.toml` reader: extracts `[mcp_servers.NAME]` tables
  /// with `command`, `args`, and `env`. Covers the common stdio case without a
  /// full TOML dependency.
  static List<McpServerConfig> parseCodexToml(
    String raw, {
    required String source,
  }) {
    final result = <McpServerConfig>[];
    final tableHeader = RegExp(r'^\s*\[mcp_servers\.([^\]]+)\]\s*$');
    String? currentName;
    String? command;
    var args = <String>[];
    final env = <String, String>{};

    void flush() {
      final name = currentName;
      final cmd = command;
      if (name != null && cmd != null && cmd.isNotEmpty) {
        result.add(
          McpServerConfig.stdio(
            name: name.replaceAll('"', '').trim(),
            command: cmd,
            args: args,
            env: env,
            source: source,
          ),
        );
      }
      command = null;
      args = <String>[];
      env.clear();
    }

    for (final line in const LineSplitter().convert(raw)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final header = tableHeader.firstMatch(line);
      if (header != null) {
        flush();
        currentName = header.group(1);
        continue;
      }
      if (currentName == null) {
        continue;
      }
      if (trimmed.startsWith('[')) {
        // Entered an unrelated table.
        flush();
        currentName = null;
        continue;
      }
      final eq = trimmed.indexOf('=');
      if (eq == -1) {
        continue;
      }
      final key = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();
      switch (key) {
        case 'command':
          command = _tomlString(value);
        case 'args':
          args = _tomlStringArray(value);
        default:
          // env entries appear as `env = { KEY = "v" }` (inline table) which
          // this minimal reader does not parse; skip.
          break;
      }
    }
    flush();
    return result;
  }

  static Map<String, dynamic>? _serversContainer(Map<String, dynamic> json) {
    if (json['mcpServers'] is Map) {
      return (json['mcpServers'] as Map).cast<String, dynamic>();
    }
    if (json['servers'] is Map) {
      return (json['servers'] as Map).cast<String, dynamic>();
    }
    final mcp = json['mcp'];
    if (mcp is Map) {
      if (mcp['servers'] is Map) {
        return (mcp['servers'] as Map).cast<String, dynamic>();
      }
      // OpenCode-style: `mcp` maps name → {type, command/url}.
      return mcp.cast<String, dynamic>();
    }
    return null;
  }

  static McpServerConfig? _normalizeEntry(
    String name,
    Map<String, dynamic> entry,
    String source,
  ) {
    // `command` can be a string (Claude/Cursor) or an array (OpenCode/kilocode
    // `["cmd", "arg1"]`). Normalise to command + args.
    String? command;
    var args = <String>[];
    final rawCommand = entry['command'];
    if (rawCommand is String) {
      command = rawCommand;
      final rawArgs = entry['args'];
      if (rawArgs is List) {
        args = rawArgs.map((e) => e.toString()).toList();
      }
    } else if (rawCommand is List && rawCommand.isNotEmpty) {
      command = rawCommand.first.toString();
      args = rawCommand.skip(1).map((e) => e.toString()).toList();
    }

    final url = (entry['url'] ?? entry['serverUrl']) as String?;
    final typeRaw = entry['type'] as String?;
    final transport = _resolveTransport(typeRaw, url: url, command: command);

    // Respect both `enabled: false` and `disabled: true`.
    final enabled = entry['enabled'] as bool? ??
        !(entry['disabled'] as bool? ?? false);

    final headers = <String, String>{};
    final rawHeaders = entry['headers'];
    if (rawHeaders is Map) {
      for (final h in rawHeaders.entries) {
        headers[h.key.toString()] = '${h.value}';
      }
    }

    final env = <String, String>{};
    final rawEnv = entry['env'] ?? entry['environment'];
    if (rawEnv is Map) {
      for (final e in rawEnv.entries) {
        env[e.key.toString()] = '${e.value}';
      }
    }

    final auth = McpAuthKind.fromWire(
      (entry['auth'] as Map?)?['type'] as String? ?? entry['auth'] as String?,
    );

    switch (transport) {
      case McpTransportKind.stdio:
        if (command == null) {
          return null;
        }
        return McpServerConfig.stdio(
          name: name,
          command: command,
          args: args,
          env: env,
          cwd: entry['cwd'] as String?,
          enabled: enabled,
          source: source,
        );
      case McpTransportKind.http:
        if (url == null) {
          return null;
        }
        return McpServerConfig.http(
          name: name,
          url: url,
          headers: headers,
          enabled: enabled,
          auth: auth,
          source: source,
        );
      case McpTransportKind.sse:
        if (url == null) {
          return null;
        }
        return McpServerConfig.sse(
          name: name,
          url: url,
          headers: headers,
          enabled: enabled,
          auth: auth,
          source: source,
        );
    }
  }

  static McpTransportKind _resolveTransport(
    String? type, {
    String? url,
    String? command,
  }) {
    switch (type) {
      case 'http':
      case 'streamable-http':
      case 'streamableHttp':
      case 'remote': // OpenCode remote == HTTP
        return McpTransportKind.http;
      case 'sse':
        return McpTransportKind.sse;
      case 'stdio':
      case 'local':
        return McpTransportKind.stdio;
    }
    // No explicit type: infer from shape.
    if (command != null) {
      return McpTransportKind.stdio;
    }
    if (url != null) {
      return McpTransportKind.http;
    }
    return McpTransportKind.stdio;
  }

  static String? _tomlString(String raw) {
    var v = raw.trim();
    if (v.endsWith(',')) {
      v = v.substring(0, v.length - 1).trim();
    }
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      return v.substring(1, v.length - 1);
    }
    return v.isEmpty ? null : v;
  }

  static List<String> _tomlStringArray(String raw) {
    var v = raw.trim();
    if (!v.startsWith('[') || !v.endsWith(']')) {
      return const [];
    }
    v = v.substring(1, v.length - 1);
    return v
        .split(',')
        .map((e) => _tomlString(e) ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<String?> _defaultReadFile(String path) async {
    try {
      // Read straight through; a missing file throws and is mapped to null
      // (avoids the slow async exists()+read race the analyzer warns about).
      return await File(path).readAsString();
    } on Object {
      return null;
    }
  }
}
