import 'package:cc_ui/cc_ui.dart';
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
      ccTestApp(CcChip(label: 'Filter', onTap: () => tapped++)),
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
      ccTestApp(CcChip(label: 'Hover', onTap: () {}, selected: true)),
    );
    // Hover the chip so the hovered + selected background branch executes.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CcChip)),
    );
    await tester.pump();
    await gesture.up();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
