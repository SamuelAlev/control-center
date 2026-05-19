import 'dart:io';

import 'package:path/path.dart' as p;

/// A skill discovered on disk: its frontmatter name/description and the path to
/// its `SKILL.md` (so the agent can read the full body on demand).
class HarnessSkillInfo {
  /// Creates a [HarnessSkillInfo].
  const HarnessSkillInfo({
    required this.name,
    required this.description,
    required this.path,
  });

  /// Skill name (frontmatter `name`, or the directory slug).
  final String name;

  /// One-line description (frontmatter `description`).
  final String description;

  /// Absolute path to the skill's `SKILL.md`.
  final String path;
}

/// Scans an agent's config dir and working tree for skills, parsing each
/// `SKILL.md`'s YAML frontmatter (`name`, `description`).
///
/// The harness autoloads the frontmatter into the system prompt so the agent
/// knows which skills exist; the full body is read on demand via the `read`
/// tool (the path is in the autoloaded list). Server-side, pure `dart:io` —
/// distinct from the app-layer scanner in `lib/`.
class HarnessSkillScanner {
  /// Creates a [HarnessSkillScanner].
  const HarnessSkillScanner({this.maxSkills = 50});

  /// Cap on the number of skills returned.
  final int maxSkills;

  /// Directories (relative to a search base) that hold `<slug>/SKILL.md`.
  static const List<String> _skillDirs = [
    '.agents/skills',
    '.agent/skills',
    '.claude/skills',
    '.opencode/skills',
    'skills',
  ];

  /// Scans each of [bases] for skills, de-duplicated by name (first wins).
  Future<List<HarnessSkillInfo>> scan(List<String?> bases) async {
    final byName = <String, HarnessSkillInfo>{};
    for (final base in bases) {
      if (base == null || base.isEmpty) {
        continue;
      }
      for (final rel in _skillDirs) {
        final dir = Directory(p.join(base, rel));
        if (!dir.existsSync()) {
          continue;
        }
        List<FileSystemEntity> children;
        try {
          children = dir.listSync(followLinks: true);
        } on FileSystemException {
          continue;
        }
        for (final child in children) {
          if (child is! Directory) {
            continue;
          }
          final skillFile = File(p.join(child.path, 'SKILL.md'));
          if (!skillFile.existsSync()) {
            continue;
          }
          final info = _parse(skillFile, p.basename(child.path));
          if (info != null) {
            byName.putIfAbsent(info.name, () => info);
          }
          if (byName.length >= maxSkills) {
            return byName.values.toList();
          }
        }
      }
    }
    return byName.values.toList();
  }

  HarnessSkillInfo? _parse(File file, String slug) {
    String content;
    try {
      content = file.readAsStringSync();
    } on Object {
      return null;
    }
    var name = slug;
    var description = '';
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('---')) {
      final end = trimmed.indexOf('\n---', 3);
      if (end != -1) {
        final front = trimmed.substring(3, end);
        for (final line in front.split('\n')) {
          final idx = line.indexOf(':');
          if (idx <= 0) {
            continue;
          }
          final key = line.substring(0, idx).trim();
          final value = _unquote(line.substring(idx + 1).trim());
          if (key == 'name' && value.isNotEmpty) {
            name = value;
          } else if (key == 'description') {
            description = value;
          }
        }
      }
    }
    return HarnessSkillInfo(
      name: name,
      description: description,
      path: file.path,
    );
  }

  static String _unquote(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
