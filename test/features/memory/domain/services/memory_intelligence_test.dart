import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/services/binary_vectors.dart';
import 'package:cc_domain/features/memory/domain/services/conflict_detector.dart';
import 'package:cc_domain/features/memory/domain/services/episodic_graph.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_classifier.dart';
import 'package:cc_domain/features/memory/domain/services/memory_mmr.dart';
import 'package:cc_domain/features/memory/domain/services/polyphonic_recall.dart';
import 'package:cc_domain/features/memory/domain/services/query_intent.dart';
import 'package:cc_domain/features/memory/domain/services/shmr_harmonizer.dart';
import 'package:cc_domain/features/memory/domain/services/weibull_decay.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryFact _fact({
  required String id,
  String topic = 'deploy target',
  String content = 'prod',
  double confidence = 1.0,
  MemoryType type = MemoryType.fact,
  MemoryVeracity veracity = MemoryVeracity.stated,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2025, 6, 1);
  return MemoryFact(
    id: id,
    workspaceId: 'ws',
    domain: 'deployment',
    topic: topic,
    content: content,
    confidence: confidence,
    memoryType: type,
    veracity: veracity,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Weibull decay (phase 4.2)', () {
    test('a fresh memory boosts ~1.0', () {
      final now = DateTime(2025, 6, 1, 12);
      final boost = weibullBoost(now, now: now, memoryType: MemoryType.fact);
      expect(boost, closeTo(1.0, 0.001));
    });

    test('AC: a 30-day-old request ranks below a fresh fact', () {
      final now = DateTime(2025, 6, 1);
      final old = now.subtract(const Duration(days: 30));
      final staleRequest =
          weibullBoost(old, now: now, memoryType: MemoryType.request);
      final freshFact =
          weibullBoost(now, now: now, memoryType: MemoryType.fact);
      expect(staleRequest, lessThan(freshFact));
      // request has eta=72h → 30 days is far past its scale → near-zero.
      expect(staleRequest, lessThan(0.05));
    });

    test('a future timestamp returns 1.0, a null returns 0.0', () {
      final now = DateTime(2025, 6, 1);
      expect(weibullBoost(now.add(const Duration(days: 1)), now: now), 1.0);
      expect(weibullBoost(null, now: now), 0.0);
    });
  });

  group('Veracity + Bayesian confidence (phase 4.1)', () {
    test('base confidence is weight * 0.5', () {
      expect(baseConfidenceFor(MemoryVeracity.stated), closeTo(0.5, 0.0001));
      expect(baseConfidenceFor(MemoryVeracity.tool), closeTo(0.25, 0.0001));
    });

    test('re-mention raises confidence toward 1.0, never above', () {
      var c = 0.5;
      for (var i = 0; i < 50; i++) {
        c = bayesianUpdate(c, MemoryVeracity.stated);
      }
      expect(c, lessThanOrEqualTo(1.0));
      expect(c, greaterThan(0.9));
    });

    test('higher veracity bumps faster', () {
      final stated = bayesianUpdate(0.5, MemoryVeracity.stated);
      final tool = bayesianUpdate(0.5, MemoryVeracity.tool);
      expect(stated, greaterThan(tool));
    });
  });

  group('Conflict detection (phase 4.1)', () {
    test('AC: contradictory content on same topic is a conflict; old loses', () {
      final older = _fact(
        id: 'old',
        content: 'deploy target is prod',
        createdAt: DateTime(2025, 5, 1),
      );
      final newer = _fact(
        id: 'new',
        content: 'deploy target is staging',
        createdAt: DateTime(2025, 6, 1),
      );
      final decisions = detectConflicts(newer, [older]);
      expect(decisions, hasLength(1));
      // equal weighted confidence → newer wins, older superseded.
      expect(decisions.single.winner.id, 'new');
      expect(decisions.single.loser.id, 'old');
    });

    test('identical content is a dedup, not a conflict', () {
      final a = _fact(id: 'a', content: 'deploy target is prod');
      final b = _fact(id: 'b', content: 'deploy target is prod');
      expect(detectConflicts(b, [a]), isEmpty);
    });

    test('higher veracity-weighted confidence wins regardless of recency', () {
      final trusted = _fact(
        id: 'trusted',
        content: 'the primary database is postgres',
        veracity: MemoryVeracity.stated,
        confidence: 0.9,
        createdAt: DateTime(2025, 5, 1),
      );
      final weak = _fact(
        id: 'weak',
        content: 'the primary database is mysql',
        veracity: MemoryVeracity.tool,
        confidence: 0.9,
        createdAt: DateTime(2025, 6, 1),
      );
      final decisions = detectConflicts(weak, [trusted]);
      expect(decisions.single.winner.id, 'trusted');
    });
  });

  group('Typed memory classifier (phase 4.1 / feature #10)', () {
    test('classifies a decision', () {
      final m = classifyMemory('We decided to go with Postgres');
      expect(m.memoryType, MemoryType.decision);
    });

    test('classifies a preference', () {
      final m = classifyMemory('The user prefers dark mode');
      expect(m.memoryType, MemoryType.preference);
    });

    test('classifies an error', () {
      final m = classifyMemory('The build failed with a timeout exception');
      expect(m.memoryType, MemoryType.error);
    });
  });

  group('Query intent (phase 4.3 / feature #6)', () {
    test('AC: "what did we decide last week" leans temporal (high FTS bias)', () {
      final intent = classifyIntent('what did we decide last week');
      expect(intent.category, QueryIntentCategory.temporal);
      expect(intent.ftsBias, greaterThan(intent.vecBias));
    });

    test('AC: "how does auth work" leans procedural (high vector bias)', () {
      final intent = classifyIntent('how does auth work');
      expect(intent.category, QueryIntentCategory.procedural);
      expect(intent.vecBias, greaterThan(intent.ftsBias));
    });

    test('weights renormalize to ~1.0', () {
      final w = adjustWeights(intent: classifyIntent('how do I deploy'));
      expect(w.vec + w.fts + w.importance, closeTo(1.0, 0.0001));
    });
  });

  group('MMR diversity (phase 4.3 / feature #7)', () {
    test('suppresses near-duplicate paraphrases', () {
      final items = [
        const MmrItem(value: 'a', score: 1.0, content: 'the server runs on port 8080'),
        const MmrItem(value: 'b', score: 0.99, content: 'server runs on port 8080'),
        const MmrItem(value: 'c', score: 0.8, content: 'deploys happen every friday afternoon'),
      ];
      final ranked = mmrRerank(items, topK: 2);
      // The near-duplicate 'b' should be passed over for the diverse 'c'.
      expect(ranked, ['a', 'c']);
    });
  });

  group('Binary vectors + Hamming (phase 4.7 / feature #8)', () {
    test('identical vectors have zero Hamming distance and score 1.0', () {
      final v = [0.5, -0.2, 0.9, -0.1, 0.3, 0.7, -0.8, 0.2];
      final a = binarizeEmbedding(v);
      final b = binarizeEmbedding(v);
      expect(hammingDistance(a, b), 0);
      expect(hammingScore(0, v.length), 1.0);
    });

    test('opposite-sign vectors are maximally distant', () {
      final v = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
      final inv = [-0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5];
      final a = binarizeEmbedding(v);
      final b = binarizeEmbedding(inv);
      expect(hammingDistance(a, b), 8);
    });

    test('cosine similarity is 1.0 for identical, -1.0 for opposite', () {
      expect(cosineSimilarity([1, 2, 3], [1, 2, 3]), closeTo(1.0, 0.0001));
      expect(cosineSimilarity([1, 2, 3], [-1, -2, -3]), closeTo(-1.0, 0.0001));
    });
  });

  group('Episodic relatedness (phase 4.5)', () {
    test('shared entities raise relatedness above the link threshold', () {
      final score = relatednessScore(
        'The Auth Service validates JWT tokens',
        'The Auth Service rotates refresh tokens',
      );
      expect(score, greaterThanOrEqualTo(episodicLinkThreshold));
    });

    test('unrelated content stays below the threshold', () {
      final score = relatednessScore(
        'The weather is sunny today',
        'Quarterly revenue grew by twelve percent',
      );
      expect(score, lessThan(episodicLinkThreshold));
    });
  });

  group('SHMR harmonization (phase 4.6 / feature #11)', () {
    test('AC: two agents asserting contradictory facts → contradiction flagged', () {
      final items = [
        const ShmrItem(
          factId: 'a',
          agentId: 'agent-1',
          topic: 'deploy target',
          content: 'the deploy target is production',
          confidence: 0.9,
        ),
        const ShmrItem(
          factId: 'b',
          agentId: 'agent-2',
          topic: 'deploy target',
          content: 'the deploy target is staging environment',
          confidence: 0.9,
        ),
      ];
      final result = harmonize(items);
      expect(result.contradictions, isNotEmpty);
      final c = result.contradictions.first;
      expect({c.itemA.agentId, c.itemB.agentId}, {'agent-1', 'agent-2'});
    });

    test('corroborating facts from two agents emit a belief', () {
      final items = [
        const ShmrItem(
          factId: 'a',
          agentId: 'agent-1',
          topic: 'api base',
          content: 'the api base url is https://api.example.com',
          confidence: 0.8,
        ),
        const ShmrItem(
          factId: 'b',
          agentId: 'agent-2',
          topic: 'api base',
          content: 'the api base url is https://api.example.com',
          confidence: 0.8,
        ),
      ];
      final result = harmonize(items);
      expect(result.beliefs, isNotEmpty);
      expect(result.beliefs.first.confidence, greaterThan(0.8));
      expect(result.beliefs.first.provenanceAgentIds, containsAll(['agent-1', 'agent-2']));
    });
  });

  group('Heuristic extraction (phase 4.4 / feature #9)', () {
    test('AC: conversation text yields facts without explicit remember', () {
      final result = heuristicExtract(
        'my name is Sam and I work at Frontify. I prefer dark mode.',
      );
      expect(result.isEmpty, isFalse);
      final all = result.toTypedItems().map((i) => i.content).join(' | ');
      expect(all.toLowerCase(), contains('sam'));
      expect(all.toLowerCase(), contains('frontify'));
      // "I prefer dark mode" → a preference.
      expect(
        result.preferences.any((p) => p.toLowerCase().contains('dark mode')),
        isTrue,
      );
    });

    test('empty/uninformative text extracts nothing', () {
      expect(heuristicExtract('the sky is blue today').isEmpty, isTrue);
    });
  });

  group('Polyphonic fusion (phase 4.3 / feature #5)', () {
    test('AC: Weibull decay sinks a stale request below a fresh fact', () {
      final now = DateTime(2025, 6, 1);
      final candidates = {
        'fresh': RecallCandidate<String>(
          id: 'fresh',
          value: 'fresh',
          content: 'deployment uses blue green strategy',
          memoryType: MemoryType.fact,
          createdAt: now,
        ),
        'stale': RecallCandidate<String>(
          id: 'stale',
          value: 'stale',
          content: 'deployment used a canary last month',
          memoryType: MemoryType.request,
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      };
      // Both appear in the fact voice at adjacent ranks.
      final ranked = fusePolyphonicRecall<String>(
        rankedIdsByVoice: {
          RecallVoice.fact: ['stale', 'fresh'],
        },
        candidates: candidates,
        now: now,
        topK: 2,
      );
      expect(ranked.first.value, 'fresh');
    });

    test('fuses multiple voices and dedups by id', () {
      final now = DateTime(2025, 6, 1);
      final candidates = {
        'x': RecallCandidate<String>(
          id: 'x',
          value: 'x',
          content: 'alpha topic one',
          memoryType: MemoryType.fact,
          createdAt: now,
        ),
        'y': RecallCandidate<String>(
          id: 'y',
          value: 'y',
          content: 'beta topic two',
          memoryType: MemoryType.fact,
          createdAt: now,
        ),
      };
      final ranked = fusePolyphonicRecall<String>(
        rankedIdsByVoice: {
          RecallVoice.fact: ['x', 'y'],
          RecallVoice.vector: ['x'],
          RecallVoice.graph: ['x'],
        },
        candidates: candidates,
        now: now,
        topK: 5,
      );
      expect(ranked.map((r) => r.value).toSet(), {'x', 'y'});
      // 'x' surfaced by three voices outranks 'y'.
      expect(ranked.first.value, 'x');
    });
  });
}
