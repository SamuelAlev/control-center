import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One language server's definition.
class LspServerConfig {
  /// Creates an [LspServerConfig].
  const LspServerConfig({
    required this.name,
    required this.command,
    this.args = const [],
    required this.fileTypes,
    required this.rootMarkers,
    this.initOptions,
    this.settings,
    this.isLinter = false,
    this.disabled = false,
  });

  /// Builds a config from a user override map, layered over [base] when the
  /// name matches a built-in (so an override can set one field without
  /// restating the command).
  factory LspServerConfig.fromJson(
    String name,
    Map<String, dynamic> json, {
    LspServerConfig? base,
  }) => LspServerConfig(
    name: name,
    command: json['command'] as String? ?? base?.command ?? '',
    args: (json['args'] as List?)?.map((e) => '$e').toList() ??
        base?.args ??
        const [],
    fileTypes:
        (json['fileTypes'] as List?)?.map((e) => '$e').toList() ??
        base?.fileTypes ??
        const [],
    rootMarkers:
        (json['rootMarkers'] as List?)?.map((e) => '$e').toList() ??
        base?.rootMarkers ??
        const [],
    initOptions:
        (json['initOptions'] as Map?)?.cast<String, dynamic>() ??
        base?.initOptions,
    settings:
        (json['settings'] as Map?)?.cast<String, dynamic>() ?? base?.settings,
    isLinter: json['isLinter'] as bool? ?? base?.isLinter ?? false,
    disabled: json['disabled'] as bool? ?? base?.disabled ?? false,
  );

  /// Stable identifier, e.g. `dartls`.
  final String name;

  /// Binary name (resolved through project-local bins then `PATH`) or an
  /// absolute path.
  final String command;

  /// Arguments passed to the binary.
  final List<String> args;

  /// Extensions this server handles, e.g. `['.dart']`.
  final List<String> fileTypes;

  /// Files or directories whose presence marks a project root for this server.
  final List<String> rootMarkers;

  /// Sent as `initializationOptions` during the handshake.
  final Map<String, dynamic>? initOptions;

  /// Pushed via `workspace/didChangeConfiguration` after initialize.
  final Map<String, dynamic>? settings;

  /// Diagnostics-only server (a linter or formatter).
  ///
  /// The flag is what keeps navigation honest: `eslint` and `ruff` answer
  /// `textDocument/publishDiagnostics` and nothing useful for "go to
  /// definition", so routing a definition request to one returns an empty
  /// result that reads to the model as "this symbol has no definition".
  /// Linters are queried for diagnostics and excluded from everything else.
  final bool isLinter;

  /// Never start this server.
  final bool disabled;

  /// Whether this server claims [path] by extension.
  bool handles(String path) {
    final ext = p.extension(path).toLowerCase();
    return fileTypes.any((t) => t.toLowerCase() == ext);
  }
}

/// The built-in server definitions.
///
/// Deliberately small and biased toward what this repo and its users actually
/// write. A server nobody has installed costs nothing (auto-detect skips it),
/// but every entry is one more thing to keep correct, so breadth is added on
/// demand rather than up front.
const List<LspServerConfig> builtinLspServers = [
  // Dart first, and not arbitrarily: Control Center is a Dart/Flutter
  // codebase, so this is the server that pays for the whole subsystem on day
  // one — an agent editing this repo gets analyzer errors as it writes.
  LspServerConfig(
    name: 'dartls',
    command: 'dart',
    args: ['language-server', '--client-id=control-center'],
    fileTypes: ['.dart'],
    rootMarkers: ['pubspec.yaml'],
  ),
  LspServerConfig(
    name: 'typescript-language-server',
    command: 'typescript-language-server',
    args: ['--stdio'],
    fileTypes: ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs'],
    rootMarkers: ['tsconfig.json', 'jsconfig.json', 'package.json'],
  ),
  LspServerConfig(
    name: 'rust-analyzer',
    command: 'rust-analyzer',
    fileTypes: ['.rs'],
    rootMarkers: ['Cargo.toml'],
  ),
  LspServerConfig(
    name: 'gopls',
    command: 'gopls',
    fileTypes: ['.go'],
    rootMarkers: ['go.mod', 'go.work'],
  ),
  LspServerConfig(
    name: 'basedpyright',
    command: 'basedpyright-langserver',
    args: ['--stdio'],
    fileTypes: ['.py', '.pyi'],
    rootMarkers: ['pyproject.toml', 'setup.py', 'requirements.txt'],
  ),
  LspServerConfig(
    name: 'pyright',
    command: 'pyright-langserver',
    args: ['--stdio'],
    fileTypes: ['.py', '.pyi'],
    rootMarkers: ['pyproject.toml', 'setup.py', 'requirements.txt'],
  ),
  LspServerConfig(
    name: 'ruff',
    command: 'ruff',
    args: ['server'],
    fileTypes: ['.py', '.pyi'],
    rootMarkers: ['pyproject.toml', 'ruff.toml', '.ruff.toml'],
    isLinter: true,
  ),
  LspServerConfig(
    name: 'clangd',
    command: 'clangd',
    fileTypes: ['.c', '.cc', '.cpp', '.h', '.hpp', '.m', '.mm'],
    rootMarkers: ['compile_commands.json', 'CMakeLists.txt', '.clangd'],
  ),
  LspServerConfig(
    name: 'lua-language-server',
    command: 'lua-language-server',
    fileTypes: ['.lua'],
    rootMarkers: ['.luarc.json', 'stylua.toml'],
  ),
  LspServerConfig(
    name: 'bashls',
    command: 'bash-language-server',
    args: ['start'],
    fileTypes: ['.sh', '.bash'],
    rootMarkers: ['.git'],
  ),
];

/// Project-local directories searched for a server binary before `$PATH`.
///
/// A repo that pins its own toolchain (a `node_modules/.bin/tsserver`, a
/// `.venv/bin/ruff`) means a version-specific server, and the globally
/// installed one may not even understand its config. Local wins.
const List<String> projectLocalBinDirs = [
  'node_modules/.bin',
  '.venv/bin',
  'venv/bin',
  '.dart_tool/bin',
  'bin',
];

/// The servers that should run for [projectRoot].
///
/// **Auto-detection is an INTERSECTION**, and both halves matter:
///
///  * a `rootMarkers` entry exists in the project — otherwise a Go server
///    starts for a repo with no Go in it and sits there holding memory; and
///  * the binary resolves — otherwise every request fails with a spawn error
///    the model reads as "this language has no definitions".
///
/// The result is that the common case needs no configuration at all, and an
/// uninstalled server is silently absent rather than loudly broken.
///
/// [overrides] layer user config over the built-ins by name. Supplying any
/// server override switches OFF auto-detection for servers not mentioned —
/// matching the principle that an explicit list is a decision, not a hint.
List<LspServerConfig> detectLspServers({
  required String projectRoot,
  Map<String, Map<String, dynamic>> overrides = const {},
  bool Function(String command)? binaryResolver,
}) {
  final resolve =
      binaryResolver ?? (cmd) => resolveServerBinary(cmd, projectRoot) != null;
  final byName = {for (final s in builtinLspServers) s.name: s};
  final merged = <String, LspServerConfig>{...byName};
  for (final entry in overrides.entries) {
    merged[entry.key] = LspServerConfig.fromJson(
      entry.key,
      entry.value,
      base: byName[entry.key],
    );
  }
  // With explicit overrides, only the named servers are candidates. Without
  // them, everything built-in is.
  final candidates = overrides.isEmpty
      ? merged.values
      : merged.values.where((s) => overrides.containsKey(s.name));

  return [
    for (final server in candidates)
      if (!server.disabled &&
          server.command.isNotEmpty &&
          _hasRootMarker(projectRoot, server.rootMarkers) &&
          resolve(server.command))
        server,
  ];
}

bool _hasRootMarker(String projectRoot, List<String> markers) {
  for (final marker in markers) {
    final path = p.join(projectRoot, marker);
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      return true;
    }
  }
  return false;
}

/// Resolves [command] to an executable path, checking project-local bin
/// directories before `$PATH`. Returns null when it cannot be found.
String? resolveServerBinary(String command, String projectRoot) {
  if (command.contains(p.separator)) {
    final file = File(command);
    return file.existsSync() ? command : null;
  }
  for (final dir in projectLocalBinDirs) {
    final candidate = p.join(projectRoot, dir, command);
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  final pathVar = Platform.environment['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  final extensions = Platform.isWindows
      ? ['.exe', '.bat', '.cmd', '']
      : [''];
  for (final dir in pathVar.split(separator)) {
    if (dir.isEmpty) {
      continue;
    }
    for (final ext in extensions) {
      final candidate = p.join(dir, '$command$ext');
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
  }
  return null;
}

/// Reads per-project LSP overrides from the first config file that exists.
///
/// Mirrors where the rest of the agent config already lives, so a repo that
/// configures skills and hooks in `.agents/` configures its language servers
/// there too rather than in a fifth convention.
Map<String, Map<String, dynamic>> loadLspOverrides(String projectRoot) {
  const candidates = [
    '.agents/lsp.json',
    '.omp/lsp.json',
    '.claude/lsp.json',
    'lsp.json',
    '.lsp.json',
  ];
  for (final relative in candidates) {
    final file = File(p.join(projectRoot, relative));
    if (!file.existsSync()) {
      continue;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) {
        continue;
      }
      // Both shapes are accepted: a `servers` wrapper and a flat map. A config
      // that only sets a non-server key must NOT disable auto-detection, so
      // non-map values are skipped rather than treated as overrides.
      final raw = decoded['servers'] is Map ? decoded['servers'] as Map : decoded;
      return {
        for (final entry in raw.entries)
          if (entry.value is Map)
            '${entry.key}': (entry.value as Map).cast<String, dynamic>(),
      };
    } on Object {
      // A malformed config falls back to auto-detection rather than failing
      // the run: no language server is a degraded agent, but a crashed
      // dispatch is a broken one.
      return const {};
    }
  }
  return const {};
}
