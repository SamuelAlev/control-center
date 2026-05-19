import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
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

  setUp(() {
    prClient = _FakeGitHubPrClient();
    registry = PipelineBodyRegistry();
    registerPrReviewBodies(registry, githubPrClient: prClient);
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

  group('registerPrReviewBodies — validation failures', () {
    test(
      'throws when repoFullName is missing (requireString is strict)',
      () async {
        // requireString raises a StateError before the body reaches its own
        // repoFullName handling — the pipeline engine surfaces this as a failed
        // step upstream.
        expect(
          () => run(state: {'prNumber': 1, 'consolidatedFindings': 'x'}),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('fails when prNumber is missing entirely', () async {
      final res = await run(
        state: {'repoFullName': 'o/r', 'consolidatedFindings': 'x'},
      );
      expect(res.errorMessage, contains('prNumber missing'));
    });

    test('fails when prNumber is non-numeric', () async {
      final res = await run(
        state: {
          'repoFullName': 'o/r',
          'prNumber': 'abc',
          'consolidatedFindings': 'x',
        },
      );
      expect(res.errorMessage, contains('prNumber missing'));
    });

    test('fails when findings are missing or empty', () async {
      final res = await run(state: {'repoFullName': 'o/r', 'prNumber': 1});
      expect(res.errorMessage, contains('No consolidated findings'));

      final res2 = await run(
        state: {
          'repoFullName': 'o/r',
          'prNumber': 1,
          'consolidatedFindings': '',
        },
      );
      expect(res2.errorMessage, contains('No consolidated findings'));
    });

    test('fails when repoFullName is not owner/repo', () async {
      final res = await run(
        state: {
          'repoFullName': 'just-one-part',
          'prNumber': 1,
          'consolidatedFindings': 'x',
        },
      );
      expect(res.errorMessage, contains('Invalid repoFullName'));
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
          'repoFullName': 'acme/widget',
          'prNumber': 42,
          'consolidatedFindings': 'looks good but nits',
        },
      );

      expect(prClient.lastOwner, 'acme');
      expect(prClient.lastRepo, 'widget');
      expect(prClient.lastPrNumber, 42);
      expect(prClient.lastEvent, 'COMMENT');
      expect(prClient.lastBody, 'looks good but nits');
      expect(res.isTerminal, isTrue);
      expect(res.mutatedState!['commentReviewId'], 99);
      expect(res.mutatedState!['commentedAt'], isNotNull);
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
            'repoFullName': 'o/r',
            'prNumber': '  7 ',
            'consolidatedFindings': 'f',
          },
        );
        expect(prClient.lastPrNumber, 7);
        expect(res.mutatedState!['commentReviewId'], 5);
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
          state: {'repoFullName': 'o/r', 'consolidatedFindings': 'f'},
          trigger: {'prNumber': 33},
        );
        expect(prClient.lastPrNumber, 33);
      },
    );
  });
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
