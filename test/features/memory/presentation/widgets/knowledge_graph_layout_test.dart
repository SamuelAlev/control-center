import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const _domain = Size(148, 86);
const _topic = Size(152, 64);
const _fact = Size(184, 116);
const _policy = Size(168, 96);

/// Builds the sizes map the layout needs, keyed the way the widget keys nodes.
Map<String, Size> _sizes(List<GraphCluster> clusters) {
  final sizes = <String, Size>{};
  for (final cluster in clusters) {
    sizes[cluster.domainKey] = _domain;
    for (final key in cluster.policyKeys) {
      sizes[key] = _policy;
    }
    for (final strip in cluster.strips) {
      sizes[strip.topicKey] = _topic;
      for (final key in strip.factKeys) {
        sizes[key] = _fact;
      }
    }
  }
  return sizes;
}

GraphCluster _cluster(
  String slug, {
  required int topics,
  int factsPerTopic = 0,
  int policies = 0,
}) => GraphCluster(
  domainKey: 'domain:$slug',
  strips: [
    for (var t = 0; t < topics; t++)
      GraphStrip(
        topicKey: 'topic:$slug/$t',
        factKeys: [for (var f = 0; f < factsPerTopic; f++) 'fact:$slug-$t-$f'],
      ),
  ],
  policyKeys: [for (var p = 0; p < policies; p++) 'policy:$slug-$p'],
);

Rect _boundsOf(Map<String, Offset> positions, Map<String, Size> sizes) {
  var left = double.infinity;
  var top = double.infinity;
  var right = -double.infinity;
  var bottom = -double.infinity;
  positions.forEach((key, at) {
    final size = sizes[key]!;
    left = math.min(left, at.dx);
    top = math.min(top, at.dy);
    right = math.max(right, at.dx + size.width);
    bottom = math.max(bottom, at.dy + size.height);
  });
  return Rect.fromLTRB(left, top, right, bottom);
}

Iterable<Rect> _rects(
  Map<String, Offset> positions,
  Map<String, Size> sizes,
) sync* {
  for (final entry in positions.entries) {
    yield entry.value & sizes[entry.key]!;
  }
}

void main() {
  group('KnowledgeGraphLayout', () {
    test('places nothing for no clusters', () {
      expect(
        KnowledgeGraphLayout.compute(clusters: const [], sizes: const {}),
        isEmpty,
      );
    });

    test('gives every node in every cluster a position', () {
      final clusters = [
        _cluster('a', topics: 6, factsPerTopic: 2, policies: 3),
        _cluster('b', topics: 1, policies: 1),
      ];
      final sizes = _sizes(clusters);
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );
      expect(positions.keys.toSet(), sizes.keys.toSet());
    });

    test('no two nodes overlap', () {
      final clusters = [
        _cluster('a', topics: 22, factsPerTopic: 1, policies: 4),
        _cluster('b', topics: 5, factsPerTopic: 3, policies: 2),
        _cluster('c', topics: 1),
      ];
      final sizes = _sizes(clusters);
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );

      final rects = _rects(positions, sizes).toList();
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            rects[i].overlaps(rects[j]),
            isFalse,
            reason: 'nodes at ${rects[i]} and ${rects[j]} overlap',
          );
        }
      }
    });

    test('a wide fan-out is packed toward the target aspect, not a row', () {
      // The regression this whole layout exists for: one domain with 22
      // topics used to be laid out as a single row ~4,500 points wide against
      // ~450 tall, so "fit to view" scaled the graph to a fifth of legible.
      final clusters = [_cluster('a', topics: 22)];
      final sizes = _sizes(clusters);
      final bounds = _boundsOf(
        KnowledgeGraphLayout.compute(clusters: clusters, sizes: sizes),
        sizes,
      );

      final aspect = bounds.width / bounds.height;
      expect(aspect, greaterThan(0.8));
      expect(aspect, lessThan(3.5));
      expect(
        bounds.width,
        lessThan(22 * _topic.width),
        reason: 'the topics must not be laid out in one row',
      );
    });

    test('many domains pack into rows rather than one long line', () {
      final clusters = [for (var i = 0; i < 8; i++) _cluster('d$i', topics: 2)];
      final sizes = _sizes(clusters);
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );

      final rows = positions.entries
          .where((e) => e.key.startsWith('domain:'))
          .map((e) => e.value.dy)
          .toSet();
      expect(
        rows.length,
        greaterThan(1),
        reason: 'eight domains on one row is the band this replaced',
      );

      final bounds = _boundsOf(positions, sizes);
      expect(bounds.width / bounds.height, greaterThan(0.6));
      expect(bounds.width / bounds.height, lessThan(3.0));
    });

    test('a topic sits directly above the facts stacked under it', () {
      final clusters = [_cluster('a', topics: 3, factsPerTopic: 2)];
      final sizes = _sizes(clusters);
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );

      for (var t = 0; t < 3; t++) {
        final topic = positions['topic:a/$t']!;
        final first = positions['fact:a-$t-0']!;
        final second = positions['fact:a-$t-1']!;
        // Same column: the strip is what keeps these edges short and vertical.
        final topicCentre = topic.dx + _topic.width / 2;
        expect(first.dx + _fact.width / 2, closeTo(topicCentre, 0.001));
        expect(second.dx + _fact.width / 2, closeTo(topicCentre, 0.001));
        expect(first.dy, greaterThan(topic.dy));
        expect(second.dy, greaterThan(first.dy));
      }
    });

    test('policies sit beside their domain, not below the grid', () {
      final clusters = [_cluster('a', topics: 4, policies: 2)];
      final sizes = _sizes(clusters);
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );

      final domain = positions['domain:a']!;
      final policy = positions['policy:a-0']!;
      expect(policy.dx, greaterThan(domain.dx));
      // Same band as the domain, above every topic.
      for (var t = 0; t < 4; t++) {
        expect(policy.dy, lessThan(positions['topic:a/$t']!.dy));
      }
    });

    test('is a pure function of its input', () {
      final clusters = [
        _cluster('a', topics: 7, factsPerTopic: 1, policies: 2),
        _cluster('b', topics: 3),
      ];
      final sizes = _sizes(clusters);
      final first = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );
      final second = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: sizes,
      );
      expect(second, first);
    });

    test('an unmeasured node still gets a position instead of throwing', () {
      final clusters = [_cluster('a', topics: 2)];
      final positions = KnowledgeGraphLayout.compute(
        clusters: clusters,
        sizes: const {},
      );
      expect(positions.length, 3);
    });
  });
}
