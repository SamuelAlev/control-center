import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/review_node_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Message _bugMessage() => Message(
  id: 'rn-1',
  spaceId: 'ch-1',
  conversationId: 'ch-1',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: 'Null dereference when foo is missing.',
  messageType: MessageType.reviewNode,
  metadata: const {
    'nodeType': 'bug',
    'priority': 'p1',
    'confidence': 0.87,
    'status': 'open',
    'filePath': 'lib/foo.dart',
    'lineNumber': 42,
  },
  createdAt: DateTime(2026),
);

Widget _host(Widget child) => ProviderScope(
  overrides: [
    agentDetailProvider.overrideWith((ref, id) async => null),
    spaceMessagesProvider.overrideWith((ref, spaceId) => Stream.value([])),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        CcTheme(data: CcThemeData.light(), child: child!),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  group('ReviewNodeBubble', () {
    testWidgets('collapsed row shows kind, priority, confidence and anchor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_host(ReviewNodeBubble(message: _bugMessage())));
      await tester.pump();

      expect(find.text('BUG'), findsOneWidget);
      expect(find.textContaining('P1'), findsOneWidget);
      expect(find.textContaining('87%'), findsOneWidget);
      // The row carries the BASENAME so the finding's own headline gets the
      // width; the full path travels with the body it describes.
      expect(find.text('foo.dart:42'), findsOneWidget);
      expect(find.textContaining('Null dereference'), findsOneWidget);
    });

    testWidgets('collapsed row shows a readable status pill', (tester) async {
      // Regression: the pill drew `borderSecondary` text over a 12%-alpha wash
      // of the same color, so "Open" was invisible on every finding.
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_host(ReviewNodeBubble(message: _bugMessage())));
      await tester.pump();

      final badge = tester.widget<CcBadge>(
        find.widgetWithText(CcBadge, 'Open'),
      );
      expect(badge.variant, CcBadgeVariant.neutral);
      expect(badge.icon, isNotNull);
    });

    testWidgets('expanding reveals the full anchor and the action bar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_host(ReviewNodeBubble(message: _bugMessage())));
      await tester.pump();

      // Body is hidden initially.
      expect(find.text('lib/foo.dart:42'), findsNothing);
      expect(find.widgetWithText(CcButton, 'Fix'), findsNothing);

      await tester.tap(find.text('BUG'));
      await tester.pumpAndSettle();

      expect(find.text('lib/foo.dart:42'), findsOneWidget);
      // The same verbs the review tab offers, from the same shared bar.
      expect(find.widgetWithText(CcButton, 'Fix'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Comment'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Fixed'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Dismiss'), findsOneWidget);
    });
  });
}
