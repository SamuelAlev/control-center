import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show JsonRpcNotification;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient, ServerBuild;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the PR queue's paging past the server's first page: totals ride the
/// snapshot, `loadMore` appends REST pages, and a pushed snapshot (which only
/// ever carries the first page) never truncates what was already loaded.
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
    createdAt: DateTime(2026, 1, 1, 0, number),
    updatedAt: DateTime(2026, 1, 1, 0, number),
    repoFullName: 'o/r',
    htmlUrl: '',
  );

  WorkspaceOpenPrs snapshot(List<int> numbers, {int total = 5}) =>
      WorkspaceOpenPrs(
        authenticated: true,
        groups: [
          RepoOpenPrs(
            repoId: 'o/r',
            hasMore: total > numbers.length,
            totalCount: total,
            prs: [for (final n in numbers) pr(n)],
          ),
        ],
      );

  late StreamController<WorkspaceOpenPrs> pushes;
  late _FakeRpc rpc;
  late ProviderContainer container;

  setUp(() async {
    pushes = StreamController<WorkspaceOpenPrs>.broadcast();
    rpc = _FakeRpc();
    container = ProviderContainer(
      overrides: [
        openPrListRepositoryProvider.overrideWithValue(
          _FakeOpenPrListRepository(pushes.stream),
        ),
        rpcClientProvider.overrideWithValue(rpc),
        activeWorkspaceIdProvider.overrideWith(_FixedWorkspace.new),
        currentUserIdProvider.overrideWith((ref) => 'user-1'),
        reposForWorkspaceProvider(
          'w1',
        ).overrideWith((ref) => Stream.value([repo])),
      ],
    );
    container.listen(prsByRepoProvider, (_, _) {});
    await _pump();
  });

  tearDown(() async {
    container.dispose();
    await pushes.close();
  });

  List<int> numbers() => [
    for (final p in container.read(prsByRepoProvider).value!.repos.single.prs)
      p.number,
  ]..sort();

  PrsByRepoState state() => container.read(prsByRepoProvider).value!;

  test('the forge total rides the snapshot', () async {
    pushes.add(snapshot([5, 4], total: 5));
    await _pump();

    expect(state().totalCount, {'o/r': 5});
    expect(state().paging['o/r'], (
      hasMore: true,
      loading: false,
      failed: false,
    ));
  });

  test('loadMore appends the next page and advances', () async {
    pushes.add(snapshot([5, 4], total: 5));
    await _pump();
    rpc.pages[2] = (prs: [3, 2], hasMore: true);
    rpc.pages[3] = (prs: [1], hasMore: false);

    await container.read(prsByRepoProvider.notifier).loadMore('o/r');
    expect(numbers(), [2, 3, 4, 5]);
    expect(state().nextPage['o/r'], 3);

    await container.read(prsByRepoProvider.notifier).loadMore('o/r');
    expect(numbers(), [1, 2, 3, 4, 5]);
    expect(state().hasMore['o/r'], isFalse);
    expect(state().paging, isEmpty);
    expect(rpc.requested, [2, 3]);
  });

  test('a push that leaves the first page alone keeps loaded pages', () async {
    pushes.add(snapshot([5, 4], total: 5));
    await _pump();
    rpc.pages[2] = (prs: [3, 2], hasMore: true);
    await container.read(prsByRepoProvider.notifier).loadMore('o/r');

    pushes.add(snapshot([5, 4], total: 5));
    await _pump();

    expect(numbers(), [2, 3, 4, 5]);
    expect(state().nextPage['o/r'], 3);
    expect(rpc.requested, [2], reason: 'nothing shifted, nothing re-read');
  });

  test(
    'a push that shifts the first page re-reads loaded pages in one swap',
    () async {
      pushes.add(snapshot([5, 4], total: 5));
      await _pump();
      rpc.pages[2] = (prs: [3, 2], hasMore: true);
      await container.read(prsByRepoProvider.notifier).loadMore('o/r');

      // PR 6 opens: 5 and 6 are the first page now, 4 slides onto page 2.
      final reread = Completer<void>();
      rpc.pages[2] = (prs: [4, 3], hasMore: true);
      rpc.onCall = reread.complete;
      pushes.add(snapshot([6, 5], total: 6));
      await _pump();
      await reread.future;
      await _pump();

      expect(numbers(), [3, 4, 5, 6]);
      expect(state().nextPage['o/r'], 3);
      expect(state().extraPrs['o/r']!.map((p) => p.number), [4, 3]);
    },
  );

  test('a failed page is recorded and retried only on request', () async {
    pushes.add(snapshot([5, 4], total: 5));
    await _pump();

    await container.read(prsByRepoProvider.notifier).loadMore('o/r');
    expect(state().paging['o/r']?.failed, isTrue);
    expect(numbers(), [4, 5]);

    rpc.pages[2] = (prs: [3, 2, 1], hasMore: false);
    await container.read(prsByRepoProvider.notifier).loadMore('o/r');
    expect(numbers(), [1, 2, 3, 4, 5]);
    expect(state().loadMoreFailed['o/r'], isFalse);
  });
}

Future<void> _pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FixedWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';
}

/// Serves `pr.openPageForRepo` from [pages]; an unset page throws.
class _FakeRpc implements RemoteRpcClient {
  final Map<int, ({List<int> prs, bool hasMore})> pages = {};
  final List<int> requested = [];
  void Function()? onCall;

  @override
  Stream<JsonRpcNotification> get notifications => const Stream.empty();

  @override
  ServerBuild? get serverBuild => null;

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async {
    expect(op, 'pr.openPageForRepo');
    final page = args['page'] as int;
    requested.add(page);
    final hook = onCall;
    onCall = null;
    final result = pages[page];
    if (result == null) {
      throw StateError('page $page unavailable');
    }
    scheduleMicrotask(() => hook?.call());
    return {
      'has_more': result.hasMore,
      'prs': [
        for (final n in result.prs)
          {
            'id': n,
            'number': n,
            'title': 'PR $n',
            'state': 'open',
            'repo_full_name': 'o/r',
            'created_at': DateTime(2026, 1, 1, 0, n).toIso8601String(),
            'updated_at': DateTime(2026, 1, 1, 0, n).toIso8601String(),
          },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRpc.${invocation.memberName}');
}

class _FakeOpenPrListRepository implements OpenPrListRepository {
  _FakeOpenPrListRepository(this._pushes);

  final Stream<WorkspaceOpenPrs> _pushes;

  @override
  Stream<WorkspaceOpenPrs> watchOpenForWorkspace(String workspaceId) => _pushes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRepo.${invocation.memberName}');
}
