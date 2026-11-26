import 'dart:ui' show CheckedState, Tristate;

import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_multi_select.dart';
import 'package:cc_ui/src/components/cc_select.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:flutter/foundation.dart';
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
  group('CcMultiSelect', () {
    testWidgets('summarises the selection count in the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a', 'b'},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('count tag clear-all carries a hover tooltip', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a'},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // The ✕ must disclose what it does on hover (Carbon: a tooltip appears
      // when hovering the close icon of the filterable tag).
      expect(
        find.byWidgetPredicate(
          (w) => w is CcTooltip && w.message == 'Clear all',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no vertical divider without a selection', (tester) async {
      // The chevron is the only interactive element, so Carbon draws no
      // divider. (ccTestApp's OverlayEntry captures its first child, so each
      // scenario pumps once — re-pumping would keep the first tree.)
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints ==
                  const BoxConstraints.tightFor(width: 1, height: 20),
        ),
        findsNothing,
      );
    });

    testWidgets('vertical divider separates count tag and chevron', (
      tester,
    ) async {
      // A selection adds the count tag's interactive ✕ — now a divider
      // separates the two interactive elements.
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a'},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints ==
                  const BoxConstraints.tightFor(width: 1, height: 20),
        ),
        findsOneWidget,
      );
    });

    testWidgets('filterable narrows the list and clear-filter restores it', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              filterable: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // The open field takes typed input.
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      // Matching options stay; the rest are temporarily removed.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      // The ✕ to the right of the typed text clears the filter (the only ✕
      // in the field — the selection is empty).
      await tester.tap(find.byIcon(CcIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('filterable keeps the menu open while toggling', (
      tester,
    ) async {
      Set<String> current = {};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              filterable: true,
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(current, {'b'});
      // Still open: other rows remain visible and tappable.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('space types into the filter instead of toggling a row', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              filterable: true,
              onChanged: (_) => calls++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // Highlight a row, then press space — while the filter field holds
      // focus it must type a space, never toggle the highlighted row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(calls, 0);
    });

    testWidgets('toggling a row mutates the set and stays open', (
      tester,
    ) async {
      Set<String> current = {};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(current, {'b'});
      // The panel is still open: the other rows remain visible.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('toggling a selected row removes it from the set', (
      tester,
    ) async {
      Set<String> current = {'a', 'b'};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('2 selected'));
      await tester.pumpAndSettle();

      // Banana is already checked — tapping it un-checks (removes) it.
      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(current, {'a'});
    });

    testWidgets('uses a custom countLabel builder', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a', 'b', 'c'},
              hintText: 'Pick fruit',
              countLabel: (n) => '$n fruits chosen',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('3 fruits chosen'), findsOneWidget);
    });

    testWidgets('shows selected labels as chips when showChips is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a', 'c'},
              hintText: 'Pick fruit',
              showChips: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // The two selected labels render as chips in the trigger.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      // The unselected label is not shown in the trigger.
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('shows the hint when nothing is selected', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pick fruit'), findsOneWidget);
    });

    testWidgets('a Clear all row clears the selection', (tester) async {
      Set<String> current = {'a', 'b'};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('2 selected'));
      await tester.pumpAndSettle();

      // The "Clear all" affordance only renders while something is selected.
      expect(find.text('Clear all'), findsOneWidget);

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(current, isEmpty);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
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

    testWidgets('the open panel autofocuses a keyboard focus scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      // The panel's list node owns the keyboard inside a closed-loop scope so
      // keyboard input is contained while it is open.
      final focus = FocusManager.instance.primaryFocus;
      expect(focus?.debugLabel, 'CcMultiSelect list');
      expect(
        focus?.ancestors
            .whereType<FocusScopeNode>()
            .first
            .traversalEdgeBehavior,
        TraversalEdgeBehavior.closedLoop,
      );
      // Sending arrow/space keys through the scope must not throw.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    for (final (name, key) in [
      ('Enter', LogicalKeyboardKey.enter),
      ('Space', LogicalKeyboardKey.space),
    ]) {
      testWidgets('$name toggles the arrow-highlighted row, not the first', (
        tester,
      ) async {
        var values = <String>{};
        await tester.pumpWidget(
          ccTestApp(
            Center(
              child: StatefulBuilder(
                builder: (context, setState) => CcMultiSelect<String>(
                  options: _options,
                  values: values,
                  hintText: 'Pick fruit',
                  onChanged: (next) => setState(() => values = next),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Pick fruit'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(values, {'b'});

        // The panel stays open and keeps the keyboard for the next toggle.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(values, {'b', 'c'});
      });
    }

    testWidgets('Escape closes the panel', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      // The panel is open.
      expect(find.text('Apple'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Closed — the option rows are gone.
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('arrow up / down / space exercise the keyboard handler', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      // Arrow up (jumps to last row), arrow down (advance), space (toggle when
      // highlighted) and a no-op key all run through the panel's key handler
      // without throwing.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('arrow down wraps around the option list', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      // Four arrow-downs across 3 options wrap around without throwing.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening and closing resets the highlight (rebuilds trigger)', (
      tester,
    ) async {
      Set<String> current = {};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => CcMultiSelect<String>(
                options: _options,
                values: current,
                hintText: 'Pick fruit',
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          ),
        ),
      );

      // Open, move highlight, close, reopen — the highlight resets each open.
      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();
      // Reopened without throwing — the trigger rebuilt on open/close.
      expect(find.text('Apple'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a muted summary and chips when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a', 'c'},
              hintText: 'Pick fruit',
              showChips: true,
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Disabled showChips still renders the selected labels.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      // Tapping the disabled trigger must not open the panel.
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('the count tag ✕ clears the selection without opening', (
      tester,
    ) async {
      Set<String> current = {'a', 'b'};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      // The hint stays visible next to the count tag while values are chosen.
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Pick fruit'), findsOneWidget);

      await tester.tap(find.byIcon(CcIcons.x));
      await tester.pumpAndSettle();

      expect(current, isEmpty);
      // Clearing from the trigger must not open the panel.
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('selected options rise to the top when the panel opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'c'},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('1 selected'));
      await tester.pumpAndSettle();

      // Cherry (selected) now lists above the unselected options.
      expect(
        tester.getTopLeft(find.text('Cherry')).dy,
        lessThan(tester.getTopLeft(find.text('Apple')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Apple')).dy,
        lessThan(tester.getTopLeft(find.text('Banana')).dy),
      );
    });

    testWidgets('a selectAllLabel parent checkbox selects all then clears', (
      tester,
    ) async {
      Set<String> current = {};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => CcMultiSelect<String>(
                options: _options,
                values: current,
                hintText: 'Pick fruit',
                selectAllLabel: 'All fruit',
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      // Unchecked parent selects every option.
      await tester.tap(find.text('All fruit'));
      await tester.pumpAndSettle();
      expect(current, {'a', 'b', 'c'});

      // Checked parent clears the whole selection.
      await tester.tap(find.text('All fruit'));
      await tester.pumpAndSettle();
      expect(current, isEmpty);
    });

    testWidgets('showChips chips carry a per-chip remove ✕', (tester) async {
      Set<String> current = {'a', 'b'};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              showChips: true,
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      final appleChip = find
          .ancestor(of: find.text('Apple'), matching: find.byType(Stack))
          .first;
      await tester.tap(
        find.descendant(of: appleChip, matching: find.byIcon(CcIcons.x)),
      );
      await tester.pumpAndSettle();

      expect(current, {'b'});
    });
  });

  group('CcMultiSelect keyboard and focus', () {
    late FocusNode after;
    setUp(() => after = FocusNode(debugLabel: 'after'));
    tearDown(() => after.dispose());

    Widget host({
      required Set<String> values,
      required ValueChanged<Set<String>> onChanged,
      bool filterable = false,
      bool showChips = false,
    }) => ccTestApp(
      Column(
        children: [
          CcMultiSelect<String>(
            options: _options,
            values: values,
            hintText: 'Pick fruit',
            filterable: filterable,
            showChips: showChips,
            onChanged: onChanged,
          ),
          CcTappable(
            focusNode: after,
            onPressed: () {},
            builder: (context, states) => const Text('After'),
          ),
        ],
      ),
    );

    // The trigger is the first tappable in the select; its ✕ buttons follow.
    Finder triggerFinder() => find
        .descendant(
          of: find.byType(CcMultiSelect<String>),
          matching: find.byType(CcTappable),
        )
        .first;

    FocusNode trigger(WidgetTester tester) =>
        tester.widget<CcTappable>(triggerFinder()).focusNode!;

    Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump();
    }

    Future<void> open(WidgetTester tester) async {
      trigger(tester).requestFocus();
      await tester.pump();
      expect(trigger(tester).hasPrimaryFocus, isTrue);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
    }

    testWidgets('opening moves focus in, Space toggles, Tab stays inside, '
        'Escape returns focus', (tester) async {
      var values = <String>{};
      await tester.pumpWidget(
        host(values: values, onChanged: (v) => values = v),
      );
      await open(tester);
      expect(find.text('Banana'), findsOneWidget);
      expect(trigger(tester).hasFocus, isFalse);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.space);
      expect(values, {'a'});
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      expect(after.hasFocus, isFalse);
      expect(find.text('Banana'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Banana'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
      await key(tester, LogicalKeyboardKey.tab);
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets('an outside tap returns focus to the trigger', (tester) async {
      await tester.pumpWidget(host(values: const {}, onChanged: (_) {}));
      await open(tester);
      await tester.tapAt(const Offset(780, 580));
      await tester.pump();
      await tester.pump();
      expect(find.text('Banana'), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('the passive checkboxes add no Tab stop or node', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(values: const {'b'}, onChanged: (_) {}));
      await open(tester);
      final row = tester.getSemantics(find.text('Banana').last);
      expect(row.label, 'Banana');
      expect(row.flagsCollection.isChecked, CheckedState.isTrue);
      final apple = tester.getSemantics(find.text('Apple'));
      expect(apple.flagsCollection.isChecked, CheckedState.isFalse);
      // Every Tab stays on the list node: no checkbox is a stop.
      for (var i = 0; i < 4; i++) {
        await key(tester, LogicalKeyboardKey.tab);
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'CcMultiSelect list',
        );
      }
      semantics.dispose();
    });

    testWidgets('filterable: typing keeps focus in the field, Space types, '
        'arrows and Escape drive the list', (tester) async {
      var values = <String>{};
      await tester.pumpWidget(
        host(values: values, filterable: true, onChanged: (v) => values = v),
      );
      await open(tester);
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasPrimaryFocus, isTrue);

      await tester.enterText(find.byType(EditableText), 'an');
      // Space reaches the text, not the trigger behind it.
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isFalse);
      await tester.enterText(find.byType(EditableText), 'an ');
      await tester.pump();
      expect(field.controller.text, 'an ');
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);

      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      expect(values, {'b'});
      expect(field.focusNode.hasPrimaryFocus, isTrue);

      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(EditableText), findsNothing);
      expect(trigger(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('filterable: a mouse click outside on desktop returns focus '
        'to the trigger', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await tester.pumpWidget(
          host(values: const {}, filterable: true, onChanged: (_) {}),
        );
        await open(tester);
        await tester.pump();
        expect(find.text('Banana'), findsOneWidget);
        final gesture = await tester.startGesture(
          const Offset(780, 580),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.up();
        await gesture.removePointer();
        await tester.pump();
        await tester.pump();
        expect(find.text('Banana'), findsNothing);
        expect(trigger(tester).hasPrimaryFocus, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('filterable: Tab away closes and lands on the page', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(values: const {}, filterable: true, onChanged: (_) {}),
      );
      await open(tester);
      await tester.pump();
      expect(find.text('Banana'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('the trigger ✕ buttons are sibling Tab stops with names', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var values = <String>{'a', 'b'};
      await tester.pumpWidget(
        host(values: values, showChips: true, onChanged: (v) => values = v),
      );
      final node = tester.getSemantics(triggerFinder());
      // The chip text is part of the trigger's value, not a node of its own.
      expect(node.label, 'Pick fruit');
      expect(node.value, 'Apple, Banana');
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      expect(find.semantics.byLabel('Remove Apple'), findsOne);
      expect(find.semantics.byLabel('Remove Banana'), findsOne);

      trigger(tester).requestFocus();
      await tester.pump();
      await key(tester, LogicalKeyboardKey.tab);
      expect(find.text('Banana'), findsOneWidget);
      // Space on the focused ✕ removes that chip without opening the panel.
      await key(tester, LogicalKeyboardKey.space);
      await tester.pump();
      expect(values, {'b'});
      semantics.dispose();
    });

    testWidgets('the count tag ✕ is named from the strings', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(values: const {'a'}, onChanged: (_) {}));
      final node = tester.getSemantics(triggerFinder());
      expect(node.label, 'Pick fruit');
      expect(node.value, '1 selected');
      expect(find.semantics.byLabel('Clear all'), findsOne);
      semantics.dispose();
    });
  });
}
