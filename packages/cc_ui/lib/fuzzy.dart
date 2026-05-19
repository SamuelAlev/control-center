/// Subsequence fuzzy scoring — the ranker behind every type-to-filter surface
/// in the design system (a searchable [CcMenu], a [CcFilterMenu] flyout) and
/// behind the app's ⌘K omnibox.
///
/// A SEPARATE ENTRYPOINT, deliberately: this library imports nothing at all, so
/// a Flutter-free consumer (a pure-Dart ranker, a benchmark, an isolate worker)
/// can `import 'package:cc_ui/fuzzy.dart'` without pulling the widget layer in
/// behind it. The `cc_ui.dart` barrel re-exports it for the common case.
library;

/// Scores one candidate string against a query. Returns null when [query] is
/// not a subsequence of [text] (no match). Higher scores rank first.
///
/// A candidate matches when the query is a case-insensitive subsequence of the
/// text; the score rewards prefix hits, word-boundary/camelCase hits and
/// consecutive runs, so "gpr" ranks "Go to pull requests" above "Group project
/// review".
///
/// Empty query → score 0 (everything "matches" so the caller shows its default
/// ordering). The scorer is intentionally cheap (single pass, no allocation of
/// per-character structures) so ranking thousands of candidates stays sub-frame.
int? fuzzyScore(String query, String text) {
  if (query.isEmpty) {
    return 0;
  }
  if (text.isEmpty) {
    return null;
  }
  final q = query.toLowerCase();
  final t = text.toLowerCase();

  var score = 0;
  var qi = 0;
  var run = 0; // length of the current consecutive-match run
  var prevMatchIdx = -2;
  for (var ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t.codeUnitAt(ti) == q.codeUnitAt(qi)) {
      var bonus = 1;
      // Consecutive matches compound — a contiguous substring is the best hit.
      if (ti == prevMatchIdx + 1) {
        run++;
        bonus += run * 4;
      } else {
        run = 0;
      }
      // Start-of-string and word/camelCase boundaries are strong signals.
      if (ti == 0) {
        bonus += 12;
      } else {
        final before = text[ti - 1];
        final here = text[ti];
        final atWordStart =
            before == ' ' ||
            before == '/' ||
            before == '.' ||
            before == '-' ||
            before == '_' ||
            before == ':';
        final atCamel =
            before.toLowerCase() == before &&
            here.toUpperCase() == here &&
            here.toLowerCase() != here;
        if (atWordStart || atCamel) {
          bonus += 8;
        }
      }
      score += bonus;
      prevMatchIdx = ti;
      qi++;
    }
  }
  if (qi < q.length) {
    return null; // not all query chars consumed — not a subsequence
  }
  // Prefer shorter targets on ties (less "noise" around the match).
  score -= (t.length - q.length) ~/ 8;
  return score;
}
