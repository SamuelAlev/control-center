/// The fuzzy ranker behind the ⌘K omnibox (PRD 19 §1).
///
/// Pure Dart — no Flutter, no I/O — so the omnibox's first-paint results come
/// from a warm in-memory index that never awaits a round-trip (the <50ms
/// acceptance criterion is measured on this). A candidate matches when the
/// query is a case-insensitive subsequence of the text; the score rewards
/// prefix hits, word-boundary/camelCase hits and consecutive runs so
/// "gpr" ranks "Go to pull requests" above "Group project review".
library;

/// Scores one candidate string against a query. Returns null when [query] is
/// not a subsequence of [text] (no match). Higher scores rank first.
///
/// Empty query → score 0 (everything "matches" so the caller shows its default
/// ordering). The scorer is intentionally cheap (single pass, no allocation of
/// per-character structures) so ranking thousands of commands stays sub-frame.
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

/// Ranks [candidates] against [query], best first. [textOf] extracts the
/// searchable text (label + description + category, joined). [recencyOf]
/// returns a per-candidate recency rank (0 = most recent, higher = older,
/// [double.infinity] = never used) used to break score ties and to order an
/// empty query. Stable within equal (score, recency).
List<T> rankCommands<T>(
  String query,
  List<T> candidates, {
  required String Function(T) textOf,
  required double Function(T) recencyOf,
}) {
  final q = query.trim();
  final scored = <(T item, int score, double recency, int index)>[];
  for (var i = 0; i < candidates.length; i++) {
    final c = candidates[i];
    final score = q.isEmpty ? 0 : fuzzyScore(q, textOf(c));
    if (score == null) {
      continue;
    }
    scored.add((c, score, recencyOf(c), i));
  }
  scored.sort((a, b) {
    // Empty query: recency first, then original order (a stable, sensible
    // "recents on top" default). Non-empty: score first, then recency.
    if (q.isNotEmpty && a.$2 != b.$2) {
      return b.$2.compareTo(a.$2);
    }
    if (a.$3 != b.$3) {
      return a.$3.compareTo(b.$3);
    }
    return a.$4.compareTo(b.$4);
  });
  return [for (final s in scored) s.$1];
}
