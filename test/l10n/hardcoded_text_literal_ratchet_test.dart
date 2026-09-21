import 'dart:io';

import 'package:test/test.dart';

/// Anti-growth ratchet for English string literals in `Text`/`CcText`/
/// `SelectableText`. Baseline is pre-existing debt — never raise it; lower by
/// routing through `AppLocalizations`. Narrow heuristic (literal-in-Text only).
void main() {
  // Matches `Text('Word…')` / `CcText("Word…")` / `SelectableText('Word…')`
  // where the literal starts with a letter, is ≥3 chars and contains no `$`
  // interpolation. The lookbehind rejects method calls like `getText('x')`
  // (the `t` before `Text` fails `(?<![A-Za-z_$.])`).
  final re = RegExp(
    r'''(?<![A-Za-z_$.])(?:Cc|Selectable)?Text\((['"])[A-Za-z][^'"$]{2,}\1''',
  );

  // Known Text()/CcText() prose literals in lib/ and apps/cc_remote/lib are
  // gone. Anti-growth only — never raise this.
  const baseline = 0;

  // Resolve the lib/ dir whether run from the repo root or elsewhere.
  Directory libDir() {
    final here = Directory('lib');
    if (here.existsSync()) {
      return here;
    }
    // Fallback: walk up until a `lib/` with a `main.dart` is found.
    var dir = Directory.current;
    while (true) {
      final candidate = Directory('${dir.path}/lib');
      if (candidate.existsSync() &&
          File('${candidate.path}/main.dart').existsSync()) {
        return candidate;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return here; // give up; the test will simply find nothing.
      }
      dir = parent;
    }
  }

  Iterable<Directory> scanRoots() {
    final lib = libDir();
    final roots = <Directory>[lib];
    final remote = Directory('${lib.parent.path}/apps/cc_remote/lib');
    if (remote.existsSync()) {
      roots.add(remote);
    }
    return roots;
  }

  test('no NEW hardcoded user-facing Text() literals in lib/ or cc_remote', () {
    final offenders = <String>[];
    for (final root in scanRoots()) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File ||
            !entity.path.endsWith('.dart') ||
            entity.path.endsWith('.g.dart')) {
          continue;
        }
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (re.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
    }

    expect(
      offenders.length,
      lessThanOrEqualTo(baseline),
      reason:
          'Hardcoded user-facing Text() literal(s) found: ${offenders.length} '
          '(baseline $baseline). Every user-facing string must go through '
          '`AppLocalizations` (CLAUDE.md). Do NOT raise the baseline — '
          'internationalize the new string instead. If you removed some, lower '
          'the baseline to the new count in the same commit.\n'
          '${offenders.join('\n')}',
    );
  });
}
