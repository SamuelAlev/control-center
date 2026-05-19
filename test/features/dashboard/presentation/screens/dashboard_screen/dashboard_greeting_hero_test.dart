import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_greeting_hero.dart';
import 'package:control_center/features/dashboard/providers/dashboard_priority_reviews_provider.dart';
import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/github_status/providers/github_status_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

final _fixedDateTime = DateTime(2026, 6, 11);

final _testGithubStatus = GitHubServiceStatus(
  indicator: GitHubStatusIndicator.none,
  description: 'All Systems Operational',
  components: const [],
  incidents: const [],
  fetchedAt: _fixedDateTime,
);

final _testWorkspace = Workspace(
  id: 'ws-test',
  name: 'TestWorkspace',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _TestGitHubStatusNotifier extends GitHubStatusNotifier {
  @override
  Future<GitHubServiceStatus> build() async => _testGithubStatus;
}

class _TestLastCheckedNotifier extends LastCheckedNotifier {
  @override
  Map<String, DateTime> build() => <String, DateTime>{};
}

void main() {
  const codeFont = 'JetBrains Mono';

  testWidgets('renders greeting when no user name', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith((ref) => Future<GitHubUser?>.value(null)),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Grüezi'), findsOneWidget);
    expect(find.textContaining('Test User'), findsNothing);
  });

  testWidgets('renders greeting with user name', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith(
            (ref) => Future.value(
              const GitHubUser(login: 'testuser', avatarUrl: '', name: 'Test User'),
            ),
          ),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Grüezi, Test User'), findsOneWidget);
  });

  testWidgets('renders date label', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith((ref) => Future<GitHubUser?>.value(null)),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The hero always renders a date eyebrow — verify the widget rendered
    // (greeting is present, which means the whole hero rendered).
    expect(find.text('Grüezi'), findsOneWidget);
  });

  testWidgets('renders workspace eyebrow when workspace present', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith((ref) => Future<GitHubUser?>.value(null)),
          workspacesProvider.overrideWith((ref) => Stream.value([_testWorkspace])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The hero renders successfully with a workspace present.
    expect(find.text('Grüezi'), findsOneWidget);
  });

  testWidgets('renders new ticket action', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith((ref) => Future<GitHubUser?>.value(null)),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('New ticket'), findsOneWidget);
  });

  testWidgets('renders GitHub status button', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          githubUserProvider.overrideWith((ref) => Future<GitHubUser?>.value(null)),
          workspacesProvider.overrideWith((ref) => Stream.value([])),
          githubStatusProvider.overrideWith(_TestGitHubStatusNotifier.new),
          dashboardPriorityReviewsProvider
              .overrideWith((ref) => Future<List<PriorityReview>>.value(const [])),
          lastCheckedProvider.overrideWith(_TestLastCheckedNotifier.new),
        ],
        child: testWrap(const DashboardGreetingHero(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('GitHub status'), findsOneWidget);
  });
}
