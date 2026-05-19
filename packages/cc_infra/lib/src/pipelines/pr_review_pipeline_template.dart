import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/cc_infra.dart';

/// Registers the PR-review-specific step bodies. The clone-the-branch step
/// is no longer here — that's a `pipeline.bashScript` node now. Only the
/// "post PR comment" body still lives in code because it has to call the
/// GitHub PR client.
void registerPrReviewBodies(
  PipelineBodyRegistry registry, {
  required GitHubPrClient githubPrClient,
}) {
  registry.registerBody(BuiltInBodyKeys.prReviewComment, (ctx) async {
    final repoFullName = ctx.requireString('repoFullName');
    // Accept an int (from a trigger payload) or a numeric string (e.g. a PR
    // number produced by an upstream bash step's stdout).
    final rawPrNumber = ctx.state['prNumber'] ?? ctx.triggerPayload?['prNumber'];
    final prNumber = rawPrNumber is int
        ? rawPrNumber
        : int.tryParse('$rawPrNumber'.trim());
    if (prNumber == null) {
      return StepResult.failed('prReviewComment: prNumber missing or not numeric');
    }
    final findings = ctx.optional<String>('consolidatedFindings');
    if (findings == null || findings.isEmpty) {
      return StepResult.failed('No consolidated findings to post.');
    }
    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      return StepResult.failed('Invalid repoFullName: $repoFullName');
    }

    final review = await githubPrClient.submitReview(
      parts[0],
      parts[1],
      prNumber: prNumber,
      event: 'COMMENT',
      body: findings,
    );

    return StepResult.terminal(mutatedState: {
      'commentReviewId': review.id,
      'commentedAt': DateTime.now().toIso8601String(),
    });
  });
}
