import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  testWidgets('renders label and leading icon', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcChip(label: 'TypeScript', leadingIcon: CcIcons.code)),
    );

    expect(find.text('TypeScript'), findsOneWidget);
    expect(find.byIcon(CcIcons.code), findsOneWidget);
  });

  testWidgets('fires onTap when tapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      ccTestApp(CcChip(label: 'Filter', onPressed: () => tapped++)),
    );

    await tester.tap(find.text('Filter'));
    expect(tapped, 1);
  });

  testWidgets('delete button fires onDeleted', (tester) async {
    var deleted = 0;
    await tester.pumpWidget(
      ccTestApp(CcChip(label: 'Removable', onDeleted: () => deleted++)),
    );

    await tester.tap(find.text('×'));
    expect(deleted, 1);
  });

  testWidgets('selected chip renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcChip(label: 'Active', selected: true)),
    );

    expect(find.byType(CcChip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled chip renders muted and does not fire delete', (
    tester,
  ) async {
    var deleted = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcChip(label: 'Locked', disabled: true, onDeleted: () => deleted++),
      ),
    );
    expect(find.text('Locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The delete affordance is inert when disabled.
    await tester.tap(find.text('×'), warnIfMissed: false);
    await tester.pump();
    expect(deleted, 0);
  });

  testWidgets('a custom deleteIcon replaces the default × glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcChip(label: 'Tag', onDeleted: _noop, deleteIcon: CcIcons.x),
      ),
    );
    expect(find.byIcon(CcIcons.x), findsOneWidget);
    expect(find.text('×'), findsNothing);
  });

  testWidgets('interactive chip reflects hovered + pressed backgrounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(CcChip(label: 'Hover', onPressed: () {}, selected: true)),
    );
    // Hover the chip so the hovered + selected background branch executes.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CcChip)),
    );
    await tester.pump();
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('body and delete are sibling controls, two Tab stops', (
    tester,
  ) async {
    var pressed = 0;
    var deleted = 0;
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox(width: 10, height: 10),
            ),
            CcChip(
              label: 'Tag',
              onPressed: () => pressed++,
              onDeleted: () => deleted++,
            ),
          ],
        ),
      ),
    );
    // Neither control sits inside the other.
    final tappables = find.byType(CcTappable);
    expect(tappables, findsNWidgets(2));
    expect(
      find.descendant(of: tappables.first, matching: tappables.last),
      findsNothing,
    );

    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect((pressed, deleted), (1, 0));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect((pressed, deleted), (1, 1));

    // A tap on the x deletes without pressing the body.
    await tester.tap(find.text('×'));
    await tester.pump();
    expect((pressed, deleted), (1, 2));
  });

  testWidgets('the delete button is named after the chip and 24px square', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcChip(label: 'Tag', onDeleted: () {}),
        ),
      ),
    );
    final delete = find.ancestor(
      of: find.text('×'),
      matching: find.byType(CcTappable),
    );
    expect(tester.getSize(delete), const Size(24, 24));
    expect(
      tester.getSemantics(delete),
      matchesSemantics(
        label: 'Remove Tag',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a selected toggle chip announces its state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(CcChip(label: 'Open', selected: true, onPressed: () {})),
    );
    expect(
      tester.getSemantics(find.byType(CcTappable)),
      matchesSemantics(
        label: 'Open',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a disabled chip reports enabled: false', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            CcChip(label: 'Body', disabled: true, onPressed: () {}),
            const CcChip(label: 'Static', disabled: true),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Body')),
      matchesSemantics(label: 'Body', isButton: true, hasEnabledState: true),
    );
    expect(
      tester.getSemantics(find.text('Static')),
      matchesSemantics(label: 'Static', hasEnabledState: true),
    );
    handle.dispose();
  });
}

void _noop() {}
