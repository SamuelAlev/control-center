import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  testWidgets('renders string title and subtitle', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: 'Workspace alpha',
          subtitle: Text('3 agents'),
          leadingIcon: CcIcons.folder,
        ),
      ),
    );

    expect(find.text('Workspace alpha'), findsOneWidget);
    expect(find.text('3 agents'), findsOneWidget);
  });

  testWidgets('fires onTap when interactive', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      ccTestApp(CcTile(title: 'Tap me', onTap: () => tapped++)),
    );

    await tester.tap(find.text('Tap me'));
    expect(tapped, 1);
  });

  testWidgets('selected tile renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcTile(title: 'Selected', selected: true)),
    );

    expect(find.byType(CcTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts a widget title and trailing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: Text('Widget title'),
          trailing: Icon(CcIcons.chevronRight),
        ),
      ),
    );

    expect(find.text('Widget title'), findsOneWidget);
    expect(find.byIcon(CcIcons.chevronRight), findsOneWidget);
  });

  testWidgets('renders a leading widget when provided', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(title: 'With avatar', leading: Icon(CcIcons.user)),
      ),
    );
    expect(find.byIcon(CcIcons.user), findsOneWidget);
  });

  testWidgets('selected interactive tile reflects hovered + pressed states', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: 'Picked',
          selected: true,
          onTap: _noop,
          leadingIcon: CcIcons.folder,
        ),
      ),
    );
    // Pressing the row executes the pressed + hovered branches of _background.
    final target = find.byType(CcTile);
    final center = tester.getCenter(target);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await gesture.up();
  });
}

void _noop() {}
