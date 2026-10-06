import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/quick_open/quick_open_dialog.dart';
import 'package:control_center/features/messaging/providers/recent_files_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';

/// The ⌘P picker: recents by default, recents-then-search while typing, and
/// the three ways out (Enter, open to the side, forget a recent).
void main() {
  late FakeRpcHost host;
  late AppPreferences prefs;
  late List<String> queries;
  QuickOpenChoice? result;
  var closed = false;

  Map<String, dynamic> hit(String path, {bool dir = false}) => {
    'absolutePath': '/tmp/demo/$path',
    'relativePath': path,
    'rootPath': '/tmp/demo',
    'isDirectory': dir,
    'score': 1.0,
    'repoId': 'r1',
  };

  setUp(() {
    host = FakeRpcHost();
    queries = [];
    result = null;
    closed = false;
    host.onCall = (op, args) {
      if (op == 'repos.searchFiles') {
        queries.add(args['query'] as String);
        return {
          'hits': [
            hit('lib/main.dart'),
            hit('lib/widgets', dir: true),
            hit('lib/widgets/menu.dart'),
          ],
          'has_more': false,
        };
      }
      return const {};
    };
    prefs = AppPreferences.inMemory({
      '${recentFilesKeyPrefix}ws': jsonEncode({
        's1': [
          {'r': 'r1', 'p': 'lib/main.dart'},
          {'r': 'r1', 'p': 'README.md'},
        ],
      }),
    });
  });

  Future<void> open(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(host.client()),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          // Above the Navigator, so the dialog route inherits both.
          builder: (context, child) => Directionality(
            textDirection: direction,
            child: CcTheme(data: CcThemeData.light(), child: child!),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                onTap: () async {
                  result = await showQuickOpen(
                    context,
                    workspaceId: 'ws',
                    spaceId: 's1',
                  );
                  closed = true;
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(CcTextField), text);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the recent files, newest first, with no search', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('README.md'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('main.dart')).dy,
      lessThan(tester.getTopLeft(find.text('README.md')).dy),
    );
    // Only the selected row carries the tag and its actions.
    expect(find.text('Recently opened'), findsOneWidget);
    expect(find.byIcon(AppIcons.columns), findsOneWidget);
    expect(find.byIcon(AppIcons.x), findsOneWidget);
    expect(queries, isEmpty);
  });

  testWidgets('typing goes straight into the field and Enter opens the pick', (
    tester,
  ) async {
    await open(tester);

    // No click first: the field owns focus (and the text input connection)
    // as soon as the picker appears.
    expect(tester.testTextInput.hasAnyClients, isTrue);
    tester.testTextInput.enterText('m');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(queries, ['m']);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result?.file, (repoId: 'r1', path: 'lib/main.dart'));
    expect(result?.toSide, isFalse);
  });

  testWidgets('a query ranks matching recents first, then new hits', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'ma');

    // main.dart is both recent and a hit: listed once, as recent. The folder
    // hit is not openable and is left out; README.md no longer matches.
    expect(find.text('main.dart'), findsOneWidget);
    expect(find.text('menu.dart'), findsOneWidget);
    expect(find.text('widgets'), findsNothing);
    expect(find.text('README.md'), findsNothing);
    expect(
      tester.getTopLeft(find.text('main.dart')).dy,
      lessThan(tester.getTopLeft(find.text('menu.dart')).dy),
    );
  });

  testWidgets('arrow down then Cmd+Enter opens the second row to the side', (
    tester,
  ) async {
    await open(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(result?.file.path, 'README.md');
    expect(result?.toSide, isTrue);
  });

  testWidgets('the row split button opens to the side', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(AppIcons.columns));
    await tester.pumpAndSettle();

    expect(result?.file.path, 'lib/main.dart');
    expect(result?.toSide, isTrue);
  });

  testWidgets('the row x forgets a recent file and keeps the picker open', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byIcon(AppIcons.x));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text('main.dart'), findsNothing);
    expect(find.text('README.md'), findsOneWidget);
    final stored = jsonDecode(prefs.getString('${recentFilesKeyPrefix}ws')!);
    expect((stored as Map)['s1'], [
      {'r': 'r1', 'p': 'README.md'},
    ]);

    // Typing still lands in the query after the click.
    tester.testTextInput.enterText('r');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(queries, ['r']);
  });

  testWidgets('says so when nothing has been opened yet', (tester) async {
    prefs = AppPreferences.inMemory();
    await open(tester);

    expect(find.text('No recently opened files'), findsOneWidget);
  });

  testWidgets('lays out under RTL', (tester) async {
    await open(tester, direction: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    expect(find.text('main.dart'), findsOneWidget);
    // The search icon leads the field at the start (right) edge.
    final field = tester.getCenter(find.byType(CcTextField));
    expect(
      tester.getCenter(find.byIcon(AppIcons.search)).dx,
      greaterThan(field.dx),
    );
  });
}
