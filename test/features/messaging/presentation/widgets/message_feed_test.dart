import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
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

/// A no-host [SpaceReadRepository] fake. The real provider is RPC-flipped and
/// would open an in-process host from a widget test; what matters here is only
/// that stamping the cursor is reachable without one.
class _FakeSpaceReadRepository implements SpaceReadRepository {
  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId,
  ) async {}

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
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

/// A space with far more history than fits a 400×600 viewport, spaced 10
/// minutes apart so no header collapses and every row is full height.
List<Message> _tallSpace({int count = 60}) => List.generate(
  count,
  (i) => Message(
    id: 'm$i',
    spaceId: 'ch-1',
    conversationId: 'ch-1',
    senderId: 'agent-1',
    senderType: SenderType.agent,
    content: 'Message $i',
    messageType: MessageType.text,
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
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) =>
                Stream.value((messages: const <Message>[], hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
      Message(
        id: 'm1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'Hello',
        messageType: MessageType.text,
        createdAt: DateTime(2024),
      ),
      Message(
        id: 'm2',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-2',
        senderType: SenderType.agent,
        content: 'Hi there',
        messageType: MessageType.text,
        createdAt: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          for (var i = 1; i <= 2; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
      (i) => Message(
        id: 'm$i',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-$i',
        senderType: SenderType.agent,
        content: 'Message $i',
        messageType: MessageType.text,
        createdAt: DateTime(2024),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          for (var i = 0; i < 3; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
      Message(
        id: 'old',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'old reply',
        messageType: MessageType.text,
        createdAt: readCursor.subtract(const Duration(minutes: 1)),
      ),
      // A read user message (never "unread" to the user).
      Message(
        id: 'u1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: SenderType.user,
        content: 'a user turn',
        messageType: MessageType.text,
        createdAt: readCursor,
      ),
      // First unread agent message — the divider lands just before this.
      Message(
        id: 'new',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'fresh agent reply',
        messageType: MessageType.text,
        createdAt: readCursor.add(const Duration(minutes: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(readCursor)),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
      Message agentTurn(String id, int minutesAfterCursor) => Message(
        id: id,
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'reply $id',
        messageType: MessageType.text,
        createdAt: readCursor.add(Duration(minutes: minutesAfterCursor)),
      );

      final window =
          StreamController<
            ({List<Message> messages, bool hasMore})
          >.broadcast();
      addTearDown(window.close);
      final unread = [agentTurn('m1', 1)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            spaceFeedWindowedProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWith((ref) => window.stream),
            spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            spaceUserLastReadAtProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(readCursor)),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
            // The feed stamps the server read cursor when it treats an arrival
            // as witnessed; the real provider is RPC-flipped and would open a
            // host from a widget test.
            spaceReadRepositoryProvider.overrideWith(
              (ref) => _FakeSpaceReadRepository(),
            ),
          ],
          child: _routedApp(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      );
      window.add((messages: unread, hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Opened with one turn past the cursor: the divider marks it.
      expect(find.textContaining('New'), findsOneWidget);

      // A fresh turn arrives. The space is short enough to fit the viewport,
      // so the reader is demonstrably parked on the live edge watching it land
      // — even though the open-time anchor left FollowState in `anchored`. That
      // is read, not new and the stale divider above what they just read goes
      // away instead of sitting there until the space is reopened.
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
      Message(
        id: 'a1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'hello',
        messageType: MessageType.text,
        createdAt: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          // The live turn relay dials the server; widget tests have no RPC
          // client, so the fold is a no-op here.
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(null)),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
        Message(
          id: 'u1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'user',
          senderType: SenderType.user,
          content: 'test',
          messageType: MessageType.text,
          createdAt: readCursor,
        ),
      ];
      // The reply lands after the cursor — the condition that used to be the
      // whole test for "unread" — but the reader is sitting right here watching
      // it arrive, so it must NOT draw a divider.
      final withReply = [
        ...opening,
        Message(
          id: 'a1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: SenderType.agent,
          content: 'live reply',
          messageType: MessageType.text,
          createdAt: readCursor.add(const Duration(minutes: 1)),
        ),
      ];

      final window =
          StreamController<({List<Message> messages, bool hasMore})>();
      addTearDown(window.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            spaceFeedWindowedProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWith((ref) => window.stream),
            spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            spaceUserLastReadAtProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(readCursor)),
            spaceReadRepositoryProvider.overrideWithValue(
              _FakeSpaceReadRepository(),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
          ],
          child: _routedApp(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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

    final messages = _tallSpace();
    // Read up to the 40th turn: 20 unread turns sit above the fold, which the
    // feed must NOT scroll up to. Opening lands at the bottom, no animation.
    final readCursor = messages[40].createdAt;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: messages, hasMore: false)),
          ),
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          spaceUserLastReadAtProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(readCursor)),
          spaceReadRepositoryProvider.overrideWithValue(
            _FakeSpaceReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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

    final messages = _tallSpace();
    final overrides = [
      spaceFeedWindowedProvider((
        spaceId: 'ch-1',
        conversationId: 'ch-1',
      )).overrideWith(
        (ref) => Stream.value((messages: messages, hasMore: false)),
      ),
      spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
      codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
      spaceUserLastReadAtProvider(
        'ch-1',
      ).overrideWith((ref) => Stream.value(null)),
      spaceReadRepositoryProvider.overrideWithValue(_FakeSpaceReadRepository()),
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
              SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
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
    // link touches a provider, the anchor scroll and the highlight pulse and
    // each used to throw on its own.
    final errors = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());

    final messages = _tallSpace(count: 20);

    final container = ProviderContainer(
      overrides: [
        activeWorkspaceIdOverride(),
        spaceFeedWindowedProvider((
          spaceId: 'ch-1',
          conversationId: 'ch-1',
        )).overrideWith(
          (ref) => Stream.value((messages: messages, hasMore: false)),
        ),
        spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
        codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
        spaceUserLastReadAtProvider(
          'ch-1',
        ).overrideWith((ref) => Stream.value(null)),
        spaceReadRepositoryProvider.overrideWithValue(
          _FakeSpaceReadRepository(),
        ),
        agentDetailProvider('agent-1').overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    // A notification tap routes to `?m=<id>` and lands here: a one-shot
    // targeting a message far up in the scrollback.
    container.read(pendingFocusMessageProvider.notifier).set((
      spaceId: 'ch-1',
      messageId: 'm3',
    ));

    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _wrap(
              const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
            ),
          ),
        ),
      );

      // Frame by frame first: the jump and the 250ms anchor scroll overlap, and
      // a coarse unbounded settle used to skip straight over the throws — and
      // sixty pumps of a 60-row tree is how this test burned CI's 10 minute
      // timeout. Restore FlutterError.onError before expect(), or the binding
      // asserts that the override leaked.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
    } finally {
      FlutterError.onError = previousOnError;
    }

    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 16),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 2),
      );
    } on FlutterError {
      // Settle hit the 2s cap; the assertions below still stand.
    }

    expect(errors, isEmpty, reason: errors.join('\n---\n'));
    // The one-shot is consumed, so a later rebuild doesn't re-scroll.
    expect(container.read(pendingFocusMessageProvider), isNull);
    // Left the live edge (offset 0) rather than staying on the newest turn.
    expect(_feedPosition(tester).pixels, isNot(0));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
