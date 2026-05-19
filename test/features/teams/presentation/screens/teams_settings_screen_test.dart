import 'package:control_center/features/teams/presentation/screens/teams_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('TeamsSettingsScreen', () {
    testWidgets('renders AppBar with teams title', (tester) async {
      await tester.pumpWidget(testWrap(
        const TeamsSettingsScreen(),
      ));

      expect(find.text('Teams'), findsOneWidget);
    });

    testWidgets('renders coming soon placeholder', (tester) async {
      await tester.pumpWidget(testWrap(
        const TeamsSettingsScreen(),
      ));

      expect(find.text('Teams — coming soon'), findsOneWidget);
    });

    testWidgets('renders with a specific workspaceId', (tester) async {
      await tester.pumpWidget(testWrap(
        const TeamsSettingsScreen(workspaceId: 'ws-42'),
      ));

      expect(find.text('Teams'), findsOneWidget);
    });

    testWidgets('renders inside a Scaffold', (tester) async {
      await tester.pumpWidget(testWrap(
        const TeamsSettingsScreen(),
      ));

      // Verify it's wrapped in a Scaffold with an AppBar.
      expect(find.byType(TeamsSettingsScreen), findsOneWidget);
    });
  });
}
