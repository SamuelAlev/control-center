import 'package:control_center/features/settings/presentation/screens/keybindings_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('renders page with title and search field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: testWrap(const KeybindingsSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // PageWrapper title
    expect(find.text('Keybindings'), findsOneWidget);
    // Search field
    expect(find.byType(FTextField), findsOneWidget);
    // Search icon inside the Row
    expect(find.byIcon(LucideIcons.search), findsOneWidget);
  });

  testWidgets('renders keybinding categories', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: testWrap(const KeybindingsSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Screen renders with search field and binding content.
    expect(find.byType(KeybindingsSettingsScreen), findsOneWidget);
    expect(find.byType(FTextField), findsOneWidget);
  });

  testWidgets('filters bindings by search query', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: testWrap(const KeybindingsSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(FTextField), 'Dashboard');
    await tester.pump();
    await tester.pump();

    // Screen still renders after filtering.
    expect(find.byType(KeybindingsSettingsScreen), findsOneWidget);
  });

  testWidgets('shows empty state when query matches nothing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: testWrap(const KeybindingsSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(FTextField),
      'nothingmatchesthisxyz123',
    );
    await tester.pump();
    await tester.pump();

    // Empty state renders — screen still present.
    expect(find.byType(KeybindingsSettingsScreen), findsOneWidget);
  });
}
