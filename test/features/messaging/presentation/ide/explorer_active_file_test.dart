import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_view_strip.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/features/messaging/providers/explorer_view_state_provider.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/messaging/providers/repo_directory_listing_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../../../../helpers/fake_rpc_client.dart';

void main() {
  late FakeRpcHost host;
  late EditorLayoutController layout;
  late ValueNotifier<IdeSidebarView> sidebar;
  late ProviderContainer container;
  Completer<RepoDirectoryListingState>? delayed;

  EditorTab file(int index, {String repoId = 'r1', bool quickView = false}) =>
      EditorTab(
        kind: quickView ? MessagingTabKinds.file : MessagingTabKinds.codeServer,
        label: '$repoId tab $index',
        args: {'repoId': repoId, 'path': 'src/deep/file_$index.dart'},
      );

  setUp(() {
    delayed = null;
    host = FakeRpcHost();
    layout = EditorLayoutController.single();
    sidebar = ValueNotifier(IdeSidebarView.explorer);
    host.onCall = (op, args) {
      if (op != 'repos.listDirectory') {
        return const {};
      }
      final path = args['path'];
      final cursor = args['cursor'] as String;
      return {
        'entries': switch (path) {
          '' => [
            {'relativePath': 'src', 'isDirectory': true},
          ],
          'src' => [
            {'relativePath': 'src/deep', 'isDirectory': true},
          ],
          _ => [
            for (
              var i = cursor.isEmpty ? 0 : 50;
              i < (cursor.isEmpty ? 50 : 100);
              i++
            )
              {'relativePath': 'src/deep/file_$i.dart', 'isDirectory': false},
          ],
        },
        'has_more': path == 'src/deep' && cursor.isEmpty,
      };
    };
  });

  tearDown(() {
    layout.dispose();
    sidebar.dispose();
  });

  Finder tree() => find.descendant(
    of: find.byType(ExplorerPanel),
    matching: find.byType(ListView),
  );

  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: tree(), matching: find.byType(Scrollable)),
      )
      .position;

  void expectCentered(WidgetTester tester, int index) {
    final target = find.text('file_$index.dart');
    expect(target, findsOneWidget);
    expect(
      tester.getCenter(target).dy,
      closeTo(tester.getCenter(tree()).dy, 1),
    );
    expect(tester.takeException(), isNull);
  }

  Future<void> selectView(WidgetTester tester, IdeSidebarView view) async {
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == viewIcon(view) &&
            widget.size == 15,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(WidgetTester tester, {bool rtl = false}) async {
    container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
        repoDirectoryListingProvider.overrideWith2(
          (args) => _DelayedListing(args, () => delayed),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Row(
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
                        tabNotifier: sidebar,
                        layout: layout,
                        workspaceId: 'ws',
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
          ),
        ),
      ),
    );
    await tester.pump();
    host.emit('workspace.watchReposForWorkspace', {
      'repos': [
        for (final id in ['r1', 'r2'])
          {
            'id': id,
            'name': id,
            'path': '/tmp/$id',
            'remote_owner': 'o',
            'remote_name': id,
          },
      ],
    });
    await tester.pumpAndSettle();
  }

  testWidgets('opening and switching file tabs expands and centers the tree', (
    tester,
  ) async {
    await pump(tester);
    layout.openInActiveLeaf(file(75));
    await tester.pumpAndSettle();
    expectCentered(tester, 75);

    layout.openInActiveLeaf(file(20, quickView: true));
    await tester.pumpAndSettle();
    expectCentered(tester, 20);

    await tester.tap(find.text('r1 tab 75').last);
    await tester.pumpAndSettle();
    expectCentered(tester, 75);

    // Background layout changes must not fight manual tree scrolling.
    await tester.drag(tree(), const Offset(0, 200));
    await tester.pumpAndSettle();
    final scrolled = position(tester).pixels;
    layout.ensureBackgroundTab(
      const EditorTab(kind: MessagingTabKinds.chat, label: 'Chat'),
    );
    await tester.pumpAndSettle();
    expect(position(tester).pixels, scrolled);

    // A distinct tab for the same path is still a navigation transition.
    layout.openInActiveLeaf(file(75, quickView: true));
    await tester.pumpAndSettle();
    expectCentered(tester, 75);
  });

  testWidgets('returning to Explore reopens ancestors and recenters the file', (
    tester,
  ) async {
    layout.openInActiveLeaf(file(75));
    await pump(tester);
    expectCentered(tester, 75);

    position(tester).jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('o/r1'));
    await tester.pumpAndSettle();
    expect(find.text('file_75.dart'), findsNothing);

    await selectView(tester, IdeSidebarView.artifacts);
    await selectView(tester, IdeSidebarView.explorer);
    expectCentered(tester, 75);

    await selectView(tester, IdeSidebarView.artifacts);
    layout.openInActiveLeaf(file(20, quickView: true));
    await tester.pump();
    await selectView(tester, IdeSidebarView.explorer);
    expectCentered(tester, 20);
  });

  testWidgets('focused split and repo identity win over an older listing', (
    tester,
  ) async {
    await pump(tester, rtl: true);
    delayed = Completer<RepoDirectoryListingState>();
    layout.openInActiveLeaf(file(75));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    layout.openInSplit(
      layout.activeLeafId,
      file(20, repoId: 'r2'),
      DropEdge.right,
    );
    // The older r1 request is still loading; r2 must already be revealed.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expectCentered(tester, 20);

    delayed!.complete((
      entries: [
        for (var i = 0; i < 100; i++)
          (relativePath: 'src/deep/file_$i.dart', isDirectory: false),
      ],
      hasMore: false,
      loadingMore: false,
      failed: false,
    ));
    await tester.pumpAndSettle();
    expectCentered(tester, 20);

    final view = container.read(explorerViewStateProvider('ws'));
    expect(view.expandedDirs, containsAll(['r2:src', 'r2:src/deep']));
  });

  testWidgets('search stays intact and clearing it reveals the current file', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(CcTextField), 'unmatched');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    layout.openInActiveLeaf(file(75));
    await tester.pumpAndSettle();
    expect(container.read(explorerViewStateProvider('ws')).query, 'unmatched');

    await tester.enterText(find.byType(CcTextField), '');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expectCentered(tester, 75);

    layout.openInActiveLeaf(
      const EditorTab(kind: MessagingTabKinds.chat, label: 'Chat'),
    );
    await tester.pumpAndSettle();
    final before = position(tester).pixels;
    await tester.pump();
    expect(position(tester).pixels, before);
  });

  testWidgets(
    'edge files remain visible and unknown files leave scroll alone',
    (tester) async {
      layout.openInActiveLeaf(file(0));
      await pump(tester);
      expect(find.text('file_0.dart').hitTestable(), findsOneWidget);
      expect(position(tester).pixels, position(tester).minScrollExtent);

      layout.openInActiveLeaf(file(99));
      await tester.pumpAndSettle();
      expect(find.text('file_99.dart').hitTestable(), findsOneWidget);
      expect(position(tester).pixels, position(tester).maxScrollExtent);
      final before = position(tester).pixels;

      layout.openInActiveLeaf(file(75, repoId: 'unlinked'));
      await tester.pumpAndSettle();
      expect(position(tester).pixels, before);
      expect(
        container.read(explorerViewStateProvider('ws')).expandedDirs,
        isNot(contains('unlinked:src')),
      );
    },
  );
}

class _DelayedListing extends RepoDirectoryListingNotifier {
  _DelayedListing(super.args, this.delayed);

  final Completer<RepoDirectoryListingState>? Function() delayed;

  @override
  Future<RepoDirectoryListingState> build() {
    final pending = delayed();
    if (args.repoId == 'r1' && args.path == 'src/deep' && pending != null) {
      return pending.future;
    }
    return super.build();
  }
}
