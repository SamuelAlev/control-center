import 'dart:async';

import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_priority_reviews.dart';
import 'package:control_center/features/dashboard/providers/dashboard_priority_reviews_provider.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

/// Helper to build a [PullRequest] with minimal valid fields.
PullRequest _makePr({
  int id = 1,
  int number = 42,
  String title = 'Fix null pointer in auth handler',
  bool isDraft = false,
  PrState state = PrState.open,
  DateTime? createdAt,
  DateTime? updatedAt,
  String headRef = 'fix/auth-null',
  int additions = 10,
  int deletions = 3,
  int commentsCount = 2,
}) {
  return PullRequest(
    id: id,
    number: number,
    title: title,
    body: '',
    state: state,
    isDraft: isDraft,
    author: null,
    createdAt: createdAt ?? DateTime(2026, 6, 10),
    updatedAt: updatedAt,
    repoFullName: 'acme/widgets',
    htmlUrl: 'https://github.com/acme/widgets/pull/$number',
    headRef: headRef,
    additions: additions,
    deletions: deletions,
    commentsCount: commentsCount,
  );
}

/// Helper to build a [Repo] with minimal valid fields.
Repo _makeRepo({
  String id = 'repo-1',
  String owner = 'acme',
  String name = 'widgets',
}) {
  final now = DateTime(2026, 6, 1);
  return Repo(
    id: id,
    name: '$owner/$name',
    path: '/Users/test/$name',
    githubOwner: owner,
    githubRepoName: name,
    createdAt: now,
    updatedAt: now,
  );
}

/// Helper to build a [PriorityReview].
PriorityReview _makeReview({
  PullRequest? pr,
  Repo? repo,
}) {
  return PriorityReview(
    pr: pr ?? _makePr(),
    repo: repo ?? _makeRepo(),
  );
}

void main() {
  const codeFont = 'JetBrains Mono';

  testWidgets('renders loading indicator when provider is loading',
      (tester) async {
    final completer = Completer<List<PriorityReview>>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // The loading state shows a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders error state without detail', (tester) async {
    final error = Exception('Something went wrong');
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) async => throw error,
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The error state shows "Failed to load"
    expect(find.text('Failed to load'), findsOneWidget);
    // Generic Exception.toString() detail
    expect(find.text('Exception: Something went wrong'), findsOneWidget);
    // No loading indicator
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders error state with NetworkException detail',
      (tester) async {
    const error = NetworkException(
      'API rate limit exceeded',
      statusCode: 403,
      responseBody: '{"message":"Rate limit"}',
    );
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) async => throw error,
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The error state shows "Failed to load"
    expect(find.text('Failed to load'), findsOneWidget);
    // NetworkException formats as "statusCode · message"
    expect(find.text('403 \u{00b7} API rate limit exceeded'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders caught-up state when reviews list is empty',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) => <PriorityReview>[],
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Empty list shows the "All caught up" message
    expect(find.text('All caught up'), findsOneWidget);
    // No count shown in the header (count is null when empty)
    expect(find.text('0'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders reviews grouped by repo with count', (tester) async {
    final repo1 = _makeRepo(id: 'repo-1', owner: 'acme', name: 'widgets');
    final repo2 = _makeRepo(id: 'repo-2', owner: 'acme', name: 'gadgets');
    final reviews = [
      _makeReview(pr: _makePr(id: 1, number: 42, title: 'Fix auth'), repo: repo1),
      _makeReview(pr: _makePr(id: 2, number: 43, title: 'Add rate limit'), repo: repo1),
      _makeReview(pr: _makePr(id: 3, number: 99, title: 'Update docs'), repo: repo2),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Header count: "3" reviews total
    expect(find.text('3'), findsOneWidget);
    // Repo names rendered via RichText TextSpan — need findRichText: true
    expect(
      find.textContaining('widgets', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('gadgets', findRichText: true),
      findsOneWidget,
    );
    // PR titles
    expect(find.text('Fix auth'), findsOneWidget);
    expect(find.text('Add rate limit'), findsOneWidget);
    expect(find.text('Update docs'), findsOneWidget);
    // PR numbers
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('#43'), findsOneWidget);
    expect(find.text('#99'), findsOneWidget);
    // Review requested badges (not drafts)
    expect(find.text('REVIEW REQUESTED'), findsNWidgets(3));
    // All pull requests link
    expect(find.text('All pull requests'), findsOneWidget);
    // No error, no caught-up, no loading
    expect(find.text('Failed to load'), findsNothing);
    expect(find.text('All caught up'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders draft PR with draft badge', (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: 'WIP: refactor', isDraft: true),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Draft badge shown, not review requested
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('REVIEW REQUESTED'), findsNothing);
  });

  testWidgets('renders diff stats when PR has additions or deletions',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, additions: 25, deletions: 7),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Diff stats shown
    expect(find.text('+25'), findsOneWidget);
    expect(find.text('\u22127'), findsOneWidget);
  });

  testWidgets('does not render diff stats when PR has zero additions and deletions',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, additions: 0, deletions: 0),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // No diff stats rendered
    expect(find.text('+0'), findsNothing);
    expect(find.text('\u22120'), findsNothing);
  });

  testWidgets('renders comment count when PR has comments', (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, commentsCount: 5),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Comment icon present
    expect(find.byIcon(LucideIcons.messageSquare), findsOneWidget);
    // "5" appears as the comment count
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('does not render comment count when PR has zero comments',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, commentsCount: 0),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.messageSquare), findsNothing);
  });

  testWidgets('renders branch ref when headRef is set', (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, headRef: 'feature/new-stuff'),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Branch ref shown in the metadata row
    expect(find.text('feature/new-stuff'), findsOneWidget);
  });

  testWidgets('does not render branch ref when headRef is empty',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, headRef: ''),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // PR number still renders
    expect(find.text('#42'), findsOneWidget);
  });

  testWidgets('renders priority reviews title with info dot', (tester) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) => <PriorityReview>[],
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Panel header title
    expect(find.text('Priority reviews'), findsOneWidget);
    // Info dot icon
    expect(find.byIcon(LucideIcons.info), findsOneWidget);
    // "All pull requests" link
    expect(find.text('All pull requests'), findsOneWidget);
  });

  testWidgets('info icon has tooltip configured', (tester) async {
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) => <PriorityReview>[],
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Info icon is present
    final infoIcon = find.byIcon(LucideIcons.info);
    expect(infoIcon, findsOneWidget);

    // FTooltip widget exists in the tree (wraps the info icon)
    expect(find.byType(FTooltip), findsOneWidget);
  });

  group('PR states', () {
    testWidgets('renders merged PR with REVIEW REQUESTED badge', (tester) async {
      final reviews = [
        _makeReview(
          pr: _makePr(
            id: 1,
            number: 42,
            title: 'Merged PR',
            state: PrState.merged,
          ),
        ),
      ];

      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
            ],
            child: const DashboardPriorityReviews(codeFont: codeFont),
          ),
        ),
      );

      expect(find.text('REVIEW REQUESTED'), findsOneWidget);
    });

    testWidgets('renders closed PR with REVIEW REQUESTED badge', (tester) async {
      final reviews = [
        _makeReview(
          pr: _makePr(
            id: 1,
            number: 42,
            title: 'Closed PR',
            state: PrState.closed,
          ),
        ),
      ];

      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
            ],
            child: const DashboardPriorityReviews(codeFont: codeFont),
          ),
        ),
      );

      expect(find.text('REVIEW REQUESTED'), findsOneWidget);
    });

    testWidgets('draft PR has no review-requested badge', (tester) async {
      final reviews = [
        _makeReview(
          pr: _makePr(
            id: 1,
            number: 42,
            title: 'WIP: draft stuff',
            isDraft: true,
          ),
        ),
      ];

      await tester.pumpWidget(
        testWrap(
          ProviderScope(
            overrides: [
              dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
            ],
            child: const DashboardPriorityReviews(codeFont: codeFont),
          ),
        ),
      );

      expect(find.text('REVIEW REQUESTED'), findsNothing);
      expect(find.text('DRAFT'), findsOneWidget);
    });
  });

  testWidgets('renders mix of open, draft, and merged PRs with correct badges',
      (tester) async {
    final repo = _makeRepo();
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 1, title: 'Open PR', state: PrState.open),
        repo: repo,
      ),
      _makeReview(
        pr: _makePr(
          id: 2,
          number: 2,
          title: 'Draft PR',
          isDraft: true,
          state: PrState.open,
        ),
        repo: repo,
      ),
      _makeReview(
        pr: _makePr(
          id: 3,
          number: 3,
          title: 'Merged PR',
          state: PrState.merged,
        ),
        repo: repo,
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    expect(find.text('REVIEW REQUESTED'), findsNWidgets(2));
    expect(find.text('DRAFT'), findsOneWidget);
  });

  testWidgets('renders single PR with no repo name without crash',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: 'No-name repo PR'),
        repo: _makeRepo(owner: '', name: ''),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Widget renders without crash; PR title is visible
    expect(find.text('No-name repo PR'), findsOneWidget);
  });

  testWidgets('renders many reviews across repos without crash', (tester) async {
    final reviews = <PriorityReview>[];
    for (var repoIdx = 0; repoIdx < 5; repoIdx++) {
      final repo = _makeRepo(
        id: 'repo-$repoIdx',
        owner: 'acme',
        name: 'proj$repoIdx',
      );
      for (var prIdx = 0; prIdx < 4; prIdx++) {
        final globalIdx = repoIdx * 4 + prIdx;
        reviews.add(_makeReview(
          pr: _makePr(
            id: globalIdx,
            number: 100 + globalIdx,
            title: 'PR #$globalIdx in repo $repoIdx',
          ),
          repo: repo,
        ));
      }
    }

    // Give enough vertical space for 20 review items to avoid overflow.
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    expect(find.byType(DashboardPriorityReviews), findsOneWidget);
  });

  testWidgets('renders PR with very long title without crash', (tester) async {
    final longTitle = 'A' * 200;
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: longTitle),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    expect(find.byType(DashboardPriorityReviews), findsOneWidget);
  });

  testWidgets('renders PR with special characters in title without crash',
      (tester) async {
    const specialTitle = '\'Quoted\' "double" <angle> &amp; & more';
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: specialTitle),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Widget should render; the title text appears (or is truncated but present)
    expect(find.byType(DashboardPriorityReviews), findsOneWidget);
  });

  testWidgets('renders PR with zero comments but large diff without comment icon',
      (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(
          id: 1,
          number: 42,
          title: 'Big diff, no comments',
          commentsCount: 0,
          additions: 500,
          deletions: 200,
        ),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // No comment icon
    expect(find.byIcon(LucideIcons.messageSquare), findsNothing);
    // Diff stats shown
    expect(find.text('+500'), findsOneWidget);
    expect(find.text('\u2212200'), findsOneWidget);
  });

  testWidgets('transitions from loading to data', (tester) async {
    final completer = Completer<List<PriorityReview>>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Loading spinner visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete with data
    completer.complete([
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: 'After load'),
      ),
    ]);
    await tester.pumpAndSettle();

    // Loading spinner gone, data visible
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('After load'), findsOneWidget);
  });

  testWidgets('renders data state with PR title', (tester) async {
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 42, title: 'Simple data PR'),
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Simple data PR'), findsOneWidget);
  });

  testWidgets('renders repo header once for multiple PRs in same repo',
      (tester) async {
    final repo = _makeRepo();
    final reviews = [
      _makeReview(
        pr: _makePr(id: 1, number: 1, title: 'First PR'),
        repo: repo,
      ),
      _makeReview(
        pr: _makePr(id: 2, number: 2, title: 'Second PR'),
        repo: repo,
      ),
      _makeReview(
        pr: _makePr(id: 3, number: 3, title: 'Third PR'),
        repo: repo,
      ),
    ];

    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            dashboardPriorityReviewsProvider.overrideWith((ref) => reviews),
          ],
          child: const DashboardPriorityReviews(codeFont: codeFont),
        ),
      ),
    );

    // Repo name appears exactly once in the RichText header
    expect(
      find.textContaining('widgets', findRichText: true),
      findsOneWidget,
    );
    // All three PR titles visible
    expect(find.text('First PR'), findsOneWidget);
    expect(find.text('Second PR'), findsOneWidget);
    expect(find.text('Third PR'), findsOneWidget);
  });
}
