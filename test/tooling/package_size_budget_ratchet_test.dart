import 'dart:io';

import 'package:test/test.dart';

/// Package-side line-budget ratchet (QUALITY.md R1).
///
/// Presentation already has `size_budget_ratchet_test.dart`. The files that
/// actually threaten review (`remote_rpc_catalog.dart`, `dispatch_session.dart`)
/// live under `packages/` and were unguarded. This freezes every `lib/` file
/// currently over 1500 lines; a split must lower the baseline, growth fails.
void main() {
  final projectRoot = _repoRoot();

  test('package lib files over 1500 lines only shrink', () {
    const failBudget = 1500;
    const baselinePath = 'test/tooling/package_size_budget_baseline.txt';
    final baseline = _readBaseline(projectRoot, baselinePath);
    final stale = <String>{...baseline.keys};
    final offenders = <String>[];
    final shrunk = <String>[];

    for (final rel in _dartFilesRelative(projectRoot, 'packages')) {
      if (!_isBudgeted(rel)) {
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
          'Package size budget exceeded (>$failBudget lines). Split the file, '
          'or — only with a reason — add it to $baselinePath:\n'
          '${offenders.join('\n')}',
    );

    expect(
      stale.toList()..sort(),
      isEmpty,
      reason:
          'Stale package size-budget baseline entries (now within budget or '
          'deleted — remove them from $baselinePath):\n'
          '${(stale.toList()..sort()).join('\n')}',
    );

    expect(
      shrunk..sort(),
      isEmpty,
      reason:
          'These files shrank below their baseline — lower the recorded number '
          'in $baselinePath so the ratchet keeps its new floor:\n'
          '${shrunk.join('\n')}',
    );
  });
}

bool _isBudgeted(String rel) {
  if (!rel.contains('/lib/')) {
    return false;
  }
  if (rel.endsWith('.g.dart')) {
    return false;
  }
  final name = rel.split('/').last;
  // Data tables, not logic. Same exclusion QUALITY.md names for geoip.
  if (name == 'geoip_country_data.dart' || name == 'emoji_shortcodes.dart') {
    return false;
  }
  return true;
}

Map<String, int> _readBaseline(String projectRoot, String relPath) {
  final file = File('$projectRoot/$relPath');
  if (!file.existsSync()) {
    fail('Missing package size-budget baseline: $relPath');
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
    yield entity.path
        .substring(projectRoot.length + 1)
        .replaceAll(r'\', '/');
  }
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/packages').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
