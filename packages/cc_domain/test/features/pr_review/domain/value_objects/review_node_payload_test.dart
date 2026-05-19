import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

/// Coverage for the typed view over a `reviewNode` channel-message metadata
/// payload: the [ReviewNodeAnchor], [ReviewNodePayload] value objects and the
/// [ReviewNodeKind], [ReviewNodePriority], [ReviewNodeStatus] enums.
void main() {
  group('ReviewNodeKind', () {
    test('exposes the five finding kinds', () {
      expect(ReviewNodeKind.values, contains(ReviewNodeKind.bug));
      expect(ReviewNodeKind.values, contains(ReviewNodeKind.suggestion));
      expect(ReviewNodeKind.values, contains(ReviewNodeKind.recommendation));
      expect(ReviewNodeKind.values, contains(ReviewNodeKind.question));
      expect(ReviewNodeKind.values, contains(ReviewNodeKind.ticket));
    });
  });

  group('ReviewNodePriority', () {
    test('exposes p0..p3 in order', () {
      expect(ReviewNodePriority.values, [
        ReviewNodePriority.p0,
        ReviewNodePriority.p1,
        ReviewNodePriority.p2,
        ReviewNodePriority.p3,
      ]);
    });
  });

  group('ReviewNodeStatus', () {
    test('exposes the four lifecycle states', () {
      expect(ReviewNodeStatus.values, contains(ReviewNodeStatus.open));
      expect(
        ReviewNodeStatus.values,
        contains(ReviewNodeStatus.consensusReady),
      );
      expect(ReviewNodeStatus.values, contains(ReviewNodeStatus.resolved));
      expect(ReviewNodeStatus.values, contains(ReviewNodeStatus.dismissed));
    });
  });

  group('ReviewNodeAnchor', () {
    test('default constructor leaves every field null', () {
      const anchor = ReviewNodeAnchor();
      expect(anchor.filePath, isNull);
      expect(anchor.lineNumber, isNull);
      expect(anchor.lineEnd, isNull);
      expect(anchor.hasAnchor, isFalse);
    });

    test('hasAnchor is true when a file path is set', () {
      const anchor = ReviewNodeAnchor(filePath: 'lib/a.dart');
      expect(anchor.hasAnchor, isTrue);
    });

    test('hasAnchor is true when only a line number is set', () {
      const anchor = ReviewNodeAnchor(lineNumber: 10);
      expect(anchor.hasAnchor, isTrue);
    });

    test('fromMetadata copies filePath, lineNumber and lineEnd when typed', () {
      final anchor = ReviewNodeAnchor.fromMetadata(const {
        'filePath': 'lib/a.dart',
        'lineNumber': 5,
        'lineEnd': 8,
      });
      expect(anchor.filePath, 'lib/a.dart');
      expect(anchor.lineNumber, 5);
      expect(anchor.lineEnd, 8);
    });

    test('fromMetadata nulls mistyped fields', () {
      final anchor = ReviewNodeAnchor.fromMetadata(const {
        'filePath': 123,
        'lineNumber': 'oops',
        'lineEnd': true,
      });
      expect(anchor.filePath, isNull);
      expect(anchor.lineNumber, isNull);
      expect(anchor.lineEnd, isNull);
    });

    test('fromMetadata tolerates missing keys', () {
      final anchor = ReviewNodeAnchor.fromMetadata(const {});
      expect(anchor.filePath, isNull);
      expect(anchor.lineNumber, isNull);
      expect(anchor.lineEnd, isNull);
    });

    test('equality and hashCode are value-based', () {
      const a = ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 1);
      const b = ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        const ReviewNodeAnchor(filePath: 'lib/b.dart', lineNumber: 1),
        isNot(a),
      );
      expect(a, isNot('string'));
    });

    test(
      'equality distinguishes anchors that share a file but differ in lines',
      () {
        const a = ReviewNodeAnchor(
          filePath: 'lib/a.dart',
          lineNumber: 1,
          lineEnd: 3,
        );
        // Same file, different start line.
        expect(
          const ReviewNodeAnchor(
            filePath: 'lib/a.dart',
            lineNumber: 2,
            lineEnd: 3,
          ),
          isNot(a),
        );
        // Same file + start line, different end line.
        expect(
          const ReviewNodeAnchor(
            filePath: 'lib/a.dart',
            lineNumber: 1,
            lineEnd: 9,
          ),
          isNot(a),
        );
      },
    );
  });

  group('ReviewNodePayload', () {
    const base = ReviewNodePayload(
      kind: ReviewNodeKind.bug,
      priority: ReviewNodePriority.p0,
      confidence: 0.8,
      anchor: ReviewNodeAnchor(
        filePath: 'lib/a.dart',
        lineNumber: 1,
        lineEnd: 2,
      ),
      status: ReviewNodeStatus.open,
      confirmedBy: ['agent-2'],
      linkedTicketIds: ['T-1'],
      cohortKey: 'auth',
      axis: ReviewAxis.correctness,
    );

    test('construction round-trips every field', () {
      expect(base.kind, ReviewNodeKind.bug);
      expect(base.priority, ReviewNodePriority.p0);
      expect(base.confidence, 0.8);
      expect(base.anchor.filePath, 'lib/a.dart');
      expect(base.status, ReviewNodeStatus.open);
      expect(base.confirmedBy, ['agent-2']);
      expect(base.linkedTicketIds, ['T-1']);
      expect(base.cohortKey, 'auth');
      expect(base.axis, ReviewAxis.correctness);
    });

    test('hasPeerConfirmation reflects confirmedBy', () {
      expect(base.hasPeerConfirmation, isTrue);
      const empty = ReviewNodePayload(
        kind: ReviewNodeKind.bug,
        priority: ReviewNodePriority.p1,
        confidence: 0.5,
        anchor: ReviewNodeAnchor(),
        status: ReviewNodeStatus.open,
      );
      expect(empty.hasPeerConfirmation, isFalse);
    });

    group('fromMetadata', () {
      test('returns null for a null map', () {
        expect(ReviewNodePayload.fromMetadata(null), isNull);
      });

      test('returns null when nodeType is missing', () {
        expect(
          ReviewNodePayload.fromMetadata(const {'priority': 'p0'}),
          isNull,
        );
      });

      test('returns null when priority is missing', () {
        expect(
          ReviewNodePayload.fromMetadata(const {'nodeType': 'bug'}),
          isNull,
        );
      });

      test('returns null when priority is not a recognized string', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p9',
          }),
          isNull,
        );
      });

      test('returns null when priority is not a string at all', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 1,
          }),
          isNull,
        );
      });

      test('returns null when confidence is missing', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p0',
          }),
          isNull,
        );
      });

      test('returns null when confidence is not a number', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p0',
            'confidence': 'high',
          }),
          isNull,
        );
      });

      test('returns null when confidence is out of range high', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p0',
            'confidence': 2.0,
          }),
          isNull,
        );
      });

      test('returns null when confidence is out of range low', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p0',
            'confidence': -0.1,
          }),
          isNull,
        );
      });

      test('returns null when confidence is NaN', () {
        expect(
          ReviewNodePayload.fromMetadata(const {
            'nodeType': 'bug',
            'priority': 'p0',
            'confidence': double.nan,
          }),
          isNull,
        );
      });

      test('parses every recognized kind, falling back to suggestion', () {
        for (final pair in <(String, ReviewNodeKind)>[
          ('bug', ReviewNodeKind.bug),
          ('suggestion', ReviewNodeKind.suggestion),
          ('recommendation', ReviewNodeKind.recommendation),
          ('question', ReviewNodeKind.question),
          ('ticket', ReviewNodeKind.ticket),
          ('totally-unknown', ReviewNodeKind.suggestion),
        ]) {
          final payload = ReviewNodePayload.fromMetadata({
            'nodeType': pair.$1,
            'priority': 'p1',
            'confidence': 0.5,
          });
          expect(payload, isNotNull, reason: pair.$1);
          expect(payload!.kind, pair.$2);
        }
      });

      test('parses priority case-insensitively for every level', () {
        for (final pair in <(String, ReviewNodePriority)>[
          ('p0', ReviewNodePriority.p0),
          ('P0', ReviewNodePriority.p0),
          ('p1', ReviewNodePriority.p1),
          ('p2', ReviewNodePriority.p2),
          ('p3', ReviewNodePriority.p3),
        ]) {
          final payload = ReviewNodePayload.fromMetadata({
            'nodeType': 'bug',
            'priority': pair.$1,
            'confidence': 0.5,
          });
          expect(payload, isNotNull, reason: pair.$1);
          expect(payload!.priority, pair.$2);
        }
      });

      test('parses every recognized status, defaulting to open', () {
        for (final pair in <(String?, ReviewNodeStatus)>[
          ('consensus_ready', ReviewNodeStatus.consensusReady),
          ('resolved', ReviewNodeStatus.resolved),
          ('dismissed', ReviewNodeStatus.dismissed),
          (null, ReviewNodeStatus.open),
          ('bogus', ReviewNodeStatus.open),
        ]) {
          final meta = <String, dynamic>{
            'nodeType': 'bug',
            'priority': 'p1',
            'confidence': 0.5,
          };
          if (pair.$1 != null) {
            meta['status'] = pair.$1;
          }
          final payload = ReviewNodePayload.fromMetadata(meta);
          expect(payload, isNotNull);
          expect(payload!.status, pair.$2, reason: '${pair.$1}');
        }
      });

      test('parses axis by wire name or dart name, null when unknown', () {
        final withAxis = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p1',
          'confidence': 0.5,
          'axis': 'test_gap',
        })!;
        expect(withAxis.axis, ReviewAxis.testGap);

        final byDartName = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p1',
          'confidence': 0.5,
          'axis': 'apiContract',
        })!;
        expect(byDartName.axis, ReviewAxis.apiContract);

        final noAxis = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p1',
          'confidence': 0.5,
        })!;
        expect(noAxis.axis, isNull);
      });

      test('parses cohortKey, confirmedBy, linkedTicketIds and anchor', () {
        final payload = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p0',
          'confidence': 0.7,
          'cohortKey': 123, // mistyped -> dropped
          'confirmedBy': ['a', 1, 'b'],
          'linkedTicketIds': ['T-1', 'T-2'],
          'filePath': 'lib/x.dart',
          'lineNumber': 4,
          'lineEnd': 9,
        })!;
        expect(payload.cohortKey, isNull);
        expect(payload.confirmedBy, ['a', 'b']);
        expect(payload.linkedTicketIds, ['T-1', 'T-2']);
        expect(payload.anchor.filePath, 'lib/x.dart');
        expect(payload.anchor.lineNumber, 4);
        expect(payload.anchor.lineEnd, 9);
      });

      test('cohortKey is kept when it is a String', () {
        final payload = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p0',
          'confidence': 0.7,
          'cohortKey': 'auth',
        })!;
        expect(payload.cohortKey, 'auth');
      });

      test('defaults confirmedBy and linkedTicketIds to empty lists', () {
        final payload = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug',
          'priority': 'p0',
          'confidence': 0.7,
        })!;
        expect(payload.confirmedBy, isEmpty);
        expect(payload.linkedTicketIds, isEmpty);
      });
    });

    group('toMetadata', () {
      test('round-trips a full payload', () {
        final meta = base.toMetadata();
        expect(meta['nodeType'], 'bug');
        expect(meta['priority'], 'p0');
        expect(meta['confidence'], 0.8);
        expect(meta['status'], 'open');
        expect(meta['confirmedBy'], ['agent-2']);
        expect(meta['linkedTicketIds'], ['T-1']);
        expect(meta['cohortKey'], 'auth');
        expect(meta['axis'], 'correctness');
        expect(meta['filePath'], 'lib/a.dart');
        expect(meta['lineNumber'], 1);
        expect(meta['lineEnd'], 2);
      });

      test('omits optional keys when absent', () {
        const minimal = ReviewNodePayload(
          kind: ReviewNodeKind.question,
          priority: ReviewNodePriority.p3,
          confidence: 0.2,
          anchor: ReviewNodeAnchor(),
          status: ReviewNodeStatus.open,
        );
        final meta = minimal.toMetadata();
        expect(meta.containsKey('cohortKey'), isFalse);
        expect(meta.containsKey('axis'), isFalse);
        expect(meta.containsKey('filePath'), isFalse);
        expect(meta.containsKey('lineNumber'), isFalse);
        expect(meta.containsKey('lineEnd'), isFalse);
        expect(meta['nodeType'], 'question');
        expect(meta['priority'], 'p3');
        expect(meta['status'], 'open');
      });

      test('emits every kind string', () {
        for (final pair in <(ReviewNodeKind, String)>[
          (ReviewNodeKind.bug, 'bug'),
          (ReviewNodeKind.suggestion, 'suggestion'),
          (ReviewNodeKind.recommendation, 'recommendation'),
          (ReviewNodeKind.question, 'question'),
          (ReviewNodeKind.ticket, 'ticket'),
        ]) {
          final p = ReviewNodePayload(
            kind: pair.$1,
            priority: ReviewNodePriority.p2,
            confidence: 0.1,
            anchor: const ReviewNodeAnchor(),
            status: ReviewNodeStatus.open,
          );
          expect(p.toMetadata()['nodeType'], pair.$2);
        }
      });

      test('emits every priority string', () {
        for (final pair in <(ReviewNodePriority, String)>[
          (ReviewNodePriority.p0, 'p0'),
          (ReviewNodePriority.p1, 'p1'),
          (ReviewNodePriority.p2, 'p2'),
          (ReviewNodePriority.p3, 'p3'),
        ]) {
          final p = ReviewNodePayload(
            kind: ReviewNodeKind.bug,
            priority: pair.$1,
            confidence: 0.1,
            anchor: const ReviewNodeAnchor(),
            status: ReviewNodeStatus.open,
          );
          expect(p.toMetadata()['priority'], pair.$2);
        }
      });

      test('emits every status string', () {
        for (final pair in <(ReviewNodeStatus, String)>[
          (ReviewNodeStatus.open, 'open'),
          (ReviewNodeStatus.consensusReady, 'consensus_ready'),
          (ReviewNodeStatus.resolved, 'resolved'),
          (ReviewNodeStatus.dismissed, 'dismissed'),
        ]) {
          final p = ReviewNodePayload(
            kind: ReviewNodeKind.bug,
            priority: ReviewNodePriority.p2,
            confidence: 0.1,
            anchor: const ReviewNodeAnchor(),
            status: pair.$1,
          );
          expect(p.toMetadata()['status'], pair.$2);
        }
      });
    });

    group('copyWith', () {
      test('overrides only the supplied fields', () {
        final next = base.copyWith(
          priority: ReviewNodePriority.p2,
          confidence: 0.3,
        );
        expect(next.priority, ReviewNodePriority.p2);
        expect(next.confidence, 0.3);
        expect(next.kind, base.kind);
        expect(next.anchor, base.anchor);
        expect(next.status, base.status);
        expect(next.confirmedBy, base.confirmedBy);
        expect(next.linkedTicketIds, base.linkedTicketIds);
        expect(next.cohortKey, base.cohortKey);
        expect(next.axis, base.axis);
      });

      test('replaces the anchor and list fields', () {
        final next = base.copyWith(
          anchor: const ReviewNodeAnchor(filePath: 'lib/z.dart'),
          confirmedBy: const ['a', 'b'],
          linkedTicketIds: const ['T-9'],
        );
        expect(next.anchor.filePath, 'lib/z.dart');
        expect(next.confirmedBy, ['a', 'b']);
        expect(next.linkedTicketIds, ['T-9']);
      });

      test('clearCohortKey overrides a non-null cohortKey argument', () {
        final next = base.copyWith(cohortKey: 'ignored', clearCohortKey: true);
        expect(next.cohortKey, isNull);
      });

      test('clearAxis overrides a non-null axis argument', () {
        final next = base.copyWith(axis: ReviewAxis.security, clearAxis: true);
        expect(next.axis, isNull);
      });

      test('with no arguments returns an equal instance', () {
        expect(base.copyWith(), base);
      });
    });

    group('equality', () {
      test('equal payloads are equal by value and hash', () {
        const other = ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.8,
          anchor: ReviewNodeAnchor(
            filePath: 'lib/a.dart',
            lineNumber: 1,
            lineEnd: 2,
          ),
          status: ReviewNodeStatus.open,
          confirmedBy: ['agent-2'],
          linkedTicketIds: ['T-1'],
          cohortKey: 'auth',
          axis: ReviewAxis.correctness,
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when any field differs', () {
        expect(base.copyWith(kind: ReviewNodeKind.suggestion), isNot(base));
        expect(base.copyWith(confirmedBy: const ['other']), isNot(base));
        expect(base.copyWith(linkedTicketIds: const ['other']), isNot(base));
        expect(base.copyWith(axis: ReviewAxis.security), isNot(base));
        expect(base.copyWith(cohortKey: 'other'), isNot(base));
        expect(
          base.copyWith(
            anchor: const ReviewNodeAnchor(filePath: 'lib/other.dart'),
          ),
          isNot(base),
        );
      });

      test('treats empty and non-empty confirmedBy as different', () {
        final a = base.copyWith();
        final b = base.copyWith(confirmedBy: const []);
        expect(a, isNot(b));
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('string'));
      });
    });
  });
}
