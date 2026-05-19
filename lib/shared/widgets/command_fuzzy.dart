/// The fuzzy ranker behind the ⌘K omnibox (PRD 19 §1).
///
/// Pure Dart — no Flutter, no I/O — so the omnibox's first-paint results come
/// from a warm in-memory index that never awaits a round-trip (the <50ms
/// acceptance criterion is measured on this).
///
/// The SCORER itself now lives in `package:cc_ui/fuzzy.dart` and is re-exported
/// here, because the design system's own type-to-filter surfaces (a searchable
/// `CcMenu`, a `CcFilterMenu` flyout) rank with it too and cc_ui cannot import
/// the host app. That entrypoint imports nothing, so this library stays
/// Flutter-free. What remains here is [rankCommands] — the omnibox's
/// recency-aware ordering, which is app policy rather than design-system
/// vocabulary.
library;

import 'package:cc_ui/fuzzy.dart';

export 'package:cc_ui/fuzzy.dart' show fuzzyScore;

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
