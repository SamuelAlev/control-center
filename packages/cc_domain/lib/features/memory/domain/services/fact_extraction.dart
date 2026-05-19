import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';

/// A subject-predicate-object knowledge-graph triple extracted from text.
class KgTriple {
  /// Creates a [KgTriple].
  const KgTriple({required this.subject, required this.predicate, required this.object});

  /// The subject (entity).
  final String subject;
  /// The predicate (relation).
  final String predicate;
  /// The object (value/entity).
  final String object;
}

/// A single extracted item with its inferred [MemoryType].
class ExtractedItem {
  /// Creates an [ExtractedItem].
  const ExtractedItem({required this.content, required this.type});

  /// The natural-language statement.
  final String content;
  /// The memory type to file it under.
  final MemoryType type;
}

/// Structured result of running extraction over a piece of text. Mirrors the
/// `{facts, instructions, preferences, timelines, kg}` shape from mnemopi
/// `core/extraction.ts`.
class ExtractionResult {
  /// Creates an [ExtractionResult].
  const ExtractionResult({
    this.facts = const [],
    this.instructions = const [],
    this.preferences = const [],
    this.timelines = const [],
    this.triples = const [],
  });

  /// An empty result.
  static const ExtractionResult empty = ExtractionResult();

  /// Persistent facts.
  final List<String> facts;
  /// Rules/commands directed at the agent.
  final List<String> instructions;
  /// Likes/dislikes.
  final List<String> preferences;
  /// Dated events.
  final List<String> timelines;
  /// Knowledge-graph triples.
  final List<KgTriple> triples;

  /// Whether nothing was extracted.
  bool get isEmpty =>
      facts.isEmpty &&
      instructions.isEmpty &&
      preferences.isEmpty &&
      timelines.isEmpty &&
      triples.isEmpty;

  /// Flattens facts/instructions/preferences/timelines into typed items, ready
  /// to record as memory facts.
  List<ExtractedItem> toTypedItems() => <ExtractedItem>[
        for (final f in facts) ExtractedItem(content: f, type: MemoryType.fact),
        for (final i in instructions)
          ExtractedItem(content: i, type: MemoryType.instruction),
        for (final p in preferences)
          ExtractedItem(content: p, type: MemoryType.preference),
        for (final t in timelines) ExtractedItem(content: t, type: MemoryType.event),
      ];
}

/// Optional host-supplied LLM extractor. When wired, it takes precedence over
/// the heuristic fallback. CC has no host LLM port in the memory subsystem
/// today, so this is the seam a future host fills.
abstract class FactExtractorPort {
  /// Extracts structured memory from [text], or returns null to fall back to
  /// the heuristic path.
  Future<ExtractionResult?> extract(String text);
}

typedef _HeuristicRule = ({RegExp pattern, String template, MemoryType type, String bucket});

({RegExp pattern, String template, MemoryType type, String bucket}) _h(
  String pattern,
  String template,
  MemoryType type,
  String bucket,
) =>
    (pattern: RegExp(pattern, caseSensitive: false), template: template, type: type, bucket: bucket);

// Ported from mnemopi `heuristicExtractFacts`. `{}` in the template is the first
// capture group. `bucket` routes the item to the right result list.
final List<_HeuristicRule> _heuristicRules = <_HeuristicRule>[
  _h(r'\bmy name is\s+([^,.!?;]+)', "The user's name is {}", MemoryType.fact, 'fact'),
  _h(r'\bi (?:am|work as)\s+(?:an?\s+)?([^,.!?;]+)', 'The user is {}', MemoryType.fact, 'fact'),
  _h(r'\bi work (?:at|for)\s+([^,.!?;]+)', 'The user works at {}', MemoryType.fact, 'fact'),
  _h(r'\bi (?:live in|am based in)\s+([^,.!?;]+)', 'The user lives in {}', MemoryType.fact, 'fact'),
  _h(r'\bi (?:use|am using)\s+([^,.!?;]+)', 'The user uses {}', MemoryType.preference, 'preference'),
  _h(r'\bi (?:like|love|prefer|enjoy)\s+([^,.!?;]+)', 'The user prefers {}', MemoryType.preference, 'preference'),
  _h(r"\bi (?:hate|dislike|do not like|don't like)\s+([^,.!?;]+)", 'The user dislikes {}', MemoryType.preference, 'preference'),
  _h(r'\b(?:i|you)\s+(?:always|never)\s+([^,.!?;]+)', 'Instruction: {}', MemoryType.instruction, 'instruction'),
];

/// Deterministic regex extraction over [text]. Always available (no LLM), so it
/// is the floor of the precedence chain. Mirrors mnemopi's heuristic fallback.
ExtractionResult heuristicExtract(String text) {
  final facts = <String>[];
  final instructions = <String>[];
  final preferences = <String>[];
  for (final rule in _heuristicRules) {
    final match = rule.pattern.firstMatch(text);
    if (match == null) {
      continue;
    }
    final captured = (match.group(1) ?? '').trim();
    if (captured.isEmpty) {
      continue;
    }
    final statement = rule.template.replaceFirst('{}', captured);
    switch (rule.bucket) {
      case 'instruction':
        instructions.add(statement);
      case 'preference':
        preferences.add(statement);
      default:
        facts.add(statement);
    }
  }
  return ExtractionResult(
    facts: facts,
    instructions: instructions,
    preferences: preferences,
  );
}

/// Runs the extraction precedence chain: optional host LLM port →
/// deterministic heuristic. Mirrors the spirit of mnemopi's
/// host-LLM → local-LLM → heuristic chain (CC has no local LLM, so the chain is
/// host → heuristic).
class MemoryExtractor {
  /// Creates a [MemoryExtractor] with an optional LLM extractor `port`.
  const MemoryExtractor({FactExtractorPort? port}) : _port = port;

  final FactExtractorPort? _port;

  /// Extracts structured memory from [text].
  Future<ExtractionResult> extract(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return ExtractionResult.empty;
    }
    final port = _port;
    if (port != null) {
      try {
        final result = await port.extract(trimmed);
        if (result != null && !result.isEmpty) {
          return result;
        }
      } on Object {
        // Fall through to the heuristic on any LLM failure.
      }
    }
    return heuristicExtract(trimmed);
  }
}