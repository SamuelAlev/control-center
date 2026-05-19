import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewNodeKind', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(ReviewNodeKind.values, containsAll([
        ReviewNodeKind.bug,
        ReviewNodeKind.suggestion,
        ReviewNodeKind.recommendation,
        ReviewNodeKind.question,
        ReviewNodeKind.ticket,
      ]));
    });
  });

  group('ReviewNodePriority', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(ReviewNodePriority.values, containsAll([
        ReviewNodePriority.p0,
        ReviewNodePriority.p1,
        ReviewNodePriority.p2,
        ReviewNodePriority.p3,
      ]));
    });

    test('index ordering is p0 < p1 < p2 < p3', timeout: const Timeout.factor(2), () {
      expect(ReviewNodePriority.p0.index, lessThan(ReviewNodePriority.p1.index));
      expect(ReviewNodePriority.p1.index, lessThan(ReviewNodePriority.p2.index));
      expect(ReviewNodePriority.p2.index, lessThan(ReviewNodePriority.p3.index));
    });
  });

  group('ReviewNodeStatus', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(ReviewNodeStatus.values, containsAll([
        ReviewNodeStatus.open,
        ReviewNodeStatus.consensusReady,
        ReviewNodeStatus.resolved,
        ReviewNodeStatus.dismissed,
      ]));
    });
  });

  group('ReviewNodeAnchor', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      const anchor = ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 10, lineEnd: 20);
      expect(anchor.filePath, 'lib/a.dart');
      expect(anchor.lineNumber, 10);
      expect(anchor.lineEnd, 20);
    });

    test('defaults to null', timeout: const Timeout.factor(2), () {
      const anchor = ReviewNodeAnchor();
      expect(anchor.filePath, isNull);
      expect(anchor.lineNumber, isNull);
      expect(anchor.lineEnd, isNull);
    });

    test('hasAnchor is true when filePath is set', timeout: const Timeout.factor(2), () {
      const anchor = ReviewNodeAnchor(filePath: 'lib/a.dart');
      expect(anchor.hasAnchor, true);
    });

    test('hasAnchor is true when lineNumber is set', timeout: const Timeout.factor(2), () {
      const anchor = ReviewNodeAnchor(lineNumber: 10);
      expect(anchor.hasAnchor, true);
    });

    test('hasAnchor is false when nothing is set', timeout: const Timeout.factor(2), () {
      const anchor = ReviewNodeAnchor();
      expect(anchor.hasAnchor, false);
    });

    group('fromMetadata', () {
      test('parses all fields', timeout: const Timeout.factor(2), () {
        final anchor = ReviewNodeAnchor.fromMetadata({
          'filePath': 'lib/a.dart',
          'lineNumber': 10,
          'lineEnd': 20,
        });
        expect(anchor.filePath, 'lib/a.dart');
        expect(anchor.lineNumber, 10);
        expect(anchor.lineEnd, 20);
      });

      test('handles missing fields', timeout: const Timeout.factor(2), () {
        final anchor = ReviewNodeAnchor.fromMetadata({});
        expect(anchor.filePath, isNull);
        expect(anchor.lineNumber, isNull);
        expect(anchor.lineEnd, isNull);
      });

      test('ignores wrong types', timeout: const Timeout.factor(2), () {
        final anchor = ReviewNodeAnchor.fromMetadata({
          'filePath': 42,
          'lineNumber': 'not-a-number',
        });
        expect(anchor.filePath, isNull);
        expect(anchor.lineNumber, isNull);
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', timeout: const Timeout.factor(2), () {
        const a = ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 10, lineEnd: 20);
        const b = ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 10, lineEnd: 20);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when filePath differs', timeout: const Timeout.factor(2), () {
        const a = ReviewNodeAnchor(filePath: 'lib/a.dart');
        const b = ReviewNodeAnchor(filePath: 'lib/b.dart');
        expect(a, isNot(equals(b)));
      });

      test('not equal when lineNumber differs', timeout: const Timeout.factor(2), () {
        const a = ReviewNodeAnchor(lineNumber: 10);
        const b = ReviewNodeAnchor(lineNumber: 20);
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('ReviewNodePayload', () {
    const payload = ReviewNodePayload(
      kind: ReviewNodeKind.bug,
      priority: ReviewNodePriority.p0,
      confidence: 0.95,
      anchor: ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 10),
      status: ReviewNodeStatus.open,
      confirmedBy: ['agent-x'],
      linkedTicketIds: ['ticket-1'],
    );

    test('creates with all fields', timeout: const Timeout.factor(2), () {
      expect(payload.kind, ReviewNodeKind.bug);
      expect(payload.priority, ReviewNodePriority.p0);
      expect(payload.confidence, 0.95);
      expect(payload.anchor.filePath, 'lib/a.dart');
      expect(payload.status, ReviewNodeStatus.open);
      expect(payload.confirmedBy, ['agent-x']);
      expect(payload.linkedTicketIds, ['ticket-1']);
    });

    test('hasPeerConfirmation is true when confirmedBy is non-empty',
        timeout: const Timeout.factor(2), () {
      expect(payload.hasPeerConfirmation, true);
    });

    test('hasPeerConfirmation is false when confirmedBy is empty',
        timeout: const Timeout.factor(2), () {
      const p = ReviewNodePayload(
        kind: ReviewNodeKind.bug,
        priority: ReviewNodePriority.p0,
        confidence: 0.9,
        anchor: ReviewNodeAnchor(),
        status: ReviewNodeStatus.open,
      );
      expect(p.hasPeerConfirmation, false);
    });

    group('fromMetadata', () {
      test('parses valid complete metadata', timeout: const Timeout.factor(2), () {
        final meta = {
          'nodeType': 'bug',
          'priority': 'p1',
          'confidence': 0.8,
          'filePath': 'lib/main.dart',
          'lineNumber': 42,
          'status': 'open',
          'confirmedBy': ['a', 'b'],
          'linkedTicketIds': ['t1'],
        };
        final p = ReviewNodePayload.fromMetadata(meta)!;
        expect(p.kind, ReviewNodeKind.bug);
        expect(p.priority, ReviewNodePriority.p1);
        expect(p.confidence, 0.8);
        expect(p.anchor.filePath, 'lib/main.dart');
        expect(p.anchor.lineNumber, 42);
        expect(p.status, ReviewNodeStatus.open);
        expect(p.confirmedBy, ['a', 'b']);
        expect(p.linkedTicketIds, ['t1']);
      });

      test('returns null for null input', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata(null), isNull);
      });

      test('returns null when nodeType is missing', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({'priority': 'p0', 'confidence': 0.9}), isNull);
      });

      test('returns null when priority is missing', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({'nodeType': 'bug', 'confidence': 0.9}), isNull);
      });

      test('returns null when priority is invalid', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'invalid', 'confidence': 0.9,
        }), isNull);
      });

      test('returns null when confidence is missing', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0',
        }), isNull);
      });

      test('returns null when confidence is out of range (> 1.0)', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 1.5,
        }), isNull);
      });

      test('returns null when confidence is negative', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': -0.1,
        }), isNull);
      });

      test('returns null when confidence is NaN', timeout: const Timeout.factor(2), () {
        expect(ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': double.nan,
        }), isNull);
      });

      test('defaults to open status for unknown status', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9, 'status': 'unknown',
        })!;
        expect(p.status, ReviewNodeStatus.open);
      });

      test('parses consensus_ready status', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9, 'status': 'consensus_ready',
        })!;
        expect(p.status, ReviewNodeStatus.consensusReady);
      });

      test('parses resolved status', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9, 'status': 'resolved',
        })!;
        expect(p.status, ReviewNodeStatus.resolved);
      });

      test('parses dismissed status', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9, 'status': 'dismissed',
        })!;
        expect(p.status, ReviewNodeStatus.dismissed);
      });

      test('defaults kind to suggestion for unknown nodeType', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'unknown_kind', 'priority': 'p0', 'confidence': 0.9,
        })!;
        expect(p.kind, ReviewNodeKind.suggestion);
      });

      test('parses all valid kinds', timeout: const Timeout.factor(2), () {
        const kinds = {'bug': ReviewNodeKind.bug, 'suggestion': ReviewNodeKind.suggestion, 'recommendation': ReviewNodeKind.recommendation, 'question': ReviewNodeKind.question, 'ticket': ReviewNodeKind.ticket};
        for (final entry in kinds.entries) {
          final p = ReviewNodePayload.fromMetadata({
            'nodeType': entry.key, 'priority': 'p0', 'confidence': 0.9,
          })!;
          expect(p.kind, entry.value);
        }
      });

      test('handles confirmedBy with non-string items', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9,
          'confirmedBy': [42, 'valid', true],
        })!;
        expect(p.confirmedBy, ['valid']);
      });

      test('handles null confirmedBy and linkedTicketIds', timeout: const Timeout.factor(2), () {
        final p = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9,
        })!;
        expect(p.confirmedBy, isEmpty);
        expect(p.linkedTicketIds, isEmpty);
      });

      test('accepts confidence at boundaries (0.0 and 1.0)', timeout: const Timeout.factor(2), () {
        final p0 = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.0,
        });
        final p1 = ReviewNodePayload.fromMetadata({
          'nodeType': 'bug', 'priority': 'p0', 'confidence': 1.0,
        });
        expect(p0, isNotNull);
        expect(p1, isNotNull);
        expect(p0!.confidence, 0.0);
        expect(p1!.confidence, 1.0);
      });
    });

    group('toMetadata', () {
      test('serializes all fields', timeout: const Timeout.factor(2), () {
        const p = ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.95,
          anchor: ReviewNodeAnchor(filePath: 'lib/a.dart', lineNumber: 10, lineEnd: 15),
          status: ReviewNodeStatus.consensusReady,
          confirmedBy: ['agent-x'],
          linkedTicketIds: ['ticket-1'],
        );
        final meta = p.toMetadata();
        expect(meta['nodeType'], 'bug');
        expect(meta['priority'], 'p0');
        expect(meta['confidence'], 0.95);
        expect(meta['status'], 'consensus_ready');
        expect(meta['confirmedBy'], ['agent-x']);
        expect(meta['linkedTicketIds'], ['ticket-1']);
        expect(meta['filePath'], 'lib/a.dart');
        expect(meta['lineNumber'], 10);
        expect(meta['lineEnd'], 15);
      });

      test('omits anchor fields when null', timeout: const Timeout.factor(2), () {
        const p = ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.9,
          anchor: ReviewNodeAnchor(),
          status: ReviewNodeStatus.open,
        );
        final meta = p.toMetadata();
        expect(meta.containsKey('filePath'), false);
        expect(meta.containsKey('lineNumber'), false);
        expect(meta.containsKey('lineEnd'), false);
      });
    });

    group('round-trip fromMetadata → toMetadata', () {
      test('round-trips correctly', timeout: const Timeout.factor(2), () {
        const original = ReviewNodePayload(
          kind: ReviewNodeKind.question,
          priority: ReviewNodePriority.p2,
          confidence: 0.75,
          anchor: ReviewNodeAnchor(filePath: 'lib/b.dart', lineNumber: 30),
          status: ReviewNodeStatus.resolved,
          confirmedBy: ['a', 'b'],
          linkedTicketIds: ['t1', 't2'],
        );
        final meta = original.toMetadata();
        final restored = ReviewNodePayload.fromMetadata(meta)!;
        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('overrides specified fields', timeout: const Timeout.factor(2), () {
        final copy = payload.copyWith(
          priority: ReviewNodePriority.p2,
          status: ReviewNodeStatus.resolved,
        );
        expect(copy.priority, ReviewNodePriority.p2);
        expect(copy.status, ReviewNodeStatus.resolved);
        expect(copy.kind, payload.kind);
        expect(copy.confidence, payload.confidence);
      });

      test('returns identical when no overrides', timeout: const Timeout.factor(2), () {
        final copy = payload.copyWith();
        expect(copy, equals(payload));
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', timeout: const Timeout.factor(2), () {
        const a = ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.9,
          anchor: ReviewNodeAnchor(filePath: 'lib/a.dart'),
          status: ReviewNodeStatus.open,
          confirmedBy: ['x'],
        );
        const b = ReviewNodePayload(
          kind: ReviewNodeKind.bug,
          priority: ReviewNodePriority.p0,
          confidence: 0.9,
          anchor: ReviewNodeAnchor(filePath: 'lib/a.dart'),
          status: ReviewNodeStatus.open,
          confirmedBy: ['x'],
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when kind differs', timeout: const Timeout.factor(2), () {
        const a = ReviewNodePayload(
          kind: ReviewNodeKind.bug, priority: ReviewNodePriority.p0,
          confidence: 0.9, anchor: ReviewNodeAnchor(), status: ReviewNodeStatus.open,
        );
        const b = ReviewNodePayload(
          kind: ReviewNodeKind.suggestion, priority: ReviewNodePriority.p0,
          confidence: 0.9, anchor: ReviewNodeAnchor(), status: ReviewNodeStatus.open,
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal when confirmedBy differs', timeout: const Timeout.factor(2), () {
        const a = ReviewNodePayload(
          kind: ReviewNodeKind.bug, priority: ReviewNodePriority.p0,
          confidence: 0.9, anchor: ReviewNodeAnchor(), status: ReviewNodeStatus.open,
          confirmedBy: ['a'],
        );
        const b = ReviewNodePayload(
          kind: ReviewNodeKind.bug, priority: ReviewNodePriority.p0,
          confidence: 0.9, anchor: ReviewNodeAnchor(), status: ReviewNodeStatus.open,
          confirmedBy: ['b'],
        );
        expect(a, isNot(equals(b)));
      });

      test('self equality', timeout: const Timeout.factor(2), () {
        expect(payload, equals(payload));
      });
    });
  });
}
