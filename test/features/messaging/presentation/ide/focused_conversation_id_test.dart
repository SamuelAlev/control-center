import 'dart:async';

import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/fake_rpc_client.dart';

const _workspaceId = 'workspace';
const _spaceId = 'space-1';
const _standingId = 'standing-1';
const _otherId = 'conv-2';
const _newId = 'new-conversation';

TodoItem _todo(String conversationId, String content) => TodoItem(
  id: '$conversationId-item',
  workspaceId: _workspaceId,
  conversationId: conversationId,
  content: content,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

EditorTab _chat(String conversationId) => EditorTab(
  kind: MessagingTabKinds.chat,
  label: conversationId,
  dedupKey: MessagingTabKinds.chatTabKey(conversationId),
  args: {'spaceId': _spaceId, 'conversationId': conversationId},
);

// The visible label follows an invisible twin that reserves selected width.
Finder _chatTab(String conversationId) => find
    .descendant(
      of: find.byType(EditorWorkspace),
      matching: find.text(conversationId),
    )
    .last;

class _Todos extends Fake implements TodoRepository {
  final rows = <String, List<TodoItem>>{
    _standingId: [_todo(_standingId, 'Standing task')],
    _otherId: [_todo(_otherId, 'Other task')],
  };
  final changes = StreamController<void>.broadcast();

  @override
  Stream<List<TodoItem>> watch(
    String workspaceId,
    String conversationId,
  ) async* {
    yield rows[conversationId] ?? const [];
    yield* changes.stream.map((_) => rows[conversationId] ?? const []);
  }

  @override
  Stream<ConversationGoal?> watchGoal(
    String workspaceId,
    String conversationId,
  ) => Stream.value(
    conversationId == _standingId
        ? ConversationGoal(
            conversationId: conversationId,
            workspaceId: workspaceId,
            title: 'Standing goal',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          )
        : null,
  );

  @override
  Future<void> updateStatus(
    String workspaceId,
    String conversationId,
    String id,
    TodoStatus status,
  ) async {
    rows[conversationId] = [
      for (final row in rows[conversationId] ?? const <TodoItem>[])
        if (row.id == id) row.copyWith(status: status) else row,
    ];
    changes.add(null);
  }
}

void main() {
  late EditorLayoutController layout;
  late _Todos todos;

  setUp(() {
    layout = EditorLayoutController.single()
      ..openInActiveLeaf(_chat(_standingId));
    todos = _Todos();
  });

  tearDown(() async {
    layout.dispose();
    await todos.changes.close();
  });

  Future<void> pump(WidgetTester tester) async {
    final host = FakeRpcHost()..onCall = (_, _) => const {};
    final client = host.client();
    addTearDown(client.close);
    final sidebarView = ValueNotifier(IdeSidebarView.general);
    addTearDown(sidebarView.dispose);
    final container = ProviderContainer(
      overrides: [
        activeWorkspaceIdOverride(_workspaceId),
        rpcClientProvider.overrideWithValue(client),
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
        todoRepositoryProvider.overrideWithValue(todos),
        standingConversationIdProvider(
          _spaceId,
        ).overrideWith((ref) async => _standingId),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedSpaceIdProvider.notifier).select(_spaceId);

    // The retained sidebar must follow local editor focus, not this stale route.
    final surface = CcTheme(
      data: CcThemeData.light(),
      child: CcToastScope(
        child: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: EditorWorkspace(
                  layout: layout,
                  chrome: const EditorChrome(),
                  buildBody: (tab, {required isVisible}) =>
                      const SizedBox.shrink(),
                ),
              ),
              SizedBox(
                width: 300,
                child: IdeSidebar(
                  tabNotifier: sidebarView,
                  layout: layout,
                  workspaceId: _workspaceId,
                  spaceId: _spaceId,
                  onOpenFile: (_) {},
                  onOpenReview: (_) {},
                  onViewSource: (_) {},
                  onRevertFiles: (_) {},
                  onOpenAgentRun: (_) {},
                  onOpenAgentShell: (_) {},
                  onFocusTerminal: (_) {},
                  onKillTerminal: (_) {},
                  onFocusRig: (_) {},
                  onFocusBrowserTab: (_) {},
                  onCloseBrowserTab: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final router = GoRouter(
      initialLocation: '/?tab=${MessagingTabKinds.chatTabKey(_standingId)}',
      routes: [GoRoute(path: '/', builder: (context, state) => surface)],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('new chat starts empty and receives only its own live todos', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Standing task'), findsOneWidget);
    expect(find.text('Standing goal'), findsOneWidget);

    layout.openInActiveLeaf(_chat(_newId));
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsNothing);
    expect(find.text('Standing goal'), findsNothing);
    final l10n = AppLocalizations.of(tester.element(find.byType(IdeSidebar)));
    expect(find.text(l10n.generalTodosEmpty), findsOneWidget);

    todos.rows[_newId] = [_todo(_newId, 'New task')];
    todos.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);

    await tester.tap(_chatTab(_standingId));
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsOneWidget);
    expect(find.text('Standing goal'), findsOneWidget);
    expect(find.text('New task'), findsNothing);

    todos.rows[_newId] = [_todo(_newId, 'Background task')];
    todos.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Background task'), findsNothing);

    await tester.tap(_chatTab(_newId));
    await tester.pumpAndSettle();
    expect(find.text('Background task'), findsOneWidget);
    expect(find.text('Standing task'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('split focus isolates todo display and status changes', (
    tester,
  ) async {
    final firstLeaf = layout.activeLeafId;
    layout.openInSplit(firstLeaf, _chat(_otherId), DropEdge.right);
    await pump(tester);
    expect(find.text('Other task'), findsOneWidget);
    expect(find.text('Standing task'), findsNothing);

    await tester.tap(find.text('Other task'));
    await tester.pumpAndSettle();
    expect(todos.rows[_otherId]!.single.status, TodoStatus.inProgress);
    expect(todos.rows[_standingId]!.single.status, TodoStatus.pending);

    await tester.tap(_chatTab(_standingId));
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsOneWidget);
    expect(find.text('Other task'), findsNothing);

    await tester.tap(_chatTab(_otherId));
    await tester.pumpAndSettle();
    expect(find.text('Other task'), findsOneWidget);
    layout.closeTabByIdentity(layout.activeLeaf.controller.tabs.single);
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsOneWidget);
    expect(find.text('Other task'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('only the seeded chat resolves the standing conversation', (
    tester,
  ) async {
    layout.openInActiveLeaf(
      EditorTab(
        kind: MessagingTabKinds.chat,
        label: 'Space chat',
        dedupKey: MessagingTabKinds.chatSpaceTabKey(_spaceId),
        args: const {'spaceId': _spaceId},
      ),
    );
    await pump(tester);
    expect(find.text('Standing task'), findsOneWidget);

    layout.openInActiveLeaf(
      const EditorTab(kind: MessagingTabKinds.file, label: 'File'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsNothing);
    expect(find.text('Standing goal'), findsNothing);

    while (!layout.activeLeaf.controller.isEmpty) {
      layout.closeTab(layout.activeLeafId, 0);
    }
    await tester.pumpAndSettle();
    expect(find.text('Standing task'), findsNothing);
    expect(find.text('Standing goal'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
