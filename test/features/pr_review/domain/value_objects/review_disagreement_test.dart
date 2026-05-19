// ignore: unused_import used for helper construction
import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_disagreement.dart';
import 'package:flutter_test/flutter_test.dart';

ChannelMessage _makeReviewNode({
  required String senderId,
  required Map<String, dynamic> metadata,
  String content = '',
}) {
  return ChannelMessage(
    id: 'msg-$senderId-${metadata.hashCode}',
    channelId: 'ch-1',
    senderId: senderId,
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.reviewNode,
    metadata: metadata,
    createdAt: DateTime(2025),
  );
}

Map<String, dynamic> _nodeMeta({
  required String kind,
  required String priority,
  required double confidence,
  String? filePath,
  int? lineNumber,
  int? lineEnd,
}) {
  return {
    'nodeType': kind,
    'priority': priority,
    'confidence': confidence,
    'filePath': ?filePath,
    'lineNumber': ?lineNumber,
    'lineEnd': ?lineEnd,
  };
}

void main() {
  group('ReviewDisagreement', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      final nodeA = _makeReviewNode(
        senderId: 'a',
        metadata: _nodeMeta(
          kind: 'bug',
          priority: 'p0',
          confidence: 0.9,
          filePath: 'lib/foo.dart',
          lineNumber: 10,
        ),
      );
      final nodeB = _makeReviewNode(
        senderId: 'b',
        metadata: _nodeMeta(
          kind: 'suggestion',
          priority: 'p2',
          confidence: 0.8,
          filePath: 'lib/foo.dart',
          lineNumber: 10,
        ),
      );
      const desc = 'Test disagreement';
      final d = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: desc);
      expect(d.nodeA, nodeA);
      expect(d.nodeB, nodeB);
      expect(d.description, desc);
    });

    test('equality based on nodeA, nodeB, description', timeout: const Timeout.factor(2), () {
      final nodeA = _makeReviewNode(senderId: 'a', metadata: {'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9});
      final nodeB = _makeReviewNode(senderId: 'b', metadata: {'nodeType': 'suggestion', 'priority': 'p2', 'confidence': 0.8});
      final d1 = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: 'desc');
      final d2 = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: 'desc');
      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('not equal when description differs', timeout: const Timeout.factor(2), () {
      final nodeA = _makeReviewNode(senderId: 'a', metadata: {'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9});
      final nodeB = _makeReviewNode(senderId: 'b', metadata: {'nodeType': 'suggestion', 'priority': 'p2', 'confidence': 0.8});
      final d1 = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: 'a');
      final d2 = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: 'b');
      expect(d1, isNot(equals(d2)));
    });

    group('anchor getter', () {
      test('returns file:line when both present', timeout: const Timeout.factor(2), () {
        final nodeA = _makeReviewNode(
          senderId: 'a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/main.dart', lineNumber: 42,
          ),
        );
        final nodeB = _makeReviewNode(senderId: 'b', metadata: _nodeMeta(kind: 'suggestion', priority: 'p2', confidence: 0.8));
        final d = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: '');
        expect(d.anchor, 'lib/main.dart:42');
      });

      test('returns file only when no line', timeout: const Timeout.factor(2), () {
        final nodeA = _makeReviewNode(
          senderId: 'a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/main.dart',
          ),
        );
        final nodeB = _makeReviewNode(senderId: 'b', metadata: _nodeMeta(kind: 'suggestion', priority: 'p2', confidence: 0.8));
        final d = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: '');
        expect(d.anchor, 'lib/main.dart');
      });

      test('returns "general finding" when no anchor', timeout: const Timeout.factor(2), () {
        final nodeA = _makeReviewNode(
          senderId: 'a',
          metadata: _nodeMeta(kind: 'bug', priority: 'p0', confidence: 0.9),
        );
        final nodeB = _makeReviewNode(senderId: 'b', metadata: _nodeMeta(kind: 'suggestion', priority: 'p2', confidence: 0.8));
        final d = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: '');
        expect(d.anchor, 'general finding');
      });

      test('returns "general finding" when anchor has no filePath', timeout: const Timeout.factor(2), () {
        final nodeA = _makeReviewNode(
          senderId: 'a',
          metadata: {'nodeType': 'bug', 'priority': 'p0', 'confidence': 0.9, 'lineNumber': 10},
        );
        final nodeB = _makeReviewNode(senderId: 'b', metadata: _nodeMeta(kind: 'suggestion', priority: 'p2', confidence: 0.8));
        final d = ReviewDisagreement(nodeA: nodeA, nodeB: nodeB, description: '');
        expect(d.anchor, 'general finding');
      });
    });
  });

  group('detectDisagreements', () {
    test('detects priority gap >= 2 on same file+line from different agents',
        timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p2', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, hasLength(1));
      expect(result.first.description, contains('P0 (block)'));
      expect(result.first.description, contains('P2'));
    });

    test('detects bug vs suggestion conflict on same anchor',
        timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p1', confidence: 0.9,
            filePath: 'lib/bar.dart', lineNumber: 5,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p1', confidence: 0.8,
            filePath: 'lib/bar.dart', lineNumber: 5,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, hasLength(1));
      expect(result.first.description, contains('Bug vs suggestion'));
    });

    test('ignores same-agent findings', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p3', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('ignores non-reviewNode messages', timeout: const Timeout.factor(2), () {
      final messages = [
        ChannelMessage(
          id: 'text-1',
          channelId: 'ch-1',
          senderId: 'agent-a',
          senderType: ChannelSenderType.agent,
          content: 'hello',
          messageType: ChannelMessageType.text,
          metadata: null,
          createdAt: DateTime(2025),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('ignores findings with no anchor', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(kind: 'bug', priority: 'p0', confidence: 0.9),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('ignores different files', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/a.dart', lineNumber: 10,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/b.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('ignores same priority + same kind (no conflict)', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p1', confidence: 0.9,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p1', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('priority gap of exactly 1 does not trigger', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p1', confidence: 0.9,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p2', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });

    test('overlapping line ranges are treated as same anchor', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/foo.dart', lineNumber: 5, lineEnd: 15,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10, lineEnd: 20,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, hasLength(1));
    });

    test('returns empty for empty list', timeout: const Timeout.factor(2), () {
      expect(detectDisagreements([]), isEmpty);
    });

    test('handles multiple disagreements', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/a.dart', lineNumber: 1,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/a.dart', lineNumber: 1,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: _nodeMeta(
            kind: 'bug', priority: 'p0', confidence: 0.9,
            filePath: 'lib/b.dart', lineNumber: 1,
          ),
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/b.dart', lineNumber: 1,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, hasLength(2));
    });

    test('ignores payloads with invalid priority', timeout: const Timeout.factor(2), () {
      final messages = [
        _makeReviewNode(
          senderId: 'agent-a',
          metadata: {
            'nodeType': 'bug',
            'priority': 'invalid',
            'confidence': 0.9,
            'filePath': 'lib/foo.dart',
            'lineNumber': 10,
          },
        ),
        _makeReviewNode(
          senderId: 'agent-b',
          metadata: _nodeMeta(
            kind: 'suggestion', priority: 'p2', confidence: 0.8,
            filePath: 'lib/foo.dart', lineNumber: 10,
          ),
        ),
      ];
      final result = detectDisagreements(messages);
      expect(result, isEmpty);
    });
  });
}
