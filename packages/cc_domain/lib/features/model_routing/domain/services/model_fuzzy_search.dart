// ignore_for_file: avoid_classes_with_only_static_members

/// A fuzzy model-id picker.
///
/// First tries a subsequence fuzzy match (rewarding contiguous, early and
/// word-boundary matches); if nothing matches, falls back to token-substring
/// scoring. Returns up to `limit` candidate ids, best first.
abstract final class ModelFuzzySearch {
  /// Ranks [candidates] against [query]. Empty query returns the first [limit]
  /// candidates unchanged.
  static List<String> search(
    String query,
    List<String> candidates, {
    int limit = 8,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return candidates.take(limit).toList();
    }

    final fuzzy = <_Hit>[];
    for (final c in candidates) {
      final score = _fuzzyScore(q, c.toLowerCase());
      if (score != null) {
        fuzzy.add(_Hit(c, score));
      }
    }
    if (fuzzy.isNotEmpty) {
      fuzzy.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        return cmp != 0 ? cmp : a.value.compareTo(b.value);
      });
      return [for (final h in fuzzy.take(limit)) h.value];
    }

    // Fallback: token-substring scoring.
    final parts = q
        .split(RegExp('[^a-z0-9]+'))
        .where((p) => p.length > 1)
        .toList();
    if (parts.isEmpty) {
      return const [];
    }
    final scored = <_Hit>[];
    for (final c in candidates) {
      final lc = c.toLowerCase();
      final hits = parts.where(lc.contains).length;
      if (hits > 0) {
        scored.add(_Hit(c, hits.toDouble()));
      }
    }
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.value.compareTo(b.value);
    });
    return [for (final h in scored.take(limit)) h.value];
  }

  /// Returns a fuzzy score (higher = better) if [query] is a subsequence of
  /// [target], else null. Rewards contiguous runs, matches right after a
  /// separator and a prefix match.
  static double? _fuzzyScore(String query, String target) {
    var ti = 0;
    var score = 0.0;
    var prevMatchIdx = -2;
    var consecutive = 0;
    for (var qi = 0; qi < query.length; qi++) {
      final qc = query.codeUnitAt(qi);
      var found = -1;
      for (var k = ti; k < target.length; k++) {
        if (target.codeUnitAt(k) == qc) {
          found = k;
          break;
        }
      }
      if (found < 0) {
        return null; // not a subsequence
      }
      score += 1;
      if (found == prevMatchIdx + 1) {
        consecutive += 1;
        score += consecutive * 2; // reward contiguous runs
      } else {
        consecutive = 0;
      }
      if (found == 0) {
        score += 3; // prefix
      } else {
        final before = target.codeUnitAt(found - 1);
        if (before == 0x2f /* / */ ||
            before == 0x2d /* - */ ||
            before == 0x5f /* _ */ ||
            before == 0x2e /* . */ ) {
          score += 2; // word boundary
        }
      }
      prevMatchIdx = found;
      ti = found + 1;
    }
    // Prefer shorter targets (less leftover noise).
    score -= (target.length - query.length) * 0.05;
    return score;
  }
}

class _Hit {
  _Hit(this.value, this.score);

  final String value;
  final double score;
}
