import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          githubCliStatusProvider.overrideWith((ref) async => const GitHubCliStatus(isInstalled: false, token: '')),
        ],
        child: testWrap(const AppearanceSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('renders appearance sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          githubCliStatusProvider.overrideWith((ref) async => const GitHubCliStatus(isInstalled: false, token: '')),
        ],
        child: testWrap(const AppearanceSettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Verify the screen renders with content.
    expect(find.byType(AppearanceSettingsScreen), findsOneWidget);

    // Verify the page title renders.
    expect(find.text('Appearance'), findsOneWidget);

    // Verify the subtitle renders.
    expect(
      find.text('Theme, language, and typography.'),
      findsOneWidget,
    );
  });
}
