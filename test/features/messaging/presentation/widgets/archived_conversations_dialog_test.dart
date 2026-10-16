import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _workspaceId = 'ws-1';
const _spaceId = 'space-1';
final _space = Space(
  id: _spaceId,
  workspaceId: _workspaceId,
  name: 'Project',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Conversation _conversation(
  String id,
  String title, {
  String workspaceId = _workspaceId,
  String spaceId = _spaceId,
  ConversationStatus status = ConversationStatus.archived,
}) => Conversation(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  title: title,
  status: status,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _WorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;

  void switchTo(String id) => state = id;
}

class _ConversationRepository implements ConversationRepository {
  final calls =
      <
        ({String workspaceId, String conversationId, ConversationStatus status})
      >[];
  Future<void> Function()? onSetStatus;

  @override
  Future<void> setStatus({
    required String workspaceId,
    required String conversationId,
    required ConversationStatus status,
  }) async {
    calls.add((
      workspaceId: workspaceId,
      conversationId: conversationId,
      status: status,
    ));
    if (onSetStatus case final action?) {
      await action();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _router() {
  Widget content(BuildContext context, GoRouterState state) => Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 360,
        child: SpaceSidebarItem(
          space: _space,
          selected: false,
          onPress: () {},
          leading: const SizedBox.shrink(),
          menuRevealed: true,
        ),
      ),
    ),
  );
  return GoRouter(
    initialLocation: spacesRoute(_workspaceId),
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId/spaces',
        builder: content,
        routes: [GoRoute(path: ':spaceId', builder: content)],
      ),
    ],
  );
}

Widget _wrap(
  GoRouter router,
  _ConversationRepository repository,
  Stream<List<Conversation>> conversations, {
  _WorkspaceId? workspace,
}) => ProviderScope(
  overrides: [
    activeWorkspaceIdProvider.overrideWith(() => workspace ?? _WorkspaceId()),
    spaceStatusProvider(_spaceId).overrideWithValue(SpaceStatus.idle),
    spaceUnreadProvider(_spaceId).overrideWithValue(false),
    conversationRepositoryProvider.overrideWithValue(repository),
    spaceConversationsProvider(_spaceId).overrideWith((ref) => conversations),
  ],
  child: CcTheme(
    data: CcThemeData.light(reducedMotion: true),
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ),
);

Future<void> _openArchive(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(
    find.byWidgetPredicate(
      (widget) => widget is CcIcon && widget.icon == AppIcons.moreVertical,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final l10n = await AppLocalizations.delegate.load(const Locale('en'));
  await tester.tap(find.text(l10n.archivedConversations));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _restoreButton() => find.ancestor(
  of: find.byIcon(AppIcons.archiveRestore),
  matching: find.byType(CcIconButton),
);

void main() {
  testWidgets('space menu opens even when its conversation archive is empty', (
    tester,
  ) async {
    final repository = _ConversationRepository();
    final router = _router();
    await tester.pumpWidget(_wrap(router, repository, Stream.value(const [])));
    await _openArchive(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.archivedConversations), findsOneWidget);
    expect(find.text(l10n.archivedConversationsEmpty), findsOneWidget);
    expect(_restoreButton(), findsNothing);
  });

  testWidgets('conversation stream loading and errors are not shown as empty', (
    tester,
  ) async {
    final repository = _ConversationRepository();
    final router = _router();
    final updates = StreamController<List<Conversation>>.broadcast();
    await tester.pumpWidget(_wrap(router, repository, updates.stream));
    await _openArchive(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text(l10n.archivedConversationsEmpty), findsNothing);
    updates.addError(StateError('stream offline'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text(l10n.failedWithError('Bad state: stream offline')),
      findsOneWidget,
    );
    expect(find.text(l10n.archivedConversationsEmpty), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await updates.close();
  });

  testWidgets(
    'archive shows only conversations owned by the space and workspace',
    (tester) async {
      final repository = _ConversationRepository();
      final router = _router();
      await tester.pumpWidget(
        _wrap(
          router,
          repository,
          Stream.value([
            _conversation('one', 'Archived here'),
            _conversation(
              'two',
              'Still active',
              status: ConversationStatus.active,
            ),
            _conversation('three', 'Another space', spaceId: 'space-2'),
            _conversation('four', 'Another workspace', workspaceId: 'ws-2'),
            _conversation('five', ''),
          ]),
        ),
      );
      await _openArchive(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text('Archived here'), findsOneWidget);
      expect(find.text(l10n.untitledConversation), findsOneWidget);
      expect(find.text('Still active'), findsNothing);
      expect(find.text('Another space'), findsNothing);
      expect(find.text('Another workspace'), findsNothing);
      expect(_restoreButton(), findsNWidgets(2));
      expect(repository.calls, isEmpty);
    },
  );

  testWidgets('switching workspace cannot restore the former space', (
    tester,
  ) async {
    final repository = _ConversationRepository();
    final workspace = _WorkspaceId();
    final router = _router();
    await tester.pumpWidget(
      _wrap(
        router,
        repository,
        Stream.value([_conversation('one', 'Archived here')]),
        workspace: workspace,
      ),
    );
    await _openArchive(tester);
    expect(find.text('Archived here'), findsOneWidget);

    workspace.switchTo('ws-2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CcDialog), findsNothing);
    expect(find.text('Archived here'), findsNothing);
    expect(repository.calls, isEmpty);
  });

  testWidgets(
    'restore waits for active stream, disables repeats and opens its tab',
    (tester) async {
      final repository = _ConversationRepository();
      final pending = Completer<void>();
      repository.onSetStatus = () => pending.future;
      final updates = StreamController<List<Conversation>>.broadcast();
      final archived = _conversation('one', 'Saved discussion');
      final router = _router();
      await tester.pumpWidget(
        _wrap(
          router,
          repository,
          (() async* {
            yield [archived];
            yield* updates.stream;
          })(),
        ),
      );
      await _openArchive(tester);
      await tester.tap(_restoreButton());
      await tester.pump();
      expect(repository.calls, [
        (
          workspaceId: _workspaceId,
          conversationId: 'one',
          status: ConversationStatus.active,
        ),
      ]);
      expect(tester.widget<CcIconButton>(_restoreButton()).onPressed, isNull);
      pending.complete();
      await tester.pump();
      expect(find.text('Saved discussion'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spacesRoute(_workspaceId),
      );

      updates.add([archived.copyWith(status: ConversationStatus.active)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        spaceRoute(_workspaceId, _spaceId, tab: conversationTabKey('one')),
      );
      expect(repository.calls, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await updates.close();
    },
  );

  testWidgets('restore error stays visible and allows retry', (tester) async {
    final repository = _ConversationRepository();
    repository.onSetStatus = () => Future.error(StateError('offline'));
    final updates = StreamController<List<Conversation>>.broadcast();
    final archived = _conversation('one', 'Saved discussion');
    final router = _router();
    await tester.pumpWidget(
      _wrap(
        router,
        repository,
        (() async* {
          yield [archived];
          yield* updates.stream;
        })(),
      ),
    );
    await _openArchive(tester);
    await tester.tap(_restoreButton());
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(l10n.failedWithError('Bad state: offline')),
      findsOneWidget,
    );
    expect(find.text('Saved discussion'), findsOneWidget);
    expect(tester.widget<CcIconButton>(_restoreButton()).onPressed, isNotNull);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      spacesRoute(_workspaceId),
    );

    repository.onSetStatus = null;
    await tester.tap(_restoreButton());
    await tester.pump();
    updates.add([archived.copyWith(status: ConversationStatus.active)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.calls, hasLength(2));
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      spaceRoute(_workspaceId, _spaceId, tab: conversationTabKey('one')),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await updates.close();
  });
}
