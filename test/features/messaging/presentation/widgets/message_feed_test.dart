import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_turn_row_views.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_conversation_read_repository.dart';

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
  localizationsDelegates: appLocalizationsDelegates,
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(null)),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          for (var i = 1; i <= 2; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(null)),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          for (var i = 0; i < 3; i++)
            agentDetailProvider('agent-$i').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(FeedPosition(at: readCursor, seq: 0))),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
            conversationLastReadProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWithValue(
              AsyncData(FeedPosition(at: readCursor, seq: 0)),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
            // The feed stamps the server read cursor when it treats an arrival
            // as witnessed; the real provider is RPC-flipped and would open a
            // host from a widget test.
            conversationReadRepositoryProvider.overrideWith(
              (ref) => FakeConversationReadRepository(),
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

  testWidgets('no unread divider when the conversation was never read', (
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(null)),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
            conversationLastReadProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWithValue(
              AsyncData(FeedPosition(at: readCursor, seq: 0)),
            ),
            conversationReadRepositoryProvider.overrideWithValue(
              FakeConversationReadRepository(),
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
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(FeedPosition(at: readCursor, seq: 0))),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
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
      activeWorkspaceIdOverride(),
      spaceFeedWindowedProvider((
        spaceId: 'ch-1',
        conversationId: 'ch-1',
      )).overrideWith(
        (ref) => Stream.value((messages: messages, hasMore: false)),
      ),
      spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
      codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
      conversationLastReadProvider((
        spaceId: 'ch-1',
        conversationId: 'ch-1',
      )).overrideWithValue(AsyncData(null)),
      conversationReadRepositoryProvider.overrideWithValue(
        FakeConversationReadRepository(),
      ),
      agentDetailProvider('agent-1').overrideWith((ref) async => null),
    ];

    // The chat sits in an IndexedStack tab, exactly as the messaging IDE hosts
    // it: switching away hides it (Visibility.of == false) with its element,
    // scroll offset and follow state all kept alive.
    Widget host(int index) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
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

  for (final keepMounted in [true, false]) {
    testWidgets('completed turn rehydrates after returning to '
        '${keepMounted ? 'a hidden' : 'a remounted'} conversation', (
      tester,
    ) async {
      final unfinished = Message(
        id: 'turn-1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: SenderType.agent,
        content: 'Partial answer',
        messageType: MessageType.agentTurn,
        metadata: const {
          'agentName': 'Architect',
          'streamComplete': false,
          'segments_elided': true,
        },
        createdAt: DateTime(2024),
      );
      var detail = unfinished;
      final window =
          StreamController<
            ({List<Message> messages, bool hasMore})
          >.broadcast();
      final selected = ValueNotifier(0);
      addTearDown(window.close);
      addTearDown(selected.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdOverride(),
            spaceFeedWindowedProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWith((ref) async* {
              // Navigation can replay an unfinished RPC snapshot before
              // the live subscription supplies the completed list row.
              yield (messages: [unfinished], hasMore: false);
              yield* window.stream;
            }),
            messageDetailProvider('turn-1').overrideWith((ref) {
              // The real detail read stays warm briefly across navigation.
              ref.keepAlive();
              return Stream.value(detail);
            }),
            spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
            codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
            conversationLastReadProvider((
              spaceId: 'ch-1',
              conversationId: 'ch-1',
            )).overrideWithValue(AsyncData(null)),
            conversationReadRepositoryProvider.overrideWithValue(
              FakeConversationReadRepository(),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _wrap(
              ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, index, _) {
                  const feed = SpaceMessageFeed(
                    spaceId: 'ch-1',
                    conversationId: 'ch-1',
                  );
                  final other = Center(
                    child: Text(keepMounted ? 'Another space' : 'Pull request'),
                  );
                  return keepMounted
                      ? IndexedStack(
                          index: index,
                          sizing: StackFit.expand,
                          children: [feed, other],
                        )
                      : index == 0
                      ? feed
                      : other;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Partial answer', findRichText: true), findsOneWidget);

      selected.value = 1;
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(
        find.text(keepMounted ? 'Another space' : 'Pull request'),
        findsOneWidget,
      );
      detail = unfinished.copyWith(
        content: 'Final answer',
        metadata: {
          'agentName': 'Architect',
          'streamComplete': true,
          'segments': encodeTranscript([
            TextSegment(
              text: 'Final transcript after navigation',
              startedAt: DateTime(2024),
              durationMs: 10,
            ),
          ]),
        },
      );
      selected.value = 0;
      await tester.pumpAndSettle(const Duration(seconds: 5));
      window.add((
        messages: [
          detail.copyWith(
            metadata: const {
              'agentName': 'Architect',
              'streamComplete': true,
              'segments_elided': true,
            },
          ),
        ],
        hasMore: false,
      ));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
      expect(
        find.text('Final transcript after navigation', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Partial answer', findRichText: true), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a turn that streamed here settles on the server transcript, '
      'not the relay snapshot', (tester) async {
    // The relay's last snapshot can stop short of what the server persisted.
    // The feed used to settle on it and cut the turn off.
    final streaming = Message(
      id: 'turn-1',
      spaceId: 'ch-1',
      conversationId: 'ch-1',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      content: '',
      messageType: MessageType.agentTurn,
      metadata: const {
        'agentName': 'Architect',
        'streamComplete': false,
        'segments_elided': true,
      },
      createdAt: DateTime(2024),
    );
    final finished = streaming.copyWith(
      content: 'Opening paragraph. Closing paragraph.',
      metadata: const {
        'agentName': 'Architect',
        'streamComplete': true,
        'segments_elided': true,
      },
    );
    final persisted = finished.copyWith(
      metadata: {
        'agentName': 'Architect',
        'streamComplete': true,
        'segments': encodeTranscript([
          TextSegment(
            text: 'Opening paragraph. Closing paragraph.',
            startedAt: DateTime(2024),
            durationMs: 10,
          ),
        ]),
      },
    );
    final window =
        StreamController<({List<Message> messages, bool hasMore})>.broadcast();
    addTearDown(window.close);
    final registry = ActiveStreamRegistry();
    final transcripts = TranscriptLruCache();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          activeStreamRegistryProvider.overrideWithValue(registry),
          transcriptCacheProvider.overrideWithValue(transcripts),
          spaceFeedWindowedProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith((ref) async* {
            yield (messages: [streaming], hasMore: false);
            yield* window.stream;
          }),
          messageDetailProvider(
            'turn-1',
          ).overrideWith((ref) => Stream.value(persisted)),
          spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
          codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
          conversationLastReadProvider((
            spaceId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWithValue(AsyncData(null)),
          conversationReadRepositoryProvider.overrideWithValue(
            FakeConversationReadRepository(),
          ),
          agentDetailProvider('agent-1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(
            const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
          ),
        ),
      ),
    );
    registry
      ..register('turn-1', spaceId: 'ch-1')
      ..apply(
        'turn-1',
        SegmentOpened(0, TextSegment(text: '', startedAt: DateTime(2024))),
      )
      ..apply('turn-1', const SegmentDelta(0, 'Opening paragraph.'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(
      find.textContaining('Opening paragraph.', findRichText: true),
      findsOneWidget,
    );
    // Laid out row by row, not as the single bubble that reads on its own.
    expect(find.byType(TurnPartRowView), findsWidgets);
    expect(find.byType(AgentTurn), findsNothing);

    // What the relay does on TurnFinished: cache its last snapshot (here
    // missing the tail), then drop the live stream.
    transcripts.put('turn-1', registry.snapshot('turn-1')!);
    await registry.unregister('turn-1');
    window.add((messages: [finished], hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(tester.takeException(), isNull);
    expect(
      find.text('Opening paragraph. Closing paragraph.', findRichText: true),
      findsOneWidget,
    );

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
        conversationLastReadProvider((
          spaceId: 'ch-1',
          conversationId: 'ch-1',
        )).overrideWithValue(AsyncData(null)),
        conversationReadRepositoryProvider.overrideWithValue(
          FakeConversationReadRepository(),
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
            localizationsDelegates: appLocalizationsDelegates,
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

  testWidgets('sending on the live edge stays locked to the bottom', (
    tester,
  ) async {
    final window = StreamController<({List<Message> messages, bool hasMore})>();
    addTearDown(window.close);
    await _pumpLiveFeed(tester, window);

    final history = _tallSpace();
    window.add((messages: history, hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(_feedPosition(tester).pixels, 0);

    final sent = [...history, _sent(history)];
    window.add((messages: sent, hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(_feedPosition(tester).pixels, 0);
    expect(find.text('just sent', findRichText: true), findsOneWidget);

    // The answer grows in at the live edge and the view keeps following it.
    for (final content in [
      'Partial',
      List.filled(40, 'A long streamed answer line.').join('\n\n'),
    ]) {
      window.add((messages: [...sent, _reply(sent, content)], hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(_feedPosition(tester).pixels, 0);
    }
    expect(find.text('Jump to latest'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('sending while reading history leaves the view where it is', (
    tester,
  ) async {
    final window = StreamController<({List<Message> messages, bool hasMore})>();
    addTearDown(window.close);
    await _pumpLiveFeed(tester, window);

    final history = _tallSpace();
    window.add((messages: history, hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Read back into history (reverse list ⇒ dragging down goes older), then
    // let the user-scroll compensation hold expire in real time.
    await tester.drag(_feedScrollable, const Offset(0, 400));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    expect(_feedPosition(tester).pixels, greaterThan(0));

    // A turn landing below the fold first: the drag left the newest row
    // unbuilt, and the arrival that builds it again corrects its stale
    // extent. What's under test is a reader settled in the scrollback.
    final settled = [...history, _reply(history, 'earlier', id: 'earlier')];
    window.add((messages: settled, hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    final reading = find.text('Message 55', findRichText: true);
    final before = tester.getTopLeft(reading).dy;

    // Sending doesn't pull the reader down to their turn. Rows that land below
    // the fold are laid out against estimated extents, so allow the small
    // settle when one is first measured — far less than the row being read.
    final sent = [...settled, _sent(settled)];
    window.add((messages: sent, hasMore: false));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.getTopLeft(reading).dy, closeTo(before, 24));
    expect(find.text('just sent', findRichText: true), findsNothing);

    // The answer streaming in below the fold holds them in place too.
    for (final content in [
      'Partial',
      List.filled(40, 'A long streamed answer line.').join('\n\n'),
    ]) {
      window.add((messages: [...sent, _reply(sent, content)], hasMore: false));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(tester.getTopLeft(reading).dy, closeTo(before, 24));
    }
    expect(find.text('Jump to latest'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}

/// Pumps a feed fed by [window] at 400×600, with no unread cursor.
Future<void> _pumpLiveFeed(
  WidgetTester tester,
  StreamController<({List<Message> messages, bool hasMore})> window,
) async {
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
        )).overrideWith((ref) => window.stream),
        spaceTurnRelayProvider('ch-1').overrideWith((ref) {}),
        codeFontFamilyProvider.overrideWith((ref) => 'monospace'),
        conversationLastReadProvider((
          spaceId: 'ch-1',
          conversationId: 'ch-1',
        )).overrideWithValue(AsyncData(null)),
        conversationReadRepositoryProvider.overrideWithValue(
          FakeConversationReadRepository(),
        ),
        agentDetailProvider('agent-1').overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _wrap(
          const SpaceMessageFeed(spaceId: 'ch-1', conversationId: 'ch-1'),
        ),
      ),
    ),
  );
}

Message _sent(List<Message> before) => Message(
  id: 'sent',
  spaceId: 'ch-1',
  conversationId: 'ch-1',
  senderId: 'user',
  senderType: SenderType.user,
  content: 'just sent',
  messageType: MessageType.text,
  createdAt: before.last.createdAt.add(const Duration(minutes: 1)),
);

Message _reply(List<Message> before, String content, {String id = 'reply'}) =>
    Message(
      id: id,
      spaceId: 'ch-1',
      conversationId: 'ch-1',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      content: content,
      messageType: MessageType.text,
      createdAt: before.last.createdAt.add(const Duration(minutes: 2)),
    );
