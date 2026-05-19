import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/pr_review/domain/services/review_suppression_matcher.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

/// Embeds a string as a unit vector pointing along the axis named by its FIRST
/// word, so "nit about naming" and "nit about spacing" are identical and
/// "bug in auth" is orthogonal to both. Deterministic, and it makes the
/// threshold arithmetic in the tests obvious rather than magical.
class _AxisEmbedder extends EmbeddingPort {
  _AxisEmbedder({this.isReady = true, this.throwOnEmbed = false});

  @override
  final bool isReady;

  final bool throwOnEmbed;

  @override
  int get dimension => 4;

  static const _axes = ['nit', 'bug', 'perf', 'style'];

  @override
  Future<Float32List> embed(String text) async {
    if (throwOnEmbed) {
      throw StateError('embedder exploded');
    }
    final head = text.trim().toLowerCase().split(RegExp(r'\s+')).first;
    final v = Float32List(dimension);
    final axis = _axes.indexOf(head);
    v[axis < 0 ? dimension - 1 : axis] = 1;
    return v;
  }
}

ReviewSuppressionCandidate _candidate(
  String title, {
  ReviewFindingSeverity severity = ReviewFindingSeverity.minor,
}) => ReviewSuppressionCandidate(title: title, severity: severity);

void main() {
  group('ReviewSuppressionMatcher', () {
    ReviewSuppressionMatcher build({
      EmbeddingPort? embedder,
      int minMatches = 2,
    }) => ReviewSuppressionMatcher(
      embedder: embedder ?? _AxisEmbedder(),
      minMatches: minMatches,
    );

    test('suppresses a finding that echoes enough past dismissals', () async {
      final hits = await build().suppressed(
        candidates: [_candidate('nit about naming here')],
        dismissedTitles: const [
          'nit about spacing',
          'nit about ordering',
        ],
      );
      expect(hits, {0});
    });

    test('leaves a finding unlike anything dismissed', () async {
      final hits = await build().suppressed(
        candidates: [_candidate('bug in the auth path')],
        dismissedTitles: const ['nit about spacing', 'nit about ordering'],
      );
      expect(hits, isEmpty);
    });

    test('one past dismissal is not enough', () async {
      // A single stubborn rejection must not suppress a whole class.
      final hits = await build().suppressed(
        candidates: [_candidate('nit about naming')],
        dismissedTitles: const ['nit about spacing'],
      );
      expect(hits, isEmpty);
    });

    test('never suppresses a critical or major finding', () async {
      // Dismissing a nit once is a preference, not permission to stop
      // reporting breaches.
      for (final severity in [
        ReviewFindingSeverity.critical,
        ReviewFindingSeverity.major,
      ]) {
        final hits = await build().suppressed(
          candidates: [_candidate('nit about naming', severity: severity)],
          dismissedTitles: const [
            'nit about spacing',
            'nit about ordering',
            'nit about casing',
          ],
        );
        expect(hits, isEmpty, reason: severity.name);
      }
    });

    test('suppresses nothing when the embedder is not ready', () async {
      // Semantic search stays FTS-only until the on-device model downloads;
      // a missing model must not turn into a reviewer that reports nothing.
      final hits = await build(embedder: _AxisEmbedder(isReady: false))
          .suppressed(
            candidates: [_candidate('nit about naming')],
            dismissedTitles: const ['nit about spacing', 'nit about ordering'],
          );
      expect(hits, isEmpty);
    });

    test('suppresses nothing when the embedder throws', () async {
      final hits = await build(embedder: _AxisEmbedder(throwOnEmbed: true))
          .suppressed(
            candidates: [_candidate('nit about naming')],
            dismissedTitles: const ['nit about spacing', 'nit about ordering'],
          );
      expect(hits, isEmpty);
    });

    test('suppresses nothing with an empty or too-small corpus', () async {
      expect(
        await build().suppressed(
          candidates: [_candidate('nit about naming')],
          dismissedTitles: const [],
        ),
        isEmpty,
      );
      expect(
        await build(minMatches: 3).suppressed(
          candidates: [_candidate('nit about naming')],
          dismissedTitles: const ['nit a', 'nit b'],
        ),
        isEmpty,
      );
    });

    test('ignores a blank-titled candidate', () async {
      final hits = await build().suppressed(
        candidates: [_candidate('   ')],
        dismissedTitles: const ['nit about spacing', 'nit about ordering'],
      );
      expect(hits, isEmpty);
    });

    test('reports indices into the original candidate list', () async {
      // The caller maps these back to message ids, so a shifted index would
      // suppress the wrong finding.
      final hits = await build().suppressed(
        candidates: [
          _candidate('bug in auth', severity: ReviewFindingSeverity.critical),
          _candidate('bug elsewhere'),
          _candidate('nit about naming'),
        ],
        dismissedTitles: const ['nit about spacing', 'nit about ordering'],
      );
      expect(hits, {2});
    });
  });
}
