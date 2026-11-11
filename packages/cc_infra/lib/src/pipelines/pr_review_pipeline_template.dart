import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show neutralizeMentions;
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/src/pipelines/pr_comment_message.dart';

/// Registers the PR-review-specific step bodies.
///
/// [finalizeReview] backs `prReview.finalize`, the last step: it turns the
/// review nodes the reviewers filed into a verdict + `review_summary` and moves
/// the association to `awaiting_approval`. Without it a pipeline review left
/// findings scattered as messages, the PR's review tab had no verdict to show
/// and the Publish button had nothing to publish.
///
/// [githubPrClientFor] resolves the client `prReview.comment` posts on: a
/// one-repository token for the repo's owner, bounded by the person who
/// started the run (the run's requester) or else the workspace's accountable
/// human. [automatedAttribution] names Control Center in the comment when
/// that token posts under a person's account.
void registerPrReviewBodies(
  PipelineBodyRegistry registry, {
  required GitHubPrClient Function(
    String workspaceId,
    String owner, {
    String? actingUserId,
  })
  githubPrClientFor,
  AutomatedReviewAttribution? automatedAttribution,
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
    // Which pull request: the run's own, from its trigger payload (the
    // event, the webhook or the person who started it), never from state a
    // step can rewrite mid-run.
    final target = _verifiedTarget(ctx.triggerPayload);
    if (target == null) {
      return StepResult.failed(
        'prReviewComment: the run names no pull request (repo_full_name as '
        'owner/name and a positive pr_number in its trigger)',
      );
    }
    final (:owner, :name, :number) = target;
    // A step that sets a `message` posts that text (its `{{key}}`
    // placeholders rendered against the run, values escaped); otherwise it
    // posts the consolidated findings. This is how a built-in greets a
    // contributor or reports a gate decision without a shell step: the
    // sandbox and pipeline shell tokens only read. Mentions the bot's text
    // carries are inert either way.
    final message = ctx.step?.config.extras[kPrCommentMessageKey];
    final String? findings;
    if (message is String && message.trim().isNotEmpty) {
      final rendered = renderPrCommentMessage(
        message,
        state: ctx.renderState,
        trigger: ctx.triggerPayload,
        forge: ForgeHost.github,
        owner: owner,
        name: name,
        number: number,
      );
      final error = rendered.error;
      if (error != null) {
        return StepResult.failed(
          'prReviewComment: step "${ctx.stepId}" message: $error',
        );
      }
      final text = rendered.text ?? '';
      findings = text.isEmpty ? null : text;
    } else {
      final prose = _prose(ctx, 'consolidated_findings');
      findings = prose == null ? null : neutralizeMentions(prose);
    }
    if (findings == null) {
      return StepResult.failed('No consolidated findings to post.');
    }
    // Dry run: name what would be posted and touch nothing on the forge.
    if (ctx.dryRun) {
      return StepResult.terminal(mutatedState: {'comment_dry_run': findings});
    }

    // Only the engine writes the requester; a payload cannot name one.
    final requester = switch (ctx.triggerPayload?[kPipelineRequestedByKey]) {
      final String id when id.isNotEmpty => id,
      _ => null,
    };
    final attribute = await automatedAttribution?.call(
      workspaceId: ctx.workspaceId,
      owner: owner,
      actingUserId: requester,
    );
    final review =
        await githubPrClientFor(
          ctx.workspaceId,
          owner,
          actingUserId: requester,
        ).submitReview(
          owner,
          name,
          prNumber: number,
          event: 'COMMENT',
          body: attribute == null ? findings : attribute(findings),
        );

    return StepResult.terminal(
      mutatedState: {
        'comment_review_id': review.id,
        'commented_at': DateTime.now().toIso8601String(),
      },
    );
  });
}

/// The pull request a run's [trigger] payload names: `repo_full_name` as a
/// plain GitHub `owner/name` and a positive `pr_number` (an int, or its
/// digits), or null when it names none.
({String owner, String name, int number})? _verifiedTarget(
  Map<String, dynamic>? trigger,
) {
  final fullName = trigger?['repo_full_name'];
  final rawNumber = trigger?['pr_number'];
  final number = rawNumber is int
      ? rawNumber
      : int.tryParse('${rawNumber ?? ''}'.trim());
  if (fullName is! String || number == null || number <= 0) {
    return null;
  }
  // A GitHub owner is letters, digits and `-`; a name adds `_` and `.` but is
  // never `.` or `..` (which would walk the API path).
  final match = RegExp(
    r'^([A-Za-z0-9-]+)/([A-Za-z0-9_.-]+)$',
  ).firstMatch(fullName.trim());
  if (match == null || match[2] == '.' || match[2] == '..') {
    return null;
  }
  return (owner: match[1]!, name: match[2]!, number: number);
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
