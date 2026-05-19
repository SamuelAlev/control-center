/// Infers which repo an agent is currently working in, from the paths its tool
/// calls touch.
///
/// A space checks out every linked repo side by side under `<spaceRoot>/repos/`
/// while the agent's cwd is its own overlay one level over. Nothing in the
/// domain records which of those the agent is actually in — `Space` has no repo
/// field and `AgentRunLog` has no `repoId` — and asking the agent to declare it
/// is a rule a prompt cannot enforce. So it is observed instead, from the
/// stream of tool calls every adapter already emits for the transcript.
///
/// The rule is deliberately asymmetric:
///
/// * A **write** switches. Editing a file in a repo is the least ambiguous
///   statement an agent can make about where it is working.
/// * A **read** only seeds, and only while nothing is active yet. Agents read
///   across repos constantly — chasing a symbol into a sibling service is
///   normal — and letting that switch would thrash the skill set on every
///   cross-repo glance.
/// * A path outside `repos/` never clears the active repo. The overlay's own
///   files, `/tmp`, and absolute paths elsewhere say nothing about it.
///
/// Pure string logic, no `dart:io` and no `package:path`: the layout this parses
/// is one the provisioner generates with `/` separators, and keeping the file
/// dependency-free makes it exhaustively testable without a filesystem.
class ActiveRepoTracker {
  /// Creates an [ActiveRepoTracker] for the space whose worktrees live in
  /// [reposDir].
  ///
  /// [knownRepos], when non-empty, is the set of directory names actually
  /// checked out. A slug outside it is ignored, so a typo, a stale path or a
  /// `repos/../..` traversal attempt cannot name a repo that does not exist.
  ActiveRepoTracker({
    required String reposDir,
    Set<String> knownRepos = const {},
  }) : _reposDir = _normalize(reposDir),
       _knownRepos = knownRepos;

  final String _reposDir;
  final Set<String> _knownRepos;

  String? _active;

  /// The repo the agent is currently working in, or null before its first
  /// touch inside one.
  String? get active => _active;

  /// Seeds the active repo without observing a tool call — used when a space
  /// is scoped to a single repo, so the very first turn is already scoped.
  ///
  /// Returns true when this changed the active repo.
  bool seed(String slug) {
    if (!_accepts(slug) || slug == _active) {
      return false;
    }
    _active = slug;
    return true;
  }

  /// Observes one tool call. Returns the new repo slug when the active repo
  /// CHANGED, and null otherwise — so a caller can treat a non-null return as
  /// "re-project the skills now".
  String? observe(String toolName, Map<String, dynamic> args) {
    final touch = _classify(toolName);
    if (touch == _Touch.other) {
      return null;
    }
    // A read that arrives once a repo is active tells us nothing new, so skip
    // the argument walk entirely.
    if (touch == _Touch.read && _active != null) {
      return null;
    }
    final slug = _slugFromArgs(touch, args);
    if (slug == null || slug == _active) {
      return null;
    }
    _active = slug;
    return slug;
  }

  bool _accepts(String slug) =>
      slug.isNotEmpty &&
      slug != '.' &&
      slug != '..' &&
      (_knownRepos.isEmpty || _knownRepos.contains(slug));

  /// Argument keys that carry a filesystem path across the adapters' tool
  /// vocabularies (built-in harness, Claude Code, ACP).
  static const Set<String> _pathKeys = {
    'path',
    'file_path',
    'filepath',
    'notebook_path',
    'cwd',
    'dir',
    'directory',
    'paths',
    'files',
    'old_path',
    'new_path',
  };

  /// Argument keys carrying a shell command. Claude Code's `Bash` takes no
  /// `cwd` — the agent writes `cd repos/<name> && …` instead — so the command
  /// text is the only signal available on that adapter.
  static const Set<String> _commandKeys = {'command', 'cmd', 'script'};

  String? _slugFromArgs(_Touch touch, Map<String, dynamic> args) {
    for (final entry in args.entries) {
      final key = entry.key.toLowerCase();
      if (_pathKeys.contains(key)) {
        final slug = _firstSlug(_strings(entry.value));
        if (slug != null) {
          return slug;
        }
      } else if (touch == _Touch.write && _commandKeys.contains(key)) {
        final value = entry.value;
        if (value is String) {
          final slug = _slugsIn(value).firstOrNull;
          if (slug != null) {
            return slug;
          }
        }
      }
    }
    return null;
  }

  Iterable<String> _strings(Object? value) sync* {
    if (value is String) {
      yield value;
    } else if (value is Iterable) {
      for (final item in value) {
        if (item is String) {
          yield item;
        }
      }
    }
  }

  String? _firstSlug(Iterable<String> candidates) {
    for (final candidate in candidates) {
      final slug = _slugFor(candidate);
      if (slug != null) {
        return slug;
      }
    }
    return null;
  }

  /// The repo slug [raw] names, or null when it does not point into `repos/`.
  ///
  /// Accepts both the absolute form (`<spaceRoot>/repos/<slug>/…`) and the
  /// relative one the agent normally uses (`repos/<slug>/…`), because the
  /// overlay reaches the shared worktrees through a `repos → ../../repos`
  /// symlink and either spelling resolves to the same directory.
  String? _slugFor(String raw) {
    final path = _normalize(raw);
    if (path.isEmpty) {
      return null;
    }
    if (_reposDir.isNotEmpty && path.startsWith('$_reposDir/')) {
      return _accepted(path.substring(_reposDir.length + 1));
    }
    return _slugsIn(path).firstOrNull;
  }

  /// Every `repos/<slug>` occurrence in [text], in order. Used both for a bare
  /// relative path and for scanning a shell command.
  Iterable<String> _slugsIn(String text) sync* {
    final normalized = _normalize(text);
    for (final match in _reposSegment.allMatches(normalized)) {
      final slug = _accepted(match.group(1) ?? '');
      if (slug != null) {
        yield slug;
      }
    }
  }

  String? _accepted(String tail) {
    final slug = tail.split('/').first;
    return _accepts(slug) ? slug : null;
  }

  /// `repos/<slug>` at a path-segment boundary, so `myrepos/x` and
  /// `backup-repos/x` do not match. The boundary includes `/` so an absolute
  /// path still resolves when it does not share a prefix with [_reposDir] —
  /// which happens whenever one side has been through a symlink.
  static final RegExp _reposSegment = RegExp(
    '(?:^|[/\\s"\'=:(,])repos/([^/\\s"\')]+)',
  );

  static _Touch _classify(String toolName) {
    final name = toolName.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    for (final needle in _writeNeedles) {
      if (name.contains(needle)) {
        return _Touch.write;
      }
    }
    for (final needle in _readNeedles) {
      if (name.contains(needle)) {
        return _Touch.read;
      }
    }
    return _Touch.other;
  }

  /// Substrings that mark a mutating tool across every adapter's vocabulary:
  /// `write`/`Write`/`write_file`, `edit`/`Edit`/`MultiEdit`/`NotebookEdit`,
  /// `apply_patch`, and the shell (`bash`/`Bash`/`shell`/`run_command`).
  static const List<String> _writeNeedles = [
    'write',
    'edit',
    'patch',
    'bash',
    'shell',
    'execute',
    'runcommand',
    'createfile',
  ];

  /// Substrings that mark a read-only tool. Checked after the write list so
  /// `read` inside `read_write` never wins.
  static const List<String> _readNeedles = [
    'read',
    'search',
    'find',
    'grep',
    'glob',
    'view',
    'cat',
    'list',
  ];
}

enum _Touch { write, read, other }

/// `\` → `/`, trailing separator dropped. The provisioner writes this layout
/// with POSIX separators; an agent on Windows may still spell a path with
/// backslashes.
String _normalize(String path) {
  final unified = path.replaceAll(r'\', '/');
  if (unified.length > 1 && unified.endsWith('/')) {
    return unified.substring(0, unified.length - 1);
  }
  return unified;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
