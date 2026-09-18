import 'dart:io';

import 'package:test/test.dart';

/// Phone presentation size budget (QUALITY.md R2).
///
/// Screens ≤250, widgets ≤300 — the same numbers as the desktop presentation
/// ratchet, applied to `apps/cc_remote`. Current offenders are frozen.
void main() {
  final projectRoot = _repoRoot();

  test('cc_remote screens and widgets only shrink', () {
    const screenBudget = 250;
    const widgetBudget = 300;
    const baselinePath = 'test/tooling/remote_size_budget_baseline.txt';
    final baseline = _readBaseline(projectRoot, baselinePath);
    final stale = <String>{...baseline.keys};
    final offenders = <String>[];
    final shrunk = <String>[];

    void measure(String relRoot, int budget) {
      for (final rel in _dartFilesRelative(projectRoot, relRoot)) {
        final lines = File('$projectRoot/$rel').readAsLinesSync().length;
        if (lines <= budget) {
          continue;
        }
        stale.remove(rel);
        final allowed = baseline[rel];
        if (allowed == null) {
          offenders.add('$rel ($lines lines, budget $budget)');
          continue;
        }
        if (lines > allowed) {
          offenders.add(
            '$rel grew to $lines lines (baselined at $allowed, budget $budget)',
          );
        } else if (lines < allowed) {
          shrunk.add('$rel is now $lines lines (baselined at $allowed)');
        }
      }
    }

    measure('apps/cc_remote/lib/screens', screenBudget);
    measure('apps/cc_remote/lib/widgets', widgetBudget);

    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'cc_remote size budget exceeded. Split the file, or add it to '
          '$baselinePath:\n${offenders.join('\n')}',
    );
    expect(
      stale.toList()..sort(),
      isEmpty,
      reason:
          'Stale remote size-budget entries — prune $baselinePath:\n'
          '${(stale.toList()..sort()).join('\n')}',
    );
    expect(
      shrunk..sort(),
      isEmpty,
      reason:
          'Lower the recorded number in $baselinePath:\n${shrunk.join('\n')}',
    );
  });
}

Map<String, int> _readBaseline(String projectRoot, String relPath) {
  final file = File('$projectRoot/$relPath');
  if (!file.existsSync()) {
    fail('Missing remote size-budget baseline: $relPath');
  }
  final out = <String, int>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final parts = line.split(RegExp(r'\s+'));
    out[parts[0]] = int.parse(parts.last);
  }
  return out;
}

Iterable<String> _dartFilesRelative(String projectRoot, String dirPath) sync* {
  final dir = Directory('$projectRoot/$dirPath');
  if (!dir.existsSync()) {
    return;
  }
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    yield entity.path.substring(projectRoot.length + 1).replaceAll(r'\', '/');
  }
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/apps/cc_remote').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
