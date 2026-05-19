import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/load_pull_request_details.dart';
import 'package:test/test.dart';

class FakePrReviewRepository implements PrReviewRepository {
  StreamController<PullRequest?>? _controller;

  void emitPullRequest(PullRequest? pr) {
    _controller?.add(pr);
  }

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) {
    _controller = StreamController<PullRequest?>.broadcast();
    return _controller!.stream;
  }

  // ── Stub remaining methods ──

  @override
  Stream<String> watchDiff(int prNumber) =>
      throw UnimplementedError('watchDiff');

  @override
  Stream<List<PrFile>> watchFiles(int prNumber) =>
      throw UnimplementedError('watchFiles');

  @override
  Stream<String> watchFileContent(String path, String ref) =>
      throw UnimplementedError('watchFileContent');

  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) =>
      throw UnimplementedError('watchCommits');

  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) =>
      throw UnimplementedError('watchCommitFiles');

  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) =>
      throw UnimplementedError('watchReviews');

  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) =>
      throw UnimplementedError('watchReviewComments');

  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) =>
      throw UnimplementedError('watchIssueComments');

  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) =>
      throw UnimplementedError('watchCheckRuns');

  @override
  Future<void> invalidatePullRequest(int prNumber) =>
      throw UnimplementedError('invalidatePullRequest');

  @override
  Future<void> invalidateDiff(int prNumber) =>
      throw UnimplementedError('invalidateDiff');

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) =>
      throw UnimplementedError('markFileAsViewed');

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
  }) =>
      throw UnimplementedError('postReviewComment');

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) =>
      throw UnimplementedError('replyToReviewComment');

  @override
  Future<void> upsertDraft(int prNumber, String text) =>
      throw UnimplementedError('upsertDraft');

  @override
  Future<String?> getDraft(int prNumber) =>
      throw UnimplementedError('getDraft');

  @override
  Future<void> clearDraft(int prNumber) =>
      throw UnimplementedError('clearDraft');

  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) =>
      throw UnimplementedError('uploadContent');

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) =>
      throw UnimplementedError('toggleReviewCommentReaction');

  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) =>
      throw UnimplementedError('toggleIssueCommentReaction');

  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) =>
      throw UnimplementedError('togglePullRequestReaction');

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) =>
      throw UnimplementedError('submitReview');

  @override
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) =>
      throw UnimplementedError('mergePullRequest');

  @override
  Future<void> closePullRequest({required int prNumber}) =>
      throw UnimplementedError('closePullRequest');

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) =>
      throw UnimplementedError('updatePullRequest');

  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  }) =>
      throw UnimplementedError('addAssignees');

  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  }) =>
      throw UnimplementedError('removeAssignees');

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) =>
      throw UnimplementedError('requestReviewers');

  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) =>
      throw UnimplementedError('removeRequestedReviewers');

  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) =>
      throw UnimplementedError('watchReviewers');

  @override
  Future<List<PrUser>> listAssignableUsers() =>
      throw UnimplementedError('listAssignableUsers');

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() =>
      throw UnimplementedError('listRequestableReviewers');
}

PullRequest _pr(int number) => PullRequest(
      id: number,
      number: number,
      title: 'PR $number',
      body: '',
      state: PrState.open,
      isDraft: false,
      author: const PrUser(login: 'dev', avatarUrl: ''),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      repoFullName: 'test/repo',
      htmlUrl: 'https://example.com',
    );

void main() {
  group('LoadPullRequestDetailsUseCase', () {
    late FakePrReviewRepository repo;
    late LoadPullRequestDetailsUseCase useCase;

    setUp(() {
      repo = FakePrReviewRepository();
      useCase = LoadPullRequestDetailsUseCase(repository: repo);
    });

    test('returns stream from repository.watchPullRequest', () {
      final stream = useCase.execute(42);

      expect(stream, isA<Stream<PullRequest?>>());
    });

    test('stream emits expected PR', () async {
      final stream = useCase.execute(42);
      final expectedPr = _pr(42);

      repo.emitPullRequest(expectedPr);

      final emitted = await stream.first;
      expect(emitted, isNotNull);
      expect(emitted!.number, 42);
      expect(emitted.title, 'PR 42');
    });

    test('stream can emit null', () async {
      final stream = useCase.execute(42);

      repo.emitPullRequest(null);

      final emitted = await stream.first;
      expect(emitted, isNull);
    });
  });
}
