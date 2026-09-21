import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/screens/keybindings_settings_screen.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('renders page with title and search field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: testWrap(const KeybindingsSettingsScreen())),
    );
    await tester.pump();
    await tester.pump();

    // PageWrapper title
    expect(find.text('Keybindings'), findsOneWidget);
    // Search field
    expect(find.byType(CcTextField), findsOneWidget);
    // Search icon inside the Row
    expect(find.byIcon(AppIcons.search), findsOneWidget);
  });
}
