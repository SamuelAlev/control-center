import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/review_node_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

ChannelMessage _bugMessage() => ChannelMessage(
      id: 'rn-1',
      channelId: 'ch-1',
      senderId: 'agent-1',
      senderType: ChannelSenderType.agent,
      content: 'Null dereference when foo is missing.',
      messageType: ChannelMessageType.reviewNode,
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
        githubAuthTokenProvider.overrideWith((ref) => 'test-token'),
        channelMessagesProvider
            .overrideWith((ref, channelId) => Stream.value([])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: [DesignSystemTokens.light()]),
        home: FTheme(
          data: FThemes.zinc.light.desktop,
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  group('ReviewNodeBubble', () {
    testWidgets('collapsed row shows kind, priority, confidence, and anchor',
        (tester) async {
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
      expect(find.textContaining('lib/foo.dart:42'), findsOneWidget);
    });

    testWidgets('expanding reveals body content and action bar',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_host(ReviewNodeBubble(message: _bugMessage())));
      await tester.pump();

      // Body is hidden initially.
      expect(find.textContaining('Null dereference'), findsNothing);

      await tester.tap(find.text('BUG'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Null dereference'), findsOneWidget);
    });
  });
}
