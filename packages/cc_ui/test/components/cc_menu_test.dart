import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcMenu', () {
    testWidgets('opens the item list on target tap', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Rename', onSelected: () {}),
                CcMenuItem(
                  label: 'Delete',
                  destructive: true,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Rename'), findsNothing);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('selecting an item closes the menu and fires onSelected', (
      tester,
    ) async {
      var selected = 0;

      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Rename', onSelected: () => selected++),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(selected, 1);
      expect(find.text('Rename'), findsNothing);
    });
  });

  group('showCcMenuAt', () {
    Widget buildTrigger({required List<CcMenuItem> items}) {
      return ccTestApp(
        Center(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => showCcMenuAt(
                context: context,
                position: const Offset(100, 100),
                items: items,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('opens the item list at the given position', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem(label: 'Rename', onSelected: () {}),
            CcMenuItem(label: 'Delete', destructive: true, onSelected: () {}),
          ],
        ),
      );

      expect(find.text('Rename'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      final panelTopLeft = tester.getTopLeft(find.text('Rename'));
      expect(panelTopLeft.dx, greaterThanOrEqualTo(100));
      expect(panelTopLeft.dy, greaterThanOrEqualTo(100));
    });

    testWidgets('selecting an item dismisses the menu and fires onSelected', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        buildTrigger(
          items: [CcMenuItem(label: 'Delete', onSelected: () => selected++)],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(selected, 1);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('tapping away dismisses without selecting', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        buildTrigger(
          items: [CcMenuItem(label: 'Delete', onSelected: () => selected++)],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(selected, 0);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('escape dismisses the menu', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [CcMenuItem(label: 'Delete', onSelected: () {})],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsNothing);
    });
  });

  group('showCcMenuAt cascading', () {
    Widget buildTrigger({required List<CcMenuItem> items}) {
      return ccTestApp(
        Center(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => showCcMenuAt(
                context: context,
                position: const Offset(100, 100),
                items: items,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders a leading check for a selected row', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem(label: 'Name', selected: true, onSelected: () {}),
            CcMenuItem(label: 'Size', onSelected: () {}),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(CcIcons.check), findsOneWidget);
    });

    testWidgets('renders a trailing shortcut hint', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem(label: 'Close', trailing: '⌘W', onSelected: () {}),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('⌘W'), findsOneWidget);
    });

    testWidgets('opens a submenu with the keyboard, and a child selection '
        'fires and dismisses', (tester) async {
      String? picked;
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem.submenu(
              label: 'Split',
              children: [
                CcMenuItem(label: 'Up', onSelected: () => picked = 'Up'),
                CcMenuItem(label: 'Down', onSelected: () => picked = 'Down'),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The submenu flyout is not open yet.
      expect(find.text('Up'), findsNothing);

      // Highlight the "Split" row, open its flyout, land on the first child.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Up'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(picked, 'Up');
      expect(find.text('Up'), findsNothing);
    });

    testWidgets('left arrow steps back out of an open submenu', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem.submenu(
              label: 'Split',
              children: [CcMenuItem(label: 'Up', onSelected: () {})],
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Up'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      // The flyout closed but the root menu is still open.
      expect(find.text('Up'), findsNothing);
      expect(find.text('Split'), findsOneWidget);
    });
  });

  group('CcMenu guidance', () {
    testWidgets('renders a divider row between item groups', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Rename', onSelected: () {}),
                const CcMenuItem.divider(),
                CcMenuItem(
                  label: 'Delete',
                  destructive: true,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      // The divider renders as a 1px hairline row.
      expect(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 1),
        findsOneWidget,
      );
    });

    testWidgets('the open panel is never narrower than its trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const SizedBox(width: 300, child: Text('Menu')),
              items: [CcMenuItem(label: 'Rename', onSelected: () {})],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // The row stretches to the panel width, which floors at the trigger's.
      final rowWidth = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Rename'),
                  matching: find.byType(Container),
                )
                .first,
          )
          .width;
      expect(rowWidth, greaterThanOrEqualTo(300));
    });

    testWidgets('long row labels truncate at maxWidth instead of widening', (
      tester,
    ) async {
      const longLabel =
          'A very long menu action label that would otherwise make the menu '
          'grow far beyond any reasonable width';
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              maxWidth: 240,
              items: [CcMenuItem(label: longLabel, onSelected: () {})],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      final rowWidth = tester
          .getSize(
            find
                .ancestor(
                  of: find.text(longLabel),
                  matching: find.byType(Container),
                )
                .first,
          )
          .width;
      expect(rowWidth, lessThanOrEqualTo(240));
    });
  });
}
