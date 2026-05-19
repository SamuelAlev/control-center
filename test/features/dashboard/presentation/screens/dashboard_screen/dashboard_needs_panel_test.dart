import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_side_panels.dart';
import 'package:control_center/features/dashboard/providers/needs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  const codeFont = 'JetBrains Mono';

  testWidgets('renders caught up state when no needs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardNeedsProvider.overrideWithValue(const []),
        ],
        child: testWrap(const DashboardNeedsPanel(codeFont: codeFont)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('No reviews, blocks, or failures need you right now.'),
        findsOneWidget);
    // Header "Needs you now" still renders even when empty — just verify it shows.
  });

  testWidgets('renders needs rows when needs present', (tester) async {
    const List<DashboardNeed> needs = [ReviewsNeed(count: 3, overTwoDays: 1)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardNeedsProvider.overrideWithValue(needs),
        ],
        child: testWrap(const DashboardNeedsPanel(codeFont: codeFont)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Needs you now'), findsOneWidget);
    expect(find.text('3 reviews awaiting you'), findsOneWidget);
    expect(find.text('1 over 2 days old'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('All caught up'), findsNothing);
  });

  testWidgets('renders multiple need types', (tester) async {
    const reviewsNeed = ReviewsNeed(count: 3, overTwoDays: 1);
    const blockedNeed = BlockedAgentNeed(agentName: 'test-agent');
    final failedNeed = FailedPipelineNeed(
      pipelineName: 'deploy',
      failedAt: _fixedDateTime,
      runId: 'run-1',
    );
    const staleNeed = StalePrNeed(
      prNumber: '#42',
      htmlUrl: 'https://github.com/acme/repo/pull/42',
    );

    final needs = <DashboardNeed>[
      reviewsNeed,
      blockedNeed,
      failedNeed,
      staleNeed,
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardNeedsProvider.overrideWithValue(needs),
        ],
        child: testWrap(const DashboardNeedsPanel(codeFont: codeFont)),
      ),
    );
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Needs you now'), findsOneWidget);

    // ReviewsNeed row
    expect(find.text('3 reviews awaiting you'), findsOneWidget);
    expect(find.text('1 over 2 days old'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);

    // BlockedAgentNeed row
    expect(find.text('test-agent is blocked'), findsOneWidget);
    expect(find.text('Waiting on your confirmation'), findsOneWidget);
    expect(find.text('Resolve'), findsOneWidget);

    // FailedPipelineNeed row
    expect(find.text('Pipeline failed'), findsOneWidget);
    expect(find.text('deploy'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // StalePrNeed row
    expect(find.text('PR #42 stale'), findsOneWidget);
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('Triage'), findsOneWidget);

    expect(find.text('All caught up'), findsNothing);
  });
}

final _fixedDateTime = DateTime(2026, 6, 10);
