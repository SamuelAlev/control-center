import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => Scaffold(
  body: CcTheme(data: CcThemeData.light(), child: child),
);


void main() {
  testWidgets('renders empty state', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelFeedWindowedProvider('ch-1').overrideWith(
            (ref) => Stream.value(
              (messages: const <ChannelMessage>[], hasMore: false),
            ),
          ),
          threadReplyMapProvider('ch-1').overrideWith((ref) => const {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const ChannelMessageFeed(channelId: 'ch-1')),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('No messages yet'), findsOneWidget);
    expect(find.text('Send the first message'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('renders messages', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = [
      ChannelMessage(
        id: 'm1',
        channelId: 'ch-1',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'Hello',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024),
      ),
      ChannelMessage(
        id: 'm2',
        channelId: 'ch-1',
        senderId: 'agent-2',
        senderType: ChannelSenderType.agent,
        content: 'Hi there',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelFeedWindowedProvider('ch-1').overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          threadReplyMapProvider('ch-1').overrideWith((ref) => const {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          for (var i = 1; i <= 2; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],

        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const ChannelMessageFeed(channelId: 'ch-1')),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hi there'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });


  testWidgets('auto scrolls when new message arrives', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = List.generate(
      3,
      (i) => ChannelMessage(
        id: 'm$i',
        channelId: 'ch-1',
        senderId: 'agent-$i',
        senderType: ChannelSenderType.agent,
        content: 'Message $i',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelFeedWindowedProvider('ch-1').overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          threadReplyMapProvider('ch-1').overrideWith((ref) => const {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          for (var i = 0; i < 3; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const ChannelMessageFeed(channelId: 'ch-1')),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Message 0'), findsOneWidget);
    expect(find.text('Message 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
