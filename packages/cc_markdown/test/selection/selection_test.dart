import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterOverlayLines', () {
    test('strips lines consisting only of spaces', () {
      expect(filterOverlayLines('real\n   \nline'), 'real\nline');
      expect(filterOverlayLines(' \nkeep'), 'keep');
      expect(filterOverlayLines('keep\n '), 'keep');
    });

    test('strips lines consisting only of non-breaking spaces', () {
      expect(filterOverlayLines('a\n  \nb'), 'a\nb');
      expect(filterOverlayLines('a\n \nb'), 'a\nb');
    });

    test('strips lines mixing spaces and NBSPs', () {
      expect(filterOverlayLines('a\n    \nb'), 'a\nb');
    });

    test('strips several artifact lines at once', () {
      expect(
        filterOverlayLines('one\n  \n \ntwo\n   \nthree'),
        'one\ntwo\nthree',
      );
    });

    test('keeps real lines, including ones padded with whitespace', () {
      expect(filterOverlayLines('hello world'), 'hello world');
      expect(filterOverlayLines('  indented code'), '  indented code');
      expect(filterOverlayLines('trailing  '), 'trailing  ');
      expect(filterOverlayLines('  x  '), '  x  ');
    });

    test('keeps genuinely empty lines', () {
      expect(filterOverlayLines('a\n\nb'), 'a\n\nb');
      expect(filterOverlayLines('\n\n'), '\n\n');
      expect(filterOverlayLines(''), '');
      // A trailing newline yields a trailing empty line — preserved.
      expect(filterOverlayLines('a\n'), 'a\n');
    });

    test('keeps lines whose whitespace is not space/NBSP (e.g. tabs)', () {
      expect(filterOverlayLines('a\n\t\nb'), 'a\n\t\nb');
    });

    test('a text that is a single artifact line collapses to empty', () {
      expect(filterOverlayLines('   '), '');
      expect(filterOverlayLines(' '), '');
    });
  });

  group('CcSelectionScope', () {
    testWidgets('of() is true under a scope and false outside it', (
      tester,
    ) async {
      late bool underScope;
      late bool outsideScope;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              CcSelectionScope(
                child: Builder(
                  builder: (context) {
                    underScope = CcSelectionScope.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Builder(
                builder: (context) {
                  outsideScope = CcSelectionScope.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
      expect(underScope, isTrue);
      expect(outsideScope, isFalse);
    });

    testWidgets('of() sees a scope through intermediate widgets', (
      tester,
    ) async {
      late bool underScope;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CcSelectionScope(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Builder(
                builder: (context) {
                  underScope = CcSelectionScope.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(underScope, isTrue);
    });
  });

  group('CcSelectionRegion', () {
    testWidgets('renders a SelectionArea around its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CcSelectionRegion(child: Text('selectable content')),
          ),
        ),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SelectionArea),
          matching: find.text('selectable content'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('defaults to the cc adaptive context menu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CcSelectionRegion(child: Text('x'))),
        ),
      );
      final area = tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(area.contextMenuBuilder, equals(ccDefaultSelectionContextMenu));
    });

    testWidgets('honors a contextMenuBuilder override', (tester) async {
      const menuKey = Key('custom-context-menu');
      Widget customMenu(BuildContext context, SelectableRegionState state) =>
          const SizedBox(key: menuKey, width: 1, height: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CcSelectionRegion(
              contextMenuBuilder: customMenu,
              child: const Text('hello selection world'),
            ),
          ),
        ),
      );

      // The override is wired straight into the SelectionArea.
      final area = tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(area.contextMenuBuilder, same(customMenu));

      // And the override — not the default toolbar — is what actually shows
      // when a long press requests the context menu.
      await tester.longPress(find.text('hello selection world'));
      await tester.pumpAndSettle();
      expect(find.byKey(menuKey), findsOneWidget);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    });

    testWidgets('places a CcSelectionCopyFilter above the SelectionArea', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CcSelectionRegion(child: Text('x'))),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(CcSelectionRegion),
          matching: find.byType(CcSelectionCopyFilter),
        ),
        findsOneWidget,
      );
      // The filter wraps the area so Cmd/Ctrl+C anywhere inside is seen.
      expect(
        find.descendant(
          of: find.byType(CcSelectionCopyFilter),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
    });
  });
}
