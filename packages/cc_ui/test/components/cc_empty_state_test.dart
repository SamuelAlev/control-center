import 'package:cc_ui/src/components/cc_empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders icon and message', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcEmptyState(
          icon: LucideIcons.folderOpen,
          message: 'No facts yet',
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.folderOpen), findsOneWidget);
    expect(find.text('No facts yet'), findsOneWidget);
  });

  testWidgets('renders description and action', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcEmptyState(
          icon: LucideIcons.inbox,
          message: 'Empty',
          description: 'Facts appear here as your agents learn.',
          action: GestureDetector(
            onTap: () => pressed++,
            child: const Text('Add fact'),
          ),
        ),
      ),
    );

    expect(find.text('Facts appear here as your agents learn.'), findsOneWidget);
    await tester.tap(find.text('Add fact'));
    expect(pressed, 1);
  });

  testWidgets('omits description when blank', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcEmptyState(
          icon: LucideIcons.inbox,
          message: 'Nothing here',
          description: '   ',
        ),
      ),
    );

    expect(find.text('   '), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
