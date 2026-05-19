import 'dart:io';

import 'package:test/test.dart';

/// Anti-growth ratchet for hardcoded, user-facing string literals in the UI
/// (FINDINGS §14.2).
///
/// CLAUDE.md: "All user-facing strings MUST be internationalized … NEVER
/// hardcode English text in widgets." This test greps `lib/` for the most
/// common violation shape — a `Text`/`CcText`/`SelectableText` widget built
/// straight from a string literal that looks like English prose (starts with a
/// letter, ≥3 chars, no `$` interpolation) — and fails if the count grows past
/// the recorded baseline.
///
/// The baseline tracks pre-existing debt (a few web/markdown surfaces). It is
/// NOT zero — the finding assumed zero from a sample, but a full scan found
/// these. Lowering the baseline means internationalizing those sites (§14.1).
/// NEVER raise it: route the new string through `AppLocalizations` instead.
///
/// This is a deliberately narrow, line-based heuristic favouring zero false
/// positives over exhaustiveness — it only catches the literal-in-`Text(`
/// shape, not every untranslated string (labels passed to other widgets, enum
/// display names, etc.). A precise gate would need analyzer-based AST parsing.
void main() {
  // Matches `Text('Word…')` / `CcText("Word…")` / `SelectableText('Word…')`
  // where the literal starts with a letter, is ≥3 chars, and contains no `$`
  // interpolation. The lookbehind rejects method calls like `getText('x')`
  // (the `t` before `Text` fails `(?<![A-Za-z_$.])`).
  final re = RegExp(
    r'''(?<![A-Za-z_$.])(?:Cc|Selectable)?Text\((['"])[A-Za-z][^'"$]{2,}\1''',
  );

  // The count after the observability redesign internationalized every
  // observability literal; the remainder is web/markdown surfaces. Anti-growth
  // only.
  const baseline = 4;

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

  test('no NEW hardcoded user-facing Text() literals in lib/', () {
    final offenders = <String>[];
    for (final entity in libDir().listSync(recursive: true)) {
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
