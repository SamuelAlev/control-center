import 'dart:ui' show CheckedState, Tristate;

import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
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

    testWidgets('a leading widget replaces the bundled icon', (tester) async {
      await tester.pumpWidget(
        buildTrigger(
          items: [
            CcMenuItem(
              label: 'Firefox',
              icon: CcIcons.check,
              leading: (color) => Container(
                key: const ValueKey('brandMark'),
                width: 16,
                height: 16,
                color: color,
              ),
              onSelected: () {},
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('brandMark')),
        findsOneWidget,
        reason:
            'The leading builder exists for brand marks the icon font cannot '
            'express (a browser engine\'s SVG logo in the VM tab menu).',
      );
      expect(
        find.byIcon(CcIcons.check),
        findsNothing,
        reason: 'A row never renders both its icon and its leading widget.',
      );
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

    testWidgets('opens a submenu with the keyboard and a child selection '
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

  group('CcMenu sections', () {
    testWidgets('renders a section heading as written without making it '
        'selectable', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                const CcMenuItem.section('Tools'),
                CcMenuItem(label: 'Terminal', onSelected: () => picked++),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // The heading is painted as written, never upper-cased.
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('TOOLS'), findsNothing);

      // One arrow-down lands on the row BELOW the heading, not the heading.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 1);
    });

    testWidgets('arrow keys skip headings, dividers and disabled rows, and '
        'wrap at the ends', (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                const CcMenuItem.section('Tools'),
                CcMenuItem(
                  label: 'Terminal',
                  onSelected: () => fired.add('Terminal'),
                ),
                CcMenuItem(
                  label: 'Editor',
                  enabled: false,
                  onSelected: () => fired.add('Editor'),
                ),
                const CcMenuItem.divider(),
                const CcMenuItem.section('Virtual machine'),
                CcMenuItem(
                  label: 'Chromium',
                  onSelected: () => fired.add('Chromium'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // Down twice: Terminal, then Chromium — the disabled row, the divider
      // and both headings are all stepped over.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fired, ['Chromium']);

      // A third down from the last selectable row wraps to the first.
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fired, ['Chromium', 'Terminal']);
    });

    testWidgets('a plain dropdown highlights nothing until an arrow is '
        'pressed', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Terminal', onSelected: () => picked++),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      // Enter with nothing highlighted must not fire the first row — a menu
      // opened with the mouse has made no choice yet.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 0);
    });
  });

  group('CcMenu searchable', () {
    Widget buildSearchable({List<CcMenuItem>? items, double maxWidth = 280}) =>
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              searchable: true,
              searchHint: 'Search',
              emptySearchLabel: 'No matches',
              maxWidth: maxWidth,
              items:
                  items ??
                  [
                    const CcMenuItem.section('Tools'),
                    CcMenuItem(label: 'Terminal', onSelected: () {}),
                    CcMenuItem(label: 'Editor', onSelected: () {}),
                    const CcMenuItem.divider(),
                    const CcMenuItem.section('Virtual machine'),
                    CcMenuItem(
                      label: 'Chromium',
                      searchText: 'Virtual machine vm',
                      onSelected: () {},
                    ),
                    CcMenuItem(
                      label: 'Firefox',
                      searchText: 'Virtual machine vm',
                      onSelected: () {},
                    ),
                  ],
            ),
          ),
        );

    testWidgets('shows a prefocused search field over the authored groups', (
      tester,
    ) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Virtual machine'), findsOneWidget);

      // The field holds focus, so typing goes into it rather than nowhere.
      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();
      expect(find.text('Firefox'), findsOneWidget);
      expect(find.text('Terminal'), findsNothing);
    });

    testWidgets('a query flattens the list — no heading outlives the rows it '
        'named', (tester) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();

      expect(find.text('Firefox'), findsOneWidget);
      expect(
        find.text('Virtual machine'),
        findsNothing,
        reason:
            'A query ranks globally, so groups are dropped wholesale rather '
            'than leaving a heading standing over an emptied group.',
      );
      expect(find.text('Tools'), findsNothing);
    });

    testWidgets('searchText matches a word the section heading lifted out of '
        'the label', (tester) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // "vm" appears in no label — only in the keywords — and must still find
      // both machines while leaving the host tools out.
      await tester.enterText(find.byType(EditableText), 'vm');
      await tester.pumpAndSettle();

      expect(find.text('Chromium'), findsOneWidget);
      expect(find.text('Firefox'), findsOneWidget);
      expect(find.text('Editor'), findsNothing);
    });

    testWidgets('Enter fires the top result without pressing Down first', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        buildSearchable(
          items: [
            CcMenuItem(
              label: 'Terminal',
              onSelected: () => picked = 'Terminal',
            ),
            CcMenuItem(label: 'Firefox', onSelected: () => picked = 'Firefox'),
          ],
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(picked, 'Firefox');
      expect(find.text('Firefox'), findsNothing, reason: 'the menu closed');
    });

    testWidgets('Escape clears the query first and only then closes', (
      tester,
    ) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();
      expect(find.text('Terminal'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // Still open, back to the full grouped list.
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Terminal'), findsNothing);
    });

    testWidgets('a query matching nothing shows the empty label', (
      tester,
    ) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Firefox'), findsNothing);
    });

    testWidgets('reopening drops the previous query', (tester) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();
      expect(find.text('Terminal'), findsNothing);

      // Close and reopen.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(
        find.text('Terminal'),
        findsOneWidget,
        reason: 'a reopened menu must not inherit the last session’s query',
      );
    });

    testWidgets('the panel keeps one width as the result set changes', (
      tester,
    ) async {
      await tester.pumpWidget(buildSearchable());
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      double panelWidth() => tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(EditableText),
                  matching: find.byType(ClipRRect),
                )
                .first,
          )
          .width;

      final before = panelWidth();
      await tester.enterText(find.byType(EditableText), 'fire');
      await tester.pumpAndSettle();

      expect(
        panelWidth(),
        before,
        reason:
            'A shrink-wrapping panel would resize on every keystroke as the '
            'widest visible row changed, which cannot be read while typing.',
      );
      expect(before, 280);
    });
  });

  group('CcMenu keyboard and focus', () {
    late List<String> picked;
    late FocusNode after;
    setUp(() {
      picked = [];
      after = FocusNode(debugLabel: 'after');
    });
    tearDown(() => after.dispose());

    List<CcMenuItem> items() => [
      CcMenuItem(label: 'Archive', onSelected: () => picked.add('Archive')),
      CcMenuItem(label: 'Branch', onSelected: () => picked.add('Branch')),
      const CcMenuItem.divider(),
      CcMenuItem(
        label: 'Bisect',
        enabled: false,
        onSelected: () => picked.add('Bisect'),
      ),
      CcMenuItem(label: 'Blame', onSelected: () => picked.add('Blame')),
      CcMenuItem(label: 'Copy', onSelected: () => picked.add('Copy')),
    ];

    Widget host() => ccTestApp(
      Column(
        children: [
          CcMenu(target: const Text('Menu'), items: items()),
          CcTappable(
            focusNode: after,
            onPressed: () {},
            builder: (context, states) => const Text('After'),
          ),
        ],
      ),
    );

    FocusNode trigger(WidgetTester tester) =>
        Focus.of(tester.element(find.text('Menu')));

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Menu'));
      await tester.pump();
      await tester.pump();
    }

    Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump();
    }

    testWidgets('arrows and Enter work at once, focus returns to the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await open(tester);
      expect(trigger(tester).hasFocus, isFalse);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, ['Branch']);
      expect(find.text('Archive'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
      await key(tester, LogicalKeyboardKey.tab);
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes and returns focus; Tab stays in the panel', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await open(tester);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      expect(after.hasFocus, isFalse);
      expect(find.text('Archive'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Archive'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('an outside tap returns focus to the trigger', (tester) async {
      await tester.pumpWidget(host());
      await open(tester);
      await tester.tapAt(const Offset(780, 580));
      await tester.pump();
      await tester.pump();
      expect(find.text('Archive'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('Home, End, typeahead and Space', (tester) async {
      await tester.pumpWidget(host());
      await open(tester);
      await key(tester, LogicalKeyboardKey.end);
      await key(tester, LogicalKeyboardKey.home);
      // "b" jumps to Branch, again to Blame (the disabled Bisect is skipped).
      await key(tester, LogicalKeyboardKey.keyB);
      await tester.pump(const Duration(seconds: 1));
      await key(tester, LogicalKeyboardKey.keyB);
      await tester.pump(const Duration(seconds: 1));
      await key(tester, LogicalKeyboardKey.space);
      await tester.pump();
      expect(picked, ['Blame']);

      await open(tester);
      await key(tester, LogicalKeyboardKey.end);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, ['Blame', 'Copy']);
    });

    testWidgets('the highlight and the check are on the row semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Light', selected: true, onSelected: () {}),
                CcMenuItem(label: 'Dark', onSelected: () {}),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Menu')).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      await open(tester);
      expect(
        tester.getSemantics(find.text('Menu')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      await key(tester, LogicalKeyboardKey.arrowDown);
      final light = tester.getSemantics(find.text('Light'));
      // One name, not the label plus the merged visible text.
      expect(light.label, 'Light');
      expect(light.flagsCollection.isSelected, Tristate.isTrue);
      expect(light.flagsCollection.isChecked, CheckedState.isTrue);
      final dark = tester.getSemantics(find.text('Dark'));
      expect(dark.flagsCollection.isSelected, Tristate.isFalse);
      expect(dark.flagsCollection.isChecked, CheckedState.isFalse);
      semantics.dispose();
    });
  });

  group('showCcMenuAt focus', () {
    testWidgets('takes focus from the page, keys work, focus returns', (
      tester,
    ) async {
      final opener = FocusNode(debugLabel: 'opener');
      addTearDown(opener.dispose);
      final picked = <String>[];
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: Builder(
              builder: (context) => CcTappable(
                focusNode: opener,
                onPressed: () => showCcMenuAt(
                  context: context,
                  position: const Offset(100, 100),
                  items: [
                    CcMenuItem(label: 'Open', onSelected: () {}),
                    CcMenuItem.submenu(
                      label: 'Share',
                      children: [
                        CcMenuItem(
                          label: 'Link',
                          onSelected: () => picked.add('Link'),
                        ),
                        CcMenuItem(
                          label: 'Mail',
                          onSelected: () => picked.add('Mail'),
                        ),
                      ],
                    ),
                    CcMenuItem(
                      label: 'Save',
                      onSelected: () => picked.add('Save'),
                    ),
                  ],
                ),
                builder: (context, states) => const Text('Trigger'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump();
      expect(opener.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Link'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(picked, ['Mail']);
      expect(opener.hasPrimaryFocus, isTrue);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Escape from the root closes and returns focus', (
      tester,
    ) async {
      final opener = FocusNode(debugLabel: 'opener');
      addTearDown(opener.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: Builder(
              builder: (context) => CcTappable(
                focusNode: opener,
                onPressed: () => showCcMenuAt(
                  context: context,
                  position: const Offset(100, 100),
                  items: [CcMenuItem(label: 'Open', onSelected: () {})],
                ),
                builder: (context, states) => const Text('Trigger'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(find.text('Open'), findsNothing);
      expect(opener.hasPrimaryFocus, isTrue);
    });
  });
}
