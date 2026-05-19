import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_command_source.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records [setActive] calls and avoids the real notifier's provider
/// dependencies (workspace id, prefs, repo list).
class _FakeActiveRepoIdNotifier extends ActiveRepoIdNotifier {
  final List<String> setActiveCalls = [];

  @override
  String? build() => null;

  @override
  Future<void> setActive(String repoId) async {
    setActiveCalls.add(repoId);
  }
}

/// Pins the active workspace id to a fixed value so [PrCommandSource] builds
/// workspace-prefixed routes (`/workspaces/w1/…`) without the real notifier's
/// prefs/route dependencies.
class _FakeActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';
}

/// Wraps [child] in a [ProviderScope] that overrides the active-repo notifier
/// with [fake] (and pins the active workspace id) so
/// [PrCommandSource.buildItems] can resolve them in tests.
Widget _scope(_FakeActiveRepoIdNotifier fake, Widget child) {
  return ProviderScope(
    overrides: [
      activeRepoIdProvider.overrideWith(() => fake),
      activeWorkspaceIdProvider.overrideWith(
        _FakeActiveWorkspaceIdNotifier.new,
      ),
    ],
    child: child,
  );
}

/// Creates a minimal PullRequest for testing.
PullRequest _pr({
  int id = 1,
  int number = 42,
  String title = 'Add feature',
  String repoFullName = 'org/repo',
  String authorLogin = 'dev',
  PrState state = PrState.open,
  bool isDraft = false,
}) {
  final now = DateTime(2024);
  return PullRequest(
    id: id,
    number: number,
    title: title,
    body: 'Body of PR #$number',
    state: state,
    isDraft: isDraft,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: now,
    updatedAt: now,
    repoFullName: repoFullName,
    htmlUrl: 'https://github.com/$repoFullName/pull/$number',
  );
}

/// Creates a minimal Repo for testing.
Repo _repo({required String owner, required String name}) {
  final now = DateTime(2024);
  return Repo(
    id: '$owner/$name',
    name: '$owner/$name',
    path: '/tmp/$owner/$name',
    githubOwner: owner,
    githubRepoName: name,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PrCommandSource', () {
    test('provides correct metadata', () {
      final source = PrCommandSource();
      expect(source.id, 'pull-requests');
      expect(source.category, 'Pull requests');
      expect(source.isDynamic, isTrue);
    });

    testWidgets('returns static item when no PRs loaded', (tester) async {
      final completer = Completer<List<CommandItem>>();
      final fake = _FakeActiveRepoIdNotifier();

      await tester.pumpWidget(
        _scope(
          fake,
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Consumer(
                    builder: (context, ref, _) {
                      final source = PrCommandSource();
                      source.testState = const PrsByRepoState(
                        repos: [],
                        hasMore: {},
                        nextPage: {},
                        loadingMore: {},
                      );
                      final items = source.buildItems(context, ref);
                      completer.complete(items);
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final items = await completer.future;
      expect(items, hasLength(1));
      expect(items.first.id, 'pr-list');
    });

    testWidgets('maps PRs to CommandItems correctly', (tester) async {
      final completer = Completer<List<CommandItem>>();
      final fake = _FakeActiveRepoIdNotifier();
      final prs = [
        _pr(id: 1, number: 42, title: 'Fix login', repoFullName: 'org/repo'),
        _pr(id: 2, number: 99, title: 'Add signup', repoFullName: 'org/repo'),
      ];
      final state = PrsByRepoState(
        repos: [
          RepoPullRequests(
            repo: _repo(owner: 'org', name: 'repo'),
            prs: prs,
          ),
        ],
        hasMore: const {},
        nextPage: const {},
        loadingMore: const {},
      );

      await tester.pumpWidget(
        _scope(
          fake,
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Consumer(
                    builder: (context, ref, _) {
                      final source = PrCommandSource();
                      source.testState = state;
                      final items = source.buildItems(context, ref);
                      completer.complete(items);
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final items = await completer.future;
      expect(items, hasLength(3));

      expect(items[0].id, 'pr-list');

      expect(items[1].id, 'pr-42');
      expect(items[1].label, '#42 Fix login');
      expect(items[1].description, 'org/repo · dev');

      expect(items[2].id, 'pr-99');
      expect(items[2].label, '#99 Add signup');
      expect(items[2].description, 'org/repo · dev');
    });

    testWidgets('handles empty PR list gracefully', (tester) async {
      final completer = Completer<List<CommandItem>>();
      final fake = _FakeActiveRepoIdNotifier();
      final state = PrsByRepoState(
        repos: [
          RepoPullRequests(
            repo: _repo(owner: 'org', name: 'repo'),
            prs: const [],
          ),
        ],
        hasMore: const {},
        nextPage: const {},
        loadingMore: const {},
      );

      await tester.pumpWidget(
        _scope(
          fake,
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Consumer(
                    builder: (context, ref, _) {
                      final source = PrCommandSource();
                      source.testState = state;
                      final items = source.buildItems(context, ref);
                      completer.complete(items);
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final items = await completer.future;
      expect(items, hasLength(1));
      expect(items.first.id, 'pr-list');
    });

    testWidgets(
      'onExecute switches the active repo to the PR\'s repo then navigates',
      (tester) async {
        final fake = _FakeActiveRepoIdNotifier();
        // The PR belongs to org/app-server while the active repo elsewhere may
        // be a different repo — the palette must switch to the PR's repo.
        final pr = _pr(
          id: 1,
          number: 42,
          title: 'Fix login',
          repoFullName: 'org/app-server',
        );
        final state = PrsByRepoState(
          repos: [
            RepoPullRequests(
              repo: _repo(owner: 'org', name: 'app-server'),
              prs: [pr],
            ),
          ],
          hasMore: const {},
          nextPage: const {},
          loadingMore: const {},
        );

        late final VoidCallback onExecute;

        await tester.pumpWidget(
          _scope(
            fake,
            MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => Consumer(
                      builder: (context, ref, _) {
                        final source = PrCommandSource();
                        source.testState = state;
                        final items = source.buildItems(context, ref);
                        onExecute = items[1].onExecute;
                        return const SizedBox();
                      },
                    ),
                  ),
                  GoRoute(
                    path: pullRequestDetailRoute('w1', 'org/app-server', 42),
                    builder: (_, _) => const Scaffold(body: Text('PR Detail')),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        onExecute();
        await tester.pumpAndSettle();

        // Active repo switched to the PR's repo (id == 'org/app-server')...
        expect(fake.setActiveCalls, ['org/app-server']);
        // ...and navigation reached the detail route.
        expect(find.text('PR Detail'), findsOneWidget);
      },
    );

    testWidgets('static item navigates to PR list', (tester) async {
      late final VoidCallback onExecute;
      final fake = _FakeActiveRepoIdNotifier();

      await tester.pumpWidget(
        _scope(
          fake,
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Consumer(
                    builder: (context, ref, _) {
                      final source = PrCommandSource();
                      source.testState = const PrsByRepoState(
                        repos: [],
                        hasMore: {},
                        nextPage: {},
                        loadingMore: {},
                      );
                      final items = source.buildItems(context, ref);
                      onExecute = items.first.onExecute;
                      return const SizedBox();
                    },
                  ),
                ),
                GoRoute(
                  path: pullRequestsRoute('w1'),
                  builder: (_, _) => const Scaffold(body: Text('PR List')),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      onExecute();
      await tester.pumpAndSettle();
      expect(find.text('PR List'), findsOneWidget);
      // The static list entry must not touch the active repo.
      expect(fake.setActiveCalls, isEmpty);
    });
  });

  group('prCommandSourceProvider', () {
    test('provider returns PrCommandSource instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final source = container.read(prCommandSourceProvider);
      expect(source, isA<CommandSource>());
      expect(source.id, 'pull-requests');
    });
  });
}
