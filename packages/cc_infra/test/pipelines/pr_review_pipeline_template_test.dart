import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/pipelines/pr_review_pipeline_template.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [registerPrReviewBodies] — the single step body that posts a
/// consolidated review comment back to a PR. Pure control-flow over an
/// injectable [GitHubPrClient]: validates the repo slug + PR number, surfaces
/// failures for missing findings / bad inputs and returns the review id on
/// success.
void main() {
  late _FakeGitHubPrClient prClient;
  late PipelineBodyRegistry registry;
  late _RecordingFinalize finalize;

  setUp(() {
    prClient = _FakeGitHubPrClient();
    finalize = _RecordingFinalize();
    registry = PipelineBodyRegistry();
    registerPrReviewBodies(
      registry,
      githubPrClient: prClient,
      finalizeReview: finalize.call,
    );
  });

  PipelineContext ctx({
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
  }) => PipelineContext(
    pipelineRunId: 'run-1',
    templateId: 'tpl-1',
    stepId: 'pr-comment',
    stepRunId: 'sr-1',
    workspaceId: 'ws-1',
    state: state,
    triggerPayload: trigger,
  );

  Future<StepResult> run({
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
  }) => registry.body(BuiltInBodyKeys.prReviewComment)(
    ctx(state: state, trigger: trigger),
  );

  Future<StepResult> finalizeStep({
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
  }) => registry.body(BuiltInBodyKeys.prReviewFinalize)(
    ctx(state: state, trigger: trigger),
  );

  group('prReview.finalize', () {
    test(
      'passes the consolidated report through as the editorial note',
      () async {
        final res = await finalizeStep(
          state: {
            'review_space_id': 'space-1',
            'consolidated_findings': '  ## Report\nlooks good  ',
          },
        );

        expect(finalize.lastSpaceId, 'space-1');
        expect(finalize.lastEditorialNote, '## Report\nlooks good');
        expect(res.mutatedState!['review_verdict'], isNotNull);
      },
    );

    test('still finalizes when the note is not a string', () async {
      // The close-out is what turns filed `review_node` findings into the
      // verdict the PR's review tab reads. It used to read the note with
      // `ctx.optional<String>`, which THROWS on a type mismatch: a
      // consolidation that harvested an empty list failed the whole step with
      // `Bad state: ... not String (got List<dynamic>)`, so 52 filed findings
      // never became a verdict. A missing note costs the note, not the verdict.
      final res = await finalizeStep(
        state: {
          'review_space_id': 'space-1',
          'consolidated_findings': <dynamic>[],
        },
      );

      expect(res.errorMessage, isNull);
      expect(finalize.calls, 1);
      expect(finalize.lastEditorialNote, isNull);
      expect(res.mutatedState!['review_verdict'], isNotNull);
    });

    test('carries the reviewed commit through to the finalizer', () async {
      // Without it the review cannot say which version of the code it read,
      // and a later push cannot be recognised as making it stale.
      await finalizeStep(
        state: {'review_space_id': 'space-1'},
        trigger: {'head_sha': 'deadbeefcafe'},
      );
      expect(finalize.lastHeadSha, 'deadbeefcafe');
    });

    test('finalizes without a commit rather than refusing', () async {
      // A run started before the commit was recorded still has findings worth
      // turning into a verdict.
      await finalizeStep(state: {'review_space_id': 'space-1'});
      expect(finalize.calls, 1);
      expect(finalize.lastHeadSha, isNull);
    });

    test('fails when no review space was resolved upstream', () async {
      final res = await finalizeStep(state: {'consolidated_findings': 'x'});
      expect(res.errorMessage, contains('no review_space_id'));
      expect(finalize.calls, 0);
    });
  });

  group('registerPrReviewBodies — validation failures', () {
    test(
      'throws when repoFullName is missing (requireString is strict)',
      () async {
        // requireString raises a StateError before the body reaches its own
        // repoFullName handling — the pipeline engine surfaces this as a failed
        // step upstream.
        expect(
          () => run(state: {'pr_number': 1, 'consolidated_findings': 'x'}),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('fails when prNumber is missing entirely', () async {
      final res = await run(
        state: {'repo_full_name': 'o/r', 'consolidated_findings': 'x'},
      );
      expect(res.errorMessage, contains('pr_number missing'));
    });

    test('fails when prNumber is non-numeric', () async {
      final res = await run(
        state: {
          'repo_full_name': 'o/r',
          'pr_number': 'abc',
          'consolidated_findings': 'x',
        },
      );
      expect(res.errorMessage, contains('pr_number missing'));
    });

    test('fails when findings are missing or empty', () async {
      final res = await run(state: {'repo_full_name': 'o/r', 'pr_number': 1});
      expect(res.errorMessage, contains('No consolidated findings'));

      final res2 = await run(
        state: {
          'repo_full_name': 'o/r',
          'pr_number': 1,
          'consolidated_findings': '',
        },
      );
      expect(res2.errorMessage, contains('No consolidated findings'));
    });

    test('fails when repoFullName is not owner/repo', () async {
      final res = await run(
        state: {
          'repo_full_name': 'just-one-part',
          'pr_number': 1,
          'consolidated_findings': 'x',
        },
      );
      expect(res.errorMessage, contains('Invalid repo_full_name'));
    });
  });

  group('registerPrReviewBodies — success', () {
    test('submits a COMMENT review and returns the review id', () async {
      prClient.reviewToReturn = GitHubReview.fromJson({
        'id': 99,
        'state': 'COMMENTED',
        'user': {'login': 'cc'},
        'submitted_at': '2026-01-01T00:00:00Z',
      });
      final res = await run(
        state: {
          'repo_full_name': 'acme/widget',
          'pr_number': 42,
          'consolidated_findings': 'looks good but nits',
        },
      );

      expect(prClient.lastOwner, 'acme');
      expect(prClient.lastRepo, 'widget');
      expect(prClient.lastPrNumber, 42);
      expect(prClient.lastEvent, 'COMMENT');
      expect(prClient.lastBody, 'looks good but nits');
      expect(res.isTerminal, isTrue);
      expect(res.mutatedState!['comment_review_id'], 99);
      expect(res.mutatedState!['commented_at'], isNotNull);
    });

    test(
      'accepts a numeric-string prNumber from an upstream bash step',
      () async {
        prClient.reviewToReturn = GitHubReview.fromJson({
          'id': 5,
          'state': 'COMMENTED',
        });
        final res = await run(
          state: {
            'repo_full_name': 'o/r',
            'pr_number': '  7 ',
            'consolidated_findings': 'f',
          },
        );
        expect(prClient.lastPrNumber, 7);
        expect(res.mutatedState!['comment_review_id'], 5);
      },
    );

    test(
      'reads prNumber from the trigger payload when absent in state',
      () async {
        prClient.reviewToReturn = GitHubReview.fromJson({
          'id': 1,
          'state': 'COMMENTED',
        });
        await run(
          state: {'repo_full_name': 'o/r', 'consolidated_findings': 'f'},
          trigger: {'pr_number': 33},
        );
        expect(prClient.lastPrNumber, 33);
      },
    );
  });
}

/// Records what the deterministic close-out was handed.
class _RecordingFinalize {
  int calls = 0;
  String? lastSpaceId;
  String? lastEditorialNote;
  ReviewLevel? lastLevel;
  String? lastHeadSha;

  Future<Map<String, dynamic>> call({
    required String workspaceId,
    required String spaceId,
    String? editorialNote,
    ReviewLevel level = ReviewLevel.balanced,
    String? headSha,
  }) async {
    calls++;
    lastSpaceId = spaceId;
    lastEditorialNote = editorialNote;
    lastLevel = level;
    lastHeadSha = headSha;
    return {'verdict': 'comment', 'findings': 52};
  }
}

/// Subclasses [GitHubPrClient] so the body calls the real type. We never touch
/// the [Dio] — only [submitReview] is exercised and it's overridden.
class _FakeGitHubPrClient extends GitHubPrClient {
  _FakeGitHubPrClient() : super(Dio());

  GitHubReview? reviewToReturn;

  String? lastOwner;
  String? lastRepo;
  int? lastPrNumber;
  String? lastEvent;
  String? lastBody;

  @override
  Future<GitHubReview> submitReview(
    String owner,
    String repo, {
    required int prNumber,
    required String event,
    String? body,
    String? commitId,
    List<Map<String, dynamic>>? comments,
    CancelToken? cancelToken,
  }) async {
    lastOwner = owner;
    lastRepo = repo;
    lastPrNumber = prNumber;
    lastEvent = event;
    lastBody = body;
    return reviewToReturn!;
  }
}
