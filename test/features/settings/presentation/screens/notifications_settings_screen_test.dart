import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('renders screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          githubCliStatusProvider.overrideWith((ref) async => const GitHubCliStatus(isInstalled: false, token: '')),
        ],
        child: testWrap(const NotificationsSettingsScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(NotificationsSettingsScreen), findsOneWidget);
  });

  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          githubCliStatusProvider.overrideWith((ref) async => const GitHubCliStatus(isInstalled: false, token: '')),
        ],
        child: testWrap(const NotificationsSettingsScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Notifications'), findsOneWidget);
  });
}
