import 'package:cc_ui/src/components/cc_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders label and leading icon', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcChip(
          label: 'TypeScript',
          leadingIcon: LucideIcons.code,
        ),
      ),
    );

    expect(find.text('TypeScript'), findsOneWidget);
    expect(find.byIcon(LucideIcons.code), findsOneWidget);
  });

  testWidgets('fires onTap when tapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcChip(
          label: 'Filter',
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Filter'));
    expect(tapped, 1);
  });

  testWidgets('delete button fires onDeleted', (tester) async {
    var deleted = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcChip(
          label: 'Removable',
          onDeleted: () => deleted++,
        ),
      ),
    );

    await tester.tap(find.text('×'));
    expect(deleted, 1);
  });

  testWidgets('selected chip renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcChip(label: 'Active', selected: true),
      ),
    );

    expect(find.byType(CcChip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
