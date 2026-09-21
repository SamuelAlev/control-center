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
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Cap eval-run token budget per model family',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: repoFullName,
    htmlUrl: 'https://example.invalid/$repoFullName/pull/$number',
    externalId: externalId,
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
