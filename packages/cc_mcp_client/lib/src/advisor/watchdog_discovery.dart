import 'dart:io';

import 'package:path/path.dart' as p;

/// Reads a file's contents, or null when absent. Injected for testability.
typedef WatchdogFileReader = Future<String?> Function(String path);

/// Discovers `WATCHDOG.md` files declaring what the advisor should scrutinise
/// (PRD 01 feature 9).
///
/// Walks from the user level down to the working directory:
/// * user level — `~/.claude/WATCHDOG.md`
/// * each ancestor from the git root (or home) down to [cwd] — `.claude/
///   WATCHDOG.md` and `./WATCHDOG.md`
///
/// User-level guidance comes first; project-level files are ordered ancestor →
/// leaf so the most specific (closest to the work) lands last.
class WatchdogDiscovery {
  /// Creates a [WatchdogDiscovery].
  WatchdogDiscovery({
    required this.homeDir,
    required this.cwd,
    this.stopDir,
    WatchdogFileReader? readFile,
  }) : _readFile = readFile ?? _defaultReadFile;

  /// The user's home directory.
  final String homeDir;

  /// The working directory to walk up from.
  final String cwd;

  /// Stop the upward walk at this directory (e.g. the git root). Defaults to
  /// [homeDir] when null.
  final String? stopDir;

  final WatchdogFileReader _readFile;

  /// The ordered candidate paths (user-level first, then ancestor → leaf).
  List<String> candidatePaths() {
    final paths = <String>[p.join(homeDir, '.claude', 'WATCHDOG.md')];

    final ceiling = stopDir ?? homeDir;
    final ancestors = <String>[];
    var dir = p.normalize(cwd);
    while (true) {
      ancestors.add(dir);
      if (dir == ceiling || p.equals(dir, ceiling)) {
        break;
      }
      final parent = p.dirname(dir);
      if (parent == dir) {
        break; // filesystem root
      }
      dir = parent;
    }
    // ancestors is leaf → root; reverse to root → leaf.
    for (final ancestor in ancestors.reversed) {
      paths.add(p.join(ancestor, '.claude', 'WATCHDOG.md'));
      paths.add(p.join(ancestor, 'WATCHDOG.md'));
    }
    return paths;
  }

  /// Reads all present `WATCHDOG.md` files and returns the combined advisor
  /// guidance block, or null when none exist.
  Future<String?> discover() async {
    final blocks = <String>[];
    final seen = <String>{};
    for (final path in candidatePaths()) {
      if (!seen.add(p.normalize(path))) {
        continue;
      }
      final content = await _readFile(path);
      if (content != null && content.trim().isNotEmpty) {
        blocks.add(content.trim());
      }
    }
    if (blocks.isEmpty) {
      return null;
    }
    return 'Especially pay attention to:\n<attention>\n'
        '${blocks.join('\n\n')}\n</attention>';
  }

  static Future<String?> _defaultReadFile(String path) async {
    try {
      return await File(path).readAsString();
    } on Object {
      return null;
    }
  }
}
