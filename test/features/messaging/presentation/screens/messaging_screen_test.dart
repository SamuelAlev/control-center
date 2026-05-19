import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_layout.dart';
import 'package:control_center/features/messaging/presentation/screens/messaging_screen.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_rpc_client.dart';

/// The workspace the screen is scoped to in these tests. The screen renders a
/// [CcSpinner] (and nothing else) until [activeWorkspaceIdProvider] resolves a
/// non-null id, so every test overrides it below.
const String _kWorkspaceId = 'ws-1';

/// A started RPC client whose only job is to keep the IDE layout alive without
/// leaking timers.
///
/// The messaging screen's editor layout reaches the server for two things these
/// tests don't exercise:
///
///  * The seeded **Terminal** tab boots by calling `terminal.spawn` the moment
///    it becomes visible. Over a plain no-op channel that request never
///    completes and leaves a 30s timeout timer pending past teardown. Answering
///    it (with an empty map — no `session_id`) completes the request, so the
///    terminal panel falls into its error branch without attaching an output
///    subscription or a kill call and no timer survives disposal.
///  * The per-conversation **editor layout** is restored/persisted through
///    `cache.read` / `cache.write`. Those must resolve too (an empty `cache.read`
///    yields "no persisted layout"), or the pending call surfaces as an
///    unhandled RPC error after the test completes.
///
/// So every `repo/call` op resolves to an empty data map; that is enough to keep
/// the surface under test rendering without any live server.
RemoteRpcClient _terminallessRpcClient() {
  final host = FakeRpcHost()..onCall = (op, args) => const <String, dynamic>{};
  return host.client();
}

Widget _wrap(Widget child) => Scaffold(
  body: CcTheme(data: CcThemeData.light(), child: child),
);

class _TestSelectedChannelNotifier extends SelectedChannelNotifier {
  _TestSelectedChannelNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

/// A no-host [ChannelReadRepository] fake. The real provider is RPC-flipped
/// (composition flip) and would open an in-process host, leaving a pending
/// reconnect timer after the widget tree is torn down. The read cursor is not
/// under test in these screen tests.
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

final _testChannelA = Channel(
  id: 'ch-1',
  name: 'Test Agent',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final _testChannelB = Channel(
  id: 'ch-2',
  name: 'Test Group',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  testWidgets('renders empty state when no channel selected', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Select a channel'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders channel list panel', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Inner sidebar is gone; the screen shell still renders.
    expect(find.byType(MessagingScreen), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders active channel pane when channel selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-1'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelA])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelA])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelParticipantsProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-1')),
        ),
      ),
    );
    await tester.pump();
    // No terminal: the conversation pane renders directly (no CcResizable).
    expect(find.byType(ChannelHeader), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('MessagingScreen renders Row layout', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MessagingScreen), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders empty state icon', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Column), findsWidgets);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('shows channel list panel always', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Inner sidebar removed: no selection → empty state (no section labels).
    expect(find.text('DIRECT MESSAGES'), findsNothing);
    expect(find.text('Select a channel'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('shows channel pane for selected channel', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelB])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelB])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelParticipantsProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
          channelFeedWindowedProvider((
            channelId: 'ch-2',
            conversationId: 'ch-2',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-2')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Conversation pane renders (no terminal → no CcResizable split).
    expect(find.byType(ChannelHeader), findsOneWidget);
    expect(find.byType(CcResizable), findsNothing);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('active pane has channel header', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelB])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelB])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-2',
            conversationId: 'ch-2',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelMessagesProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-2')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ChannelHeader), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('active pane has input bar', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelB])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelB])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-2',
            conversationId: 'ch-2',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-2')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ChannelInputBar), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('empty state shows correct text', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith(
            (ref) => Stream.value(const <Channel>[]),
          ),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value(const <Channel>[])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Select a channel'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  // Regression: the IDE action sink used to be constructed inside
  // `MessagingScreen.build`, so the first rebuild handed the keybinding
  // dispatcher a fresh, unwired sink (MessagingIdeLayout only wires its
  // callbacks in `initState`). ⌘W/⌘T/⌘B then matched their binding — consuming
  // the key, so ⌘W didn't even fall through to the macOS "close window" menu —
  // and silently no-oped. The sink must be state-owned and stay wired.
  testWidgets('IDE action sink stays wired across screen rebuilds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Drives a rebuild of MessagingScreen the same way the real app does: a new
    // emission on the channel list the screen watches.
    final channels = StreamController<List<Channel>>.broadcast();
    addTearDown(channels.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelB])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => channels.stream),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-2',
            conversationId: 'ch-2',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-2')),
        ),
      ),
    );
    channels.add([_testChannelB]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    MessagingIdeActions sink() => tester
        .widget<MessagingIdeLayout>(find.byType(MessagingIdeLayout))
        .actions;

    final firstSink = sink();
    expect(firstSink.closeActiveTab, isNotNull, reason: 'wired on mount');

    // Rebuild the screen (a channel-list update, e.g. a new message bumping a
    // conversation) and re-check. The pre-fix code allocated a new sink here.
    channels.add([_testChannelB, _testChannelA]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final secondSink = sink();
    expect(
      secondSink,
      same(firstSink),
      reason: 'sink is state-owned, not rebuilt',
    );
    expect(
      secondSink.closeActiveTab,
      isNotNull,
      reason: '⌘W still closes a tab',
    );
    expect(
      secondSink.openEditor,
      isNotNull,
      reason: '⌘T still opens the editor',
    );
    expect(secondSink.toggleSidebar, isNotNull, reason: '⌘B still toggles');

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('deleting a channel shows dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(_terminallessRpcClient()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelB])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelB])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-2',
            conversationId: 'ch-2',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _wrap(const MessagingScreen(selectedChannelId: 'ch-2')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete channel'), findsWidgets);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  // Repro for the reported regression: open a terminal in a channel, navigate
  // away (newsfeed) so the whole screen unmounts, come back — the terminal
  // must re-claim its kept session from the app-level registry, not spawn a
  // fresh shell.
  testWidgets('terminal session survives unmount + remount of the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var spawnCount = 0;
    var killCount = 0;
    final cacheStore = <String, String?>{};
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      switch (op) {
        case 'terminal.spawn':
          spawnCount++;
          return {'session_id': 'srv-$spawnCount'};
        case 'terminal.kill':
          killCount++;
          return const <String, dynamic>{};
        case 'cache.read':
          return {'payload': cacheStore['${args['kind']}/${args['key']}']};
        case 'cache.write':
          cacheStore['${args['kind']}/${args['key']}'] =
              args['payload'] as String?;
          return const <String, dynamic>{};
      }
      return const <String, dynamic>{};
    };
    final client = host.client();

    final overrides = [
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
      ),
      rpcClientProvider.overrideWithValue(client),
      selectedChannelIdProvider.overrideWith(
        () => _TestSelectedChannelNotifier('ch-1'),
      ),
      channelsProvider.overrideWith((ref) => Stream.value([_testChannelA])),
      workspaceChannelsProvider(
        _kWorkspaceId,
      ).overrideWith((ref) => Stream.value([_testChannelA])),
      agentsProvider.overrideWith((ref) => Stream.value(const [])),
      channelParticipantsProvider(
        'ch-1',
      ).overrideWith((ref) => Stream.value(const [])),
      workspacesProvider.overrideWith((ref) => Stream.value(const [])),
      speechTranscriberProvider.overrideWith((ref) => null),
      channelFeedWindowedProvider((
        channelId: 'ch-1',
        conversationId: 'ch-1',
      )).overrideWith(
        (ref) => Stream.value((messages: const [], hasMore: false)),
      ),
      channelReadRepositoryProvider.overrideWith(
        (ref) => _FakeChannelReadRepository(),
      ),
      channelMessagesProvider(
        'ch-1',
      ).overrideWith((ref) => Stream.value(const [])),
    ];

    Widget app() => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _wrap(
          const MessagingScreen(
            selectedChannelId: 'ch-1',
            // The `?tab=` the URL carried when the user navigated away:
            // focuses the terminal without a tap (no GoRouter in tests).
            focusedTabKey: 'terminal',
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(spawnCount, 1, reason: 'the focused terminal boots its shell');

    // Navigate away (newsfeed): the screen unmounts; the app container (the
    // ProviderScope above the routes) lives on, keeping the terminal registry.
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SizedBox()),
    );
    await tester.pumpAndSettle();
    expect(
      killCount,
      0,
      reason: 'unmounting the screen must not kill the server PTY',
    );

    // Back.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(
      killCount,
      0,
      reason: 'the kept session must not be killed on the way back',
    );
    expect(
      spawnCount,
      1,
      reason:
          'the restored terminal tab must re-claim its kept session, not '
          'spawn a fresh shell',
    );

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SizedBox()),
    );
    await tester.pumpAndSettle();
  });

  // Same scenario over a REAL router: `?tab=` writes, page rebuilds and
  // back-navigation all run through go_router exactly as in the app.
  testWidgets('terminal session survives real-router navigation away + back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var spawnCount = 0;
    var killCount = 0;
    final cacheStore = <String, String?>{};
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      switch (op) {
        case 'terminal.spawn':
          spawnCount++;
          return {'session_id': 'srv-$spawnCount'};
        case 'terminal.kill':
          killCount++;
          return const <String, dynamic>{};
        case 'cache.read':
          return {'payload': cacheStore['${args['kind']}/${args['key']}']};
        case 'cache.write':
          cacheStore['${args['kind']}/${args['key']}'] =
              args['payload'] as String?;
          return const <String, dynamic>{};
      }
      return const <String, dynamic>{};
    };

    final router = GoRouter(
      initialLocation: '/workspaces/ws-1/channels/ch-1?tab=terminal',
      routes: [
        GoRoute(
          path: '/workspaces/:wid/channels/:cid',
          builder: (context, state) => _wrap(
            MessagingScreen(
              selectedChannelId: state.pathParameters['cid'],
              focusedTabKey: state.uri.queryParameters['tab'],
            ),
          ),
        ),
        GoRoute(
          path: '/workspaces/:wid/newsfeed',
          builder: (context, state) =>
              const SizedBox(key: Key('newsfeed-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(host.client()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-1'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelA])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelA])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(spawnCount, 1, reason: 'the focused terminal boots its shell');

    // To the newsfeed and back, through the real router.
    router.go('/workspaces/ws-1/newsfeed');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newsfeed-stub')), findsOneWidget);
    expect(
      killCount,
      0,
      reason: 'navigating away must not kill the server PTY',
    );

    router.go('/workspaces/ws-1/channels/ch-1?tab=terminal');
    await tester.pumpAndSettle();

    expect(
      killCount,
      0,
      reason: 'the kept session must not be killed on the way back',
    );
    expect(
      spawnCount,
      1,
      reason:
          'the restored terminal tab must re-claim its kept session, not '
          'spawn a fresh shell',
    );
  });

  // Regression: the shell's custom tab name (OSC/foreground title) used to
  // vanish on navigation until the tab was opened again — the per-tab title
  // map dies with the layout state and was only repopulated when the tab body
  // rebuilt. The kept controller's title must back the tab strip label even
  // before the body is built.
  testWidgets('terminal tab keeps its custom name across navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var spawnCount = 0;
    final cacheStore = <String, String?>{};
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      switch (op) {
        case 'terminal.spawn':
          spawnCount++;
          return {'session_id': 'srv-$spawnCount'};
        case 'cache.read':
          return {'payload': cacheStore['${args['kind']}/${args['key']}']};
        case 'cache.write':
          cacheStore['${args['kind']}/${args['key']}'] =
              args['payload'] as String?;
          return const <String, dynamic>{};
      }
      return const <String, dynamic>{};
    };

    final router = GoRouter(
      initialLocation: '/workspaces/ws-1/channels/ch-1',
      routes: [
        GoRoute(
          path: '/workspaces/:wid/channels/:cid',
          builder: (context, state) => _wrap(
            MessagingScreen(
              selectedChannelId: state.pathParameters['cid'],
              focusedTabKey: state.uri.queryParameters['tab'],
            ),
          ),
        ),
        GoRoute(
          path: '/workspaces/:wid/newsfeed',
          builder: (context, state) =>
              const SizedBox(key: Key('newsfeed-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    // The chat pane runs a perpetual animation (pumpAndSettle never returns
    // while it is visible), so drive time manually like the other screen
    // tests do.
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
          ),
          rpcClientProvider.overrideWithValue(host.client()),
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-1'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testChannelA])),
          workspaceChannelsProvider(
            _kWorkspaceId,
          ).overrideWith((ref) => Stream.value([_testChannelA])),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelFeedWindowedProvider((
            channelId: 'ch-1',
            conversationId: 'ch-1',
          )).overrideWith(
            (ref) => Stream.value((messages: const [], hasMore: false)),
          ),
          channelReadRepositoryProvider.overrideWith(
            (ref) => _FakeChannelReadRepository(),
          ),
          channelMessagesProvider(
            'ch-1',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle();

    // Open the terminal tab (the URL `?tab=` drives focus, as after a real
    // tap's `?tab=` write) and let the shell name itself — the server-polled
    // foreground-process title, e.g. `claude`.
    router.go('/workspaces/ws-1/channels/ch-1?tab=terminal');
    await settle();
    expect(spawnCount, 1);
    host.emit('terminal.titles', {'title': 'claude'});
    await tester.pump();
    await tester.pump();
    expect(find.text('claude'), findsWidgets);

    // Focus the chat tab so the terminal tab body is NOT built on restore —
    // the exact gap where the name used to be lost.
    router.go('/workspaces/ws-1/channels/ch-1?tab=chat');
    await settle();

    router.go('/workspaces/ws-1/newsfeed');
    await settle();
    router.go('/workspaces/ws-1/channels/ch-1');
    await settle();

    expect(
      spawnCount,
      1,
      reason: 'the kept session is re-claimed, not respawned',
    );
    expect(
      find.text('claude'),
      findsWidgets,
      reason:
          'the tab strip must show the shell title straight after restore, '
          'before the terminal tab body is opened again',
    );

    // Opening the tab keeps the same name (claim repopulates the live map).
    router.go('/workspaces/ws-1/channels/ch-1?tab=terminal');
    await settle();
    expect(spawnCount, 1);
    expect(find.text('claude'), findsWidgets);
  });
}
