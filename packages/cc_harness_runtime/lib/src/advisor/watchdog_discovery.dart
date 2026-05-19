import 'dart:io';

import 'package:path/path.dart' as p;

/// The context files the `WatchdogAdvisor` loads from disk: the `WATCHDOG.md`
/// attention block(s) and the project's standing convention files.
class WatchdogContext {
  /// Creates a [WatchdogContext].
  const WatchdogContext({this.attention, this.projectContext});

  /// Concatenated `WATCHDOG.md` content the reviewer should weigh especially,
  /// or null when none was found.
  final String? attention;

  /// Concatenated project instruction files (AGENTS.md / CLAUDE.md) so the
  /// reviewer holds the agent to its own conventions, or null when none exist.
  final String? projectContext;

  /// The empty context (nothing on disk).
  static const WatchdogContext none = WatchdogContext();
}

/// Per-file read cap so a giant instruction file can't balloon the reviewer's
/// (cache-free) system prompt.
const int _maxFileBytes = 16 * 1024;

/// Loads the advisor's on-disk context from the working tree and the agent
/// config dir.
///
/// - **attention**: `WATCHDOG.md` found at `<cwd>/WATCHDOG.md`,
///   `<cwd>/.agents/WATCHDOG.md` and `<agentConfigDir>/WATCHDOG.md`
///   (concatenated, first-listed first, each path read once).
/// - **projectContext**: `AGENTS.md` then `CLAUDE.md` at the repo root (`cwd`).
///
/// Missing/oversized/unreadable files are skipped; never throws. Returns
/// [WatchdogContext.none] when nothing relevant is on disk.
Future<WatchdogContext> loadWatchdogContext(
  String? cwd, {
  String? agentConfigDir,
}) async {
  final attentionPaths = <String>[
    if (cwd != null && cwd.isNotEmpty) ...[
      p.join(cwd, 'WATCHDOG.md'),
      p.join(cwd, '.agents', 'WATCHDOG.md'),
    ],
    if (agentConfigDir != null && agentConfigDir.isNotEmpty)
      p.join(agentConfigDir, 'WATCHDOG.md'),
  ];
  final conventionPaths = <String>[
    if (cwd != null && cwd.isNotEmpty) ...[
      p.join(cwd, 'AGENTS.md'),
      p.join(cwd, 'CLAUDE.md'),
    ],
  ];

  final attention = await _readAndJoin(attentionPaths);
  final projectContext = await _readAndJoin(conventionPaths);
  if (attention == null && projectContext == null) {
    return WatchdogContext.none;
  }
  return WatchdogContext(attention: attention, projectContext: projectContext);
}

/// Reads each distinct path (skipping missing/oversized/unreadable) and joins
/// the non-empty bodies with a blank line. Returns null when nothing was read.
Future<String?> _readAndJoin(List<String> paths) async {
  final seen = <String>{};
  final parts = <String>[];
  for (final path in paths) {
    if (!seen.add(path)) {
      continue;
    }
    final body = await _readCapped(path);
    if (body != null && body.trim().isNotEmpty) {
      parts.add(body.trim());
    }
  }
  return parts.isEmpty ? null : parts.join('\n\n');
}

Future<String?> _readCapped(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    if (await file.length() > _maxFileBytes) {
      // Read only the head so an oversized file still contributes something
      // without blowing up the reviewer prompt.
      final raw = await file.openRead(0, _maxFileBytes).toList();
      return String.fromCharCodes(raw.expand((chunk) => chunk));
    }
    return await file.readAsString();
  } on Object {
    return null;
  }
}
