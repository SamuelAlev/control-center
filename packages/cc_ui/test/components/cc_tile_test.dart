import 'package:cc_ui/src/components/cc_tile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders string title and subtitle', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: 'Workspace alpha',
          subtitle: Text('3 agents'),
          leadingIcon: LucideIcons.folder,
        ),
      ),
    );

    expect(find.text('Workspace alpha'), findsOneWidget);
    expect(find.text('3 agents'), findsOneWidget);
  });

  testWidgets('fires onTap when interactive', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcTile(
          title: 'Tap me',
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    expect(tapped, 1);
  });

  testWidgets('selected tile renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: 'Selected',
          selected: true,
        ),
      ),
    );

    expect(find.byType(CcTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts a widget title and trailing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcTile(
          title: Text('Widget title'),
          trailing: Icon(LucideIcons.chevronRight),
        ),
      ),
    );

    expect(find.text('Widget title'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });
}
