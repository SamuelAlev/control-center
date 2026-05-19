import 'dart:convert';
import 'dart:io';

import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';
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
  ///
  /// A skill entry that is a SYMLINK is followed only when its target resolves
  /// inside one of [permittedLinkRoots] — the server-managed directories that
  /// legitimately hold skills (`<wsRoot>/skills` for the ones
  /// `syncAgentSkillLinks` attaches to an agent, `<spaceRoot>/repos` for the
  /// ones a repo ships). With no roots passed nothing is followed, which is the
  /// behaviour this scanner had before.
  Future<List<HarnessSkillInfo>> scan(
    List<String?> bases, {
    List<String> permittedLinkRoots = const [],
  }) async {
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
          // Do NOT follow links out of the skills dir. A skill's frontmatter is
          // autoloaded into the system prompt, so a symlink here is a way to
          // get arbitrary on-disk content in front of the model from a
          // directory nobody audited — and unlike the skills-BUNDLE path, this
          // one has no scan verdict in front of it. `permittedLinkRoots` is the
          // narrow, caller-declared exception to that.
          children = dir.listSync(followLinks: false);
        } on FileSystemException {
          continue;
        }
        for (final child in children) {
          final skillDir = _skillDirFor(child, permittedLinkRoots);
          if (skillDir == null) {
            continue;
          }
          final skillFile = File(p.join(skillDir, 'SKILL.md'));
          if (!skillFile.existsSync()) {
            continue;
          }
          final info = _parse(skillFile, p.basename(skillDir));
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

  /// The directory to read `SKILL.md` from for one entry of a skills dir, or
  /// null when the entry is not a usable skill directory.
  ///
  /// Returns the LINK path rather than its target for a permitted link, so the
  /// `path` the agent is handed stays addressable from its own working
  /// directory (the same reason `listWorkspaceTree` keeps the symlinked
  /// prefix).
  String? _skillDirFor(
    FileSystemEntity child,
    List<String> permittedLinkRoots,
  ) {
    // `isLinkLike` rather than `child is Link`: on Windows a junction comes
    // back from a `followLinks: false` listing typed as a Directory, so the
    // type test alone would wave it through the gate below.
    if (!isLinkLike(child.path)) {
      return child is Directory ? child.path : null;
    }
    if (FileSystemEntity.typeSync(child.path) !=
        FileSystemEntityType.directory) {
      return null;
    }
    return resolvesInsideRoots(child.path, permittedLinkRoots)
        ? child.path
        : null;
  }

  /// How much of a SKILL.md is read to find its frontmatter. Frontmatter lives
  /// at the very top, so reading the whole file — some run to tens of KB — to
  /// parse two lines is pure waste. When the closing `---` is not inside the
  /// head, the full file is read as a fallback so nothing is misparsed.
  static const int _frontmatterProbeBytes = 8192;

  HarnessSkillInfo? _parse(File file, String slug) {
    String content;
    try {
      final head = _readHead(file, _frontmatterProbeBytes);
      final headTrimmed = head.trimLeft();
      content =
          !headTrimmed.startsWith('---') ||
              headTrimmed.indexOf('\n---', 3) != -1
          ? head
          : file.readAsStringSync();
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

  /// The first [maxBytes] of [file], decoded leniently (a multi-byte character
  /// straddling the cut must not throw).
  static String _readHead(File file, int maxBytes) {
    final raf = file.openSync();
    try {
      final length = raf.lengthSync();
      final n = length < maxBytes ? length : maxBytes;
      return utf8.decode(raf.readSync(n), allowMalformed: true);
    } finally {
      raf.closeSync();
    }
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
