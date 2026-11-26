import 'dart:ui' show Tristate;

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/compaction_divider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

/// The slim divider a compaction renders as.
///
/// The behaviour worth pinning is that the summary is COLLAPSED by default. A
/// compaction summary stands in for dozens of turns, so it is long by
/// construction — rendering it inline drops a page of prose into the middle of
/// the conversation at exactly the moment the reader is scrolling past it.
void main() {
  Message compaction({int? folded, String summary = 'A long summary.'}) =>
      Message(
        id: 'm1',
        spaceId: 'sp',
        conversationId: 'c1',
        senderId: 'system',
        senderType: SenderType.user,
        messageType: MessageType.system,
        content: summary,
        metadata: {
          'kind': 'compaction',
          'compactedCount': ?folded,
        },
        createdAt: DateTime.utc(2026),
      );

  group('CompactionDivider', () {
    testWidgets('collapses the summary by default', (tester) async {
      await tester.pumpWidget(
        testWrap(
          CompactionDivider(
            message: compaction(summary: 'THE SUMMARY BODY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('THE SUMMARY BODY'), findsNothing);
    });

    testWidgets('expands to the summary on tap, and collapses again', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          CompactionDivider(
            message: compaction(summary: 'THE SUMMARY BODY'),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(CcTappable));
      await tester.pumpAndSettle();
      expect(find.textContaining('THE SUMMARY BODY'), findsWidgets);

      await tester.tap(find.byType(CcTappable));
      await tester.pumpAndSettle();
      expect(find.textContaining('THE SUMMARY BODY'), findsNothing);
    });

    testWidgets('names how many messages were folded when the server said', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(CompactionDivider(message: compaction(folded: 42))),
      );
      await tester.pump();

      expect(find.textContaining('42'), findsOneWidget);
    });

    testWidgets('still renders when the count is missing', (tester) async {
      // An older compaction row carries no count. The divider is still the
      // context boundary, which is the fact worth showing.
      await tester.pumpWidget(
        testWrap(CompactionDivider(message: compaction())),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CcTappable), findsOneWidget);
    });

    testWidgets('is announced as an expandable control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        testWrap(CompactionDivider(message: compaction(folded: 7))),
      );
      await tester.pump();

      // A control that only reads as a horizontal rule is one a
      // screen-reader user cannot open.
      final node = tester.getSemantics(find.byType(CcTappable));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      expect(node.label, contains('7'));
      handle.dispose();
    });

    testWidgets('opens and closes from the keyboard', (tester) async {
      await tester.pumpWidget(
        testWrap(
          CompactionDivider(message: compaction(summary: 'THE SUMMARY BODY')),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.textContaining('THE SUMMARY BODY'), findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.textContaining('THE SUMMARY BODY'), findsNothing);
    });
  });
}
