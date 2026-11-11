import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/pipelines/pr_review_pipeline_template.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises [registerPrReviewBodies] — the single step body that posts a
/// consolidated review comment back to a PR. Pure control-flow over an
/// injectable [GitHubPrClient]: takes the repo slug + PR number from the
/// trigger, renders a message's placeholders escaped, surfaces failures for
/// missing findings / bad inputs and returns the review id on success.
void main() {
  late _FakeGitHubPrClient prClient;
  late PipelineBodyRegistry registry;
  late _RecordingFinalize finalize;
  late List<String?> actingUsers;
  late List<String?> attributedFor;
  late bool postsAsPerson;

  setUp(() {
    prClient = _FakeGitHubPrClient();
    finalize = _RecordingFinalize();
    actingUsers = [];
    attributedFor = [];
    postsAsPerson = false;
    registry = PipelineBodyRegistry();
    registerPrReviewBodies(
      registry,
      githubPrClientFor: (_, _, {actingUserId}) {
        actingUsers.add(actingUserId);
        return prClient;
      },
      automatedAttribution:
          ({required workspaceId, required owner, actingUserId}) async {
            attributedFor.add(actingUserId);
            return postsAsPerson
                ? (body) => '**Control Center** (for @octocat): $body'
                : null;
          },
      finalizeReview: finalize.call,
    );
  });

  PipelineContext ctx({
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
    String? message,
    bool dryRun = false,
  }) => PipelineContext(
    pipelineRunId: 'run-1',
    templateId: 'tpl-1',
    stepId: 'pr-comment',
    stepRunId: 'sr-1',
    workspaceId: 'ws-1',
    state: state,
    triggerPayload: trigger,
    dryRun: dryRun,
    step: message == null
        ? null
        : PipelineStepDefinition(
            id: 'pr-comment',
            kind: StepKind.listen,
            bodyKey: BuiltInBodyKeys.prReviewComment,
            config: PipelineNodeConfig(extras: {kPrCommentMessageKey: message}),
          ),
  );

  Future<StepResult> run({
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
    String? message,
    bool dryRun = false,
  }) => registry.body(BuiltInBodyKeys.prReviewComment)(
    ctx(state: state, trigger: trigger, message: message, dryRun: dryRun),
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

  const pr = {'repo_full_name': 'o/r', 'pr_number': 1};
  const z = '​';

  group('registerPrReviewBodies — validation failures', () {
    test('fails when the trigger names no repository', () async {
      final res = await run(
        state: {'consolidated_findings': 'x'},
        trigger: {'pr_number': 1},
      );
      expect(res.errorMessage, contains('names no pull request'));
    });

    test(
      'fails when prNumber is missing, non-numeric or not positive',
      () async {
        for (final number in [null, 'abc', 0, -3]) {
          final res = await run(
            state: {'consolidated_findings': 'x'},
            trigger: {'repo_full_name': 'o/r', 'pr_number': ?number},
          );
          expect(res.errorMessage, contains('names no pull request'));
        }
      },
    );

    test('fails when repoFullName is not a plain owner/repo', () async {
      for (final name in [
        'just-one-part',
        'o/r/x',
        'o/r)',
        '../r',
        'o/..',
        'o.x/r',
      ]) {
        final res = await run(
          state: {'consolidated_findings': 'x'},
          trigger: {'repo_full_name': name, 'pr_number': 1},
        );
        expect(res.errorMessage, contains('names no pull request'));
      }
      expect(prClient.lastBody, isNull);
    });

    test('the target comes from the trigger, never from state a step can '
        'rewrite', () async {
      final res = await run(
        state: {
          'repo_full_name': 'o/elsewhere',
          'pr_number': 99,
          'consolidated_findings': 'x',
        },
      );
      expect(res.errorMessage, contains('names no pull request'));

      prClient.reviewToReturn = GitHubReview.fromJson({
        'id': 2,
        'state': 'COMMENTED',
      });
      await run(
        state: {
          'repo_full_name': 'o/elsewhere',
          'pr_number': 99,
          'consolidated_findings': 'x',
        },
        trigger: pr,
      );
      expect(prClient.lastRepo, 'r');
      expect(prClient.lastPrNumber, 1);
    });

    test('fails when findings are missing or empty', () async {
      final res = await run(trigger: pr);
      expect(res.errorMessage, contains('No consolidated findings'));

      final res2 = await run(state: {'consolidated_findings': ''}, trigger: pr);
      expect(res2.errorMessage, contains('No consolidated findings'));
    });

    test('fails on a message placeholder the run cannot fill', () async {
      final res = await run(trigger: pr, message: 'Hello {{pr_title}}!');
      expect(res.errorMessage, contains('unresolved placeholders: pr_title'));
      expect(prClient.lastBody, isNull);
    });

    test('an author that is not a forge username fails the step', () async {
      for (final author in [null, '', 'org/team', 'a b', 'x' * 40, '@eve']) {
        final res = await run(
          trigger: {...pr, 'author': ?author},
          message: 'Thanks, @{{author}}!',
        );
        expect(res.errorMessage, contains('is not a GitHub username'));
      }
      expect(prClient.lastBody, isNull);
    });

    test('a dry run posts nothing', () async {
      final res = await run(
        state: {'consolidated_findings': 'f'},
        trigger: pr,
        dryRun: true,
      );
      expect(prClient.lastBody, isNull);
      expect(actingUsers, isEmpty);
      expect(res.isTerminal, isTrue);
      expect(res.mutatedState!['comment_dry_run'], 'f');
    });
  });

  group('registerPrReviewBodies — success', () {
    setUp(() {
      prClient.reviewToReturn = GitHubReview.fromJson({
        'id': 8,
        'state': 'COMMENTED',
      });
    });

    test('submits a COMMENT review and returns the review id', () async {
      prClient.reviewToReturn = GitHubReview.fromJson({
        'id': 99,
        'state': 'COMMENTED',
        'user': {'login': 'cc'},
        'submitted_at': '2026-01-01T00:00:00Z',
      });
      final res = await run(
        state: {'consolidated_findings': 'looks good but nits'},
        trigger: {'repo_full_name': 'acme/widget', 'pr_number': 42},
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

    test('accepts a numeric-string prNumber in the trigger', () async {
      await run(
        state: {'consolidated_findings': 'f'},
        trigger: {'repo_full_name': 'o/r', 'pr_number': '  7 '},
      );
      expect(prClient.lastPrNumber, 7);
    });

    test('posts bounded by the run\'s requester, never a payload\'s claim of '
        'one', () async {
      await run(
        state: {
          'consolidated_findings': 'f',
          // State is agent-writable: it must not pick who the comment is
          // bounded by.
          kPipelineRequestedByKey: 'mallory',
        },
        trigger: {...pr, kPipelineRequestedByKey: 'alice'},
      );
      expect(actingUsers, ['alice']);
      expect(attributedFor, ['alice']);
    });

    test('names Control Center when the token posts as a person', () async {
      postsAsPerson = true;
      await run(state: {'consolidated_findings': 'two nits'}, trigger: pr);
      expect(prClient.lastBody, '**Control Center** (for @octocat): two nits');
      expect(actingUsers, [null], reason: 'no requester: accountable human');
    });

    test('posts the step message, rendered against the run', () async {
      final res = await run(
        state: {'consolidated_findings': 'two nits'},
        trigger: {
          'repo_full_name': 'o/r',
          'pr_number': 12,
          'author': 'octocat',
        },
        message: 'Thanks, @{{author}}!\n\n{{consolidated_findings}}',
      );
      expect(prClient.lastBody, 'Thanks, @octocat!\n\ntwo nits');
      expect(prClient.lastPrNumber, 12);
      expect(res.mutatedState!['comment_review_id'], 8);
    });

    test('the author comes from the trigger, never from state', () async {
      await run(
        state: {'author': 'mallory'},
        trigger: {...pr, 'author': 'octocat'},
        message: 'Thanks, @{{author}}!',
      );
      expect(prClient.lastBody, 'Thanks, @octocat!');
    });

    test('coordinates render from the verified pull request', () async {
      await run(
        state: {'repo_owner': 'evil', 'repo_name': 'x'},
        trigger: {'repo_full_name': 'acme/widget', 'pr_number': 5},
        message:
            '[guide](https://github.com/{{repo_owner}}/{{repo_name}}/blob/'
            'main/CONTRIBUTING.md) for #{{pr_number}}',
      );
      expect(
        prClient.lastBody,
        '[guide](https://github.com/acme/widget/blob/main/CONTRIBUTING.md) '
        'for #5',
      );
    });

    test('other values are escaped as plain text, mentions inert', () async {
      await run(
        trigger: {
          ...pr,
          'pr_title': '*Fix* [it](https://evil) @org/team <img src=x>\n# h',
        },
        message: 'Reviewed: {{pr_title}}',
      );
      expect(
        prClient.lastBody,
        r'Reviewed: \*Fix\* \[it\]\(https://evil\) @' +
            z +
            r'org/team \<img src=x\> \# h',
      );
    });

    test('consolidated findings stay markdown with mentions made inert, in a '
        'message or posted as is', () async {
      const findings = '## Findings\n- cc @org/security\n- see `@Override`';
      const inert = '## Findings\n- cc @${z}org/security\n- see `@Override`';
      await run(
        state: {'consolidated_findings': findings},
        trigger: pr,
        message: 'Gate:\n\n{{consolidated_findings}}',
      );
      expect(prClient.lastBody, 'Gate:\n\n$inert');
      await run(state: {'consolidated_findings': findings}, trigger: pr);
      expect(prClient.lastBody, inert);
    });
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

/// Subclasses [GitHubPrClient] so the body calls the real type. The client is
/// never reached — only [submitReview] is exercised and it's overridden.
class _FakeGitHubPrClient extends GitHubPrClient {
  _FakeGitHubPrClient() : super(_NullHttpClient());

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

/// An rhttp client that is never reached — [_FakeGitHubPrClient] overrides
/// every method the pipeline body calls.
class _NullHttpClient implements RhttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('_FakeGitHubPrClient should not reach the network');
}
