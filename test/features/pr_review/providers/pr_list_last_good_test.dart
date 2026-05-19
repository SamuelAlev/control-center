import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the stale-while-revalidate seeding behind the inbox / PR-list revisit:
/// the autoDispose data providers release their snapshot on navigate-away and
/// a revisit must render the previous visit's data INSTANTLY (from the
/// keepAlive last-good stores) while the fresh fetch/subscription lands.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = Repo(
    id: 'o/r',
    name: 'o/r',
    path: '/tmp/r',
    remoteOwner: 'o',
    remoteName: 'r',
    createdAt: DateTime(2020),
    updatedAt: DateTime(2020),
  );

  PullRequest pr(int number) => PullRequest(
    id: number,
    number: number,
    title: 'PR $number',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: DateTime(2026, 1, number),
    updatedAt: DateTime(2026, 1, number),
    repoFullName: 'o/r',
    htmlUrl: '',
  );

  ProviderContainer containerFor(
    _FakeOpenPrListRepository fake, {
    required ActiveWorkspaceIdNotifier Function() workspace,
  }) {
    return ProviderContainer(
      overrides: [
        openPrListRepositoryProvider.overrideWithValue(fake),
        activeWorkspaceIdProvider.overrideWith(workspace),
        currentUserLoginProvider.overrideWithValue('me'),
        reposForWorkspaceProvider(
          'w1',
        ).overrideWith((ref) => Stream.value([repo])),
        reposForWorkspaceProvider(
          'w2',
        ).overrideWith((ref) => Stream.value([repo])),
      ],
    );
  }

  group('prsByRepoProvider last-good seeding', () {
    test(
      'a revisit shows the previous snapshot instantly, before any new push',
      () async {
        final fake = _FakeOpenPrListRepository();
        final container = containerFor(fake, workspace: _FixedWorkspace.new);
        addTearDown(container.dispose);

        // First visit: the server-pushed snapshot becomes the live state.
        final first = container.listen(prsByRepoProvider, (_, _) {});
        fake.autoEmit = true;
        fake.latest = WorkspaceOpenPrs(
          authenticated: true,
          groups: [
            RepoOpenPrs(repoId: 'o/r', hasMore: false, prs: [pr(1)]),
          ],
        );
        final firstSub = fake.watchControllers.single;
        addTearDown(firstSub.close);
        firstSub.add(fake.latest);
        await _pump();
        expect(
          container
              .read(prsByRepoProvider)
              .value
              ?.repos
              .single
              .prs
              .single
              .number,
          1,
        );

        // Navigate away: the autoDispose provider releases the snapshot.
        first.close();
        // Force the dispose+rebuild a real revisit hits (Riverpod defers
        // autoDispose disposal past an immediate re-listen, which would make
        // the revisit assertions vacuous).
        container.invalidate(prsByRepoProvider);
        // Revisit with the push channel SILENT: any value shown now can only
        // be the seeded last-good snapshot.
        fake.autoEmit = false;
        final second = container.listen(prsByRepoProvider, (_, _) {});
        addTearDown(second.close);
        await _pump();

        final seeded = container.read(prsByRepoProvider);
        expect(
          seeded.hasValue,
          isTrue,
          reason: 'the revisit must render instantly, before a new push',
        );
        expect(seeded.value?.repos.single.prs.single.number, 1);
        expect(
          fake.watchCalls,
          greaterThan(1),
          reason: 'a live re-subscription still happens underneath',
        );

        // The fresh push then replaces the seed.
        fake.watchControllers.last.add(
          WorkspaceOpenPrs(
            authenticated: true,
            groups: [
              RepoOpenPrs(repoId: 'o/r', hasMore: false, prs: [pr(1), pr(2)]),
            ],
          ),
        );
        await _pump();
        expect(
          container.read(prsByRepoProvider).value?.repos.single.prs.length,
          2,
        );
      },
    );
  });

  group('reviewedByMePrKeysProvider last-good seeding', () {
    test(
      'a revisit serves the stale set instantly, then the fresh one',
      () async {
        final fake = _FakeOpenPrListRepository()..reviewedKeys = {'o/r#1'};
        final container = containerFor(fake, workspace: _FixedWorkspace.new);
        addTearDown(container.dispose);

        final first = container.listen(reviewedByMePrKeysProvider, (_, _) {});
        await _pump();
        expect(container.read(reviewedByMePrKeysProvider).value, {'o/r#1'});
        expect(fake.reviewedCalls, 1);
        first.close();
        // See the prsByRepo test: invalidate reproduces the dispose+rebuild of
        // a real revisit deterministically.
        container.invalidate(reviewedByMePrKeysProvider);

        // Revisit with the second fetch GATED: the visible value must be the
        // stale set until the gate opens.
        final gate = Completer<Set<String>>();
        fake.onReviewed = (_) => gate.future;
        final second = container.listen(reviewedByMePrKeysProvider, (_, _) {});
        addTearDown(second.close);
        await _pump();

        final seeded = container.read(reviewedByMePrKeysProvider);
        expect(seeded.hasValue, isTrue);
        expect(seeded.value, {'o/r#1'}, reason: 'stale set renders instantly');
        expect(
          fake.reviewedCalls,
          2,
          reason: 'the fresh search still runs underneath',
        );

        gate.complete({'o/r#2'});
        await _pump();
        expect(container.read(reviewedByMePrKeysProvider).value, {'o/r#2'});
      },
    );

    test('a workspace switch seeds nothing from another workspace', () async {
      final switchable = _SwitchableWorkspace();
      final fake = _FakeOpenPrListRepository()..reviewedKeys = {'o/r#1'};
      final container = containerFor(fake, workspace: () => switchable);
      addTearDown(container.dispose);

      final sub = container.listen(reviewedByMePrKeysProvider, (_, _) {});
      addTearDown(sub.close);
      await _pump();
      expect(container.read(reviewedByMePrKeysProvider).value, {'o/r#1'});

      // Switch to w2 with the fetch gated. Riverpod's seamless reload keeps
      // the PREVIOUS value visible while the new build is pending (the UI
      // strips value-on-reload where a flash would mislead, as the calendar
      // does) — but the store must hold NO w2 entry, so nothing can seed w2
      // from w1's data across visits.
      final gate = Completer<Set<String>>();
      fake.onReviewed = (_) => gate.future;
      switchable.switchTo('w2');
      await _pump();

      expect(
        container.read(lastGoodReviewedKeysProvider)['w2'],
        isNull,
        reason: 'w1\'s set must never be stamped or read as w2\'s',
      );

      gate.complete({'o/r#2'});
      await _pump();
      expect(container.read(reviewedByMePrKeysProvider).value, {'o/r#2'});
      expect(container.read(lastGoodReviewedKeysProvider)['w2'], {'o/r#2'});
    });
  });

  group('recentlyMergedPrsProvider last-good seeding', () {
    test(
      'a revisit serves the stale page instantly, then the fresh one',
      () async {
        final fake = _FakeOpenPrListRepository()
          ..closed = [
            RepoOpenPrs(repoId: 'o/r', hasMore: false, prs: [pr(7)]),
          ];
        final container = containerFor(fake, workspace: _FixedWorkspace.new);
        addTearDown(container.dispose);

        final first = container.listen(recentlyMergedPrsProvider, (_, _) {});
        await _pump();
        expect(
          container
              .read(recentlyMergedPrsProvider)
              .value
              ?.single
              .prs
              .single
              .number,
          7,
        );
        final afterFirst = fake.closedCalls;
        expect(afterFirst, greaterThanOrEqualTo(1));
        first.close();
        container.invalidate(recentlyMergedPrsProvider);

        final gate = Completer<List<RepoOpenPrs>>();
        fake.onClosed = (_, _) => gate.future;
        final second = container.listen(recentlyMergedPrsProvider, (_, _) {});
        addTearDown(second.close);
        await _pump();

        final seeded = container.read(recentlyMergedPrsProvider);
        expect(seeded.hasValue, isTrue);
        expect(
          seeded.value?.single.prs.single.number,
          7,
          reason: 'stale page renders instantly',
        );
        expect(
          fake.closedCalls,
          greaterThan(afterFirst),
          reason: 'the fresh search still runs underneath',
        );

        gate.complete([
          RepoOpenPrs(repoId: 'o/r', hasMore: false, prs: [pr(8)]),
        ]);
        await _pump();
        expect(
          container
              .read(recentlyMergedPrsProvider)
              .value
              ?.single
              .prs
              .single
              .number,
          8,
        );
      },
    );
  });
}

/// Lets the event queue turn a few times so provider builds, stream events,
/// and listener notifications all settle.
Future<void> _pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Pins the active workspace to `w1`.
class _FixedWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';
}

/// Active workspace a test can flip mid-session.
class _SwitchableWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';

  /// Switches the active workspace id.
  void switchTo(String id) => state = id;
}

/// Controllable [OpenPrListRepository]: subscriptions and searches are
/// scripted per test phase.
class _FakeOpenPrListRepository implements OpenPrListRepository {
  int watchCalls = 0;
  int reviewedCalls = 0;
  int closedCalls = 0;

  /// When true, each new subscription replays [latest] on the first
  /// microtask — mirroring the server's push-on-subscribe.
  bool autoEmit = true;
  WorkspaceOpenPrs latest = WorkspaceOpenPrs.empty;
  final List<StreamController<WorkspaceOpenPrs>> watchControllers = [];

  Set<String> reviewedKeys = const {};
  Future<Set<String>> Function(String workspaceId)? onReviewed;

  List<RepoOpenPrs> closed = const [];
  Future<List<RepoOpenPrs>> Function(String workspaceId, String login)?
  onClosed;

  @override
  Stream<WorkspaceOpenPrs> watchOpenForWorkspace(String workspaceId) {
    watchCalls++;
    final controller = StreamController<WorkspaceOpenPrs>();
    watchControllers.add(controller);
    if (autoEmit) {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(latest);
        }
      });
    }
    return controller.stream;
  }

  @override
  Future<Set<String>> reviewedByKeysForWorkspace(String workspaceId) {
    reviewedCalls++;
    final hook = onReviewed;
    return hook != null ? hook(workspaceId) : Future.value(reviewedKeys);
  }

  @override
  Future<List<RepoOpenPrs>> closedByAuthorForWorkspace(
    String workspaceId,
    String login,
  ) {
    closedCalls++;
    final hook = onClosed;
    return hook != null ? hook(workspaceId, login) : Future.value(closed);
  }

  @override
  Future<WorkspaceOpenPrs> listOpenForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<void> refreshOpenForWorkspace(String workspaceId) async {}

  @override
  Stream<int> watchNeedsMyReviewCount(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<List<({String repoId, PullRequest pr})>> reviewRequestedForWorkspace(
    String workspaceId,
  ) => throw UnimplementedError();
}
