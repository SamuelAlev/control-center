import 'dart:io';

import 'package:test/test.dart';

/// Ratchets the presentation-layer size budgets stated in `AGENTS.md`
/// ("Screens (<250 lines), widgets (<300 lines)").
///
/// The budgets existed but nothing measured them, so 48% of screens and 36% of
/// widget files had drifted past them. This is the same shrinking-allowlist
/// shape the repo already uses for the Material/Cupertino migration: the
/// current offenders are frozen in a baseline file, and the test fails when
///
///   1. a file exceeds its budget and is NOT in the baseline (new debt), or
///   2. a baseline entry no longer exceeds its budget, or no longer exists
///      (stale entry — prune it, so the list provably mirrors reality).
///
/// The intended direction is one-way: split a file, delete its line from the
/// baseline. Nothing here forces the existing god files to be split today.
void main() {
  final projectRoot = _repoRoot();

  test('presentation size budgets only shrink', () {
    const screenBudget = 250;
    const widgetBudget = 300;

    const baselinePath = 'test/tooling/size_budget_baseline.txt';
    final baseline = _readBaseline(projectRoot, baselinePath);
    final stale = <String>{...baseline.keys};
    final offenders = <String>[];
    final shrunk = <String>[];

    for (final rel in _dartFilesRelative(projectRoot, 'lib/features')) {
      final budget = _budgetFor(rel, screenBudget, widgetBudget);
      if (budget == null) {
        continue;
      }
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
      // A baselined file may not GROW past the size it was frozen at.
      if (lines > allowed) {
        offenders.add(
          '$rel grew to $lines lines (baselined at $allowed, budget $budget)',
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
          'Presentation size budget exceeded (screens <$screenBudget lines, '
          'widgets <$widgetBudget). Split the file, or — only with a reason — '
          'add it to $baselinePath:\n${offenders.join('\n')}',
    );

    final staleList = stale.toList()..sort();
    expect(
      staleList,
      isEmpty,
      reason:
          'Stale size-budget baseline entries (now within budget or deleted — '
          'remove them from $baselinePath):\n${staleList.join('\n')}',
    );

    shrunk.sort();
    expect(
      shrunk,
      isEmpty,
      reason:
          'These files shrank below their baseline — lower the recorded number '
          'in $baselinePath so the ratchet keeps its new floor:\n'
          '${shrunk.join('\n')}',
    );
  });
}

/// The budget for [rel], or null when the file is not size-budgeted.
int? _budgetFor(String rel, int screenBudget, int widgetBudget) {
  if (!rel.contains('/presentation/')) {
    return null;
  }
  if (rel.contains('/screens/')) {
    return screenBudget;
  }
  if (rel.contains('/widgets/')) {
    return widgetBudget;
  }
  // A feature's own settings surface (`presentation/settings/`) is the same two
  // kinds of file under a different roof: `*_view.dart` is the page a feature
  // contributes to a settings destination, everything else is a section card.
  // Without this the whole directory went UNMEASURED — which is how it first
  // announced itself, by turning two baselined files into "stale" entries the
  // moment they moved there.
  if (rel.contains('/presentation/settings/')) {
    return rel.endsWith('_view.dart') ? screenBudget : widgetBudget;
  }
  return null;
}

/// `path → line count when baselined`, from a `path  count` per line file.
Map<String, int> _readBaseline(String projectRoot, String relPath) {
  final file = File('$projectRoot/$relPath');
  if (!file.existsSync()) {
    fail('Missing size-budget baseline: $relPath');
  }
  final out = <String, int>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length != 2) {
      fail('Malformed baseline line in $relPath: "$raw"');
    }
    out[parts[0]] = int.parse(parts[1]);
  }
  return out;
}

List<String> _dartFilesRelative(String projectRoot, String relDir) {
  final dir = Directory('$projectRoot/$relDir');
  if (!dir.existsSync()) {
    fail('Size-budget scan root is missing: $relDir');
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map(
        (f) => f.path.substring(projectRoot.length + 1).replaceAll(r'\', '/'),
      )
      .toList()
    ..sort();
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/lib/features').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
