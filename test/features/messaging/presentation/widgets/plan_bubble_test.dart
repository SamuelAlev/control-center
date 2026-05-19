import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/plan_bubble.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FTheme(data: FThemes.zinc.light.desktop, child: child),
      ),
    );

ChannelMessage _plan(String status, {String content = '## Steps\n- one\n- two'}) {
  return ChannelMessage(
    id: 'plan-1',
    channelId: 'ch',
    senderId: 'agent',
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.plan,
    metadata: {'planStatus': status},
    createdAt: DateTime(2026),
  );
}

void main() {
  group('PlanBubble', () {
    testWidgets('renders PLAN header and pending actions', (tester) async {
      await tester.pumpWidget(_host(PlanBubble(message: _plan('pending'))));
      await tester.pumpAndSettle();

      // Header strip shows uppercase label.
      expect(find.text('PLAN'), findsOneWidget);

      // All three action buttons render.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.compress), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('approved status replaces buttons with footer', (tester) async {
      await tester.pumpWidget(_host(PlanBubble(message: _plan('approved'))));
      await tester.pumpAndSettle();

      expect(find.text('PLAN APPROVED'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.textContaining('Plan approved'), findsOneWidget);
    });

    testWidgets('refining status shows progress indicator', (tester) async {
      await tester.pumpWidget(_host(PlanBubble(message: _plan('refining'))));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });
  });
}
