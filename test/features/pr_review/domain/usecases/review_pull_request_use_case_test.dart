import 'dart:async';

import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/usecases/review_pull_request_use_case.dart';
import 'package:test/test.dart';

class FakePrReviewRepository implements PrReviewRepository {
  final List<Map<String, dynamic>> postCommentCalls = [];
  final List<Map<String, dynamic>> replyCalls = [];
  final List<Map<String, dynamic>> upsertDraftCalls = [];
  final List<Map<String, dynamic>> markFileViewedCalls = [];
  final Map<int, String> drafts = {};

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
    postCommentCalls.add({
      'prNumber': prNumber,
      'commitSha': commitSha,
      'path': path,
      'line': line,
      'side': side,
      'body': body,
      'startLine': startLine,
      'startSide': startSide,
    });
    return {'id': 1};
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    replyCalls.add({
      'prNumber': prNumber,
      'parentCommentId': parentCommentId,
      'body': body,
    });
  }

  @override
  Future<void> upsertDraft(int prNumber, String text) async {
    upsertDraftCalls.add({'prNumber': prNumber, 'text': text});
    drafts[prNumber] = text;
  }

  @override
  Future<String?> getDraft(int prNumber) async => drafts[prNumber];

  @override
  Future<void> clearDraft(int prNumber) async {
    drafts.remove(prNumber);
  }

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) async {
    markFileViewedCalls.add({
      'prNumber': prNumber,
      'nodeId': nodeId,
      'path': path,
      'viewed': viewed,
    });
  }

  // ── Stub remaining methods ──

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) =>
      throw UnimplementedError('watchPullRequest');

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

void main() {
  group('ReviewPullRequestUseCase', () {
    late FakePrReviewRepository repo;
    late ReviewPullRequestUseCase useCase;

    setUp(() {
      repo = FakePrReviewRepository();
      useCase = ReviewPullRequestUseCase(repository: repo);
    });

    group('postComment', () {
      test('delegates correctly with all params', () async {
        final result = await useCase.postComment(
          prNumber: 42,
          commitSha: 'abc123',
          path: 'src/foo.dart',
          line: 10,
          side: 'RIGHT',
          body: 'Looks good!',
        );

        expect(repo.postCommentCalls, hasLength(1));
        expect(repo.postCommentCalls.first['prNumber'], 42);
        expect(repo.postCommentCalls.first['commitSha'], 'abc123');
        expect(repo.postCommentCalls.first['path'], 'src/foo.dart');
        expect(repo.postCommentCalls.first['line'], 10);
        expect(repo.postCommentCalls.first['side'], 'RIGHT');
        expect(repo.postCommentCalls.first['body'], 'Looks good!');
        expect(repo.postCommentCalls.first['startLine'], isNull);
        expect(repo.postCommentCalls.first['startSide'], isNull);
        expect(result, {'id': 1});
      });

      test('with optional startLine/startSide', () async {
        await useCase.postComment(
          prNumber: 42,
          commitSha: 'abc123',
          path: 'src/foo.dart',
          line: 15,
          side: 'RIGHT',
          body: 'Multi-line comment',
          startLine: 10,
          startSide: 'RIGHT',
        );

        expect(repo.postCommentCalls, hasLength(1));
        expect(repo.postCommentCalls.first['startLine'], 10);
        expect(repo.postCommentCalls.first['startSide'], 'RIGHT');
      });
    });

    group('replyToComment', () {
      test('delegates correctly', () async {
        await useCase.replyToComment(
          prNumber: 42,
          parentCommentId: 99,
          body: 'Thanks for the review!',
        );

        expect(repo.replyCalls, hasLength(1));
        expect(repo.replyCalls.first['prNumber'], 42);
        expect(repo.replyCalls.first['parentCommentId'], 99);
        expect(repo.replyCalls.first['body'], 'Thanks for the review!');
      });
    });

    group('drafts', () {
      test('upsertDraft stores and getDraft retrieves', () async {
        await useCase.upsertDraft(42, 'Work in progress...');

        final draft = await useCase.getDraft(42);
        expect(draft, 'Work in progress...');
        expect(repo.upsertDraftCalls, hasLength(1));
        expect(repo.upsertDraftCalls.first['prNumber'], 42);
        expect(repo.upsertDraftCalls.first['text'], 'Work in progress...');
      });

      test('clearDraft removes draft', () async {
        await useCase.upsertDraft(42, 'Some text');
        await useCase.clearDraft(42);

        final draft = await useCase.getDraft(42);
        expect(draft, isNull);
      });

      test('getDraft returns null for missing draft', () async {
        final draft = await useCase.getDraft(999);
        expect(draft, isNull);
      });

      test('multiple upsertDraft calls overwrite', () async {
        await useCase.upsertDraft(42, 'First draft');
        await useCase.upsertDraft(42, 'Second draft');

        final draft = await useCase.getDraft(42);
        expect(draft, 'Second draft');
        expect(repo.upsertDraftCalls, hasLength(2));
      });
    });
  });
}
