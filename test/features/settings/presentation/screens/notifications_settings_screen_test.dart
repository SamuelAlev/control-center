import 'package:control_center/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: testWrap(const NotificationsSettingsScreen()),
      ),
    );
    await tester.pump();
    // The page title, and the label of the master switch's card (labels are
    // painted as written, so it reads the same as the title).
    expect(find.text('Notifications'), findsNWidgets(2));
  });
}
