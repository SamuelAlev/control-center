import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/github_profile_metrics_panel.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/profile_delivery_scaffold.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('shows delivery patterns at desktop and phone widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final activity = GitHubProfileActivity(
      metrics: GitHubProfileMetrics(
        open: 2,
        draft: 1,
        merged: 6,
        closed: 2,
        analyzedPullRequests: 9,
        resultsTruncated: true,
        medianLinesChanged: 120,
        p90LinesChanged: 900,
        medianHoursToMerge: 12.5,
        p90HoursToMerge: 49,
        medianHoursToFirstReview: 0.5,
        reviewCoveragePercent: 80,
      ),
      repos: [
        GitHubProfileRepoPullRequests(
          repoId: 'repo-1',
          prs: [
            _pr(1, DateTime.utc(2026, 6, 1, 9), const Duration(minutes: 30), 8),
            _pr(2, DateTime.utc(2026, 6, 2, 12), const Duration(hours: 2), 24),
            _pr(3, DateTime.utc(2026, 6, 8, 15), const Duration(hours: 6), 80),
            _pr(
              4,
              DateTime.utc(2026, 6, 9, 18),
              const Duration(hours: 12),
              120,
            ),
            _pr(
              5,
              DateTime.utc(2026, 6, 15, 21),
              const Duration(hours: 30),
              400,
            ),
            _pr(6, DateTime.utc(2026, 6, 22, 3), const Duration(days: 8), 900),
            _pr(7, DateTime.utc(2026, 6, 23, 6), null, 12000),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      testWrap(
        SingleChildScrollView(
          child: GitHubProfileMetricsPanel(activity: AsyncValue.data(activity)),
        ),
      ),
    );

    expect(find.text('Delivery metrics'), findsOneWidget);
    expect(find.text('PRs analyzed: 9'), findsOneWidget);
    expect(find.text('Merge rate'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Review coverage'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Time to first review'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('PR size'), findsOneWidget);
    expect(find.text('p50 120 lines · p90 900 lines'), findsOneWidget);
    expect(find.text('Merge time trend'), findsOneWidget);
    expect(find.text('Weekly median, log scale'), findsOneWidget);
    expect(find.text('Weekday × hour, local time'), findsOneWidget);
    expect(find.text('< 10'), findsOneWidget);
    expect(find.text('≥ 10K'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GitHubProfileMetricsPanel),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Percentiles use a limited sample of the available pull requests.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 900);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('PR size'), findsOneWidget);
    expect(find.text('Merge time trend'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GitHubProfileMetricsPanel),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('keeps a floor height for the PR table', (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const queueKey = Key('profile-queue');
    await tester.pumpWidget(
      testWrap(
        ProfileDeliveryScaffold(
          header: const SizedBox(height: 80, child: Text('header')),
          activity: AsyncValue.data(GitHubProfileActivity.empty),
          queue: const ColoredBox(
            key: queueKey,
            color: Color(0x00000000),
            child: Text('queue'),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(queueKey)).height,
      greaterThanOrEqualTo(ProfileDeliveryScaffold.tableMinHeight),
    );
    expect(
      tester.getRect(find.byType(SingleChildScrollView)).right,
      tester.getRect(find.byType(ProfileDeliveryScaffold)).right,
    );
  });
}

PullRequest _pr(
  int number,
  DateTime createdAt,
  Duration? timeToMerge,
  int lines,
) => PullRequest(
  id: number,
  number: number,
  title: 'PR $number',
  body: '',
  state: timeToMerge == null ? PrState.open : PrState.merged,
  isDraft: false,
  author: null,
  createdAt: createdAt,
  updatedAt: timeToMerge == null ? createdAt : createdAt.add(timeToMerge),
  repoFullName: 'acme/app',
  htmlUrl: 'https://github.com/acme/app/pull/$number',
  mergedAt: timeToMerge == null ? null : createdAt.add(timeToMerge),
  additions: lines,
);
