import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_group.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
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

final _spaceB = Space(
  id: 'g-2',
  name: 'Ops',
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
List<Override> _commonOverrides({
  required List<Space> spaces,
  Set<String> unreadSpaceIds = const {},
  String? branch,
  Map<String, List<SpaceParticipant>> participants = const {},
  Map<String, List<PullRequest>> pullRequests = const {},
}) => [
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspaceIdNotifier.new),
  workspaceVisibleSpacesProvider(_workspaceId).overrideWithValue(spaces),
  appPreferencesProvider.overrideWithValue(prefs),
  workspacesProvider.overrideWith((ref) => Stream.value(const [])),
  for (final c in spaces) ...[
    spaceStatusProvider(c.id).overrideWithValue(SpaceStatus.idle),
    spaceUnreadProvider(c.id).overrideWithValue(unreadSpaceIds.contains(c.id)),
    spacePrsProvider(c.id).overrideWithValue(pullRequests[c.id] ?? const []),
    spaceBranchPullRequestsProvider(c.id).overrideWith((ref) async => const []),
    spaceParticipantsProvider(c.id).overrideWith(
      (ref) => Stream.value(participants[c.id] ?? const <SpaceParticipant>[]),
    ),
  ],
  spaceSidebarBranchProvider.overrideWith((ref, _) async => branch),
];

/// A space with two live conversations — the sidebar lists them under the
/// space row. [unread] lights the unread dot on those conversation ids.
List<Override> _listedConversationOverrides({
  Map<String, bool> unread = const {},
}) => [
  spaceConversationsProvider(
    'g-1',
  ).overrideWith((ref) => Stream.value(_twoConversations)),
  spaceBusyConversationIdsProvider('g-1').overrideWithValue(const <String>{}),
  spaceRunStartedAtProvider(
    'g-1',
  ).overrideWithValue(const <String, DateTime>{}),
  for (final c in _twoConversations)
    conversationUnreadProvider((
      spaceId: 'g-1',
      conversationId: c.id,
    )).overrideWithValue(unread[c.id] ?? false),
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

Widget _wrap(GoRouter router, {bool reducedMotion = false}) => CcTheme(
  data: CcThemeData.light(reducedMotion: reducedMotion),
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

late AppPreferences prefs;

Finder _overflowTrigger() => find.byWidgetPredicate(
  (widget) => widget is CcIcon && widget.icon == AppIcons.moreVertical,
);

double _spaceCardHeight(WidgetTester tester, String name) {
  return tester
      .getSize(
        find.ancestor(
          of: find.text(name),
          matching: find.byType(SpaceSidebarGroup),
        ),
      )
      .height;
}

/// Hovers [row] so its overflow trigger takes layout space, then opens the
/// dropdown. Widget tests default to a touch pointer, so hover is a real
/// mouse move, matching the production reveal.
Future<void> _openOverflow(WidgetTester tester, Finder row) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(row));
  await tester.pump();
  await tester.tap(_overflowTrigger());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

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

    testWidgets('a space shows its checked-out branch under the name', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(
            spaces: [_space],
            branch: 'fix/checks-detail-link',
          ),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      expect(find.text('fix/checks-detail-link'), findsOneWidget);
      final branch = tester.getRect(find.text('fix/checks-detail-link'));
      final row = tester.getRect(
        find.ancestor(
          of: find.text('fix/checks-detail-link'),
          matching: find.byType(SpaceRow),
        ),
      );
      expect(
        row.top,
        lessThanOrEqualTo(branch.top),
        reason: 'The hover wash is the whole row, including the branch.',
      );
      expect(row.bottom, greaterThanOrEqualTo(branch.bottom));
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('a closed space keeps the open panel vertical spacing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(
            spaces: [_space, _spaceB],
            branch: 'conv/6b2256bb',
          ),
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-2'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final groups = find.byType(SpaceSidebarGroup);
      expect(groups, findsNWidgets(2));

      double titleInset(int index, String name) {
        final groupTop = tester.getTopLeft(groups.at(index)).dy;
        final titleTop = tester
            .getTopLeft(
              find.descendant(of: groups.at(index), matching: find.text(name)),
            )
            .dy;
        return titleTop - groupTop;
      }

      final closed = titleInset(0, 'Dev Team');
      final open = titleInset(1, 'Ops');
      expect(closed, open);
      // Panel inset is [AppSpacing.sm], plus the two-line row's own air.
      expect(closed, greaterThanOrEqualTo(AppSpacing.sm));
      expect(closed, lessThan(AppSpacing.md));

      // The inset is part of the row's box. A press paints that box, so it
      // has to cover the card instead of sitting inside a second background.
      for (var i = 0; i < 2; i++) {
        final group = tester.getRect(groups.at(i));
        final row = tester.getRect(
          find.descendant(of: groups.at(i), matching: find.byType(SpaceRow)),
        );
        expect(row.top, group.top);
        expect(row.bottom, group.bottom);
        expect(row.left, group.left);
        expect(row.right, group.right);
      }

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('a space with a pull request shows its icon and count', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(
            spaces: [_space, _spaceB],
            pullRequests: {
              'g-1': [
                PullRequest(
                  id: 12,
                  number: 12,
                  title: 'Open',
                  body: '',
                  state: PrState.open,
                  isDraft: false,
                  author: null,
                  createdAt: DateTime(2024),
                  updatedAt: DateTime(2024),
                  repoFullName: 'acme/web',
                  htmlUrl: 'https://example.invalid/acme/web/pull/12',
                  headRef: 'conv/fb49964',
                  baseRef: 'main',
                ),
              ],
            },
          ),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byType(SpaceStatusMark), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('space rows share a travelling fluid hover wash', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [_space, _spaceB]),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(
        location: tester.getCenter(find.text('Dev Team')),
      );
      await tester.pump();
      await tester.pump();

      final highlight = tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey<String>('cc-fluid-hover-highlight')),
      );
      expect(
        highlight.opacity,
        1,
        reason: 'The spaces group must wash the hovered row, not skip it.',
      );

      await pointer.moveTo(tester.getCenter(find.text('Ops')));
      await tester.pump();
      await tester.pump();

      final moved = tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey<String>('cc-fluid-hover-highlight')),
      );
      expect(moved.opacity, 1);
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

    testWidgets('spaces header has no collapse caret and stays open', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: const []),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(AppIcons.archive), findsOneWidget);
      expect(find.byIcon(AppIcons.plus), findsWidgets);
      expect(find.byIcon(AppIcons.chevronDown), findsNothing);
      expect(find.text('No spaces yet'), findsOneWidget);

      await tester.tap(find.text('SPACES'));
      await tester.pump();

      expect(find.text('No spaces yet'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

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

    testWidgets('overflow menu archives the space instead of deleting it', (
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
      await _openOverflow(tester, find.text('Dev Team'));

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

    testWidgets('overflow trigger is hidden until the row is hovered', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(spaces: [_space]),
          child: _wrap(_router(spacesRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_overflowTrigger(), findsNothing);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Dev Team')));
      await tester.pump();

      expect(_overflowTrigger(), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'overflow trigger hides after the menu closes and the pointer leaves',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _commonOverrides(spaces: [_space]),
            child: _wrap(_router(spacesRoute(_workspaceId))),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Dev Team')));
        await tester.pump();

        await tester.tap(_overflowTrigger());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.archiveSpace), findsOneWidget);
        expect(_overflowTrigger(), findsOneWidget);

        await tester.tapAt(const Offset(700, 500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(l10n.archiveSpace), findsNothing);
        // The mouse is still over the row, so the trigger stays revealed.
        expect(_overflowTrigger(), findsOneWidget);

        await mouse.moveTo(const Offset(-20, -20));
        await tester.pump();

        expect(_overflowTrigger(), findsNothing);

        await mouse.moveTo(tester.getCenter(find.text('Dev Team')));
        await tester.pump();
        expect(_overflowTrigger(), findsOneWidget);

        await mouse.moveTo(const Offset(-20, -20));
        await tester.pump();
        expect(_overflowTrigger(), findsNothing);

        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('right-click no longer opens the space menu', (tester) async {
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
      expect(find.text(l10n.archiveSpace), findsNothing);
      expect(find.text(l10n.renameSpace), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('long-press on the space row does not archive or open a menu', (
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

      await tester.longPress(find.text('Dev Team'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.archiveSpace), findsNothing);
      expect(
        port.archived,
        isEmpty,
        reason: 'the long-press alone must not archive the space',
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'long-press on a conversation row does not archive or open a menu',
      (tester) async {
        final conversations = _FakeConversationRepository();
        final router = _router(spaceRoute(_workspaceId, 'g-1'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._commonOverrides(spaces: [_space]),
              messagingServiceProvider.overrideWithValue(_FakeMessagingPort()),
              conversationRepositoryProvider.overrideWithValue(conversations),
              ..._listedConversationOverrides(),
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
        expect(find.text(l10n.archiveConversation), findsNothing);
        expect(
          conversations.statusCalls,
          isEmpty,
          reason: 'the long-press alone must not archive the conversation',
        );
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('space row overflow offers rename, repositories and archive', (
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

      await _openOverflow(tester, find.text('Dev Team'));

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

      await _openOverflow(tester, find.text('Dev Team'));

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

      await _openOverflow(tester, find.text('Dev Team'));

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

    testWidgets('a conversation row has no overflow menu', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            ..._listedConversationOverrides(),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Design review')));
      await tester.pump();

      expect(_overflowTrigger(), findsNothing);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Design review'),
                matching: find.byType(SpaceRow),
              ),
            )
            .height,
        kConversationRowExtent,
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('the conversation count collapses and expands conversations', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            ..._listedConversationOverrides(),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final label = l10n.conversationCount(2);
      expect(find.text(label), findsOneWidget);
      expect(find.text('Design review'), findsOneWidget);
      final openHeight = _spaceCardHeight(tester, 'Dev Team');

      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      // Still mounted while the card clips shut.
      expect(find.text('Design review'), findsOneWidget);
      final closingHeight = _spaceCardHeight(tester, 'Dev Team');
      expect(closingHeight, lessThan(openHeight - 8));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Design review'), findsNothing);
      final closedHeight = _spaceCardHeight(tester, 'Dev Team');
      expect(closingHeight, greaterThan(closedHeight + 8));

      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Design review'), findsOneWidget);
      final openingHeight = _spaceCardHeight(tester, 'Dev Team');
      expect(openingHeight, greaterThan(closedHeight + 8));
      expect(openingHeight, lessThan(openHeight - 8));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Design review'), findsOneWidget);
      expect(_spaceCardHeight(tester, 'Dev Team'), greaterThan(openingHeight));
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('switching spaces shrinks one card and grows the other', (
      tester,
    ) async {
      final opsThreads = [
        Conversation(
          id: 'conv-3',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops thread',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        Conversation(
          id: 'conv-4',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops review',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      final router = _router(spaceRoute(_workspaceId, 'g-1'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space, _spaceB]),
            ..._listedConversationOverrides(),
            spaceConversationsProvider(
              'g-2',
            ).overrideWith((ref) => Stream.value(opsThreads)),
            spaceBusyConversationIdsProvider(
              'g-2',
            ).overrideWithValue(const <String>{}),
            spaceRunStartedAtProvider(
              'g-2',
            ).overrideWithValue(const <String, DateTime>{}),
            for (final c in opsThreads)
              conversationUnreadProvider((
                spaceId: 'g-2',
                conversationId: c.id,
              )).overrideWithValue(false),
          ],
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final devOpen = _spaceCardHeight(tester, 'Dev Team');
      final opsClosed = _spaceCardHeight(tester, 'Ops');
      expect(devOpen, greaterThan(opsClosed + 8));

      await tester.tap(find.text('Ops'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));

      final devMid = _spaceCardHeight(tester, 'Dev Team');
      final opsMid = _spaceCardHeight(tester, 'Ops');
      expect(devMid, lessThan(devOpen - 8));
      expect(devMid, greaterThan(opsClosed));
      expect(opsMid, greaterThan(opsClosed + 8));
      expect(find.text('Design review'), findsOneWidget);
      expect(find.text('Ops review'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.text('Design review'), findsNothing);
      expect(find.text('Ops review'), findsOneWidget);
      expect(_spaceCardHeight(tester, 'Dev Team'), lessThan(devMid - 8));
      expect(_spaceCardHeight(tester, 'Ops'), greaterThan(opsMid + 8));
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spaceRoute(_workspaceId, 'g-2'),
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('reduced motion snaps both cards when switching spaces', (
      tester,
    ) async {
      final opsThreads = [
        Conversation(
          id: 'conv-3',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops thread',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        Conversation(
          id: 'conv-4',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops review',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space, _spaceB]),
            ..._listedConversationOverrides(),
            spaceConversationsProvider(
              'g-2',
            ).overrideWith((ref) => Stream.value(opsThreads)),
            spaceBusyConversationIdsProvider(
              'g-2',
            ).overrideWithValue(const <String>{}),
            spaceRunStartedAtProvider(
              'g-2',
            ).overrideWithValue(const <String, DateTime>{}),
            for (final c in opsThreads)
              conversationUnreadProvider((
                spaceId: 'g-2',
                conversationId: c.id,
              )).overrideWithValue(false),
          ],
          child: _wrap(
            _router(spaceRoute(_workspaceId, 'g-1')),
            reducedMotion: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Ops'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Design review'), findsNothing);
      expect(find.text('Ops review'), findsOneWidget);

      // The title row's own inset still eases. The conversation panel must
      // already be at its snapped height, so nothing moves after that.
      await tester.pump(const Duration(milliseconds: 80));
      final dev = _spaceCardHeight(tester, 'Dev Team');
      final ops = _spaceCardHeight(tester, 'Ops');
      expect(ops, greaterThan(dev));

      await tester.pump(const Duration(milliseconds: 240));
      expect(_spaceCardHeight(tester, 'Dev Team'), dev);
      expect(_spaceCardHeight(tester, 'Ops'), ops);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('reduced motion mid-flight drops the closing conversations', (
      tester,
    ) async {
      final opsThreads = [
        Conversation(
          id: 'conv-3',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops thread',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        Conversation(
          id: 'conv-4',
          workspaceId: _workspaceId,
          spaceId: 'g-2',
          title: 'Ops review',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
      final router = _router(spaceRoute(_workspaceId, 'g-1'));
      var reducedMotion = false;
      Widget host() => ProviderScope(
        overrides: [
          ..._commonOverrides(spaces: [_space, _spaceB]),
          ..._listedConversationOverrides(),
          spaceConversationsProvider(
            'g-2',
          ).overrideWith((ref) => Stream.value(opsThreads)),
          spaceBusyConversationIdsProvider(
            'g-2',
          ).overrideWithValue(const <String>{}),
          spaceRunStartedAtProvider(
            'g-2',
          ).overrideWithValue(const <String, DateTime>{}),
          for (final c in opsThreads)
            conversationUnreadProvider((
              spaceId: 'g-2',
              conversationId: c.id,
            )).overrideWithValue(false),
        ],
        child: _wrap(router, reducedMotion: reducedMotion),
      );

      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Ops'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Design review'), findsOneWidget);

      reducedMotion = true;
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text('Design review'), findsNothing);
      expect(find.text('Ops review'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tapping a conversation opens the space', (tester) async {
      final router = _router(
        spaceRoute(_workspaceId, 'g-1', tab: 'chat:conv-2'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            ..._listedConversationOverrides(),
          ],
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Design review'));
      await tester.pump();
      await tester.pump();

      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, '/workspaces/$_workspaceId/spaces/g-1');
      expect(uri.queryParameters.containsKey('tab'), isFalse);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('an inactive space hides its conversations and count', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space, _spaceB]),
            ..._listedConversationOverrides(),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-2'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('Dev Team'), findsOneWidget);
      expect(find.text(l10n.conversationCount(2)), findsNothing);
      expect(find.text('Design review'), findsNothing);
      expect(find.text('Main thread'), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('one conversation adds no count label when the space opens', (
      tester,
    ) async {
      final now = DateTime(2024);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            spaceConversationsProvider('g-1').overrideWith(
              (ref) => Stream.value([
                Conversation(
                  id: 'conv-1',
                  workspaceId: _workspaceId,
                  spaceId: 'g-1',
                  title: 'Main thread',
                  createdAt: now,
                  updatedAt: now,
                ),
              ]),
            ),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('Dev Team'), findsOneWidget);
      expect(find.text(l10n.conversationCount(1)), findsNothing);
      expect(find.text('Main thread'), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('a running conversation shows how long the run has lasted', (
      tester,
    ) async {
      final now = DateTime.now();
      final conversations = [
        Conversation(
          id: 'conv-1',
          workspaceId: _workspaceId,
          spaceId: 'g-1',
          title: 'Main thread',
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 8)),
        ),
        Conversation(
          id: 'conv-2',
          workspaceId: _workspaceId,
          spaceId: 'g-1',
          title: 'Design review',
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 8)),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._commonOverrides(spaces: [_space]),
            spaceConversationsProvider(
              'g-1',
            ).overrideWith((ref) => Stream.value(conversations)),
            spaceBusyConversationIdsProvider(
              'g-1',
            ).overrideWithValue(const <String>{}),
            spaceRunStartedAtProvider('g-1').overrideWithValue({
              'conv-2': now.subtract(const Duration(hours: 6)),
            }),
            for (final c in conversations)
              conversationUnreadProvider((
                spaceId: 'g-1',
                conversationId: c.id,
              )).overrideWithValue(false),
          ],
          child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.sidebarAgeHours(6)), findsOneWidget);
      expect(find.text(l10n.sidebarAgeHours(8)), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Design review'),
            matching: find.byType(SpaceRow),
          ),
          matching: find.byType(CcSpinner),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Main thread'),
            matching: find.byType(SpaceRow),
          ),
          matching: find.byType(SpaceStatusMark),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'unread dot sits on the conversation, not the parent space, when listed',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._commonOverrides(spaces: [_space], unreadSpaceIds: {'g-1'}),
              ..._listedConversationOverrides(unread: {'conv-1': true}),
            ],
            child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        Finder trailingOn(String label) => find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(SpaceRow),
          ),
          matching: find.byType(SpaceTrailingIndicator),
        );
        Finder markOn(String label, Type type) => find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(SpaceRow),
          ),
          matching: find.byType(type),
        );

        expect(trailingOn('Dev Team'), findsNothing);
        expect(trailingOn('Main thread'), findsNothing);
        expect(markOn('Main thread', ConversationUnreadMark), findsOneWidget);
        expect(markOn('Design review', ConversationUnreadMark), findsNothing);
        expect(markOn('Design review', SpaceStatusMark), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('Main thread')).style?.fontSize,
          kConversationLabelFontSize,
        );
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'unread dot stays on the space when conversations are not listed',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._commonOverrides(spaces: [_space], unreadSpaceIds: {'g-1'}),
            ],
            child: _wrap(_router(spaceRoute(_workspaceId, 'g-1'))),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Dev Team'),
              matching: find.byType(SpaceRow),
            ),
            matching: find.byType(SpaceTrailingIndicator),
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

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
