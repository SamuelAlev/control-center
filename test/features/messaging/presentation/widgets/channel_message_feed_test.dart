import 'dart:async';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../../../../helpers/active_workspace.dart';

Widget _wrap(Widget child) => Scaffold(
  body: CcTheme(data: CcThemeData.light(), child: child),
);

/// Hosts [child] under a real `/workspaces/:workspaceId` route.
///
/// The workspace itself comes from [activeWorkspaceIdOverride], not the route —
/// the feed reads it from the provider so a debounced callback cannot outlive the
/// `BuildContext` it would otherwise need. What the router adds here is the rest
/// of the navigation surface these two tests touch (permalink opening), which a
/// bare [MaterialApp] has no answer for.
Widget _routedApp(Widget child) => MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: GoRouter(
    initialLocation: '/workspaces/ws-1',
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId',
        builder: (context, state) => _wrap(child),
      ),
    ],
  ),
);

/// A no-host [ChannelReadRepository] fake. The real provider is RPC-flipped and
/// would open an in-process host from a widget test; what matters here is only
/// that stamping the cursor is reachable without one.
class _FakeChannelReadRepository implements ChannelReadRepository {
  @override
  Future<void> markChannelRead(
    String workspaceId,
    String channelId,
    String userId,
  ) async {}

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String channelId,
    String userId,
  ) => Stream.value(null);
}

/// The feed's own scrollable: the reverse (axisDirection up) viewport the
/// SuperListView builds. Scrollables inside bubbles (code blocks) run
/// horizontally, so the axis alone identifies the feed.
final _feedScrollable = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.up,
);

ScrollPosition _feedPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(_feedScrollable).position;

/// A channel with far more history than fits a 400×600 viewport, spaced 10
/// minutes apart so no header collapses and every row is full height.
List<ChannelMessage> _tallChannel({int count = 60}) => List.generate(
  count,
  (i) => ChannelMessage(
    id: 'm$i',
    channelId: 'ch-1',
    conversationId: 'ch-1',
    senderId: 'agent-1',
    senderType: ChannelSenderType.agent,
    content: 'Message $i',
    messageType: ChannelMessageType.text,
    createdAt: DateTime(2024, 1, 1, 12).add(Duration(minutes: 10 * i)),
  ),
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
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((
              messages: const <ChannelMessage>[],
              hasMore: false,
            )),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
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
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'Hello',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024),
      ),
      ChannelMessage(
        id: 'm2',
        channelId: 'ch-1',
        conversationId: 'ch-1',
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
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          for (var i = 1; i <= 2; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Message bodies render as RichText (the feed's single SelectionArea owns
    // selection, so bubbles render non-selectable rich text).
    expect(find.text('Hello', findRichText: true), findsOneWidget);
    expect(find.text('Hi there', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('renders messages when scrolled away from the live edge', (
    tester,
  ) async {
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
        conversationId: 'ch-1',
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
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          for (var i = 0; i < 3; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Message 0', findRichText: true), findsOneWidget);
    expect(find.text('Message 2', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('shows unread divider before the first unread agent message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final readCursor = DateTime(2024, 1, 1, 12, 0, 0);
    final messages = [
      // Older, already-read agent message (before the cursor).
      ChannelMessage(
        id: 'old',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'old reply',
        messageType: ChannelMessageType.text,
        createdAt: readCursor.subtract(const Duration(minutes: 1)),
      ),
      // A read user message (never "unread" to the user).
      ChannelMessage(
        id: 'u1',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: ChannelSenderType.user,
        content: 'a user turn',
        messageType: ChannelMessageType.text,
        createdAt: readCursor,
      ),
      // First unread agent message — the divider lands just before this.
      ChannelMessage(
        id: 'new',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'fresh agent reply',
        messageType: ChannelMessageType.text,
        createdAt: readCursor.add(const Duration(minutes: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(readCursor)),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The unread divider is inserted exactly once (1 unread agent message).
    expect(find.textContaining('New'), findsOneWidget);
    expect(find.text('fresh agent reply', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets(
    'unread divider clears when a turn lands while the reader sits on the '
    'live edge',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readCursor = DateTime(2024, 1, 1, 12);
      ChannelMessage agentTurn(String id, int minutesAfterCursor) =>
          ChannelMessage(
            id: id,
            channelId: 'ch-1',
            conversationId: 'ch-1',
            senderId: 'agent-1',
            senderType: ChannelSenderType.agent,
            content: 'reply $id',
            messageType: ChannelMessageType.text,
            createdAt: readCursor.add(Duration(minutes: minutesAfterCursor)),
          );

      final window =
          StreamController<
            ({List<ChannelMessage> messages, bool hasMore})
          >.broadcast();
      addTearDown(window.close);
      final unread = [agentTurn('m1', 1)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            channelFeedWindowedProvider((
              channelId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWith((ref) => window.stream),
            channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            channelUserLastReadAtProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(readCursor)),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
            // The feed stamps the server read cursor when it treats an arrival
            // as witnessed; the real provider is RPC-flipped and would open a
            // host from a widget test.
            channelReadRepositoryProvider.overrideWith(
              (ref) => _FakeChannelReadRepository(),
            ),
          ],
          child: _routedApp(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      );
      window.add((messages: unread, hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Opened with one turn past the cursor: the divider marks it.
      expect(find.textContaining('New'), findsOneWidget);

      // A fresh turn arrives. The channel is short enough to fit the viewport,
      // so the reader is demonstrably parked on the live edge watching it land
      // — even though the open-time anchor left FollowState in `anchored`. That
      // is read, not new, and the stale divider above what they just read goes
      // away instead of sitting there until the channel is reopened.
      window.add((messages: [...unread, agentTurn('m2', 2)], hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('reply m2', findRichText: true), findsOneWidget);
      expect(find.textContaining('New'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle(const Duration(seconds: 5));
    },
  );

  testWidgets('no unread divider when cursor is null (never opened)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = [
      ChannelMessage(
        id: 'a1',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: ChannelSenderType.agent,
        content: 'hello',
        messageType: ChannelMessageType.text,
        createdAt: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('New'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets(
    'no unread divider for a reply that arrives while the reader is present',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final readCursor = DateTime(2024, 1, 1, 12, 0, 0);
      final opening = [
        ChannelMessage(
          id: 'u1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'test',
          messageType: ChannelMessageType.text,
          createdAt: readCursor,
        ),
      ];
      // The reply lands after the cursor — the condition that used to be the
      // whole test for "unread" — but the reader is sitting right here watching
      // it arrive, so it must NOT draw a divider.
      final withReply = [
        ...opening,
        ChannelMessage(
          id: 'a1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'live reply',
          messageType: ChannelMessageType.text,
          createdAt: readCursor.add(const Duration(minutes: 1)),
        ),
      ];

      final window =
          StreamController<({List<ChannelMessage> messages, bool hasMore})>();
      addTearDown(window.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            channelFeedWindowedProvider((
              channelId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWith((ref) => window.stream),
            channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            channelUserLastReadAtProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(readCursor)),
            channelReadRepositoryProvider.overrideWithValue(
              _FakeChannelReadRepository(),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
          ],
          child: _routedApp(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      );

      window.add((messages: opening, hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      window.add((messages: withReply, hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('live reply', findRichText: true), findsOneWidget);
      expect(find.textContaining('New'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle(const Duration(seconds: 5));
    },
  );

  testWidgets('opens on the live edge, not on the first unread turn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = _tallChannel();
    // Read up to the 40th turn: 20 unread turns sit above the fold, which the
    // feed must NOT scroll up to. Opening lands at the bottom, no animation.
    final readCursor = messages[40].createdAt;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          channelUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(readCursor)),
          channelReadRepositoryProvider.overrideWithValue(
            _FakeChannelReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Offset 0 in a reverse list IS the newest end.
    expect(_feedPosition(tester).pixels, 0);
    expect(find.text('Message 59', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('returning to a hidden chat lands back on the live edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final messages = _tallChannel();
    final overrides = [
      channelFeedWindowedProvider((
        channelId: 'ch-1',
        conversationId: 'ch-1',
      )).overrideWith(
        (ref) => Stream.value((messages: messages, hasMore: false)),
      ),
      channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
      codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
      channelUserLastReadAtProvider(
        'ch-1',
      ).overrideWith((ref) => Stream.value(null)),
      channelReadRepositoryProvider.overrideWithValue(
        _FakeChannelReadRepository(),
      ),
      agentDetailProvider('agent-1').overrideWith((ref) async => null),
    ];

    // The chat sits in an IndexedStack tab, exactly as the messaging IDE hosts
    // it: switching away hides it (Visibility.of == false) with its element,
    // scroll offset and follow state all kept alive.
    Widget host(int index) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _wrap(
          IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: const [
              ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
              SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(_feedPosition(tester).pixels, 0);

    // Read back into history (reverse list ⇒ dragging down goes older).
    await tester.drag(_feedScrollable, const Offset(0, 400));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(_feedPosition(tester).pixels, greaterThan(0));

    // Switch to the other tab and back: the surviving offset is reset.
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(_feedPosition(tester).pixels, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('opening a permalink (notification tap) throws nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Everything the frame reports, not just the first: consuming the deep
    // link touches a provider, the anchor scroll and the highlight pulse, and
    // each used to throw on its own.
    final errors = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previousOnError);

    final messages = _tallChannel();

    final container = ProviderContainer(
      overrides: [
        channelFeedWindowedProvider((
          channelId: 'ch-1',
          conversationId: 'ch-1',
        )).overrideWith(
          (ref) => Stream.value((messages: messages, hasMore: false)),
        ),
        channelTurnRelayProvider('ch-1').overrideWith((ref) {}),
        codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
        channelUserLastReadAtProvider(
          'ch-1',
        ).overrideWith((ref) => Stream.value(null)),
        channelReadRepositoryProvider.overrideWithValue(
          _FakeChannelReadRepository(),
        ),
        agentDetailProvider('agent-1').overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    // A notification tap routes to `?m=<id>` and lands here: a one-shot
    // targeting a message far up in the scrollback.
    container.read(pendingFocusMessageProvider.notifier).set((
      channelId: 'ch-1',
      messageId: 'm3',
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const ChannelMessageFeed(channelId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );

    // Frame by frame: the jump, the anchor scroll and the 1.2s highlight pulse
    // overlap, and a coarse settle step steps straight over them.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }

    expect(errors, isEmpty, reason: errors.join('\n---\n'));
    // The one-shot is consumed, so a later rebuild doesn't re-scroll.
    expect(container.read(pendingFocusMessageProvider), isNull);
    // The target was reached rather than left at the live edge.
    expect(find.text('Message 3', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(errors, isEmpty, reason: errors.join('\n---\n'));
  });
}
