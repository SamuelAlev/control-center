import 'dart:io';

import 'package:path/path.dart' as p;

/// A user-authored slash command discovered on disk.
class HarnessCommandInfo {
  /// Creates a [HarnessCommandInfo].
  const HarnessCommandInfo({
    required this.name,
    required this.description,
    required this.path,
    required this.body,
    this.model,
    this.allowedTools = const [],
  });

  /// Invocation name, e.g. `review` for `/review`. A command in a
  /// subdirectory is also reachable as `dir:name`.
  final String name;

  /// One-line description for the composer's autocomplete.
  final String description;

  /// Absolute path to the markdown file.
  final String path;

  /// The command body, frontmatter stripped, before argument expansion.
  final String body;

  /// Optional model override from frontmatter.
  final String? model;

  /// Optional tool allowlist from frontmatter.
  final List<String> allowedTools;

  /// The body with the caller's [args] substituted.
  String render(String args) => expandCommandArgs(body, args);
}

/// Substitutes a slash command's arguments into its body.
///
/// Supported forms, in the order they are resolved:
///
///  * `$ARGUMENTS` / `$@` — everything the caller typed, verbatim.
///  * `$1`, `$2`, … — positional words (quote-aware).
///  * `$@[2]`, `$@[2:3]` — a 1-based slice: from word 2, optionally 3 words.
///
/// A command whose body uses NO placeholder still receives the arguments —
/// appended on their own line. Otherwise `/review some/file.dart` on a command
/// that forgot `$ARGUMENTS` would silently discard the only thing the user
/// typed, which reads as the command ignoring them.
String expandCommandArgs(String body, String args) {
  final trimmed = args.trim();
  final words = _splitArgs(trimmed);
  var out = body;
  var usedPlaceholder = false;

  String mark(String replaced) {
    usedPlaceholder = true;
    return replaced;
  }

  // Slices first: `$@[2:3]` must not be eaten by the bare `$@` rule.
  out = out.replaceAllMapped(RegExp(r'\$@\[(\d+)(?::(\d+))?\]'), (match) {
    final start = int.parse(match.group(1)!) - 1;
    final length = match.group(2) == null ? null : int.parse(match.group(2)!);
    if (start < 0 || start >= words.length) {
      return mark('');
    }
    final end = length == null
        ? words.length
        : (start + length).clamp(0, words.length);
    return mark(words.sublist(start, end).join(' '));
  });

  out = out.replaceAllMapped(RegExp(r'\$(\d+)'), (match) {
    final index = int.parse(match.group(1)!) - 1;
    return mark(index >= 0 && index < words.length ? words[index] : '');
  });

  if (out.contains(r'$ARGUMENTS') || out.contains(r'$@')) {
    out = mark(out.replaceAll(r'$ARGUMENTS', trimmed).replaceAll(r'$@', trimmed));
  }

  if (!usedPlaceholder && trimmed.isNotEmpty) {
    out = '${out.trimRight()}\n\n$trimmed';
  }
  return out;
}

/// Splits arguments into words, respecting single and double quotes.
///
/// No backslash escaping: a slash command is prose with placeholders, and the
/// backslashes people type are overwhelmingly Windows paths rather than escape
/// sequences. Treating `C:\Users\x` as three escapes would be worse than not
/// supporting escaping at all.
List<String> _splitArgs(String text) {
  final words = <String>[];
  final buffer = StringBuffer();
  String? quote;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        buffer.write(char);
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }
    if (char.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        words.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) {
    words.add(buffer.toString());
  }
  return words;
}

/// Scans for user-authored slash commands: markdown files whose name is the
/// command.
///
/// **Why this exists.** Skills already let a user drop reusable instructions on
/// disk, but a skill is discovered by the MODEL from a description — it is a
/// capability the agent may choose. A slash command is the other thing: a
/// shortcut the HUMAN invokes deliberately, with arguments. Without it, every
/// repeated prompt has to be retyped or hidden inside a skill the agent might
/// not pick.
///
/// Security posture is copied from the skill scanner rather than reinvented,
/// because the exposure is identical — a file on disk becomes text in a model's
/// prompt: symlinks are not followed, the file read is bounded, and the number
/// of commands is capped.
class HarnessCommandScanner {
  /// Creates a [HarnessCommandScanner].
  const HarnessCommandScanner({
    this.maxCommands = 100,
    this.maxBodyBytes = 64 * 1024,
  });

  /// Cap on the number of commands returned.
  final int maxCommands;

  /// Cap on a single command's body.
  final int maxBodyBytes;

  /// Directories (relative to a search base) holding `<name>.md`.
  ///
  /// The cross-tool paths are deliberate: a team that already wrote commands
  /// for another agent should not have to port them to try this one.
  static const List<String> commandDirs = [
    '.agents/commands',
    '.agent/commands',
    '.claude/commands',
    '.codex/commands',
    '.opencode/commands',
  ];

  /// Scans each of [bases], de-duplicated by name (first base wins).
  ///
  /// Order matters and is the caller's: a project directory listed before the
  /// user's home directory lets a repo override a personal command, which is
  /// the precedence people expect.
  Future<List<HarnessCommandInfo>> scan(List<String?> bases) async {
    final byName = <String, HarnessCommandInfo>{};
    for (final base in bases) {
      if (base == null || base.isEmpty) {
        continue;
      }
      for (final relative in commandDirs) {
        final dir = Directory(p.join(base, relative));
        if (!dir.existsSync()) {
          continue;
        }
        await _scanDir(dir, byName, prefix: '');
        if (byName.length >= maxCommands) {
          return byName.values.toList();
        }
      }
    }
    return byName.values.toList();
  }

  Future<void> _scanDir(
    Directory dir,
    Map<String, HarnessCommandInfo> out, {
    required String prefix,
    int depth = 0,
  }) async {
    // One level of nesting is enough for `review/security.md` → `review:security`
    // and stops a symlink loop or a vendored tree turning discovery into a
    // full-disk walk.
    if (depth > 1 || out.length >= maxCommands) {
      return;
    }
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      return;
    }
    for (final entry in entries) {
      if (out.length >= maxCommands) {
        return;
      }
      if (entry is Directory) {
        await _scanDir(
          entry,
          out,
          prefix: '${p.basename(entry.path)}:',
          depth: depth + 1,
        );
        continue;
      }
      if (entry is! File || p.extension(entry.path) != '.md') {
        continue;
      }
      final info = await _parse(entry, prefix: prefix);
      if (info != null) {
        out.putIfAbsent(info.name, () => info);
      }
    }
  }

  Future<HarnessCommandInfo?> _parse(File file, {required String prefix}) async {
    String raw;
    try {
      if (await file.length() > maxBodyBytes) {
        return null;
      }
      raw = await file.readAsString();
    } on Object {
      return null;
    }
    final name = '$prefix${p.basenameWithoutExtension(file.path)}'.toLowerCase();
    if (name.isEmpty) {
      return null;
    }

    var description = '';
    String? model;
    var allowedTools = const <String>[];
    var body = raw;

    final frontmatter = _splitFrontmatter(raw);
    if (frontmatter != null) {
      body = frontmatter.body;
      for (final line in frontmatter.header.split('\n')) {
        final idx = line.indexOf(':');
        if (idx <= 0) {
          continue;
        }
        final key = line.substring(0, idx).trim().toLowerCase();
        final value = line.substring(idx + 1).trim().replaceAll(
          RegExp(r'''^['"]|['"]$'''),
          '',
        );
        switch (key) {
          case 'description':
            description = value;
          case 'model':
            model = value.isEmpty ? null : value;
          case 'allowed-tools':
          case 'allowedtools':
            allowedTools = [
              for (final t in value.split(RegExp(r'[,\s]+')))
                if (t.trim().isNotEmpty) t.trim(),
            ];
        }
      }
    }

    body = body.trim();
    if (body.isEmpty) {
      return null;
    }
    if (description.isEmpty) {
      // Fall back to the first non-heading line, so a command with no
      // frontmatter still reads sensibly in the autocomplete list.
      for (final line in body.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          description = trimmed.length > 80
              ? '${trimmed.substring(0, 77)}…'
              : trimmed;
          break;
        }
      }
    }

    return HarnessCommandInfo(
      name: name,
      description: description,
      path: file.path,
      body: body,
      model: model,
      allowedTools: allowedTools,
    );
  }

  ({String header, String body})? _splitFrontmatter(String raw) {
    if (!raw.startsWith('---')) {
      return null;
    }
    final end = raw.indexOf('\n---', 3);
    if (end < 0) {
      return null;
    }
    final headerEnd = raw.indexOf('\n', 3);
    if (headerEnd < 0 || headerEnd > end) {
      return null;
    }
    final afterClose = raw.indexOf('\n', end + 1);
    return (
      header: raw.substring(headerEnd + 1, end),
      body: afterClose < 0 ? '' : raw.substring(afterClose + 1),
    );
  }
}
