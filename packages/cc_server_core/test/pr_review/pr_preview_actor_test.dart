import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';
import 'package:cc_server_core/src/catalog/pr_review_ops.dart';
import 'package:test/test.dart';

/// Pins that a markdown reference preview is fetched as the session user.
///
/// The no-caller GitHub client is the App installation. GitHub answers 404
/// for a private repo that installation cannot see, and the chip then renders
/// as a plain link. The handler must hand the caller through, and must not
/// share the cached title with a different member.
void main() {
  test('pr preview is fetched and cached as the caller', () async {
    String? seenUser;
    String? seenWorkspace;
    String? seenKey;

    final ops = _ops(
      onPreview:
          (owner, repo, number, {required actingUserId, workspaceId}) async {
            seenUser = actingUserId;
            seenWorkspace = workspaceId;
            expect(owner, 'ControlCenter');
            expect(repo, 'application');
            expect(number, 33982);
            return {
              'title': 'feat: do something',
              'state': 'open',
              'is_draft': false,
              'is_merged': false,
              'html_url': 'https://github.com/ControlCenter/application/pull/33982',
            };
          },
      onSwr: (key) => seenKey = key,
    );

    final op = ops.singleWhere((o) => o.name == 'pr_review.prPreview');
    final result = await op.handler(
      const RepoOpContext(
        args: {'owner': 'ControlCenter', 'repo': 'application', 'number': 33982},
        workspaceId: 'ws-1',
        deviceId: 'device-1',
        userId: 'user-1',
      ),
    );

    expect(seenUser, 'user-1');
    expect(seenWorkspace, 'ws-1');
    expect(seenKey, 'user-1|ControlCenter/application#33982');
    expect(
      result['preview'],
      containsPair('title', 'feat: do something'),
    );
  });

  test('commit preview is fetched and cached as the caller', () async {
    String? seenUser;
    String? seenKey;

    final ops = _ops(
      onCommit: (owner, repo, sha, {required actingUserId, workspaceId}) async {
        seenUser = actingUserId;
        expect(workspaceId, 'ws-1');
        expect(sha, 'abc123');
        return {'title': 'fix the menu', 'short_sha': 'abc123'};
      },
      onSwr: (key) => seenKey = key,
    );

    final op = ops.singleWhere((o) => o.name == 'pr_review.commitPreview');
    await op.handler(
      const RepoOpContext(
        args: {'owner': 'ControlCenter', 'repo': 'application', 'sha': 'abc123'},
        workspaceId: 'ws-1',
        deviceId: 'device-1',
        userId: 'user-1',
      ),
    );

    expect(seenUser, 'user-1');
    expect(seenKey, 'user-1|ControlCenter/application@abc123');
  });
}

List<RepoOp> _ops({
  PrPreviewFetcher? onPreview,
  CommitPreviewFetcher? onCommit,
  required void Function(String key) onSwr,
}) => buildPrReviewOps(
  resolvePrReviewRepository:
      (
        String workspaceId,
        String owner,
        String repo, {
        required String userId,
        bool asApp = false,
      }) async => throw UnimplementedError(),
  requireRepoCoords: (args) =>
      (owner: args['owner'] as String, repo: args['repo'] as String),
  previewSwr:
      ({
        required String workspaceId,
        required String kind,
        required String key,
        required Future<Map<String, dynamic>?> Function() fetch,
      }) async {
        onSwr(key);
        return fetch();
      },
  assertSpaceOwned: (workspaceId, spaceId) async {},
  messagingRepository: _UnusedMessaging(),
  fetchPrPreview: onPreview,
  fetchCommitPreview: onCommit,
);

class _UnusedMessaging implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
