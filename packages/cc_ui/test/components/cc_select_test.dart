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
  group('CcSelect', () {
    testWidgets('shows the hint when nothing is selected', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pick fruit'), findsOneWidget);
    });

    testWidgets('opening the dropdown shows the options', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Banana'), findsNothing);

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('short lists shrink-wrap to their rows', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // 3 options × 40px rows — no scroll cap below the sixth option.
      expect(
        tester.getSize(find.byType(SingleChildScrollView)).height,
        3 * 40.0,
      );
    });

    testWidgets('long lists cap at five and a half rows', (tester) async {
      final manyOptions = [
        for (var i = 0; i < 8; i++) CcSelectOption(value: 'v$i', label: 'V$i'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: manyOptions,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // 8 options scroll from the sixth: the panel stops at 5.5 rows so the
      // half-cut row signals there is more below.
      expect(
        tester.getSize(find.byType(SingleChildScrollView)).height,
        5.5 * 40.0,
      );
      // The list is really scrollable — the last option is reachable.
      await tester.scrollUntilVisible(
        find.text('V7'),
        40,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('V7'), findsOneWidget);
    });

    testWidgets('selecting a row updates the value and closes', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(chosen, 'b');
      // Panel closed: the only remaining "Apple"/"Cherry" rows are gone.
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('trigger border reverts to resting after closing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final resting = _triggerBorder(tester);

      // Open the dropdown — border switches to the focused (brand) color.
      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      final open = _triggerBorder(tester);
      expect(
        open,
        isNot(equals(resting)),
        reason: 'border should be the brand color while open',
      );

      // Close by tapping the dismissal barrier (outside the panel).
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(
        _triggerBorder(tester),
        equals(resting),
        reason: 'border must revert to the resting color after closing',
      );
    });

    testWidgets('shows the selected option label in the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: 'b',
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // The selected label replaces the hint in the trigger.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Pick fruit'), findsNothing);
    });

    testWidgets('renders a label above the trigger', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              label: 'Favourite fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Favourite fruit'), findsOneWidget);
    });

    testWidgets('renders an error message beneath the trigger', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              errorText: 'Required',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('renders a warning message beneath the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              warnText: 'Double-check',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Double-check'), findsOneWidget);
    });

    testWidgets('error takes precedence over warn', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              warnText: 'warn here',
              errorText: 'error here',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('error here'), findsOneWidget);
      expect(find.text('warn here'), findsNothing);
    });

    testWidgets('renders helper text when there is no error or warn', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              helperText: 'Pick up to one',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pick up to one'), findsOneWidget);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Tapping a disabled trigger must not open the panel.
      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('arrow keys move the highlighted row', (tester) async {
      String? value;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: _MirrorSelect(
              options: _options,
              initial: null,
              hintText: 'Pick fruit',
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(); // Let the post-frame focus request land on the list.

      // Arrow down highlights the first row; pressing Enter selects it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(value, 'a');
      // The first option (Apple) is now selected and shown in the trigger.
      expect(find.text('Apple'), findsOneWidget);
      // The dropdown closed, so Banana is no longer rendered as a row.
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('arrow up highlights starting from the last row', (
      tester,
    ) async {
      String? value;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: _MirrorSelect(
              options: _options,
              initial: null,
              hintText: 'Pick fruit',
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(); // Let the post-frame focus request land on the list.

      // With no prior highlight, Arrow Up jumps to the last row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(value, 'c');
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('Enter without a highlighted row does nothing', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // No row highlighted yet — Enter is a no-op.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(chosen, isNull);
    });

    group('keyboard scrolling', () {
      // Long enough that the panel caps at 5.5 rows and scrolls.
      final long = <CcSelectOption<String>>[
        for (var i = 0; i < 20; i++)
          CcSelectOption(value: '$i', label: 'Option $i'),
      ];

      Future<ScrollPosition> openLongList(
        WidgetTester tester, {
        String? value,
      }) async {
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: CcSelect<String>(
                options: long,
                value: value,
                hintText: 'Pick one',
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.tap(find.byType(CcSelect<String>));
        await tester.pumpAndSettle();
        await tester.pump(); // Let the post-frame focus request land.
        await tester.pumpAndSettle();
        return tester.state<ScrollableState>(find.byType(Scrollable)).position;
      }

      testWidgets('arrowing past the fold brings the highlight into view', (
        tester,
      ) async {
        final position = await openLongList(tester);
        expect(position.pixels, 0);

        for (var i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        }

        // Row 7 sits past the 5.5-row cap, so the list had to move.
        expect(position.pixels, greaterThan(0));
        final row = tester.getRect(find.text('Option 7'));
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(row.top, greaterThanOrEqualTo(viewport.top - 0.5));
        expect(row.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      });

      testWidgets('a row already on screen does not move the list', (
        tester,
      ) async {
        final position = await openLongList(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        expect(position.pixels, 0);
      });

      testWidgets('wrapping past the last row scrolls back to the top', (
        tester,
      ) async {
        final position = await openLongList(tester);

        // Arrow Up with no highlight jumps to the last row...
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));

        // ...and wrapping forward off the end returns to the first.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(position.pixels, 0);
      });

      testWidgets('opening on a selected option shows it', (tester) async {
        final position = await openLongList(tester, value: '17');

        expect(position.pixels, greaterThan(0));
        // The trigger shows the same label, so scope the lookup to the list.
        final row = tester.getRect(
          find.descendant(
            of: find.byType(CcSelectRow<String>),
            matching: find.text('Option 17'),
          ),
        );
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(row.top, greaterThanOrEqualTo(viewport.top - 0.5));
        expect(row.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      });
    });

    testWidgets('CcSelectRow equality is value based', (tester) async {
      // CcSelectOption's == / hashCode back trigger/row lookups; exercise them.
      const a = CcSelectOption(value: 'a', label: 'Apple');
      const aDup = CcSelectOption(value: 'a', label: 'Apple');
      const b = CcSelectOption(value: 'a', label: 'Apricot');
      const c = CcSelectOption(value: 'b', label: 'Apple');

      expect(a, equals(aDup));
      expect(a.hashCode, aDup.hashCode);
      expect(a == b, isFalse); // different label
      expect(a == c, isFalse); // different value
    });
  });
}

/// The border color of the select trigger (the bordered box holding the hint).
Color? _triggerBorder(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.ancestor(
      of: find.text('Pick fruit'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  // Field chrome: the resting box carries a 1px bottom underline; opening draws
  // a 2px accent outline on the foregroundDecoration. Report whichever is the
  // active border so the open state is distinguishable from resting.
  final fg = container.foregroundDecoration;
  if (fg is BoxDecoration && fg.border is Border) {
    return (fg.border! as Border).top.color;
  }
  final border = (container.decoration! as BoxDecoration).border;
  return border is Border ? border.bottom.color : null;
}

/// A host that mirrors the selected value back into the select's `value` prop,
/// so a keyboard-driven selection is reflected in the trigger after the panel
/// closes.
class _MirrorSelect extends StatefulWidget {
  const _MirrorSelect({
    required this.options,
    required this.initial,
    required this.hintText,
    required this.onChanged,
  });

  final List<CcSelectOption<String>> options;
  final String? initial;
  final String hintText;
  final ValueChanged<String?> onChanged;

  @override
  State<_MirrorSelect> createState() => _MirrorSelectState();
}

class _MirrorSelectState extends State<_MirrorSelect> {
  String? _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return CcSelect<String>(
      options: widget.options,
      value: _value,
      hintText: widget.hintText,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}
