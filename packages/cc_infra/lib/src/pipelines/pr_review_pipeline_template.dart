import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_infra/cc_infra.dart';

/// Registers the PR-review-specific step bodies.
///
/// [finalizeReview] backs `prReview.finalize`, the last step: it turns the
/// review nodes the reviewers filed into a verdict + `review_summary` and moves
/// the association to `awaiting_approval`. Without it a pipeline review left
/// findings scattered as messages, the PR's review tab had no verdict to show
/// and the Publish button had nothing to publish.
void registerPrReviewBodies(
  PipelineBodyRegistry registry, {
  required GitHubPrClient githubPrClient,
  Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    String? editorialNote,
    ReviewLevel level,
    String? headSha,
  })?
  finalizeReview,
}) {
  registry.registerBody(BuiltInBodyKeys.prReviewFinalize, (ctx) async {
    final finalize = finalizeReview;
    if (finalize == null) {
      return StepResult.failed(
        'prReviewFinalize: no review finalizer is wired on this host',
      );
    }
    final spaceId = ctx.optional<String>('review_space_id')?.trim() ?? '';
    if (spaceId.isEmpty) {
      return StepResult.failed(
        'prReviewFinalize: no review_space_id in state — the review space '
        'step must run before this one',
      );
    }
    try {
      final result = await finalize(
        workspaceId: ctx.workspaceId,
        spaceId: spaceId,
        editorialNote: _prose(ctx, 'consolidated_findings'),
        level: _resolveLevel(ctx),
        // Which commit this review actually read. Carried from the trigger so
        // a later push can be recognised as making the review stale.
        headSha: _prose(ctx, 'head_sha'),
      );
      return StepResult.ok(mutatedState: {'review_verdict': result});
    } on Object catch (e) {
      return StepResult.failed('prReviewFinalize: $e');
    }
  });

  registry.registerBody(BuiltInBodyKeys.prReviewComment, (ctx) async {
    final repoFullName = ctx.requireString('repo_full_name');
    // Accept an int (from a trigger payload) or a numeric string (e.g. a PR
    // number produced by an upstream bash step's stdout).
    final rawPrNumber =
        ctx.state['pr_number'] ?? ctx.triggerPayload?['pr_number'];
    final prNumber = rawPrNumber is int
        ? rawPrNumber
        : int.tryParse('$rawPrNumber'.trim());
    if (prNumber == null) {
      return StepResult.failed(
        'prReviewComment: pr_number missing or not numeric',
      );
    }
    final findings = _prose(ctx, 'consolidated_findings');
    if (findings == null) {
      return StepResult.failed('No consolidated findings to post.');
    }
    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      return StepResult.failed('Invalid repo_full_name: $repoFullName');
    }

    final review = await githubPrClient.submitReview(
      parts[0],
      parts[1],
      prNumber: prNumber,
      event: 'COMMENT',
      body: findings,
    );

    return StepResult.terminal(
      mutatedState: {
        'comment_review_id': review.id,
        'commented_at': DateTime.now().toIso8601String(),
      },
    );
  });
}

/// The review level this run is executing at.
///
/// Reads state first, then the trigger payload, then falls back to the default.
/// An unrecognized value falls back too rather than failing the step: the level
/// changes how much of a review is reported, and refusing to review at all
/// because a stored string was misspelled is the worse failure.
ReviewLevel _resolveLevel(PipelineContext ctx) {
  final raw =
      ctx.state[kReviewLevelStateKey] ??
      ctx.triggerPayload?[kReviewLevelStateKey];
  return ReviewLevel.fromWire(raw is String ? raw : null) ??
      ReviewLevel.defaultLevel;
}

/// Reads [key] from pipeline state as human-readable prose: the trimmed string
/// when there is one, null for anything else.
///
/// Deliberately NOT `ctx.optional<String>`, which THROWS on a type mismatch.
/// The consolidated report is prose an agent produced, so its type is only as
/// reliable as that agent's last turn — and it is the least important part of
/// the close-out. A run whose consolidation harvested an empty list failed
/// finalize outright with `Bad state: "consolidated_findings" not String (got
/// List)`, so 52 filed review findings never became a verdict and the PR's
/// review tab stayed empty. A missing note must cost the note, not the verdict.
String? _prose(PipelineContext ctx, String key) {
  final raw = ctx.state[key] ?? ctx.triggerPayload?[key];
  if (raw is! String) {
    return null;
  }
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}
