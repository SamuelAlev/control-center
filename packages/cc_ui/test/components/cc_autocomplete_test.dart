import 'package:cc_ui/src/components/cc_autocomplete.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const _options = <CcSelectOption<String>>[
  CcSelectOption(value: 'a', label: 'Apple'),
  CcSelectOption(value: 'b', label: 'Banana'),
  CcSelectOption(value: 'c', label: 'Cherry'),
];

void main() {
  group('CcAutocomplete', () {
    testWidgets('typing filters the options into the floating list', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search fruit',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search fruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('selecting a match fills the field and reports the value', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search fruit',
              onSelected: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search fruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ch');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();

      expect(chosen, 'c');
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, 'Cherry');
    });

    testWidgets('uses a custom displayString for filtering and selection', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              displayString: (o) => o.label.toUpperCase(),
              onSelected: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'APP');
      await tester.pumpAndSettle();

      // The default filter matches on the custom display string ("APPLE"),
      // surfacing the Apple row (rows render the option label).
      expect(find.text('Apple'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(chosen, 'a');
      // On selection the displayString is written into the field.
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'APPLE',
      );
    });

    testWidgets('uses a custom filter', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              // Custom filter: only options whose value equals the query.
              filter: (opts, q) =>
                  opts.where((o) => o.value == q.trim().toLowerCase()).toList(),
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('Escape closes the open panel', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('tapping a panel row after clicking the empty field selects', (
      tester,
    ) async {
      // Regression: a row tap read as "outside" the EditableText's tap region,
      // unfocused the field and the focus-loss panel hide cancelled the tap
      // before it selected (keyboard Enter was unaffected).
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(chosen, 'b');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Banana',
      );
    });

    testWidgets(
      'clicking a filled field opens the full list, not a prefilter',
      (tester) async {
        // A seeded (non-empty) field has no hint to tap; the displayed
        // selection is not a query, so opening lists every option.
        final controller = TextEditingController(text: 'Apple');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: CcAutocomplete<String>(
                options: _options,
                hintText: 'Search',
                controller: controller,
                onSelected: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsWidgets);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Cherry'), findsOneWidget);
      },
    );

    testWidgets(
      'reopening after a selection still lists every option',
      (tester) async {
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: CcAutocomplete<String>(
                options: _options,
                hintText: 'Search',
                onSelected: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'ch');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cherry'));
        await tester.pumpAndSettle();

        expect(find.text('Banana'), findsNothing);

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Cherry'), findsWidgets);
      },
    );

    testWidgets(
      'a live typed query still filters when the field is clicked again',
      (tester) async {
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: CcAutocomplete<String>(
                options: _options,
                hintText: 'Search',
                onSelected: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'an');
        await tester.pumpAndSettle();

        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Cherry'), findsNothing);

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Apple'), findsNothing);
        expect(find.text('Cherry'), findsNothing);
      },
    );

    testWidgets(
      'clicking the field padding focuses it and keeps the panel open',
      (tester) async {
        // Regression: a click on chrome padding (outside the 18px glyph
        // strip) showed the I-beam but never focused — pointer-down opened
        // the overlay, then pointer-up hit the dismiss barrier.
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: SizedBox(
                width: 280,
                child: CcAutocomplete<String>(
                  options: _options,
                  hintText: 'Search',
                  focusNode: focusNode,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        final chrome = tester.getRect(find.byType(CcAutocomplete<String>));
        final glyphs = tester.getRect(find.byType(EditableText));
        expect(
          chrome.top < glyphs.top,
          isTrue,
          reason: 'field chrome includes padding above the glyphs',
        );
        await tester.tapAt(Offset(glyphs.center.dx, chrome.top + 3));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);
        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Cherry'), findsOneWidget);
      },
    );

    testWidgets('double-clicking selects the word under the pointer', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 280,
              child: CcAutocomplete<String>(
                options: _options,
                hintText: 'Search',
                controller: controller,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final target =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(10, 8);
      await tester.tapAt(target, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(target, kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(
        controller.selection.textInside(controller.text),
        'hello',
        reason: 'double-click should select the word under the pointer',
      );
    });

    testWidgets('click-dragging selects a text range', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 280,
              child: CcAutocomplete<String>(
                options: _options,
                hintText: 'Search',
                controller: controller,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final left = tester.getTopLeft(find.byType(EditableText));
      final gesture = await tester.startGesture(
        left + const Offset(2, 8),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(left + const Offset(200, 8));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        controller.selection.isCollapsed,
        isFalse,
        reason: 'click-drag should select a range, not just move the caret',
      );
    });

    testWidgets('options arriving after first build still open on click', (
      tester,
    ) async {
      // ccTestApp's OverlayEntry captures its first child, so async arrival
      // is simulated with an in-tree state change instead of a re-pump.
      await tester.pumpWidget(ccTestApp(const Center(child: _AsyncLoader())));

      // No options yet — clicking opens nothing.
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);

      await tester.tap(find.text('Load'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('does not open the panel when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              enabled: false,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Typing into a disabled field must not surface the option list.
      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('the best-matching option is highlighted while typing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      // The single match ('Banana') carries the highlight wash without any
      // arrow-key navigation: the Container nearest the row's label holds
      // the row's background, transparent unless highlighted.
      final rowBoxes = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('Banana'),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final wash = rowBoxes.last.decoration as BoxDecoration;
      expect(wash.color, isNot(const Color(0x00000000)));
    });

    testWidgets('the clear icon empties the input and shows the full list', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      // No ✕ before text is entered; one once it is.
      expect(find.text('Cherry'), findsNothing);
      await tester.tap(find.byIcon(CcIcons.x));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
      // The unfiltered list is back.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('combo box commits a custom value on Enter', (tester) async {
      String? committed;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
              onCustomValue: (v) => committed = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'zz');
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(committed, 'zz');

      // Committing the same text again (e.g. focus loss after Enter) does
      // not fire twice.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(committed, 'zz');
    });

    testWidgets('combo box commits a custom value on outside tap', (
      tester,
    ) async {
      String? committed;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
              onCustomValue: (v) => committed = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'zz');
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(committed, 'zz');
      // The saved value stays displayed in the field.
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'zz',
      );
    });

    testWidgets('an exact option match is a selection, never a custom value', (
      tester,
    ) async {
      String? committed;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
              onCustomValue: (v) => committed = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Apple');
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(committed, isNull);
    });

    testWidgets('Escape does not commit a pending custom value', (
      tester,
    ) async {
      String? committed;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search',
              onSelected: (_) {},
              onCustomValue: (v) => committed = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Ap');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(committed, isNull);
    });

    testWidgets('long lists cap at five and a half rows', (tester) async {
      final manyOptions = [
        for (var i = 0; i < 8; i++) CcSelectOption(value: 'v$i', label: 'V$i'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: manyOptions,
              hintText: 'Search',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(SingleChildScrollView)).height,
        5.5 * 40.0,
      );
      await tester.scrollUntilVisible(
        find.text('V7'),
        40,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('V7'), findsOneWidget);
    });

    testWidgets(
      'a long list stays attached to the field instead of covering it',
      (tester) async {
        final manyOptions = [
          for (var i = 0; i < 40; i++)
            CcSelectOption(value: 'v$i', label: 'Option $i'),
        ];
        const fieldKey = Key('autocomplete-field');
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: SizedBox(
                key: fieldKey,
                width: 240,
                child: CcAutocomplete<String>(
                  options: manyOptions,
                  hintText: 'Search',
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        final field = tester.getRect(find.byKey(fieldKey));
        final panel = tester.getRect(find.byType(SingleChildScrollView));
        expect(panel.overlaps(field), isFalse);
        expect(panel.top, greaterThanOrEqualTo(field.bottom));
      },
    );
  });
}

/// Harness that starts with no options and loads them on demand — the async
/// model/branch list case.
class _AsyncLoader extends StatefulWidget {
  const _AsyncLoader();

  @override
  State<_AsyncLoader> createState() => _AsyncLoaderState();
}

class _AsyncLoaderState extends State<_AsyncLoader> {
  List<CcSelectOption<String>> _options = const [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(
            () => _options = _options.isEmpty
                ? const [
                    CcSelectOption(value: 'a', label: 'Apple'),
                    CcSelectOption(value: 'b', label: 'Banana'),
                  ]
                : _options,
          ),
          child: const Text('Load'),
        ),
        CcAutocomplete<String>(
          options: _options,
          hintText: 'Search',
          onSelected: (_) {},
        ),
      ],
    );
  }
}
