import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_facets.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr({
  required int number,
  String title = 'A change',
  String body = '',
  String repoFullName = 'acme/web-app',
  String authorLogin = 'author',
  bool isDraft = false,
  PrState state = PrState.open,
  PrReviewDecision reviewDecision = PrReviewDecision.none,
  List<PrUser> requestedReviewers = const [],
  List<String> requestedTeamSlugs = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
  int additions = 0,
  int deletions = 0,
  int changedFiles = 0,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: body,
    state: state,
    isDraft: isDraft,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: createdAt ?? DateTime(2024, 6, 15),
    updatedAt: updatedAt ?? createdAt ?? DateTime(2024, 6, 15),
    repoFullName: repoFullName,
    htmlUrl: 'https://github.com/$repoFullName/pull/$number',
    requestedReviewers: requestedReviewers,
    requestedTeamSlugs: requestedTeamSlugs,
    assignees: const [],
    reviewDecision: reviewDecision,
    additions: additions,
    deletions: deletions,
    changedFiles: changedFiles,
  );
}

void main() {
  group('prPassesFilters', () {
    test('status facets OR together and derive from state/draft/decision', () {
      final draft = _pr(number: 1, isDraft: true);
      final approved = _pr(
        number: 2,
        reviewDecision: PrReviewDecision.approved,
      );
      final inReview = _pr(
        number: 3,
        reviewDecision: PrReviewDecision.reviewRequired,
      );

      const filters = PrListFilters(
        statuses: {PrStatusFilter.draft, PrStatusFilter.approved},
      );
      expect(
        applyFilters(
          [draft, approved, inReview],
          filters: filters,
          currentLogin: '',
        ),
        [draft, approved],
      );
    });

    test('draft PRs are also open facets', () {
      final draft = _pr(number: 1, isDraft: true);
      expect(prMatchesStatus(draft, PrStatusFilter.draft), isTrue);
      expect(prMatchesStatus(draft, PrStatusFilter.open), isFalse);
    });

    test('author filter is case-insensitive', () {
      final pr = _pr(number: 1, authorLogin: 'Alice');
      const filters = PrListFilters(authors: {'alice'});
      expect(prPassesFilters(pr, filters: filters, currentLogin: ''), isTrue);
    });

    test('reviewer filter matches requested reviewers', () {
      final pr = _pr(
        number: 1,
        requestedReviewers: const [PrUser(login: 'Bob', avatarUrl: '')],
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(reviewers: {'bob'}),
          currentLogin: '',
        ),
        isTrue,
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(reviewers: {'carol'}),
          currentLogin: '',
        ),
        isFalse,
      );
    });

    test('awaiting-review filter matches a pending team the viewer is on', () {
      final pr = _pr(
        number: 1,
        requestedTeamSlugs: const ['frontend-platform'],
      );
      const filters = PrListFilters(awaitingReview: true);
      expect(
        prPassesFilters(
          pr,
          filters: filters,
          currentLogin: 'me',
          viewerTeamsByOrg: {
            'acme': {'frontend-platform'},
          },
        ),
        isTrue,
      );
      expect(
        prPassesFilters(pr, filters: filters, currentLogin: 'me'),
        isFalse,
      );
    });

    test('content filter searches title and body', () {
      final pr = _pr(number: 1, title: 'Fix login', body: 'Closes #42');
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(content: 'LOGIN'),
          currentLogin: '',
        ),
        isTrue,
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(content: '#42'),
          currentLogin: '',
        ),
        isTrue,
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(content: 'logout'),
          currentLogin: '',
        ),
        isFalse,
      );
    });

    test('repo owner/name filters split repoFullName', () {
      final pr = _pr(number: 1, repoFullName: 'Acme/Web-App');
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(repoOwners: {'acme'}),
          currentLogin: '',
        ),
        isTrue,
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(repoNames: {'web-app'}),
          currentLogin: '',
        ),
        isTrue,
      );
      expect(
        prPassesFilters(
          pr,
          filters: const PrListFilters(repoNames: {'other'}),
          currentLogin: '',
        ),
        isFalse,
      );
    });

    test('date windows bound opened/updated recency', () {
      final now = DateTime.now();
      final fresh = _pr(
        number: 1,
        createdAt: now.subtract(const Duration(hours: 12)),
      );
      final stale = _pr(
        number: 2,
        createdAt: now.subtract(const Duration(days: 10)),
      );
      const filters = PrListFilters(openedWithin: PrDateWindow.day);
      expect(applyFilters([fresh, stale], filters: filters, currentLogin: ''), [
        fresh,
      ]);
    });

    test('quick to review requires known small metrics', () {
      final quick = _pr(
        number: 1,
        additions: 20,
        deletions: 5,
        changedFiles: 2,
      );
      final big = _pr(
        number: 2,
        additions: 400,
        deletions: 100,
        changedFiles: 12,
      );
      final unknown = _pr(number: 3);
      const filters = PrListFilters(quickToReview: true);
      expect(
        applyFilters([quick, big, unknown], filters: filters, currentLogin: ''),
        [quick],
      );
    });

    test('includeDrafts=false drops drafts even without filters', () {
      final draft = _pr(number: 1, isDraft: true);
      final open = _pr(number: 2);
      expect(
        applyFilters(
          [draft, open],
          filters: const PrListFilters(),
          currentLogin: '',
          includeDrafts: false,
        ),
        [open],
      );
    });

    test('categories AND together', () {
      final match = _pr(number: 1, authorLogin: 'alice', title: 'Fix login');
      final wrongAuthor = _pr(number: 2, title: 'Fix login');
      final wrongTitle = _pr(number: 3, authorLogin: 'alice');
      const filters = PrListFilters(authors: {'alice'}, content: 'login');
      expect(
        applyFilters(
          [match, wrongAuthor, wrongTitle],
          filters: filters,
          currentLogin: '',
        ),
        [match],
      );
    });
  });

  group('PrListFiltersNotifier count/isActive', () {
    test('count sums per-value criteria', () {
      const filters = PrListFilters(
        statuses: {PrStatusFilter.draft, PrStatusFilter.open},
        authors: {'alice'},
        content: 'x',
        openedWithin: PrDateWindow.week,
        quickToReview: true,
      );
      expect(filters.count, 6);
      expect(filters.isActive, isTrue);
      expect(const PrListFilters().isActive, isFalse);
    });
  });

  group('facet counts', () {
    test('a category ignores its own selections but honors the others', () {
      final prs = [
        _pr(number: 1, authorLogin: 'alice', isDraft: true),
        _pr(number: 2, authorLogin: 'alice'),
        _pr(number: 3, authorLogin: 'bob'),
      ];
      // Status draft selected; author counts must reflect the OTHER category
      // (statuses) — alice keeps only her draft PR, bob none.
      const filters = PrListFilters(statuses: {PrStatusFilter.draft});
      final population = facetPopulation(
        prs,
        category: PrFilterCategory.author,
        filters: filters,
        currentLogin: '',
        includeDrafts: true,
      );
      final options = authorFacetOptions(
        prs,
        population,
        filters: filters,
        currentLogin: '',
      );
      final byLogin = {for (final o in options) o.value: o.count};
      expect(byLogin['alice'], 1);
      expect(byLogin['bob'], 0);

      // The status category itself counts against everything (its own
      // selection cleared): open counts PRs 2+3.
      final statusPopulation = facetPopulation(
        prs,
        category: PrFilterCategory.status,
        filters: filters,
        currentLogin: '',
        includeDrafts: true,
      );
      final statusOptions = statusFacetOptions(
        statusPopulation,
        filters: filters,
      );
      final byStatus = {for (final o in statusOptions) o.value: o.count};
      expect(byStatus[PrStatusFilter.draft], 1);
      expect(byStatus[PrStatusFilter.open], 2);
    });

    test('quickToReviewCount counts small known diffs', () {
      final prs = [
        _pr(number: 1, additions: 10, deletions: 2, changedFiles: 1),
        _pr(number: 2, additions: 900, deletions: 0, changedFiles: 9),
        _pr(number: 3),
      ];
      expect(
        quickToReviewCount(
          prs,
          filters: const PrListFilters(),
          currentLogin: '',
          includeDrafts: true,
        ),
        1,
      );
    });
  });
}
