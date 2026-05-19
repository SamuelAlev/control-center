import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/github_status/presentation/widgets/github_status_indicator.dart';
import 'package:control_center/features/github_status/providers/github_status_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_database.dart';

/// A test-only [CeoAgentSeedNotifier] that does nothing.
class _TestCeoAgentSeedNotifier extends CeoAgentSeedNotifier {
  @override
  void build() {}
}

/// A test-only [GitHubStatusNotifier] that skips the timer.
class _TestGitHubStatusNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async {
    return GitHubServiceStatus(
      indicator: GitHubStatusIndicator.none,
      description: 'All Systems Operational',
      components: const [],
      incidents: const [],
      fetchedAt: DateTime(2024, 1, 1),
    );
  }
}

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          speechTranscriberProvider.overrideWithValue(null),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          ceoAgentSeedProvider.overrideWith(_TestCeoAgentSeedNotifier.new),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
          githubUserProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: const DashboardScreen(),
            ),
          ),
        ),
      ),
    );
    // Stream/async providers start loading; pump to let them emit.
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders dashboard with greeting', (tester) async {
    await pumpDashboard(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Grüezi'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders new ticket action', (tester) async {
    await pumpDashboard(tester);
    expect(find.text('New ticket'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders active fleet section', (tester) async {
    await pumpDashboard(tester);
    expect(find.text('Active fleet'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders GitHub status button', (tester) async {
    await pumpDashboard(tester);
    expect(find.byType(GitHubStatusButton), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
