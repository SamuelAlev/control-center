import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _wrap(Widget child) => SingleChildScrollView(
  child: FTheme(data: FThemes.zinc.light.desktop, child: child),
);

List _testOverrides() => [
  codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
  githubUserProvider.overrideWith((ref) async => null),
  activeStreamRegistryProvider.overrideWithValue(ActiveStreamRegistry()),
  agentDetailProvider('agent-1').overrideWith((ref) => null),
];

ChannelMessage _createMsg({
  String id = 'msg-1',
  String content = 'Hello',
  ChannelMessageType messageType = ChannelMessageType.text,
  ChannelSenderType senderType = ChannelSenderType.agent,
  String senderId = 'agent-1',
  DateTime? createdAt,
  Map<String, dynamic>? metadata,
}) {
  return ChannelMessage(
    id: id,
    channelId: 'ch-1',
    senderId: senderId,
    senderType: senderType,
    content: content,
    messageType: messageType,
    metadata: metadata,
    createdAt: createdAt ?? DateTime(2024),
  );
}

void main() {
  testWidgets('renders text message from agent', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(content: 'Agent response');

    await tester.pumpWidget(
      ProviderScope(
          overrides: [..._testOverrides()],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Agent response'), findsOneWidget);
  });

  testWidgets('renders user message', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: 'User message',
      senderType: ChannelSenderType.user,
      senderId: 'user',
    );

    await tester.pumpWidget(
      ProviderScope(
          overrides: [..._testOverrides()],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('User message'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
  });

  testWidgets('renders system message', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: 'System notification',
      messageType: ChannelMessageType.system,
    );

    await tester.pumpWidget(
      ProviderScope(
          overrides: [..._testOverrides()],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('System notification'), findsOneWidget);
  });

  testWidgets('renders ticket card message', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: 'Ticket description',
      messageType: ChannelMessageType.ticketCard,
    );

    await tester.pumpWidget(
      ProviderScope(
          overrides: [..._testOverrides()],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ticket description'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });

  testWidgets('renders thinking timeline summary when events present',
      (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: '',
      messageType: ChannelMessageType.thinking,
      metadata: {
        'streamComplete': true,
        'agentName': 'Builder',
        'events': [
          {
            'kind': 'reasoning',
            'content': 'Considering the request.',
            'timestamp': DateTime(2026).millisecondsSinceEpoch,
            'durationMs': 4000,
          },
          {
            'kind': 'tool_call',
            'content': 'read_file',
            'toolName': 'read_file',
            'timestamp': DateTime(2026).add(const Duration(seconds: 4)).millisecondsSinceEpoch,
            'durationMs': 2000,
          },
        ],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._testOverrides()],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Thought for'), findsOneWidget);
    expect(find.textContaining('1 tool call'), findsOneWidget);
  });

  testWidgets('renders empty thinking bubble when no events', (tester) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: '',
      messageType: ChannelMessageType.thinking,
      metadata: {'agentName': 'Builder'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._testOverrides()],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Empty timeline: no summary, no error.
    expect(find.byType(ChannelMessageBubble), findsOneWidget);
    expect(find.textContaining('Thought for'), findsNothing);
  });

  testWidgets('renders ticket with metadata title', (tester) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: 'Fallback',
      messageType: ChannelMessageType.ticketCard,
      metadata: {'title': 'Bug Fix', 'ticketUrl': 'https://example.com'},
    );

    await tester.pumpWidget(
      ProviderScope(
          overrides: [..._testOverrides()],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrap(ChannelMessageBubble(message: msg)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bug Fix'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });
}
