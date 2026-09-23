import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';
import '../../../helpers/fake_rpc_client.dart';

PullRequest _pr({
  int number = 412,
  String repoFullName = 'helix/evalkit',
  String externalId = 'PR_412',
  String headRef = 'conv/6b2256bb',
  PrState state = PrState.open,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Cap eval-run token budget per model family',
    body: '',
    state: state,
    isDraft: false,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: repoFullName,
    htmlUrl: 'https://example.invalid/$repoFullName/pull/$number',
    externalId: externalId,
    headRef: headRef,
  );
}

ReviewSpaceAssociation _assoc({
  String spaceId = 'eval-review-space',
  int prNumber = 412,
  String repoFullName = 'helix/evalkit',
  String prExternalId = '4120001',
}) {
  final now = DateTime.utc(2026);
  return ReviewSpaceAssociation(
    id: 'assoc-1',
    spaceId: spaceId,
    workspaceId: kTestWorkspaceId,
    prExternalId: prExternalId,
    prNumber: prNumber,
    repoFullName: repoFullName,
    status: ReviewSpaceStatus.inProgress,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prSpaceProvider', () {
    test(
      'demo looks up the seeded space by repo + number, not forge id',
      () async {
        final calls = <String>[];
        final host = FakeRpcHost()
          ..onCall = (op, _) {
            calls.add(op);
            return const <String, dynamic>{};
          };
        final container = ProviderContainer(
          overrides: [
            isDemoServerProvider.overrideWithValue(true),
            activeWorkspaceIdOverride(),
            reviewSpaceRepositoryProvider.overrideWithValue(
              _FakeReviewSpaces([_assoc()]),
            ),
            rpcClientProvider.overrideWithValue(host.client()),
          ],
        );
        addTearDown(container.dispose);

        // Fixture node id (`PR_412`) ≠ seeder key (`4120001`). Matching on
        // externalId would miss and the chat tab would stay empty.
        final spaceId = await container.read(prSpaceProvider(_pr()).future);
        expect(spaceId, 'eval-review-space');
        expect(calls, isEmpty, reason: 'a demo must not call pr.ensureSpace');
      },
    );

    test('demo with no association is PrSpaceUnavailable', () async {
      final pr = _pr();
      final container = ProviderContainer(
        overrides: [
          isDemoServerProvider.overrideWithValue(true),
          activeWorkspaceIdOverride(),
          reviewSpaceRepositoryProvider.overrideWithValue(
            const _FakeReviewSpaces([]),
          ),
          rpcClientProvider.overrideWithValue(fakeRpcClient()),
        ],
      );
      addTearDown(container.dispose);

      Object? error;
      final sub = container.listen(prSpaceProvider(pr), (_, next) {
        if (next.hasError) {
          error = next.error;
        }
      }, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      expect(error, isA<PrSpaceUnavailable>());
    });

    test('a real host still calls pr.ensureSpace', () async {
      final calls = <String>[];
      final host = FakeRpcHost()
        ..onCall = (op, args) {
          calls.add(op);
          expect(args['pr_number'], 412);
          return {'space_id': 'minted-space'};
        };
      final container = ProviderContainer(
        overrides: [
          isDemoServerProvider.overrideWithValue(false),
          activeWorkspaceIdOverride(),
          reviewSpaceRepositoryProvider.overrideWithValue(
            _FakeReviewSpaces([_assoc()]),
          ),
          rpcClientProvider.overrideWithValue(host.client()),
        ],
      );
      addTearDown(container.dispose);

      final spaceId = await container.read(prSpaceProvider(_pr()).future);
      expect(spaceId, 'minted-space');
      expect(calls, ['pr.ensureSpace']);
    });
  });

  group('pullRequestsForSpaceRow', () {
    test('a branch-matched PR with no association is shown once', () {
      final pr = _pr(number: 33982, repoFullName: 'control-center/control-center');
      final shown = pullRequestsForSpaceRow(
        linked: const [],
        branchMatched: [pr],
      );
      expect(shown, [pr]);
      expect(shown.single.isOpen, isTrue);
    });

    test('the same PR from an association and a branch match counts once', () {
      final linked = _pr();
      final shown = pullRequestsForSpaceRow(
        linked: [linked],
        branchMatched: [_pr()],
      );
      expect(shown, [linked]);
    });

    test('a second repo\'s branch PR sits beside the linked one', () {
      final linked = _pr();
      final branch = _pr(number: 33982, repoFullName: 'control-center/control-center');
      final shown = pullRequestsForSpaceRow(
        linked: [linked],
        branchMatched: [branch],
      );
      expect(shown.map((pr) => pr.number), [412, 33982]);
    });
  });

  group('pullRequestForCheckedOutBranch', () {
    const repoId = 'repo-1';
    const repo = 'control-center/control-center';

    PullRequest? lookup({
      String branch = 'conv/6b2256bb',
      List<SpaceBranchPr> branchMatched = const [],
      List<PullRequest> linked = const [],
    }) {
      return pullRequestForCheckedOutBranch(
        branch: branch,
        repoId: repoId,
        repoFullName: repo,
        branchMatched: branchMatched,
        linked: linked,
      );
    }

    test('a branch match for the checked-out branch is that pull request', () {
      final pr = _pr(repoFullName: repo);
      expect(
        lookup(
          branchMatched: [
            (repoId: repoId, repoFullName: repo, branch: pr.headRef, pr: pr),
          ],
        ),
        pr,
      );
    });

    test('a cached match for the previous branch is not this one', () {
      final previous = _pr(repoFullName: repo, headRef: 'space/other');
      expect(
        lookup(
          branchMatched: [
            (
              repoId: repoId,
              repoFullName: repo,
              branch: 'space/other',
              pr: previous,
            ),
          ],
        ),
        isNull,
      );
    });

    test('a linked pull request whose head is this branch counts', () {
      final pr = _pr(repoFullName: repo);
      expect(lookup(linked: [pr])?.number, pr.number);
    });

    test('a linked pull request for another branch does not', () {
      expect(
        lookup(
          linked: [_pr(repoFullName: repo, headRef: 'space/other')],
        ),
        isNull,
      );
    });

    test('a closed pull request does not block creating a new one', () {
      expect(
        lookup(
          linked: [_pr(repoFullName: repo, state: PrState.closed)],
        ),
        isNull,
      );
    });
  });
}

class _FakeReviewSpaces implements ReviewSpaceRepository {
  const _FakeReviewSpaces(this.rows);

  final List<ReviewSpaceAssociation> rows;

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value(rows.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(
    rows
        .where(
          (a) => a.workspaceId == workspaceId && a.prExternalId == prExternalId,
        )
        .firstOrNull,
  );

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    rows
        .where((a) => a.workspaceId == workspaceId && a.spaceId == spaceId)
        .firstOrNull,
  );

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(
    rows
        .where((a) => a.workspaceId == workspaceId && a.spaceId == spaceId)
        .toList(),
  );

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) => throw UnimplementedError();

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) async {}
}
