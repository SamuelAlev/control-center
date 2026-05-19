import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;

const _workspaceId = 'ws-1';

class _ActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

final _space = Space(
  id: 'g-1',
  name: 'Dev Team',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// Two ACTIVE conversations in `_space` — a space only lists its
/// conversations beneath the row when more than one is live.
final _twoConversations = [
  Conversation(
    id: 'conv-1',
    workspaceId: _workspaceId,
    spaceId: 'g-1',
    title: 'Main thread',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
  Conversation(
    id: 'conv-2',
    workspaceId: _workspaceId,
    spaceId: 'g-1',
    title: 'Design review',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
];

Repo _repo(String id, String fullName) => Repo(
  id: id,
  name: fullName,
  path: '/src/$id',
  remoteOwner: fullName.split('/').first,
  remoteName: fullName.split('/').last,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// Common provider overrides so the sidebar's per-row providers resolve to
/// cheap defaults instead of reaching for DB/RPC infrastructure.
List<Override> _commonOverrides({required List<Space> spaces}) => [
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspaceIdNotifier.new),
  workspaceVisibleSpacesProvider(_workspaceId).overrideWithValue(spaces),
  appPreferencesProvider.overrideWithValue(prefs),
  workspacesProvider.overrideWith((ref) => Stream.value(const [])),
  for (final c in spaces) ...[
    spaceStatusProvider(c.id).overrideWithValue(SpaceStatus.idle),
    spaceUnreadProvider(c.id).overrideWithValue(false),
    spacePrsProvider(c.id).overrideWithValue(const []),
  ],
];

/// Hosts [ConversationsSidebarSection] at a spaces location so the widget's
/// `GoRouterState`/`currentWorkspaceId` reads resolve. The URL is the source of
/// truth for the selected space, so [location] sets the active highlight.
GoRouter _router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(
      path: '/workspaces/:workspaceId/spaces',
      builder: (_, _) => const Scaffold(body: ConversationsSidebarSection()),
      routes: [
        GoRoute(
          path: ':spaceId',
          builder: (_, _) =>
              const Scaffold(body: ConversationsSidebarSection()),
        ),
      ],
    ),
  ],
);

Widget _wrap(GoRouter router) => CcTheme(
  data: CcThemeData.light(),
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

late AppPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  group('ConversationsSidebarSection', () {
    testWidgets('renders the Spaces section label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: const []),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The section label renders as a branded mono eyebrow (uppercased).
      expect(find.text('SPACES'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows empty state hint when no spaces', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: const []),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No spaces yet'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders space items by name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [_space]),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders a Plus icon for adding a space', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: const []),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(AppIcons.plus), findsWidgets);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'spaces header archive, plus and chevron share even horizontal slots',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _commonOverrides(spaces: const []),
            child: _wrap(_router(spacesRoute(_workspaceId))),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final archive = tester.getCenter(find.byIcon(AppIcons.archive));
        final plus = tester.getCenter(find.byIcon(AppIcons.plus).first);
        final chevron = tester.getCenter(find.byIcon(AppIcons.chevronDown));
        expect(plus.dx - archive.dx, closeTo(chevron.dx - plus.dx, 1));
        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('selected space (from URL) still renders', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [_space]),
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('unnamed space shows Space label', (tester) async {
      final unnamed = Space(
        id: 'g-unnamed',
        name: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [unnamed]),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Space'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tapping a space navigates to its space route', (tester) async {
      final router = _router(spacesRoute(_workspaceId));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [_space]),
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Dev Team'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spaceRoute(_workspaceId, 'g-1'),
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('right-click archives the space instead of deleting it', (
      tester,
    ) async {
      final port = _FakeMessagingPort();
      final router = _router(spaceRoute(_workspaceId, 'g-1'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(port),
          ],
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The row menu's only destructive-adjacent action is Archive — a
      // reversible hide, so it fires with no confirmation dialog.
      await tester.tapAt(
        tester.getCenter(find.text('Dev Team')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.archiveSpace), findsOneWidget);
      expect(find.text(l10n.deleteSpace), findsNothing);

      await tester.tap(find.text(l10n.archiveSpace));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.archived, [(_workspaceId, 'g-1')]);
      expect(port.deleted, isEmpty);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spacesRoute(_workspaceId),
        reason: 'the archived space leaves the URL for the space list',
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('long-press on the space row opens the menu, never archives', (
      tester,
    ) async {
      // Long-press is the mobile right-click: it must OPEN the menu. An
      // instant fire on the hold itself is a mis-tap away from shelving a
      // space the user only pressed a beat too long.
      final port = _FakeMessagingPort();
      final router = _router(spaceRoute(_workspaceId, 'g-1'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(port),
          ],
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.longPress(find.text('Dev Team'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.archiveSpace), findsOneWidget);
      expect(
        port.archived,
        isEmpty,
        reason: 'the long-press alone must not archive the space',
      );

      // The deliberate second tap still archives.
      await tester.tap(find.text(l10n.archiveSpace));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.archived, [(_workspaceId, 'g-1')]);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spacesRoute(_workspaceId),
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'long-press on a conversation row opens the menu, never archives',
      (tester) async {
        // Regression: a long-press used to archive the conversation outright —
        // indistinguishable from a delete, because archived conversations have
        // no restore surface. The long-press must only OPEN the menu.
        final conversations = _FakeConversationRepository();
        final router = _router(spaceRoute(_workspaceId, 'g-1'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._commonOverrides(spaces: [_space]),
              messagingServiceProvider.overrideWithValue(_FakeMessagingPort()),
              conversationRepositoryProvider.overrideWithValue(conversations),
              spaceConversationsProvider(
                'g-1',
              ).overrideWith((ref) => Stream.value(_twoConversations)),
              spaceBusyConversationIdsProvider(
                'g-1',
              ).overrideWithValue(const <String>{}),
            ],
            child: _wrap(router),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.longPress(find.text('Design review'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.archiveConversation), findsOneWidget);
        expect(
          conversations.statusCalls,
          isEmpty,
          reason: 'the long-press alone must not archive the conversation',
        );

        // The deliberate second tap still archives.
        await tester.tap(find.text(l10n.archiveConversation));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(conversations.statusCalls, [
          (workspaceId: _workspaceId, conversationId: 'conv-2'),
        ]);
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('space row menu offers rename, repositories and archive', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(_FakeMessagingPort()),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tapAt(
        tester.getCenter(find.text('Dev Team')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.renameSpace), findsOneWidget);
      expect(find.text(l10n.editSpaceRepos), findsOneWidget);
      expect(find.text(l10n.archiveSpace), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('renaming a space from the menu updates the name', (
      tester,
    ) async {
      final port = _FakeMessagingPort();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(port),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tapAt(
        tester.getCenter(find.text('Dev Team')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.renameSpace));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(CcTextField), 'Renamed crew');
      await tester.tap(find.text(l10n.save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.renamed, [(_workspaceId, 'g-1', 'Renamed crew')]);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('editing a space\u2019s repositories saves the new selection', (
      tester,
    ) async {
      final port = _FakeMessagingPort(); // currentRepos null = all repos
      final repos = [_repo('r-1', 'o/one'), _repo('r-2', 'o/two')];
      final container = ProviderContainer(
        overrides: [
          ..._commonOverrides(spaces: [_space]),
          messagingServiceProvider.overrideWithValue(port),
          reposForWorkspaceProvider(
            _workspaceId,
          ).overrideWith((ref) => Stream.value(repos)),
        ],
      );
      addTearDown(container.dispose);
      // The dialog reads `reposForWorkspaceProvider(...).future` — without a
      // held listener the stream subscription closes before it emits (the
      // same keepAlive convention the provider tests use).
      final keepAlive = container.listen(
        reposForWorkspaceProvider(_workspaceId),
        (_, _) {},
      );
      addTearDown(keepAlive.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tapAt(
        tester.getCenter(find.text('Dev Team')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.editSpaceRepos));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The dialog warns that a removed repo loses its folder, and NO agent
      // picker is offered — agents are not editable here.
      expect(find.text(l10n.editSpaceReposWarning), findsOneWidget);
      expect(find.text(l10n.addAgents), findsNothing);

      // Uncheck 'o/two' (the overlay row, not the field's selected label),
      // close the dropdown (Escape hides its panel), then save: the space
      // keeps only r-1.
      await tester.tap(find.byType(CcMultiSelect<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('o/two').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(l10n.save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.repoSelections, [
        ['r-1'],
      ]);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('renaming a conversation from the menu renames it', (
      tester,
    ) async {
      final conversations = _FakeConversationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(_FakeMessagingPort()),
            conversationRepositoryProvider.overrideWithValue(conversations),
            spaceConversationsProvider(
              'g-1',
            ).overrideWith((ref) => Stream.value(_twoConversations)),
            spaceBusyConversationIdsProvider(
              'g-1',
            ).overrideWithValue(const <String>{}),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tapAt(
        tester.getCenter(find.text('Design review')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.renameConversation));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(CcTextField), 'Spec review');
      await tester.tap(find.text(l10n.save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(conversations.renameCalls, [
        (
          workspaceId: _workspaceId,
          conversationId: 'conv-2',
          title: 'Spec review',
        ),
      ]);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('archive trigger opens the archived-spaces dialog', (
      tester,
    ) async {
      final archivedSpace = Space(
        id: 'g-2',
        name: 'Old project',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        archivedAt: DateTime(2026, 1, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(_FakeMessagingPort()),
            archivedSpacesProvider(
              _workspaceId,
            ).overrideWithValue([archivedSpace]),
          ],
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The trigger sits left of the section's `+` and must work from the
      // sidebar's overlay-mounted dialog (no GoRouterState above it there).
      await tester.tap(find.byIcon(AppIcons.archive));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.archivedSpaces), findsOneWidget);
      expect(find.text('Old project'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('restoring an archived space reopens it', (tester) async {
      final port = _FakeMessagingPort();
      final archivedSpace = Space(
        id: 'g-2',
        name: 'Old project',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        archivedAt: DateTime(2026, 1, 10),
      );
      final router = _router(spacesRoute(_workspaceId));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(port),
            archivedSpacesProvider(
              _workspaceId,
            ).overrideWithValue([archivedSpace]),
          ],
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(AppIcons.archive));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(AppIcons.archiveRestore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.unarchived, [(_workspaceId, 'g-2')]);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spaceRoute(_workspaceId, 'g-2'),
        reason: 'restore returns the space to the sidebar and opens it',
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('permanent delete stays available behind a confirmation', (
      tester,
    ) async {
      final port = _FakeMessagingPort();
      final archivedSpace = Space(
        id: 'g-2',
        name: 'Old project',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        archivedAt: DateTime(2026, 1, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            messagingServiceProvider.overrideWithValue(port),
            archivedSpacesProvider(
              _workspaceId,
            ).overrideWithValue([archivedSpace]),
          ],
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(AppIcons.archive));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.deleteSpaceConfirm), findsOneWidget);
      expect(port.deleted, isEmpty);

      await tester.tap(find.text(l10n.delete));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(port.deleted, [(_workspaceId, 'g-2')]);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}

/// Records the space-lifecycle calls the archive surface makes; everything
/// else on the port is unreachable from these tests.
class _FakeMessagingPort implements MessagingPort {
  final List<(String, String)> archived = [];
  final List<(String, String)> unarchived = [];
  final List<(String, String)> deleted = [];
  final List<(String, String, String)> renamed = [];
  final List<List<String>?> repoSelections = [];

  /// What [getSpaceRepos] answers (null = the all-repos default).
  List<String>? currentRepos;

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) async {
    archived.add((workspaceId, spaceId));
  }

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) async {
    unarchived.add((workspaceId, spaceId));
  }

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {
    deleted.add((workspaceId, spaceId));
  }

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) async {
    renamed.add((workspaceId, spaceId, name));
  }

  @override
  Future<List<String>?> getSpaceRepos(
    String workspaceId,
    String spaceId,
  ) async => currentRepos;

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {
    repoSelections.add(repoIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

/// Records `setStatus`/`rename` calls; everything else on the repository is
/// unreachable from these tests.
class _FakeConversationRepository implements ConversationRepository {
  final List<({String workspaceId, String conversationId})> statusCalls = [];
  final List<({String workspaceId, String conversationId, String title})>
  renameCalls = [];

  @override
  Future<void> setStatus({
    required String workspaceId,
    required String conversationId,
    required ConversationStatus status,
  }) async {
    statusCalls.add((workspaceId: workspaceId, conversationId: conversationId));
  }

  @override
  Future<void> rename({
    required String workspaceId,
    required String conversationId,
    required String title,
  }) async {
    renameCalls.add((
      workspaceId: workspaceId,
      conversationId: conversationId,
      title: title,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
