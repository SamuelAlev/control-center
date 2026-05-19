import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/presentation/screens/messaging_screen.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap(Widget child) => Scaffold(
  body: CcTheme(data: CcThemeData.light(), child: child),
);

class _TestSelectedChannelNotifier extends SelectedChannelNotifier {
  _TestSelectedChannelNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

final _testDmChannel = Channel(
  id: 'ch-1',
  name: 'Test Agent',
  isDm: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final _testGroupChannel = Channel(
  id: 'ch-2',
  name: 'Test Group',
  isDm: false,
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Select a conversation'), findsOneWidget);
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Messaging'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders active channel pane when channel selected', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-1'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testDmChannel])),
          dmChannelsProvider.overrideWith((ref) => [_testDmChannel]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelParticipantsProvider('ch-1').overrideWith((ref) => Stream.value(const [])),
          channelTopLevelMessagesProvider('ch-1').overrideWith((ref) => Stream.value(const [])),
          channelMessagesProvider('ch-1').overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CcResizable), findsOneWidget);
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Section labels render as branded mono eyebrows (uppercased).
    expect(find.text('DIRECT MESSAGES'), findsOneWidget);
    expect(find.text('GROUPS'), findsOneWidget);
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testGroupChannel])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => [_testGroupChannel]),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelParticipantsProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          channelTopLevelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          channelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CcResizable), findsOneWidget);
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testGroupChannel])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => [_testGroupChannel]),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelTopLevelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          channelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testGroupChannel])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => [_testGroupChannel]),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelTopLevelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          channelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier(null),
          ),
          channelsProvider.overrideWith((ref) => Stream.value(const <Channel>[])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Select a conversation'), findsOneWidget);
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
          selectedChannelIdProvider.overrideWith(
            () => _TestSelectedChannelNotifier('ch-2'),
          ),
          channelsProvider.overrideWith((ref) => Stream.value([_testGroupChannel])),
          dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
          groupChannelsProvider.overrideWith((ref) => [_testGroupChannel]),
          agentsProvider.overrideWith((ref) => Stream.value(const [])),
          channelParticipantsProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          speechTranscriberProvider.overrideWith((ref) => null),
          channelTopLevelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
          channelMessagesProvider('ch-2').overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: _wrap(const MessagingScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete conversation'), findsWidgets);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
