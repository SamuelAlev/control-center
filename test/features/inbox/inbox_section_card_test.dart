import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_section_card.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

Repo _repo({String id = 'r1', String owner = 'o', String name = 'r1'}) => Repo(
  id: id,
  name: name,
  path: '/tmp/$name',
  githubOwner: owner,
  githubRepoName: name,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PrInboxItem _item(
  int number, {
  String title = 'PR',
  String author = 'alice',
  int additions = 0,
  int deletions = 0,
  DateTime? updatedAt,
  Repo? repo,
}) => PrInboxItem(
  repo: repo ?? _repo(),
  pr: PullRequest(
    id: number,
    number: number,
    title: '$title $number',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: PrUser(login: author, avatarUrl: ''),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 2),
    repoFullName:
        '${(repo ?? _repo()).githubOwner}/${(repo ?? _repo()).githubRepoName}',
    htmlUrl: '',
    additions: additions,
    deletions: deletions,
  ),
);

void main() {
  testWidgets('renders rows with title, meta and diff churn', (tester) async {
    await tester.pumpWidget(
      testWrap(
        InboxSectionCard(
          section: PrInboxSection.needsYourReview,
          items: [_item(1, additions: 42, deletions: 10)],
        ),
      ),
    );

    expect(find.text('Needs your review'), findsOneWidget);
    expect(find.text('PR 1'), findsOneWidget);
    expect(find.text('alice · o/r1 #1'), findsOneWidget);
    expect(find.text('+42'), findsOneWidget);
    expect(find.text('−10'), findsOneWidget);
  });

  testWidgets('collapsing via the header hides the rows', (tester) async {
    await tester.pumpWidget(
      testWrap(
        InboxSectionCard(section: PrInboxSection.drafts, items: [_item(7)]),
      ),
    );
    expect(find.text('PR 7'), findsOneWidget);

    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();

    expect(find.text('PR 7'), findsNothing);
  });

  testWidgets('tapping the changes column re-sorts the rows', (tester) async {
    await tester.pumpWidget(
      testWrap(
        InboxSectionCard(
          section: PrInboxSection.waitingForReviewers,
          items: [
            _item(1, additions: 5, updatedAt: DateTime(2026, 1, 10)),
            _item(2, additions: 100, updatedAt: DateTime(2026, 1, 1)),
          ],
        ),
      ),
    );

    // Default: most recently updated first.
    var y1 = tester.getTopLeft(find.text('PR 1')).dy;
    var y2 = tester.getTopLeft(find.text('PR 2')).dy;
    expect(y1 < y2, isTrue);

    await tester.tap(find.text('Changes'));
    await tester.pumpAndSettle();

    // Largest churn first.
    y1 = tester.getTopLeft(find.text('PR 1')).dy;
    y2 = tester.getTopLeft(find.text('PR 2')).dy;
    expect(y2 < y1, isTrue);
  });

  testWidgets('author grouping renders subgroup headers within the section', (
    tester,
  ) async {
    // Seed the persisted display prefs so the shared Grouping is `author`.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            AppPreferences.inMemory({prListGroupingKey: 'author'}),
          ),
        ],
        child: testWrap(
          InboxSectionCard(
            section: PrInboxSection.needsYourReview,
            items: [
              _item(1, author: 'zoe'),
              _item(2, author: 'alice'),
            ],
          ),
        ),
      ),
    );

    // One subheader per author, alphabetical (no operator login in tests).
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('zoe'), findsOneWidget);
    final aliceY = tester.getTopLeft(find.text('alice')).dy;
    final zoeY = tester.getTopLeft(find.text('zoe')).dy;
    expect(aliceY < zoeY, isTrue);
  });

  test('sortInboxItems orders by title, churn and recency', () {
    final items = [
      _item(1, title: 'Beta', additions: 5, updatedAt: DateTime(2026, 1, 10)),
      _item(2, title: 'Alpha', additions: 100, updatedAt: DateTime(2026, 1, 1)),
    ];

    List<int> numbers(InboxSort sort) =>
        sortInboxItems(items, sort).map((i) => i.pr.number).toList();

    expect(
      numbers(const InboxSort(column: InboxSortColumn.title, ascending: true)),
      [2, 1],
    );
    expect(
      numbers(
        const InboxSort(column: InboxSortColumn.changes, ascending: false),
      ),
      [2, 1],
    );
    expect(
      numbers(
        const InboxSort(column: InboxSortColumn.updated, ascending: false),
      ),
      [1, 2],
    );
  });
}
