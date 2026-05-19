import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';

/// Result of classifying a piece of text into a [MemoryType].
class TypeMatch {
  /// Creates a [TypeMatch].
  const TypeMatch({
    required this.memoryType,
    required this.confidence,
    required this.matchedPattern,
  });

  /// The inferred type.
  final MemoryType memoryType;

  /// Classifier confidence in `[0,1]`.
  final double confidence;

  /// A short label of the pattern that matched (for diagnostics).
  final String matchedPattern;
}

/// A single classification rule: a case-insensitive regex, the type it implies,
/// and a base confidence.
typedef _TypeRule = ({RegExp pattern, MemoryType type, double base});

({RegExp pattern, MemoryType type, double base}) _rule(
  String pattern,
  MemoryType type,
  double base,
) =>
    (pattern: RegExp(pattern, caseSensitive: false), type: type, base: base);

/// Heuristic memory-type rules, ported from oh-my-pi mnemopi
/// `core/typed-memory.ts` `TYPE_PATTERNS`. Order matters only as a tie-break
/// input via [MemoryType.rankPriority].
final List<_TypeRule> _rules = <_TypeRule>[
  // FACT
  _rule(r'\b(is|are|was|were)\s+(a|an|the)\s+\w+', MemoryType.fact, 0.6),
  _rule(r'\b(has|have|had)\s+\d+', MemoryType.fact, 0.7),
  _rule(r'\b(contains|consists?|comprises?)\b', MemoryType.fact, 0.8),
  _rule(r'\b(version|v)\s*\d+\.?\d*', MemoryType.fact, 0.9),
  _rule(r'\b(API|endpoint|URL|database|DB)\s+(is|at|points?\s+to)', MemoryType.fact, 0.8),
  // PREFERENCE
  _rule(r'\b(prefer|likes?|enjoys?|loves?|hates?|dislikes?)\b', MemoryType.preference, 0.8),
  _rule(r'\b(want|wants|wanted)\s+(to|the|a|an)\b', MemoryType.preference, 0.6),
  _rule(r'\b(dark\s+mode|light\s+mode|theme|color\s+scheme)\b', MemoryType.preference, 0.9),
  _rule(r'\b(usually|typically|normally|generally)\b', MemoryType.preference, 0.6),
  // DECISION
  _rule(r'\b(decided|chose|selected|picked|opted)\b', MemoryType.decision, 0.9),
  _rule(r'\b(going\s+with|settled\s+on|locked\s+in)\b', MemoryType.decision, 0.8),
  _rule(r'\b(final\s+decision|final\s+call|final\s+choice)\b', MemoryType.decision, 0.9),
  _rule(r'\b(will\s+use|using|adopt|adopting)\s+(the|a|an)?\s*\w+', MemoryType.decision, 0.7),
  // COMMITMENT
  _rule(r'\b(will|shall|must|need\s+to)\s+\w+\s+(by|before|until)\b', MemoryType.commitment, 0.8),
  _rule(r'\b(deadline|due\s+date|due|milestone)\b', MemoryType.commitment, 0.9),
  _rule(r'\b(promise|committed|pledged|obligated)\b', MemoryType.commitment, 0.9),
  _rule(r'\b(deliver|ship|release|deploy)\s+(by|before|on)\b', MemoryType.commitment, 0.8),
  _rule(r'\b(EOD|COB|end\s+of\s+day|close\s+of\s+business)\b', MemoryType.commitment, 0.7),
  // GOAL
  _rule(r'\b(goal|objective|target|aim|purpose)\b', MemoryType.goal, 0.9),
  _rule(r'\b(achieve|reach|hit|attain|accomplish)\s+\d+', MemoryType.goal, 0.8),
  _rule(r'\b(KPI|metric|OKR|success\s+criteria)\b', MemoryType.goal, 0.9),
  _rule(r'\b(roadmap|plan|strategy)\s+(for|to)\b', MemoryType.goal, 0.7),
  // EVENT
  _rule(r'\b(meeting|call|discussion|conversation)\s+(with|about)\b', MemoryType.event, 0.7),
  _rule(r'\b(happened|occurred|took\s+place)\b', MemoryType.event, 0.8),
  _rule(r'\b(yesterday|last\s+week|last\s+month|earlier\s+today)\b', MemoryType.event, 0.6),
  _rule(r'\b(incident|outage|bug|issue)\s+#?\d+', MemoryType.event, 0.8),
  _rule(r'\b(launched|released|shipped|deployed)\s+(on|at)\b', MemoryType.event, 0.8),
  // INSTRUCTION
  _rule(r"\b(always|never|must|should|shall|do\s+not|don't)\b", MemoryType.instruction, 0.7),
  _rule(r'\b(rule|policy|guideline|procedure|protocol)\b', MemoryType.instruction, 0.9),
  _rule(r'\b(how\s+to|steps?\s+to|guide\s+to|tutorial)\b', MemoryType.instruction, 0.8),
  _rule(r'\b(remember\s+to|make\s+sure|ensure|verify)\b', MemoryType.instruction, 0.6),
  // RELATIONSHIP
  _rule(r'\b(manages?|reports?\s+to|supervises?|leads?)\b', MemoryType.relationship, 0.9),
  _rule(r'\b(owns?|belongs?\s+to|part\s+of|member\s+of)\b', MemoryType.relationship, 0.8),
  _rule(r'\b(works?\s+with|collaborates?\s+with|partners?\s+with)\b', MemoryType.relationship, 0.8),
  _rule(r'\b(depends?\s+on|requires?|needs?)\b', MemoryType.relationship, 0.7),
  // CONTEXT
  _rule(r'\b(currently|right\s+now|at\s+the\s+moment|presently)\b', MemoryType.context, 0.7),
  _rule(r'\b(working\s+on|focusing\s+on|dealing\s+with)\b', MemoryType.context, 0.8),
  _rule(r'\b(in\s+progress|ongoing|active|pending|blocked)\b', MemoryType.context, 0.8),
  _rule(r'\b(environment|setup|configuration|settings?)\b', MemoryType.context, 0.6),
  // LEARNING
  _rule(r'\b(learned|realized|discovered|found\s+out)\b', MemoryType.learning, 0.8),
  _rule(r'\b(lesson|takeaway|insight|finding)\b', MemoryType.learning, 0.9),
  _rule(r'\b(turns?\s+out|surprisingly|interestingly)\b', MemoryType.learning, 0.7),
  _rule(r'\b(best\s+practice|lessons?\s+learned|post[-\s]?mortem)\b', MemoryType.learning, 0.9),
  // OBSERVATION
  _rule(r'\b(noticed|observed|saw|seems?)\b', MemoryType.observation, 0.7),
  _rule(r'\b(pattern|trend|correlation|tends?\s+to)\b', MemoryType.observation, 0.9),
  _rule(r'\b(often|frequently|sometimes|rarely)\s+\w+', MemoryType.observation, 0.6),
  _rule(r'\b(every\s+time|whenever|each\s+time)\b', MemoryType.observation, 0.8),
  // ERROR
  _rule(r'\b(error|bug|issue|problem|failure|crash)\b', MemoryType.error, 0.7),
  _rule(r"\b(broke|broken|failed|failing|doesn't\s+work)\b", MemoryType.error, 0.8),
  _rule(r'\b(deprecated|obsolete|legacy|outdated)\b', MemoryType.error, 0.8),
  _rule(r'\b(exception|timeout|crash|hang|freeze)\b', MemoryType.error, 0.8),
  _rule(r'\b(workaround|hotfix|patch|kludge)\b', MemoryType.error, 0.7),
  // ARTIFACT
  _rule(r'\b(document|doc|spreadsheet|sheet|slide)\b', MemoryType.artifact, 0.6),
  _rule(r'\b(file|folder|directory|path)\s+(name|called|at)\b', MemoryType.artifact, 0.7),
  _rule(r'\b(PR|pull\s+request|issue|ticket)\s+#?\d+', MemoryType.artifact, 0.9),
  _rule(r'\b(commit|branch|tag|release)\s+[a-f0-9]{7,40}\b', MemoryType.artifact, 0.9),
  _rule(r'\b(README|CHANGELOG|LICENSE|CONTRIBUTING)\b', MemoryType.artifact, 0.9),
];

/// Per-type words that bump confidence by 0.05 when present.
const Map<MemoryType, List<String>> _confidenceBoosters = <MemoryType, List<String>>{
  MemoryType.fact: ['verified', 'confirmed', 'official', 'documented', 'according to'],
  MemoryType.preference: ['always', 'never', 'absolutely', 'definitely', 'strongly'],
  MemoryType.decision: ['final', 'official', 'approved', 'agreed', 'consensus'],
  MemoryType.commitment: ['promise', 'guarantee', 'committed', 'deadline', 'sla'],
  MemoryType.goal: ['target', 'objective', 'kpi', 'okr'],
  MemoryType.event: ['specifically', 'exactly', 'precisely'],
  MemoryType.instruction: ['mandatory', 'required', 'critical', 'important'],
  MemoryType.relationship: ['directly', 'reports to', 'managed by', 'owned by'],
  MemoryType.context: ['currently', 'right now', 'active', 'in progress'],
  MemoryType.learning: ['key lesson', 'important finding', 'critical insight'],
  MemoryType.observation: ['consistently', 'repeatedly', 'over time', 'pattern'],
  MemoryType.error: ['critical', 'severe', 'blocking', 'p0', 'p1'],
  MemoryType.artifact: ['official', 'canonical', 'source of truth', 'reference'],
};

/// Classifies free text into a [MemoryType] with a confidence score, ported
/// from mnemopi `classifyMemory`. Used to auto-type facts that arrive without an
/// explicit type (so Weibull decay and surfacing behave per-type).
TypeMatch classifyMemory(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    return const TypeMatch(
      memoryType: MemoryType.unknown,
      confidence: 0,
      matchedPattern: '',
    );
  }
  final lower = trimmed.toLowerCase();
  TypeMatch? best;
  var bestScore = 0.0;

  for (final rule in _rules) {
    final match = rule.pattern.firstMatch(lower);
    if (match == null) {
      continue;
    }
    var confidence = rule.base;
    final matchText = match.group(0) ?? '';
    if (matchText.length > 20) {
      confidence += 0.1;
    } else if (matchText.length > 10) {
      confidence += 0.05;
    }
    for (final booster in _confidenceBoosters[rule.type] ?? const <String>[]) {
      if (lower.contains(booster)) {
        confidence += 0.05;
      }
    }
    if (confidence > 1.0) {
      confidence = 1.0;
    }
    // Bias toward higher-priority types when confidence ties, mirroring the
    // reference's index-based score nudge.
    final score = confidence * (1.0 + 0.02 * rule.type.rankPriority);
    if (score > bestScore) {
      bestScore = score;
      best = TypeMatch(
        memoryType: rule.type,
        confidence: confidence,
        matchedPattern: rule.pattern.pattern,
      );
    }
  }

  if (best != null) {
    return best;
  }
  // No rule matched: short text → a bare fact, longer text → situational context.
  final wordCount = trimmed.split(RegExp(r'\s+')).length;
  return wordCount < 5
      ? const TypeMatch(memoryType: MemoryType.fact, confidence: 0.3, matchedPattern: 'default_short')
      : const TypeMatch(memoryType: MemoryType.context, confidence: 0.3, matchedPattern: 'default_long');
}
