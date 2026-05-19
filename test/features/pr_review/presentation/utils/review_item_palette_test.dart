import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(WidgetBuilder builder) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        CcTheme(data: CcThemeData.light(), child: child!),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Builder(builder: builder),
    ),
  );
}

ChannelMessage _reviewMessage({
  required String id,
  required String nodeType,
  required String priority,
  required double confidence,
  required String status,
  String filePath = 'lib/foo.dart',
  int lineNumber = 42,
  DateTime? createdAt,
}) {
  return ChannelMessage(
    id: id,
    channelId: 'test-channel',
    senderId: 'agent-1',
    senderType: ChannelSenderType.agent,
    content: 'Test content\nSecond line',
    messageType: ChannelMessageType.reviewNode,
    metadata: {
      'nodeType': nodeType,
      'priority': priority,
      'confidence': confidence,
      'status': status,
      'filePath': filePath,
      'lineNumber': lineNumber,
    },
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  group('reviewItemDecor', () {
    testWidgets('returns correct label for each kind', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.bug,
          ReviewNodePriority.p0,
        );
        expect(decor.label, 'BUG');
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns SUGGEST label for suggestion kind', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.suggestion,
          ReviewNodePriority.p2,
        );
        expect(decor.label, 'SUGGEST');
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns RECOMMEND label for recommendation kind',
        (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.recommendation,
          ReviewNodePriority.p3,
        );
        expect(decor.label, 'RECOMMEND');
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns QUESTION label for question kind', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.question,
          ReviewNodePriority.p3,
        );
        expect(decor.label, 'QUESTION');
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns TICKET label for ticket kind', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.ticket,
          ReviewNodePriority.p2,
        );
        expect(decor.label, 'TICKET');
        return const SizedBox.shrink();
      }));
    });

    testWidgets('P0 bug uses error accent', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.bug,
          ReviewNodePriority.p0,
        );
        expect(decor.accent, tokens.fgErrorPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('P1 uses warning accent', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.bug,
          ReviewNodePriority.p1,
        );
        expect(decor.accent, tokens.fgWarningPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('P2 suggestion uses brand accent', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.suggestion,
          ReviewNodePriority.p2,
        );
        expect(decor.accent, tokens.fgBrandPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('P3 uses tertiary text accent', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.suggestion,
          ReviewNodePriority.p3,
        );
        expect(decor.accent, tokens.textTertiary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('ticket kind always uses fgBrandPrimary accent',
        (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final decor = reviewItemDecor(
          context,
          ReviewNodeKind.ticket,
          ReviewNodePriority.p0,
        );
        expect(decor.accent, tokens.fgBrandPrimary);
        return const SizedBox.shrink();
      }));
    });
  });

  group('reviewPriorityColor', () {
    testWidgets('returns fgErrorPrimary for P0', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewPriorityColor(ReviewNodePriority.p0, context);
        expect(color, tokens.fgErrorPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns fgWarningPrimary for P1', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewPriorityColor(ReviewNodePriority.p1, context);
        expect(color, tokens.fgWarningPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns fgBrandPrimary for P2', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewPriorityColor(ReviewNodePriority.p2, context);
        expect(color, tokens.fgBrandPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns textTertiary for P3', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewPriorityColor(ReviewNodePriority.p3, context);
        expect(color, tokens.textTertiary);
        return const SizedBox.shrink();
      }));
    });
  });

  group('reviewStatusRingColor', () {
    testWidgets('returns borderSecondary for null status (open)',
        (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewStatusRingColor(null, context);
        expect(color, tokens.borderSecondary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns borderSecondary for open status', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color = reviewStatusRingColor(ReviewNodeStatus.open, context);
        expect(color, tokens.borderSecondary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns fgBrandPrimary for consensusReady status',
        (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color =
            reviewStatusRingColor(ReviewNodeStatus.consensusReady, context);
        expect(color, tokens.fgBrandPrimary);
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns textTertiary with alpha for resolved status',
        (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color =
            reviewStatusRingColor(ReviewNodeStatus.resolved, context);
        expect(color, tokens.textTertiary.withValues(alpha: 0.5));
        return const SizedBox.shrink();
      }));
    });

    testWidgets('returns textTertiary for dismissed status', (tester) async {
      await tester.pumpWidget(_buildTestApp((context) {
        final tokens = context.designSystem!;
        final color =
            reviewStatusRingColor(ReviewNodeStatus.dismissed, context);
        expect(color, tokens.textTertiary);
        return const SizedBox.shrink();
      }));
    });
  });

  group('parseAndSortFindings', () {
    test('filters to reviewNode messages only', () {
      final textMessage = ChannelMessage(
        id: 'text-1',
        channelId: 'ch',
        senderId: 'user-1',
        senderType: ChannelSenderType.user,
        content: 'plain text',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024, 1, 1),
      );
      final reviewMessage = _reviewMessage(
        id: 'review-1',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
      );

      final result = parseAndSortFindings([textMessage, reviewMessage]);

      expect(result.length, 1);
      expect(result.first.message.id, 'review-1');
    });

    test('sorts by priority descending (P0 > P1 > P2 > P3)', () {
      final p3 = _reviewMessage(
        id: 'p3',
        nodeType: 'suggestion',
        priority: 'p3',
        confidence: 0.7,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );
      final p0 = _reviewMessage(
        id: 'p0',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.95,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );
      final p1 = _reviewMessage(
        id: 'p1',
        nodeType: 'bug',
        priority: 'p1',
        confidence: 0.85,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );
      final p2 = _reviewMessage(
        id: 'p2',
        nodeType: 'suggestion',
        priority: 'p2',
        confidence: 0.75,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );

      final result = parseAndSortFindings([p3, p0, p1, p2]);

      expect(result[0].message.id, 'p0');
      expect(result[1].message.id, 'p1');
      expect(result[2].message.id, 'p2');
      expect(result[3].message.id, 'p3');
    });

    test(
        'sorts by status within same priority (dismissed < resolved < consensus < open)',
        () {
      final open = _reviewMessage(
        id: 'open',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );
      final consensus = _reviewMessage(
        id: 'consensus',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'consensus_ready',
        createdAt: DateTime(2024, 1, 1),
      );
      final resolved = _reviewMessage(
        id: 'resolved',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'resolved',
        createdAt: DateTime(2024, 1, 1),
      );
      final dismissed = _reviewMessage(
        id: 'dismissed',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'dismissed',
        createdAt: DateTime(2024, 1, 1),
      );

      final result =
          parseAndSortFindings([open, consensus, resolved, dismissed]);

      expect(result[0].message.id, 'dismissed');
      expect(result[1].message.id, 'resolved');
      expect(result[2].message.id, 'consensus');
      expect(result[3].message.id, 'open');
    });

    test('sorts by createdAt ascending within same priority and status', () {
      final earlier = _reviewMessage(
        id: 'earlier',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
        createdAt: DateTime(2024, 1, 1),
      );
      final later = _reviewMessage(
        id: 'later',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
        createdAt: DateTime(2024, 1, 2),
      );
      final latest = _reviewMessage(
        id: 'latest',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
        createdAt: DateTime(2024, 1, 3),
      );

      final result = parseAndSortFindings([latest, earlier, later]);

      expect(result[0].message.id, 'earlier');
      expect(result[1].message.id, 'later');
      expect(result[2].message.id, 'latest');
    });

    test('skips messages whose payload fails validation', () {
      final noMetadata = ChannelMessage(
        id: 'no-meta',
        channelId: 'ch',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'content',
        messageType: ChannelMessageType.reviewNode,
        createdAt: DateTime(2024, 1, 1),
      );
      final missingPriority = ChannelMessage(
        id: 'missing-priority',
        channelId: 'ch',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'content',
        messageType: ChannelMessageType.reviewNode,
        metadata: {'nodeType': 'bug', 'confidence': 0.9, 'status': 'open'},
        createdAt: DateTime(2024, 1, 1),
      );
      final invalidConfidence = ChannelMessage(
        id: 'bad-conf',
        channelId: 'ch',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'content',
        messageType: ChannelMessageType.reviewNode,
        metadata: {
          'nodeType': 'bug',
          'priority': 'p0',
          'confidence': 1.5,
          'status': 'open',
        },
        createdAt: DateTime(2024, 1, 1),
      );
      final valid = _reviewMessage(
        id: 'valid',
        nodeType: 'bug',
        priority: 'p0',
        confidence: 0.9,
        status: 'open',
      );

      final result = parseAndSortFindings(
        [noMetadata, missingPriority, invalidConfidence, valid],
      );

      expect(result.length, 1);
      expect(result.first.message.id, 'valid');
    });

    test('returns empty list for empty input', () {
      final result = parseAndSortFindings([]);
      expect(result, isEmpty);
    });
  });
}
