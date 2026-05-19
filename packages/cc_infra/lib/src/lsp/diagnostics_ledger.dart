/// One diagnostic, normalized across servers.
class LspDiagnostic {
  /// Creates an [LspDiagnostic].
  const LspDiagnostic({
    required this.path,
    required this.line,
    required this.column,
    required this.severity,
    required this.message,
    this.source,
    this.code,
  });

  /// Absolute file path.
  final String path;

  /// 1-indexed line.
  final int line;

  /// 1-indexed column.
  final int column;

  /// `error` | `warning` | `info` | `hint`.
  final String severity;

  /// Human-readable text.
  final String message;

  /// Which server or linter produced it.
  final String? source;

  /// The server's own rule/error code, when it supplies one.
  final String? code;

  /// `path:line:col severity: message` — the shape the model reads.
  String render({bool includePath = true}) {
    final where = includePath ? '$path:$line:$column' : '$line:$column';
    final origin = source == null ? '' : ' ($source)';
    return '$where $severity: $message$origin';
  }

  /// What makes this diagnostic "the same problem" across two reports.
  ///
  /// Deliberately EXCLUDES the position. Inserting a line above an existing
  /// error moves it without changing it, and an agent that gets told about
  /// the same unchanged error after every edit learns to ignore the whole
  /// channel. Message + severity + code is the identity that survives an edit
  /// elsewhere in the file.
  String get identity => '$severity|${code ?? ''}|$message';
}

/// Remembers which diagnostics a file has already reported, so a writer only
/// ever hears about what is NEW.
///
/// This is what makes diagnostics-on-write usable rather than noisy. A file
/// with twelve pre-existing warnings would otherwise re-report all twelve on
/// every edit, burying the one error the edit just introduced — and costing a
/// dozen lines of context each time. After the first report the ledger has
/// them, so the second edit says only what changed.
///
/// Per run, not per process: a new run should hear the current state of the
/// world once, because it has no memory of the previous one.
class DiagnosticsLedger {
  final Map<String, Set<String>> _seen = {};

  /// Returns the diagnostics in [current] that have not been reported for
  /// [path] before, and records the full current set as seen.
  ///
  /// Recording the FULL set (not just the fresh ones) is what lets a fixed
  /// error be re-reported if it comes back: the identity leaves the ledger
  /// when the diagnostic leaves the file.
  List<LspDiagnostic> fresh(String path, List<LspDiagnostic> current) {
    final previous = _seen[path];
    final currentIdentities = <String>{};
    final out = <LspDiagnostic>[];
    for (final diagnostic in current) {
      final identity = diagnostic.identity;
      currentIdentities.add(identity);
      if (previous == null || !previous.contains(identity)) {
        out.add(diagnostic);
      }
    }
    if (currentIdentities.isEmpty) {
      _seen.remove(path);
    } else {
      _seen[path] = currentIdentities;
    }
    return out;
  }

  /// Forgets [path], so its next report is treated as first-seen. Used when a
  /// file is deleted or renamed.
  void forget(String path) => _seen.remove(path);

  /// Whether [path] has ever been reported on.
  bool hasSeen(String path) => _seen.containsKey(path);

  /// Drops every remembered file.
  void clear() => _seen.clear();
}

/// Renders diagnostics for a tool result: at most [limit] lines, errors first.
///
/// Errors before warnings because an edit that introduced a type error and a
/// style warning has one problem worth the model's next action; truncating the
/// error to fit the warning would be exactly backwards.
String renderDiagnostics(
  List<LspDiagnostic> diagnostics, {
  int limit = 20,
  bool includePath = true,
}) {
  if (diagnostics.isEmpty) {
    return '';
  }
  const rank = {'error': 0, 'warning': 1, 'info': 2, 'hint': 3};
  final sorted = [...diagnostics]..sort((a, b) {
    final bySeverity = (rank[a.severity] ?? 9).compareTo(rank[b.severity] ?? 9);
    if (bySeverity != 0) {
      return bySeverity;
    }
    return a.line.compareTo(b.line);
  });
  final shown = sorted.take(limit).toList();
  final buffer = StringBuffer();
  for (final diagnostic in shown) {
    buffer.writeln(diagnostic.render(includePath: includePath));
  }
  if (sorted.length > shown.length) {
    buffer.writeln('… and ${sorted.length - shown.length} more');
  }
  return buffer.toString().trimRight();
}
