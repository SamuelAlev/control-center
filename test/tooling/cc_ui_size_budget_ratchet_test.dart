import 'dart:io';

import 'package:test/test.dart';

/// cc_ui component line budget (QUALITY.md P2.10 / R19).
///
/// Files over 1000 lines are frozen. A split must lower the baseline; growth
/// fails. Tokens and generated files are out of scope.
void main() {
  final projectRoot = _repoRoot();

    test('cc_ui components over 1000 lines only shrink', () {
    const failBudget = 1000;
    const baselinePath = 'test/tooling/cc_ui_size_budget_baseline.txt';
    final baseline = _readBaseline(projectRoot, baselinePath);
    final stale = <String>{...baseline.keys};
    final offenders = <String>[];
    final shrunk = <String>[];

    for (final rel in _dartFilesRelative(
      projectRoot,
      'packages/cc_ui/lib/src/components',
    )) {
      if (rel.endsWith('.g.dart')) {
        continue;
      }
      final lines = File('$projectRoot/$rel').readAsLinesSync().length;
      if (lines <= failBudget) {
        continue;
      }
      stale.remove(rel);
      final allowed = baseline[rel];
      if (allowed == null) {
        offenders.add('$rel ($lines lines, budget $failBudget)');
        continue;
      }
      if (lines > allowed) {
        offenders.add(
          '$rel grew to $lines lines (baselined at $allowed, budget $failBudget)',
        );
      } else if (lines < allowed) {
        shrunk.add('$rel is now $lines lines (baselined at $allowed)');
      }
    }

    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'cc_ui size budget exceeded (>$failBudget lines). Split the file, '
          'or add it to $baselinePath:\n${offenders.join('\n')}',
    );
    expect(
      stale.toList()..sort(),
      isEmpty,
      reason:
          'Stale cc_ui size-budget entries — prune $baselinePath:\n'
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
    fail('Missing cc_ui size-budget baseline: $relPath');
  }
  final out = <String, int>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      fail('Malformed baseline line in $relPath: $raw');
    }
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
    if (Directory('${dir.path}/packages/cc_ui').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
