import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/explorer_panel.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';

/// Widget tests for the Explorer panel's lazy, paginated tree.
///
/// The panel must never ask for a whole repo in one frame (that unbounded
/// response was the frame that saturated the WS transport's outbound buffer
/// and reconnect-looped the desktop). These tests pin the wire shape the lazy
/// tree actually issues: a root `repos.listDirectory` on mount, one per
/// expanded folder, cursor pages auto-drained until `has_more` is false, and
/// offset pages for the typed flat search.
void main() {
  late FakeRpcHost host;

  setUp(() {
    host = FakeRpcHost();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [rpcClientProvider.overrideWithValue(host.client())],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );

  void emitRepos() => host.emit('workspace.watchReposForWorkspace', {
    'repos': [
      {
        'id': 'r1',
        'name': 'demo',
        'path': '/tmp/demo',
        'remote_owner': 'o',
        'remote_name': 'demo',
      },
    ],
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(const ExplorerPanel(workspaceId: 'ws', onOpenFile: _noopOpen)),
    );
    // First pump establishes the workspace-repos subscription; only then can
    // the fake host push its snapshot.
    await tester.pump();
    emitRepos();
  }

  testWidgets('mounts with a root listing and auto-drains cursor pages', (
    tester,
  ) async {
    final calls = <Map<String, dynamic>>[];
    // Fake pages of two regardless of the requested limit: page 1 (cursor '')
    // → 2 entries + has_more; page 2 (cursor 'b.txt') → the tail, complete.
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        calls.add(args);
        final cursor = args['cursor'] as String? ?? '';
        if (cursor.isEmpty) {
          return {
            'entries': [
              {'relativePath': 'a.txt', 'isDirectory': false},
              {'relativePath': 'b.txt', 'isDirectory': false},
            ],
            'has_more': true,
          };
        }
        return {
          'entries': [
            {'relativePath': 'c.txt', 'isDirectory': false},
          ],
          'has_more': false,
        };
      }
      return const {};
    };

    await pumpPanel(tester);
    await tester.pumpAndSettle();

    // The repo root row renders.
    expect(find.text('o/demo'), findsOneWidget);
    // Page 1 paints immediately.
    expect(find.text('a.txt'), findsOneWidget);
    expect(find.text('b.txt'), findsOneWidget);

    // Auto-drain pulled the second page without any interaction.
    expect(find.text('c.txt'), findsOneWidget);
    expect(calls, hasLength(2));
    expect(calls[0]['path'], '');
    expect(calls[0]['cursor'], '');
    // The drain continued from the LAST entry of page 1.
    expect(calls[1]['cursor'], 'b.txt');
  });

  testWidgets('expanding a folder fetches that folder\'s listing', (
    tester,
  ) async {
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        final path = args['path'] as String? ?? '';
        if (path.isEmpty) {
          return {
            'entries': [
              {'relativePath': 'lib', 'isDirectory': true},
              {'relativePath': 'README.md', 'isDirectory': false},
            ],
            'has_more': false,
          };
        }
        return {
          'entries': [
            {'relativePath': 'lib/main.dart', 'isDirectory': false},
          ],
          'has_more': false,
        };
      }
      return const {};
    };

    await pumpPanel(tester);
    await tester.pumpAndSettle();

    // Child not fetched before the folder is expanded.
    expect(find.text('main.dart'), findsNothing);

    await tester.tap(find.text('lib'));
    await tester.pumpAndSettle();

    expect(find.text('main.dart'), findsOneWidget);
  });

  testWidgets('cursor pages follow the wire order, not the display order', (
    tester,
  ) async {
    final cursors = <String>[];
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        final cursor = args['cursor'] as String? ?? '';
        cursors.add(cursor);
        if (cursor.isEmpty) {
          // The wire pages in plain path order — 'b.txt' then 'lib'. Display
          // order hoists the directory, so the LAST rendered entry is
          // 'b.txt'; paging from that would re-serve the same page forever.
          return {
            'entries': [
              {'relativePath': 'b.txt', 'isDirectory': false},
              {'relativePath': 'lib', 'isDirectory': true},
            ],
            'has_more': true,
          };
        }
        return {
          'entries': [
            {'relativePath': 'zz.txt', 'isDirectory': false},
          ],
          'has_more': false,
        };
      }
      return const {};
    };

    await pumpPanel(tester);
    await tester.pumpAndSettle();

    expect(cursors, ['', 'lib']);
    expect(find.text('zz.txt'), findsOneWidget);
  });

  testWidgets('re-entering the panel repaints from cache, then revalidates', (
    tester,
  ) async {
    var calls = 0;
    host.onCall = (op, args) {
      if (op == 'repos.listDirectory') {
        calls++;
        final path = args['path'] as String? ?? '';
        if (path.isEmpty) {
          return {
            'entries': [
              {'relativePath': 'lib', 'isDirectory': true},
              {'relativePath': 'README.md', 'isDirectory': false},
            ],
            'has_more': false,
          };
        }
        return {
          'entries': [
            {'relativePath': 'lib/main.dart', 'isDirectory': false},
          ],
          'has_more': false,
        };
      }
      return const {};
    };

    // The sidebar picks its panel with a `switch`, so leaving the Explorer
    // UNMOUNTS it. Same provider container across the swap, as in the app.
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      wrap(
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, show, _) => show
              ? const ExplorerPanel(workspaceId: 'ws', onOpenFile: _noopOpen)
              : const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    emitRepos();
    await tester.pumpAndSettle();

    await tester.tap(find.text('lib'));
    await tester.pumpAndSettle();
    expect(find.text('main.dart'), findsOneWidget);
    final afterFirstVisit = calls; // root + lib
    expect(afterFirstVisit, 2);

    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.text('main.dart'), findsNothing);

    // Back on the first frame: the expanded folder is still open and its rows
    // are already painted — no spinner, no round trip yet.
    visible.value = true;
    await tester.pump();
    expect(find.text('README.md'), findsOneWidget);
    expect(find.text('main.dart'), findsOneWidget);
    expect(calls, afterFirstVisit);

    // ...and every listing it painted from cache is re-checked once, in the
    // background, so a folder written to while the tab was closed corrects
    // itself instead of going stale.
    await tester.pumpAndSettle();
    expect(calls, afterFirstVisit + 2);
  });

  testWidgets('typed search pages by offset as the list scrolls', (
    tester,
  ) async {
    final offsets = <int>[];
    Map<String, dynamic> hit(int i) => {
      'absolutePath': '/tmp/demo/file_$i.dart',
      'relativePath': 'file_$i.dart',
      'rootPath': '/tmp/demo',
      'isDirectory': false,
      'score': 1.0,
      'repoId': 'r1',
    };
    host.onCall = (op, args) {
      if (op == 'repos.searchFiles') {
        final offset = (args['offset'] as num?)?.toInt() ?? 0;
        offsets.add(offset);
        if (offset == 0) {
          return {
            'hits': [for (var i = 0; i < 30; i++) hit(i)],
            'has_more': true,
          };
        }
        return {
          'hits': [hit(30)],
          'has_more': false,
        };
      }
      return const {};
    };

    await pumpPanel(tester);
    await tester.pumpAndSettle();

    // Type a query — after the 150ms debounce the flat list replaces the
    // tree and page 0 renders.
    await tester.enterText(find.byType(CcTextField), 'file');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('file_0.dart'), findsOneWidget);
    expect(offsets, [0]);

    // Scroll near the end: loadMore fetches offset = hits accumulated so far.
    // Bounded pumps, not pumpAndSettle — the trailing CcSpinner row animates
    // forever by design.
    await tester.drag(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
      const Offset(0, -600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(offsets, contains(30));
    expect(find.text('file_30.dart'), findsOneWidget);
  });
}

void _noopOpen(({String repoId, String path}) _) {}
