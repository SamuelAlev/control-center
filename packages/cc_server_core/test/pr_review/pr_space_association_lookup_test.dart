import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_server_core/src/pr_review/pr_space_provisioning.dart';
import 'package:test/test.dart';

/// A PR's space is checked out at that PR's head, so the lookup behind
/// `pr.ensureSpace` must never hand back another pull request's space.
void main() {
  ReviewSpaceAssociation assoc(
    String spaceId, {
    required String externalId,
    required int number,
    String repo = 'acme/web',
  }) => ReviewSpaceAssociation(
    id: 'a-$spaceId',
    spaceId: spaceId,
    workspaceId: 'ws',
    prExternalId: externalId,
    prNumber: number,
    repoFullName: repo,
    status: ReviewSpaceStatus.requested,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<String?> find(
    List<ReviewSpaceAssociation> rows, {
    required String externalId,
    required int number,
    String repo = 'acme/web',
  }) async => (await findPrSpaceAssociation(
    _FakeAssociations(rows),
    workspaceId: 'ws',
    repoFullName: repo,
    prNumber: number,
    prExternalId: externalId,
  ))?.spaceId;

  test('the forge id finds its own pull request', () async {
    expect(
      await find(
        [assoc('s42', externalId: 'PR_42', number: 42)],
        externalId: 'PR_42',
        number: 42,
      ),
      's42',
    );
  });

  test('a by-id row naming another pull request is not reused', () async {
    // Reusing it would open #43's worktree for #42.
    expect(
      await find(
        [assoc('s43', externalId: 'PR_X', number: 43)],
        externalId: 'PR_X',
        number: 42,
      ),
      isNull,
    );
  });

  test('an empty forge id never matches the rows written under it', () async {
    final rows = [
      assoc('s7', externalId: '', number: 7),
      assoc('s8', externalId: '', number: 8),
    ];
    expect(await find(rows, externalId: '', number: 8), 's8');
    expect(await find(rows, externalId: '', number: 9), isNull);
  });

  test('repo + number finds a row written under another id', () async {
    expect(
      await find(
        [assoc('s42', externalId: 'synthetic-key', number: 42)],
        externalId: 'PR_42',
        number: 42,
      ),
      's42',
    );
  });

  test(
    'the same number in a sibling repo is a different pull request',
    () async {
      expect(
        await find(
          [assoc('s42', externalId: 'PR_A', number: 42, repo: 'acme/api')],
          externalId: 'PR_B',
          number: 42,
        ),
        isNull,
      );
    },
  );
}

class _FakeAssociations implements ReviewSpaceRepository {
  _FakeAssociations(this.rows);

  /// Newest first, like the real repository.
  final List<ReviewSpaceAssociation> rows;

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) => Stream.value(
    rows.where((a) => a.prExternalId == prExternalId).firstOrNull,
  );

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value(rows);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
