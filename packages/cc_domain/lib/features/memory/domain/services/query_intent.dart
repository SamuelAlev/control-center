/// Query-intent classification + per-intent recall-weight rebalancing, ported
/// from oh-my-pi mnemopi `core/query-intent.ts`.
library;

/// The intent category a recall query expresses.
enum QueryIntentCategory {
  /// "when did…", dates, "last week" — leans on FTS + temporal voices.
  temporal,

  /// "what is…", "who is…" — balanced fact lookup.
  factual,

  /// "tell me about X" — entity-centric, leans on importance.
  entity,

  /// "should I…", "prefer" — leans on importance/preferences.
  preference,

  /// "how to…", "configure/deploy" — leans on the vector voice.
  procedural,

  /// No strong signal.
  general,
}

/// The classified intent plus the multiplicative biases it applies to the
/// vector / FTS / importance signals.
class QueryIntent {
  /// Creates a [QueryIntent].
  const QueryIntent({
    required this.category,
    required this.confidence,
    required this.vecBias,
    required this.ftsBias,
    required this.importanceBias,
  });

  /// The dominant category.
  final QueryIntentCategory category;

  /// Classifier confidence in `[0,1]`.
  final double confidence;

  /// Multiplier on the vector voice weight.
  final double vecBias;

  /// Multiplier on the FTS/fact voice weight.
  final double ftsBias;

  /// Multiplier on the importance/temporal weight.
  final double importanceBias;
}

typedef _IntentRules = ({QueryIntentCategory category, List<RegExp> patterns});

({double vec, double fts, double importance}) _weightsFor(
  QueryIntentCategory category,
) {
  switch (category) {
    case QueryIntentCategory.temporal:
      return (vec: 0.6, fts: 1.5, importance: 0.8);
    case QueryIntentCategory.factual:
      return (vec: 1.0, fts: 1.2, importance: 0.9);
    case QueryIntentCategory.entity:
      return (vec: 1.1, fts: 1.0, importance: 1.3);
    case QueryIntentCategory.preference:
      return (vec: 0.9, fts: 0.8, importance: 1.5);
    case QueryIntentCategory.procedural:
      return (vec: 1.3, fts: 0.9, importance: 0.7);
    case QueryIntentCategory.general:
      return (vec: 1.0, fts: 1.0, importance: 1.0);
  }
}

List<RegExp> _compile(List<String> patterns) =>
    [for (final p in patterns) RegExp(p, caseSensitive: false)];

final List<_IntentRules> _intentRules = <_IntentRules>[
  (
    category: QueryIntentCategory.temporal,
    patterns: _compile([
      r'\b(when|last|yesterday|today|tomorrow|ago|before|after|since|until|during|recently|lately)\b',
      r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\b',
      r'\b\d{4}-\d{2}-\d{2}\b',
      r'\b(this|next|last)\s+(week|month|year)\b',
      r'\b\d+\s+(day|week|month|year|hour|minute)s?\s+(ago|from now|later|earlier)\b',
    ]),
  ),
  (
    category: QueryIntentCategory.factual,
    patterns: _compile([
      r'\bwhat\s+is\b',
      r'\bwho\s+is\b',
      r'\bwhere\s+is\b',
      r'\b(definition|define|explain|meaning)\b',
      r'\bhow\s+(many|much|long|far)\b',
    ]),
  ),
  (
    category: QueryIntentCategory.entity,
    patterns: _compile([
      r'\b(tell\s+me\s+about|what\s+do\s+you\s+know\s+about)\b',
      r'\b(about|regarding|concerning)\s+[a-z]+\b',
    ]),
  ),
  (
    category: QueryIntentCategory.preference,
    patterns: _compile([
      r'\b(prefer|like|dislike|want|hate|love|enjoy|favorite|best|worst)\b',
      r'\b(should\s+i|would\s+you|do\s+you\s+recommend)\b',
      r'\b(choose|pick|select|option|choice|decide)\b',
    ]),
  ),
  (
    category: QueryIntentCategory.procedural,
    patterns: _compile([
      r'\bhow\s+(to|do|does|can|should|would)\b',
      r'\b(step|process|procedure|workflow|guide|tutorial)\b',
      r'\b(setup|install|configure|build|deploy|run|execute|start|stop)\b',
    ]),
  ),
];

/// Classifies [query] into a [QueryIntent]. Each matching pattern adds 0.15 to a
/// per-category score (base 0.3, capped at 1.0); the highest-scoring category
/// wins, defaulting to [QueryIntentCategory.general]. Mirrors `classifyIntent`.
QueryIntent classifyIntent(String query) {
  final lower = query.toLowerCase();
  var best = QueryIntentCategory.general;
  var bestScore = 0.0;

  for (final rule in _intentRules) {
    var matches = 0;
    for (final pattern in rule.patterns) {
      if (pattern.hasMatch(lower)) {
        matches++;
      }
    }
    if (matches > 0) {
      final score = (0.3 + matches * 0.15).clamp(0.0, 1.0);
      if (score > bestScore) {
        bestScore = score;
        best = rule.category;
      }
    }
  }

  final w = _weightsFor(best);
  return QueryIntent(
    category: best,
    confidence: bestScore,
    vecBias: w.vec,
    ftsBias: w.fts,
    importanceBias: w.importance,
  );
}

/// Rebalances base voice weights by an [intent]'s biases and renormalizes them
/// to sum to 1. Returns `(vec, fts, importance)`. Mirrors `adjustWeights`.
({double vec, double fts, double importance}) adjustWeights({
  double baseVec = 0.5,
  double baseFts = 0.3,
  double baseImportance = 0.2,
  QueryIntent? intent,
}) {
  final vecBias = intent?.vecBias ?? 1.0;
  final ftsBias = intent?.ftsBias ?? 1.0;
  final importanceBias = intent?.importanceBias ?? 1.0;
  var vec = baseVec * vecBias;
  var fts = baseFts * ftsBias;
  var importance = baseImportance * importanceBias;
  final total = vec + fts + importance;
  if (total > 0) {
    vec /= total;
    fts /= total;
    importance /= total;
  }
  return (vec: vec, fts: fts, importance: importance);
}