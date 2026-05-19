import 'dart:io';

import 'package:path/path.dart' as p;

/// Loads a repo's `AGENTS.md` operating instructions — root and nested — into a
/// block for the harness system prompt.
///
/// This mirrors how external coding CLIs auto-load their instruction files from
/// the working tree: the built-in harness must do it itself. Bounded (file
/// count, total bytes, depth) and skips VCS/build dirs so a large tree can't
/// blow up the prompt. This is a freeform-instructions loader — distinct from
/// the agent-*definition* frontmatter parser.
class AgentsMdContextLoader {
  /// Creates an [AgentsMdContextLoader].
  const AgentsMdContextLoader({
    this.maxFiles = 12,
    this.maxTotalBytes = 60000,
    this.maxDepth = 6,
    this.fileName = 'AGENTS.md',
  });

  /// Cap on the number of AGENTS.md files included.
  final int maxFiles;

  /// Cap on total bytes across all included files.
  final int maxTotalBytes;

  /// How deep below the working directory to search.
  final int maxDepth;

  /// The instruction file name to collect.
  final String fileName;

  static const Set<String> _skipDirs = {
    '.git',
    'node_modules',
    '.dart_tool',
    'build',
    '.fvm',
    '.next',
    'target',
    'venv',
    '.venv',
    '__pycache__',
    '.cache',
  };

  /// Returns a formatted block of the AGENTS.md files under [root] (root first,
  /// then nested by path), or an empty string when none are found.
  Future<String> load(String root) async {
    final files = await _discover(root);
    if (files.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    var total = 0;
    var included = 0;
    for (final file in files) {
      if (included >= maxFiles || total >= maxTotalBytes) {
        break;
      }
      String content;
      try {
        content = await File(file).readAsString();
      } on Object {
        continue;
      }
      if (content.trim().isEmpty) {
        continue;
      }
      final remaining = maxTotalBytes - total;
      if (content.length > remaining) {
        content = '${content.substring(0, remaining)}\n…(truncated)';
      }
      final rel = p.relative(file, from: root);
      final label = rel == '.' || rel.isEmpty ? fileName : rel;
      buffer
        ..writeln('=== $label ===')
        ..writeln(content.trimRight())
        ..writeln();
      total += content.length;
      included++;
    }
    return buffer.toString().trimRight();
  }

  Future<List<String>> _discover(String root) async {
    final dir = Directory(root);
    if (!dir.existsSync()) {
      return const [];
    }
    final found = <String>[];
    await _walk(dir, root, 0, found);
    // Shallowest (root) first, then alphabetical for stable ordering.
    found.sort((a, b) {
      final da = p.split(p.relative(a, from: root)).length;
      final db = p.split(p.relative(b, from: root)).length;
      return da != db ? da.compareTo(db) : a.compareTo(b);
    });
    return found;
  }

  Future<void> _walk(
    Directory dir,
    String root,
    int depth,
    List<String> found,
  ) async {
    if (depth > maxDepth || found.length >= maxFiles * 4) {
      return;
    }
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      return;
    }
    for (final entity in entries) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        if (_skipDirs.contains(name) || name.startsWith('.')) {
          continue;
        }
        await _walk(entity, root, depth + 1, found);
      } else if (entity is File && name == fileName) {
        found.add(entity.path);
      }
    }
  }
}
