import 'package:cc_ui/src/components/cc_filter_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  /// Pumps a [CcFilterMenu] with an author-style category whose selection is
  /// live (toggles rebuild with the next set), mirroring app wiring.
  Future<void> pumpMenu(
    WidgetTester tester, {
    required List<CcFilterOption> options,
    Set<String> initial = const {},
    List<Set<String>>? changes,
  }) async {
    var selected = initial;
    await tester.pumpWidget(
      ccTestApp(
        Align(
          alignment: Alignment.topLeft,
          child: StatefulBuilder(
            builder: (context, setState) => CcFilterMenu(
              target: const Text('Filters'),
              searchHint: 'Add filter…',
              optionSearchHint: 'Filter…',
              emptySearchLabel: 'No matches',
              categories: [
                CcFilterCategory(
                  id: 'author',
                  label: 'Author',
                  selected: selected,
                  hiddenCountLabel: (hidden) => '$hidden hidden',
                  onChanged: (next) {
                    changes?.add(next);
                    setState(() => selected = next);
                  },
                  options: options,
                ),
                CcFilterCategory(
                  id: 'repository',
                  label: 'Repository',
                  selected: const {},
                  onChanged: (_) {},
                  options: const [
                    CcFilterOption(value: 'r1', label: 'acme/web', count: 2),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  const authors = [
    CcFilterOption(value: 'me', label: 'Current user', pinned: true, count: 0),
    CcFilterOption(
      value: 'ada',
      label: 'ada',
      count: 3,
      countLabel: '3 pull requests',
    ),
    CcFilterOption(value: 'grace', label: 'grace', count: 1),
    CcFilterOption(value: 'linus', label: 'linus', count: 0),
  ];

  group('CcFilterMenu', () {
    testWidgets('opens the category panel on trigger tap', (tester) async {
      await pumpMenu(tester, options: authors);

      expect(find.text('Author'), findsNothing);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Repository'), findsOneWidget);
      // No flyout yet.
      expect(find.text('ada'), findsNothing);
    });

    testWidgets('activating a category opens its flyout with counts, hides '
        'zero-count options behind the footer and pins pinned rows', (
      tester,
    ) async {
      await pumpMenu(tester, options: authors);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Author'));
      await tester.pumpAndSettle();

      expect(find.text('ada'), findsOneWidget);
      expect(find.text('3 pull requests'), findsOneWidget);
      expect(find.text('grace'), findsOneWidget);
      // Zero-count option is hidden and summarised by the footer…
      expect(find.text('linus'), findsNothing);
      expect(find.text('1 hidden'), findsOneWidget);
      // …but a pinned zero-count option stays visible.
      expect(find.text('Current user'), findsOneWidget);
    });

    testWidgets(
      'toggling options reports the next set and keeps the menu open',
      (tester) async {
        final changes = <Set<String>>[];
        await pumpMenu(tester, options: authors, changes: changes);

        await tester.tap(find.text('Filters'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Author'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('ada'));
        await tester.pumpAndSettle();
        expect(changes, [
          {'ada'},
        ]);
        // Menu and flyout stay open for further toggles in the same session.
        expect(find.text('grace'), findsOneWidget);

        await tester.tap(find.text('grace'));
        await tester.pumpAndSettle();
        expect(changes.last, {'ada', 'grace'});

        // Untoggle.
        await tester.tap(find.text('ada'));
        await tester.pumpAndSettle();
        expect(changes.last, {'grace'});
      },
    );

    testWidgets('a selected zero-count option stays visible', (tester) async {
      await pumpMenu(tester, options: authors, initial: const {'linus'});

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Author'));
      await tester.pumpAndSettle();

      expect(find.text('linus'), findsOneWidget);
      // linus no longer counts toward the hidden footer.
      expect(find.text('1 hidden'), findsNothing);
    });

    testWidgets('the flyout search narrows options', (tester) async {
      await pumpMenu(tester, options: authors);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Author'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).last, 'gra');
      await tester.pumpAndSettle();

      expect(find.text('grace'), findsOneWidget);
      expect(find.text('ada'), findsNothing);

      await tester.enterText(find.byType(EditableText).last, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('the root search narrows categories', (tester) async {
      await pumpMenu(tester, options: authors);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'repo');
      await tester.pumpAndSettle();

      expect(find.text('Repository'), findsOneWidget);
      expect(find.text('Author'), findsNothing);
    });

    testWidgets('Escape steps back out of the flyout, then closes the menu', (
      tester,
    ) async {
      await pumpMenu(tester, options: authors);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Author'));
      await tester.pumpAndSettle();
      expect(find.text('ada'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // Flyout closed, root panel still open.
      expect(find.text('ada'), findsNothing);
      expect(find.text('Author'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Author'), findsNothing);
    });

    testWidgets('tapping outside closes the menu', (tester) async {
      await pumpMenu(tester, options: authors);

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Author'), findsOneWidget);

      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(find.text('Author'), findsNothing);
    });
  });
}
