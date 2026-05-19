import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Repo _repo(String id, String owner, String name) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/tmp/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PullRequest _pr(
  int number, {
  String? author,
  String repoFullName = 'acme/web-app',
  String title = 'A change',
  bool isDraft = false,
  List<PrUser> requestedReviewers = const [],
}) => PullRequest(
  id: number,
  number: number,
  title: '$title $number',
  body: '',
  state: PrState.open,
  isDraft: isDraft,
  author: author == null ? null : PrUser(login: author, avatarUrl: ''),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
  repoFullName: repoFullName,
  htmlUrl: '',
  requestedReviewers: requestedReviewers,
);

void main() {
  group('applyInboxFilters', () {
    final byRepo = [
      RepoPullRequests(
        repo: _repo('a', 'acme', 'web-app'),
        prs: [
          _pr(1, author: 'Ada'),
          _pr(2, author: 'grace', isDraft: true),
          _pr(
            3,
            author: 'grace',
            requestedReviewers: const [PrUser(login: 'Ada', avatarUrl: '')],
          ),
        ],
      ),
      RepoPullRequests(
        repo: _repo('b', 'umbrella', 'test-web-app'),
        prs: [_pr(4, author: 'ada', repoFullName: 'umbrella/test-web-app')],
      ),
    ];

    List<int> numbers(List<RepoPullRequests> groups) => [
      for (final g in groups) ...g.prs.map((p) => p.number),
    ];

    test('narrows by author case-insensitively, keeping group shape', () {
      final result = applyInboxFilters(
        byRepo,
        filters: const PrListFilters(authors: {'ada'}),
        viewerLogins: {ForgeHost.github: ''},
        includeDrafts: true,
      );
      expect(numbers(result), [1, 4]);
      expect(result, hasLength(2));
    });

    test('narrows by repo owner and name from repoFullName', () {
      expect(
        numbers(
          applyInboxFilters(
            byRepo,
            filters: const PrListFilters(repoOwners: {'umbrella'}),
            viewerLogins: {ForgeHost.github: ''},
            includeDrafts: true,
          ),
        ),
        [4],
      );
      expect(
        numbers(
          applyInboxFilters(
            byRepo,
            filters: const PrListFilters(repoNames: {'web-app'}),
            viewerLogins: {ForgeHost.github: ''},
            includeDrafts: true,
          ),
        ),
        [1, 2, 3],
      );
    });

    test('narrows by status facet and requested reviewer', () {
      expect(
        numbers(
          applyInboxFilters(
            byRepo,
            filters: const PrListFilters(statuses: {PrStatusFilter.draft}),
            viewerLogins: {ForgeHost.github: ''},
            includeDrafts: true,
          ),
        ),
        [2],
      );
      expect(
        numbers(
          applyInboxFilters(
            byRepo,
            filters: const PrListFilters(reviewers: {'ada'}),
            viewerLogins: {ForgeHost.github: ''},
            includeDrafts: true,
          ),
        ),
        [3],
      );
    });

    test('includeDrafts=false drops drafts even with no filters', () {
      final result = applyInboxFilters(
        byRepo,
        filters: const PrListFilters(),
        viewerLogins: {ForgeHost.github: ''},
        includeDrafts: false,
      );
      expect(numbers(result), [1, 3, 4]);
    });
  });

  group('groupInboxItems', () {
    PrInboxItem item(
      int number, {
      required String repoId,
      required String owner,
      required String name,
      String? author,
    }) => PrInboxItem(
      repo: _repo(repoId, owner, name),
      pr: _pr(number, author: author, repoFullName: '$owner/$name'),
    );

    final items = [
      item(1, repoId: 'b', owner: 'umbrella', name: 'test-web-app', author: 'zoe'),
      item(2, repoId: 'a', owner: 'acme', name: 'web-app', author: 'me'),
      item(3, repoId: 'a', owner: 'acme', name: 'web-app', author: 'alice'),
    ];

    test('none, status and repository stay flat (one unlabeled group)', () {
      // Repository deliberately renders flat in the inbox — it is one stream
      // per lifecycle section, never separated by repo.
      for (final grouping in [
        PrListGrouping.none,
        PrListGrouping.status,
        PrListGrouping.repository,
      ]) {
        final groups = groupInboxItems(
          items,
          grouping: grouping,
          viewerLogins: {ForgeHost.github: 'me'},
        );
        expect(groups, hasLength(1));
        expect(groups.single.label, isNull);
        expect(groups.single.items.map((i) => i.pr.number), [1, 2, 3]);
      }
      expect(
        groupInboxItems(
          const [],
          grouping: PrListGrouping.none,
          viewerLogins: {ForgeHost.github: ''},
        ),
        isEmpty,
      );
    });

    test('author grouping puts the operator first, then alphabetical', () {
      final groups = groupInboxItems(
        items,
        grouping: PrListGrouping.author,
        viewerLogins: {ForgeHost.github: 'me'},
      );
      expect(groups.map((g) => g.label), ['me', 'alice', 'zoe']);
      expect(groups.first.user?.login, 'me');
    });
  });

  group('inboxSortProvider default', () {
    test('derives from the shared Ordering and resets on change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var sort = container.read(inboxSortProvider);
      expect(sort.column, InboxSortColumn.updated);
      expect(sort.ascending, isFalse);

      // A column click overrides the default…
      container.read(inboxSortProvider.notifier).toggle(InboxSortColumn.title);
      expect(container.read(inboxSortProvider).column, InboxSortColumn.title);

      // …until the shared Ordering changes, which rebuilds the default.
      container.read(prListSortProvider.notifier).set(PrListSort.largest);
      sort = container.read(inboxSortProvider);
      expect(sort.column, InboxSortColumn.changes);
      expect(sort.ascending, isFalse);

      container.read(prListSortProvider.notifier).set(PrListSort.oldest);
      sort = container.read(inboxSortProvider);
      expect(sort.column, InboxSortColumn.updated);
      expect(sort.ascending, isTrue);
    });
  });
}
