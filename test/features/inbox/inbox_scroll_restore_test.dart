import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/presentation/inbox_screen.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';

Repo _repo() => Repo(
  id: 'r1',
  name: 'r1',
  path: '/tmp/r1',
  remoteOwner: 'o',
  remoteName: 'r1',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PrInboxItem _item(int number) => PrInboxItem(
  repo: _repo(),
  pr: PullRequest(
    id: number,
    number: number,
    title: 'PR $number',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'alice', avatarUrl: ''),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    repoFullName: 'o/r1',
    htmlUrl: '',
  ),
);

class _StubPrsByRepo extends PrsByRepoNotifier {
  @override
  Future<PrsByRepoState> build() async => const PrsByRepoState(
    repos: [],
    hasMore: {},
    nextPage: {},
    loadingMore: {},
  );
}

class _StubMerged extends RecentlyMergedPrsNotifier {
  @override
  Future<List<RepoPullRequests>> build() async => const [];
}

class _StubReviewed extends ReviewedByMePrKeysNotifier {
  @override
  Future<Set<String>> build() async => const {};
}

/// The inbox hero's shader animates forever, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _inbox = '/inbox';
const _detail = '/detail';

/// Opening a pull request REPLACES the inbox route (the detail is a sibling
/// under the shell), so the route's `PageStorage` bucket is gone on the way
/// back; the offset must come back from the session-scoped store instead.
void main() {
  testWidgets('going to a sibling route and back keeps the inbox offset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final data = PrInboxData(
      sections: {
        for (final s in PrInboxSection.values) s: const <PrInboxItem>[],
        PrInboxSection.needsYourReview: [
          for (var i = 1; i <= 40; i++) _item(i),
        ],
      },
    );
    final router = GoRouter(
      initialLocation: _inbox,
      routes: [
        GoRoute(
          path: _inbox,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const InboxScreen()),
        ),
        GoRoute(
          path: _detail,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const SizedBox()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          inboxDataProvider.overrideWithValue(AsyncData(data)),
          prsByRepoProvider.overrideWith(_StubPrsByRepo.new),
          recentlyMergedPrsProvider.overrideWith(_StubMerged.new),
          reviewedByMePrKeysProvider.overrideWith(_StubReviewed.new),
          reposForWorkspaceProvider(
            kTestWorkspaceId,
          ).overrideWith((ref) => Stream.value([_repo()])),
          inboxAttentionSourcesProvider.overrideWithValue(const []),
        ],
        child: testRouterWrap(router),
      ),
    );
    await _settle(tester);

    ScrollPosition position() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const PageStorageKey('inbox-sections')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    expect(position().maxScrollExtent, greaterThan(600));
    position().jumpTo(600);
    await tester.pump();

    router.go(_detail);
    await _settle(tester);
    expect(find.byType(InboxScreen), findsNothing);

    router.go(_inbox);
    await _settle(tester);
    expect(position().pixels, 600);
  });
}
