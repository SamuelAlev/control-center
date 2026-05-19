/// Pure relatedness scoring + entity extraction for the episodic knowledge
/// graph, ported from oh-my-pi mnemopi `core/episodic-graph.ts`. The BFS
/// traversal itself lives in the DAO (it needs the edge table); this file is the
/// scoring used to *propose* edges on ingest.
library;

/// Relatedness at or above which two facts get linked on ingest.
const double episodicLinkThreshold = 0.35;

const Set<String> _stopwords = <String>{
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'and', 'or',
  'but', 'if', 'in', 'on', 'at', 'to', 'of', 'for', 'with', 'by', 'as', 'from',
  'this', 'that', 'these', 'those', 'it', 'its', 'they', 'them', 'their',
  'has', 'have', 'had', 'do', 'does', 'did', 'will', 'would', 'can', 'could',
};

/// Extracts capital-cased named entities ("Deploy Target", "Auth Service")
/// from [text]. Mirrors mnemopi's `\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b`.
Set<String> extractEntities(String text) {
  final matches = RegExp(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b').allMatches(text);
  return {for (final m in matches) m.group(0)!.toLowerCase()};
}

/// Significant lowercased tokens (stopword-filtered, length ≥ 3) for lexical
/// similarity.
Set<String> significantTokens(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 3 && !_stopwords.contains(t))
      .toSet();
}

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  var intersection = 0;
  for (final x in a) {
    if (b.contains(x)) {
      intersection++;
    }
  }
  return intersection / (a.length + b.length - intersection);
}

/// Entity overlap score: `|A ∩ B| / max(|A|, |B|)`. Mirrors mnemopi's
/// `overlapScore`.
double entityOverlap(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  var intersection = 0;
  for (final x in a) {
    if (b.contains(x)) {
      intersection++;
    }
  }
  final denom = a.length > b.length ? a.length : b.length;
  return intersection / denom;
}

/// Three-component relatedness for two fact contents, ported from mnemopi's
/// contextual score: `max(lexicalJaccard, entityOverlap, temporalMatch)`.
///
/// [temporalMatch] is 1.0 when the two facts share a temporal scope, else 0;
/// callers that don't track temporal scope pass false.
double relatednessScore(
  String contentA,
  String contentB, {
  bool temporalMatch = false,
}) {
  final lexical = _jaccard(significantTokens(contentA), significantTokens(contentB));
  final entities = entityOverlap(extractEntities(contentA), extractEntities(contentB));
  final temporal = temporalMatch ? 1.0 : 0.0;
  final scores = [lexical, entities, temporal];
  return scores.reduce((a, b) => a > b ? a : b);
}