import 'package:cc_connect_core/cc_connect_core.dart'
    show
        GitHubReviewCommentInput,
        GitHubReviewCommentOutcome,
        GitHubReviewCommentStatus;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show mentionBreak;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show kNeedsSignInCode, kRepoReplacedCode;
import 'package:cc_server_core/src/catalog/pr_review_ops.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('pr_review.commentFindings', () {
    test(
      'posts through resolveReviewBotClient with neutralized mentions and attribution, then invalidates PR cache',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(
            id: 'f-1',
            content: 'Check @alice and @acme/security on this path.',
            filePath: 'lib/a.dart',
            lineNumber: 12,
            lineEnd: 15,
          ),
        ]);
        final botClient = _FakeForgePrClient();
        final reviewRepo = _FakePrReviewRepository();
        final botCalls =
            <({String workspaceId, String owner, String repo, String userId})>[];
        final attributionCalls =
            <({String workspaceId, String owner, String? actingUserId})>[];

        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (ws, owner, repo, {required userId}) async {
            expect(ws, 'ws-1');
            expect(owner, 'acme');
            expect(repo, 'app');
            expect(userId, 'user-1');
            return reviewRepo;
          },
          resolveReviewBotClient: (ws, owner, repo, {required userId}) async {
            botCalls.add((
              workspaceId: ws,
              owner: owner,
              repo: repo,
              userId: userId,
            ));
            return (repo: _repo(), client: botClient);
          },
          automatedReviewAttribution:
              ({required workspaceId, required owner, actingUserId}) async {
                attributionCalls.add((
                  workspaceId: workspaceId,
                  owner: owner,
                  actingUserId: actingUserId,
                ));
                return (body) =>
                    GitHubPrConversationBridge.attributed('alice', body);
              },
        );

        final result = await op.handler(
          const RepoOpContext(
            args: {
              'workspace_id': 'ws-1',
              'space_id': 'space-1',
              'owner': 'acme',
              'repo': 'app',
              'pr_number': 42,
              'commit_sha': 'abc123',
              'message_ids': ['f-1'],
            },
            workspaceId: 'ws-1',
            deviceId: 'dev-1',
            userId: 'user-1',
          ),
        );

        expect(result, {
          'posted': 1,
          'skipped': 0,
          'outOfDiff': 0,
          'failed': 0,
        });
        expect(botCalls, [
          (workspaceId: 'ws-1', owner: 'acme', repo: 'app', userId: 'user-1'),
        ]);
        expect(attributionCalls, [
          (workspaceId: 'ws-1', owner: 'acme', actingUserId: 'user-1'),
        ]);
        expect(reviewRepo.postedComments, isEmpty);
        expect(reviewRepo.invalidatedPrs, [42]);

        expect(botClient.posted, hasLength(1));
        final posted = botClient.posted.single;
        expect(posted.prNumber, 42);
        expect(posted.commitSha, 'abc123');
        expect(posted.path, 'lib/a.dart');
        expect(posted.line, 15);
        expect(posted.startLine, 12);
        expect(posted.side, 'RIGHT');
        expect(
          posted.body,
          '**Control Center** (for @alice): '
          'Check @$mentionBreak'
          'alice and @$mentionBreak'
          'acme/security on this path.',
        );
      },
    );

    test(
      'neutralizes mentions even when attribution is null or on non-GitHub forges',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(
            id: 'f-1',
            content: 'Ping @bob here.',
            filePath: 'lib/b.dart',
            lineNumber: 9,
          ),
        ]);
        final botClient = _FakeForgePrClient();
        final reviewRepo = _FakePrReviewRepository();
        var attributionCalled = false;

        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (_, _, _, {required userId}) async =>
              reviewRepo,
          resolveReviewBotClient: (_, _, _, {required userId}) async =>
              (repo: _repo(forge: ForgeHost.gitlab), client: botClient),
          automatedReviewAttribution:
              ({required workspaceId, required owner, actingUserId}) async {
                attributionCalled = true;
                return (body) => 'should-not-run: $body';
              },
        );

        final result = await op.handler(
          const RepoOpContext(
            args: {
              'workspace_id': 'ws-1',
              'space_id': 'space-1',
              'owner': 'acme',
              'repo': 'app',
              'pr_number': 7,
              'commit_sha': 'sha',
              'message_ids': ['f-1'],
            },
            workspaceId: 'ws-1',
            deviceId: 'dev-1',
            userId: 'user-1',
          ),
        );

        expect(result['posted'], 1);
        expect(attributionCalled, isFalse);
        expect(botClient.posted.single.body, 'Ping @$mentionBreak' 'bob here.');
        expect(reviewRepo.invalidatedPrs, [7]);
      },
    );

    test(
      'counts skipped and out-of-diff findings without invalidating when posted is zero',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(id: 'f-unanchored', content: 'No anchor'),
          _finding(
            id: 'f-out',
            content: 'Outside diff',
            filePath: 'lib/other.dart',
            lineNumber: 3,
          ),
        ]);
        final botClient = _FakeForgePrClient()
          ..onPost = (_) {
            throw const NetworkException(
              'Unprocessable entity',
              statusCode: 422,
              responseBody:
                  '{"errors":[{"field":"pull_request_review_thread.path"}]}',
              code: 'unprocessable_entity',
            );
          };
        final reviewRepo = _FakePrReviewRepository();

        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (_, _, _, {required userId}) async =>
              reviewRepo,
          resolveReviewBotClient: (_, _, _, {required userId}) async =>
              (repo: _repo(), client: botClient),
        );

        final result = await op.handler(
          const RepoOpContext(
            args: {
              'workspace_id': 'ws-1',
              'space_id': 'space-1',
              'owner': 'acme',
              'repo': 'app',
              'pr_number': 9,
              'commit_sha': 'sha',
              'message_ids': ['f-unanchored', 'f-out'],
            },
            workspaceId: 'ws-1',
            deviceId: 'dev-1',
            userId: 'user-1',
          ),
        );

        expect(result, {
          'posted': 0,
          'skipped': 1,
          'outOfDiff': 1,
          'failed': 0,
          'outOfDiffPaths': ['lib/other.dart'],
        });
        expect(reviewRepo.invalidatedPrs, isEmpty);
      },
    );

    test(
      'rethrows NeedsSignInException and repo_replaced NetworkException instead of swallowing into errors',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(
            id: 'f-1',
            content: 'Body',
            filePath: 'lib/a.dart',
            lineNumber: 1,
          ),
        ]);
        final botClient = _FakeForgePrClient();
        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (_, _, _, {required userId}) async =>
              _FakePrReviewRepository(),
          resolveReviewBotClient: (_, _, _, {required userId}) async =>
              (repo: _repo(), client: botClient),
        );

        botClient.onPost = (_) =>
            throw const NeedsSignInException('github', 'Sign in');
        await expectLater(
          op.handler(
            const RepoOpContext(
              args: {
                'workspace_id': 'ws-1',
                'space_id': 'space-1',
                'owner': 'acme',
                'repo': 'app',
                'pr_number': 1,
                'commit_sha': 'sha',
                'message_ids': ['f-1'],
              },
              workspaceId: 'ws-1',
              deviceId: 'dev-1',
              userId: 'user-1',
            ),
          ),
          throwsA(isA<NeedsSignInException>()),
        );

        botClient.onPost = (_) => throw const NetworkException(
          'Repo replaced',
          statusCode: 409,
          code: kRepoReplacedCode,
        );
        await expectLater(
          op.handler(
            const RepoOpContext(
              args: {
                'workspace_id': 'ws-1',
                'space_id': 'space-1',
                'owner': 'acme',
                'repo': 'app',
                'pr_number': 1,
                'commit_sha': 'sha',
                'message_ids': ['f-1'],
              },
              workspaceId: 'ws-1',
              deviceId: 'dev-1',
              userId: 'user-1',
            ),
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.code,
              'code',
              kRepoReplacedCode,
            ),
          ),
        );

        botClient.onPost = (_) => throw const NetworkException(
          'Sign in',
          statusCode: 401,
          code: kNeedsSignInCode,
        );
        await expectLater(
          op.handler(
            const RepoOpContext(
              args: {
                'workspace_id': 'ws-1',
                'space_id': 'space-1',
                'owner': 'acme',
                'repo': 'app',
                'pr_number': 1,
                'commit_sha': 'sha',
                'message_ids': ['f-1'],
              },
              workspaceId: 'ws-1',
              deviceId: 'dev-1',
              userId: 'user-1',
            ),
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.code,
              'code',
              kNeedsSignInCode,
            ),
          ),
        );
      },
    );

    test(
      'routes GitHub findings through postConnectReviewComments when on Connect, '
      'tallies outcomes, and invalidates PR cache',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(
            id: 'f-1',
            content: 'Check @alice here.',
            filePath: 'lib/a.dart',
            lineNumber: 12,
            lineEnd: 15,
          ),
          _finding(
            id: 'f-2',
            content: 'Same-line anchor.',
            filePath: 'lib/b.dart',
            lineNumber: 8,
            lineEnd: 8,
          ),
          _finding(
            id: 'f-3',
            content: 'Outside diff.',
            filePath: 'lib/c.dart',
            lineNumber: 3,
          ),
          _finding(id: 'f-unanchored', content: 'No anchor'),
        ]);
        final botClient = _FakeForgePrClient();
        final reviewRepo = _FakePrReviewRepository();
        List<GitHubReviewCommentInput>? capturedInputs;

        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (_, _, _, {required userId}) async =>
              reviewRepo,
          resolveReviewBotClient: (_, _, _, {required userId}) async =>
              (repo: _repo(), client: botClient),
          postConnectReviewComments:
              ({
                required workspaceId,
                required repo,
                required userId,
                required prNumber,
                required commitSha,
                required comments,
              }) async {
                expect(workspaceId, 'ws-1');
                expect(userId, 'user-1');
                expect(prNumber, 42);
                expect(commitSha, 'abc123');
                capturedInputs = comments;
                return const [
                  GitHubReviewCommentOutcome(
                    index: 0,
                    status: GitHubReviewCommentStatus.posted,
                    commentId: 101,
                  ),
                  GitHubReviewCommentOutcome(
                    index: 1,
                    status: GitHubReviewCommentStatus.failed,
                  ),
                  GitHubReviewCommentOutcome(
                    index: 2,
                    status: GitHubReviewCommentStatus.outOfDiff,
                  ),
                ];
              },
        );

        final result = await op.handler(
          const RepoOpContext(
            args: {
              'workspace_id': 'ws-1',
              'space_id': 'space-1',
              'owner': 'acme',
              'repo': 'app',
              'pr_number': 42,
              'commit_sha': 'abc123',
              'message_ids': ['f-1', 'f-2', 'f-3', 'f-unanchored'],
            },
            workspaceId: 'ws-1',
            deviceId: 'dev-1',
            userId: 'user-1',
          ),
        );

        expect(botClient.posted, isEmpty);
        expect(reviewRepo.postedComments, isEmpty);
        expect(reviewRepo.invalidatedPrs, [42]);
        expect(capturedInputs, hasLength(3));
        expect(capturedInputs![0].body, 'Check @alice here.');
        expect(capturedInputs![0].startLine, 12);
        expect(capturedInputs![0].line, 15);
        expect(capturedInputs![1].startLine, isNull);
        expect(capturedInputs![1].line, 8);
        expect(result['posted'], 1);
        expect(result['skipped'], 1);
        expect(result['outOfDiff'], 1);
        expect(result['outOfDiffPaths'], ['lib/c.dart']);
        expect(result['failed'], 1);
      },
    );

    test(
      'falls back to bot.client.postReviewComment when postConnectReviewComments returns null',
      () async {
        final messaging = _FakeMessagingRepository([
          _finding(
            id: 'f-1',
            content: 'Own App finding.',
            filePath: 'lib/a.dart',
            lineNumber: 5,
          ),
        ]);
        final botClient = _FakeForgePrClient();
        final reviewRepo = _FakePrReviewRepository();

        final op = _commentFindingsOp(
          messaging: messaging,
          resolvePrReviewRepository: (_, _, _, {required userId}) async =>
              reviewRepo,
          resolveReviewBotClient: (_, _, _, {required userId}) async =>
              (repo: _repo(), client: botClient),
          postConnectReviewComments:
              ({
                required workspaceId,
                required repo,
                required userId,
                required prNumber,
                required commitSha,
                required comments,
              }) async => null,
        );

        final result = await op.handler(
          const RepoOpContext(
            args: {
              'workspace_id': 'ws-1',
              'space_id': 'space-1',
              'owner': 'acme',
              'repo': 'app',
              'pr_number': 42,
              'commit_sha': 'abc123',
              'message_ids': ['f-1'],
            },
            workspaceId: 'ws-1',
            deviceId: 'dev-1',
            userId: 'user-1',
          ),
        );

        expect(result, {
          'posted': 1,
          'skipped': 0,
          'outOfDiff': 0,
          'failed': 0,
        });
        expect(botClient.posted, hasLength(1));
        expect(botClient.posted.single.body, 'Own App finding.');
        expect(reviewRepo.invalidatedPrs, [42]);
      },
    );
  });
}

Repo _repo({ForgeHost forge = ForgeHost.github}) => Repo(
  id: 'repo-1',
  name: 'acme/app',
  path: '/repos/app',
  forge: forge,
  remoteOwner: 'acme',
  remoteName: 'app',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Message _finding({
  required String id,
  required String content,
  String? filePath,
  int? lineNumber,
  int? lineEnd,
}) => Message(
  id: id,
  spaceId: 'space-1',
  conversationId: 'conv-reviewer',
  senderId: 'agent-reviewer',
  senderType: SenderType.agent,
  content: content,
  messageType: MessageType.reviewNode,
  createdAt: DateTime.utc(2026),
  metadata: {
    'nodeType': 'bug',
    'priority': 'p1',
    'confidence': 0.9,
    'status': 'open',
    'filePath': ?filePath,
    'lineNumber': ?lineNumber,
    'lineEnd': ?lineEnd,
  },
);

RepoOp _commentFindingsOp({
  required MessagingRepository messaging,
  required Future<PrReviewRepository> Function(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
  })
  resolvePrReviewRepository,
  Future<({Repo repo, ForgePrClient client})?> Function(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
  })?
  resolveReviewBotClient,
  ConnectReviewCommentPoster? postConnectReviewComments,
  Future<String Function(String body)?> Function({
    required String workspaceId,
    required String owner,
    String? actingUserId,
  })?
  automatedReviewAttribution,
}) => buildPrReviewOps(
  resolvePrReviewRepository: resolvePrReviewRepository,
  resolveReviewBotClient: resolveReviewBotClient,
  postConnectReviewComments: postConnectReviewComments,
  automatedReviewAttribution: automatedReviewAttribution,
  requireRepoCoords: (args) =>
      (owner: args['owner'] as String, repo: args['repo'] as String),
  previewSwr:
      ({
        required String workspaceId,
        required String kind,
        required String key,
        required Future<Map<String, dynamic>?> Function() fetch,
      }) async => fetch(),
  assertSpaceOwned: (_, _, _) async {},
  messagingRepository: messaging,
).singleWhere((o) => o.name == 'pr_review.commentFindings');

class _FakeMessagingRepository implements MessagingRepository {
  _FakeMessagingRepository(this.messages);
  final List<Message> messages;

  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      Future.value(messages);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeForgePrClient implements ForgePrClient {
  final List<
    ({
      int prNumber,
      String commitSha,
      String path,
      int line,
      String side,
      String body,
      int? startLine,
    })
  >
  posted = [];
  void Function(String path)? onPost;

  @override
  Future<PrCodeReviewComment?> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
    ForgeCancelToken? cancelToken,
  }) async {
    onPost?.call(path);
    posted.add((
      prNumber: prNumber,
      commitSha: commitSha,
      path: path,
      line: line,
      side: side,
      body: body,
      startLine: startLine,
    ));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePrReviewRepository implements PrReviewRepository {
  final List<String> postedComments = [];
  final List<int> invalidatedPrs = [];

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async {
    postedComments.add(body);
    return {'id': 1};
  }

  @override
  Future<void> invalidatePullRequest(int prNumber) async {
    invalidatedPrs.add(prNumber);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
