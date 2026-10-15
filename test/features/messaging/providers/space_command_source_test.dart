import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_command_source.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../helpers/active_workspace.dart';

Space _space(
  String id,
  String name, {
  String? workspaceId = kTestWorkspaceId,
  DateTime? archivedAt,
  String? pipelineRunId,
  SpaceKind kind = SpaceKind.topic,
}) => Space(
  id: id,
  name: name,
  workspaceId: workspaceId,
  archivedAt: archivedAt,
  pipelineRunId: pipelineRunId,
  kind: kind,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Conversation _conversation(
  String id,
  String spaceId,
  String title, {
  String? workspaceId = kTestWorkspaceId,
  ConversationStatus status = ConversationStatus.active,
}) => Conversation(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  title: title,
  status: status,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _SelectedAlphaSpace extends SelectedSpaceNotifier {
  @override
  String? build() => 'alpha';
}

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: Center(
          child: CcButton(
            onPressed: () => showCommandPalette(
              context,
              (context, ref) =>
                  ref.read(spaceCommandSourceProvider).buildItems(context, ref),
            ),
            child: const Text('Open palette'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/spaces/:spaceId',
      builder: (_, state) => Scaffold(body: Text('Destination: ${state.uri}')),
    ),
  ],
);

Widget _app(GoRouter router, AppPreferences prefs, List<Override> overrides) =>
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        codeFontFamilyProvider.overrideWithValue('Fira Code'),
        ...overrides,
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open palette'));
  await tester.pumpAndSettle();
}

Future<void> _searchAndEnter(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(CcTextField), query);
  await tester.pumpAndSettle();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  late AppPreferences prefs;
  setUp(() => prefs = AppPreferences.inMemory());

  testWidgets('new conversation in an unselected space becomes searchable', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    final arriving = StreamController<List<Conversation>>();
    addTearDown(arriving.close);
    await tester.pumpWidget(
      _app(router, prefs, [
        activeWorkspaceIdOverride(),
        selectedSpaceIdProvider.overrideWith(_SelectedAlphaSpace.new),
        workspaceVisibleSpacesProvider(
          kTestWorkspaceId,
        ).overrideWithValue([_space('alpha', 'Alpha'), _space('beta', 'Beta')]),
        spaceConversationsProvider(
          'alpha',
        ).overrideWith((ref) => Stream.value(const <Conversation>[])),
        spaceConversationsProvider(
          'beta',
        ).overrideWith((ref) => arriving.stream),
      ]),
    );
    await _open(tester);
    await tester.enterText(find.byType(CcTextField), 'Sprint retro');
    await tester.pump();
    expect(find.text('No commands match'), findsOneWidget);

    arriving.add([_conversation('retro', 'beta', 'Sprint retro')]);
    await tester.pumpAndSettle();
    expect(find.text('No commands match'), findsNothing);
    expect(find.text('Sprint retro'), findsWidgets);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Destination: ${spaceRoute(kTestWorkspaceId, 'beta', tab: conversationTabKey('retro'))}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('same-titled conversations open their own parent space', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _app(router, prefs, [
        activeWorkspaceIdOverride(),
        workspaceVisibleSpacesProvider(
          kTestWorkspaceId,
        ).overrideWithValue([_space('alpha', 'Alpha'), _space('beta', 'Beta')]),
        spaceConversationsProvider('alpha').overrideWith(
          (ref) => Stream.value([_conversation('review-a', 'alpha', 'Review')]),
        ),
        spaceConversationsProvider('beta').overrideWith(
          (ref) => Stream.value([_conversation('review-b', 'beta', 'Review')]),
        ),
      ]),
    );
    await _open(tester);
    await tester.enterText(find.byType(CcTextField), 'Review');
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Destination: ${spaceRoute(kTestWorkspaceId, 'beta', tab: conversationTabKey('review-b'))}',
      ),
      findsOneWidget,
    );

    router.go('/');
    await tester.pumpAndSettle();
    await _open(tester);
    await tester.enterText(find.byType(CcTextField), 'Review');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Destination: ${spaceRoute(kTestWorkspaceId, 'alpha', tab: conversationTabKey('review-a'))}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('filters hidden and foreign spaces and inactive conversations', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _app(router, prefs, [
        activeWorkspaceIdOverride(),
        workspaceSpacesProvider(kTestWorkspaceId).overrideWithValue(
          AsyncData([
            _space('active', 'Visible Space'),
            _space('archived', 'Archived Space', archivedAt: DateTime(2025)),
            _space('pipeline', 'Pipeline Space', pipelineRunId: 'run-1'),
            _space('pr', 'Hidden PR', kind: SpaceKind.pr),
            _space('foreign', 'Foreign Space', workspaceId: 'elsewhere'),
          ]),
        ),
        workspaceSpaceActivityProvider(
          kTestWorkspaceId,
        ).overrideWithValue(const AsyncData(<String, SpaceActivity>{})),
        spaceConversationsProvider('active').overrideWith(
          (ref) => Stream.value([
            _conversation('live', 'active', 'Visible Chat'),
            _conversation(
              'archived-chat',
              'active',
              'Archived Chat',
              status: ConversationStatus.archived,
            ),
            _conversation(
              'foreign-chat',
              'active',
              'Foreign Chat',
              workspaceId: 'elsewhere',
            ),
            _conversation('wrong-parent', 'elsewhere', 'Wrong Parent Chat'),
          ]),
        ),
        for (final id in ['archived', 'pipeline', 'pr', 'foreign'])
          spaceConversationsProvider(id).overrideWith(
            (ref) => throw StateError('Must not subscribe to $id'),
          ),
      ]),
    );
    await _open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Visible Space'), findsWidgets);
    expect(find.text('Visible Chat'), findsOneWidget);
    for (final hidden in [
      'Archived Space',
      'Pipeline Space',
      'Hidden PR',
      'Foreign Space',
      'Archived Chat',
      'Foreign Chat',
      'Wrong Parent Chat',
    ]) {
      expect(find.text(hidden), findsNothing);
    }
    await _searchAndEnter(tester, 'Visible Space');
    expect(
      find.text('Destination: ${spaceRoute(kTestWorkspaceId, 'active')}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'without an active workspace no entity providers are subscribed',
    (tester) async {
      final router = _router();
      addTearDown(router.dispose);
      var spaceReads = 0;
      var conversationReads = 0;
      await tester.pumpWidget(
        _app(router, prefs, [
          activeWorkspaceIdOverride(null),
          visibleSpacesProvider.overrideWith(
            (ref) => throw StateError('Must not read fallback spaces'),
          ),
          workspaceVisibleSpacesProvider(kTestWorkspaceId).overrideWith((ref) {
            spaceReads++;
            return [_space('active', 'Visible Space')];
          }),
          spaceConversationsProvider('active').overrideWith((ref) {
            conversationReads++;
            return Stream.value([
              _conversation('live', 'active', 'Visible Chat'),
            ]);
          }),
        ]),
      );
      await _open(tester);
      expect(find.text('Visible Space'), findsNothing);
      expect(find.text('Visible Chat'), findsNothing);
      expect(spaceReads, 0);
      expect(conversationReads, 0);
    },
  );
}
