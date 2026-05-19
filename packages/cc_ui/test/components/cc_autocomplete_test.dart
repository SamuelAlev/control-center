import 'package:cc_ui/src/components/cc_autocomplete.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
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
      // unfocused the field, and the focus-loss panel hide cancelled the tap
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

    testWidgets('clicking directly on the field text opens the full list', (
      tester,
    ) async {
      // The model-chooser bug: a seeded (non-empty) field has no hint to tap,
      // and the EditableText claims taps on the text before the field's own
      // gesture detector — so the panel only opened after typing.
      final controller = TextEditingController(text: 'Apple');
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

      // A committed selection reopens to the FULL list, not a one-row menu
      // filtered by the selection's own label. 'Apple' matches twice: the
      // field's own text and its panel row.
      expect(find.text('Apple'), findsWidgets);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
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
      // arrow-key navigation: the DecoratedBox nearest the row's label holds
      // the row's background, transparent unless highlighted.
      final rowBoxes = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('Banana'),
              matching: find.byType(DecoratedBox),
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
          onTap: () => setState(() => _options = _options.isEmpty
              ? const [
                  CcSelectOption(value: 'a', label: 'Apple'),
                  CcSelectOption(value: 'b', label: 'Banana'),
                ]
              : _options),
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
