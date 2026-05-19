import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => SingleChildScrollView(
  child: CcTheme(data: CcThemeData.light(), child: child),
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
    // Flat agent turn: name-only header present (senderId prefix), no avatar.
    expect(find.text('agen'), findsOneWidget);
    expect(find.byType(GitHubUserAvatar), findsNothing);
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

  testWidgets('renders reasoning, tools, and answer inline in order',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final base = DateTime(2026);
    final msg = _createMsg(
      content: 'Done — fixed the bug.',
      messageType: ChannelMessageType.agentTurn,
      metadata: {
        'streamComplete': true,
        'agentName': 'Builder',
        'segments': [
          {
            'type': 'reasoning',
            'text': 'Considering the request.',
            'ts': base.millisecondsSinceEpoch,
            'durationMs': 4000,
          },
          {
            'type': 'tool',
            'toolName': 'read_file',
            'toolCallId': 't1',
            'status': 'ok',
            'ts': base.add(const Duration(seconds: 4)).millisecondsSinceEpoch,
            'durationMs': 2000,
          },
          {
            'type': 'text',
            'text': 'Done — fixed the bug.',
            'ts': base.add(const Duration(seconds: 6)).millisecondsSinceEpoch,
            'durationMs': 100,
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

    // The whole turn is inline: reasoning prose (shown by default, not hidden
    // behind a master accordion), the tool call, and the answer text all render.
    expect(find.textContaining('Considering the request.'), findsWidgets);
    expect(find.textContaining('Read'), findsWidgets);
    expect(find.textContaining('Done — fixed the bug.'), findsWidgets);
  });

  testWidgets('renders agent turn with no segments', (tester) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final msg = _createMsg(
      content: 'Just an answer.',
      messageType: ChannelMessageType.agentTurn,
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

    // No transcript: the content renders directly as the answer prose.
    expect(find.byType(ChannelMessageBubble), findsOneWidget);
    expect(find.textContaining('Just an answer.'), findsWidgets);
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
