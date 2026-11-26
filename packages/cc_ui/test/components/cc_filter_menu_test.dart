import 'dart:ui' show CheckedState, Tristate;

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
        // A WidgetsApp's caret keys, so ← and → can move through the search.
        DefaultTextEditingShortcuts(
          child: Align(
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

  group('CcFilterMenu keyboard and focus', () {
    FocusNode trigger(WidgetTester tester) =>
        Focus.of(tester.element(find.text('Filters')));

    Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump();
    }

    Future<void> open(WidgetTester tester) async {
      trigger(tester).requestFocus();
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
    }

    EditableText field(WidgetTester tester, {bool flyout = false}) {
      final fields = find.byType(EditableText);
      return tester.widget<EditableText>(flyout ? fields.last : fields.first);
    }

    testWidgets('opening focuses the search; Tab stays in; Escape returns '
        'focus to the trigger', (tester) async {
      await pumpMenu(tester, options: authors);
      await open(tester);
      expect(find.text('Author'), findsOneWidget);
      expect(field(tester).focusNode.hasPrimaryFocus, isTrue);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      expect(find.text('Author'), findsOneWidget);
      expect(trigger(tester).hasFocus, isFalse);
      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Author'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('an outside tap returns focus to the trigger', (tester) async {
      await pumpMenu(tester, options: authors);
      await open(tester);
      await tester.tapAt(const Offset(780, 580));
      await tester.pump();
      await tester.pump();
      expect(find.text('Author'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('← and → move the caret and leave the text only at its edge', (
      tester,
    ) async {
      await pumpMenu(tester, options: authors);
      await open(tester);
      await tester.enterText(find.byType(EditableText).first, 'Au');
      await tester.pump();
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(field(tester).controller.selection.baseOffset, 1);
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(field(tester).controller.selection.baseOffset, 2);
      expect(find.text('ada'), findsNothing);
      // At the end of the text, → opens the flyout.
      await key(tester, LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('ada'), findsOneWidget);
      expect(field(tester, flyout: true).focusNode.hasPrimaryFocus, isTrue);

      await tester.enterText(find.byType(EditableText).last, 'ad');
      await tester.pump();
      await key(tester, LogicalKeyboardKey.arrowLeft);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(field(tester, flyout: true).controller.selection.baseOffset, 0);
      expect(find.text('ada'), findsOneWidget);
      // Up/Down and Enter still drive the list while typing.
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        tester.getSemantics(find.text('ada')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      // At the start, ← closes the flyout.
      await key(tester, LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.text('ada'), findsNothing);
      expect(field(tester).focusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets('Home, End and Space work the list while nothing is typed', (
      tester,
    ) async {
      final changes = <Set<String>>[];
      await pumpMenu(tester, options: authors, changes: changes);
      await open(tester);
      await key(tester, LogicalKeyboardKey.end);
      expect(
        tester.getSemantics(find.text('Repository')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      await key(tester, LogicalKeyboardKey.home);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('ada'), findsOneWidget);
      // Visible: Current user (pinned), ada, grace.
      await key(tester, LogicalKeyboardKey.end);
      await key(tester, LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes.last, {'grace'});
      expect(find.text('ada'), findsOneWidget);
    });

    testWidgets('rows report checked and the trigger reports expanded', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMenu(tester, options: authors, initial: {'ada'});
      expect(
        tester.getSemantics(find.text('Filters')).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      await open(tester);
      expect(
        tester.getSemantics(find.text('Filters')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      await tester.tap(find.text('Author'));
      await tester.pumpAndSettle();
      final ada = tester.getSemantics(find.text('ada'));
      expect(ada.label, startsWith('ada'));
      expect(ada.label, isNot(startsWith('ada\nada')));
      expect(ada.flagsCollection.isChecked, CheckedState.isTrue);
      expect(
        tester.getSemantics(find.text('grace')).flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      expect(
        tester.getSemantics(find.text('Author')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      semantics.dispose();
    });
  });
}
