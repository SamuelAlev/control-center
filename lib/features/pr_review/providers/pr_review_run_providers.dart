import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The template every AI review runs on.
const String kPrReviewTemplateId = 'pr_review';

/// Identifies a pull request the way its review is actually findable: by the
/// repo it is in and its number.
///
/// NOT by forge id. A review keyed on `PullRequest.externalId` was keyed on
/// whatever that field happened to hold, and it held '' for every PR fetched
/// from the REST API — so the PR page looked up its own review by '' and found
/// either nothing or a different PR's row. `owner/repo#number` is what a human
/// would use, it is what the server's own resolver caches on, and it cannot be
/// empty.
typedef PrReviewKey = ({String repoFullName, int prNumber});

/// Every review-space association in the active workspace.
///
/// One subscription for the page rather than one per PR: the association is
/// found by scanning it, and a PR page opening its own watch per lookup would
/// be a subscription per tab for a list the workspace already streams.
final reviewSpacesForWorkspaceProvider =
    StreamProvider.autoDispose<List<ReviewSpaceAssociation>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const <ReviewSpaceAssociation>[]);
      }
      return ref
          .watch(reviewSpaceRepositoryProvider)
          .watchByWorkspace(workspaceId);
    });

/// The review space association for a pull request, matched by repo + number.
///
/// The by-forge-id lookup it replaces returned null for every PR whose
/// `externalId` was empty — which was all of them on the REST path — so a PR
/// with a finished review reported having none.
final prReviewAssociationProvider = Provider.autoDispose
    .family<ReviewSpaceAssociation?, PrReviewKey>((ref, key) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return null;
      }
      final all =
          ref.watch(reviewSpacesForWorkspaceProvider).asData?.value ??
          const <ReviewSpaceAssociation>[];
      for (final a in all) {
        if (a.repoFullName == key.repoFullName && a.prNumber == key.prNumber) {
          return a;
        }
      }
      return null;
    });

/// The latest `pr_review` run for ONE pull request, or null when none has run.
///
/// Matched on the run's trigger payload rather than on a run id handed back by
/// the start call: the tab has to find the run again on reopen, after a
/// restart, and on a machine that did not start it.
final prReviewRunProvider = Provider.autoDispose
    .family<PipelineRun?, PrReviewKey>((ref, key) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return null;
      }
      final runs =
          ref.watch(workspacePipelineRunsProvider(workspaceId)).asData?.value ??
          const <PipelineRun>[];
      PipelineRun? latest;
      for (final run in runs) {
        if (run.templateId != kPrReviewTemplateId) {
          continue;
        }
        final payload = run.triggerPayload;
        if (payload?['repo_full_name'] != key.repoFullName ||
            (payload?['pr_number'] as num?)?.toInt() != key.prNumber) {
          continue;
        }
        if (latest == null || run.startedAt.isAfter(latest.startedAt)) {
          latest = run;
        }
      }
      return latest;
    });

/// The pull requests whose review START is in flight — the window between
/// pressing "Ask AI" and the run turning up on the workspace run stream.
///
/// It exists because that window is long and silent. `startPrReview` creates
/// the run and then WAITS for the PR's worktree to finish provisioning before
/// it answers (up to two minutes on a cold checkout), so a caller that only
/// reacts to the reply spends that whole time showing the "no review yet" CTA
/// — which reads as "nothing happened" and invites a second start.
///
/// Not `autoDispose`: the flag has to outlive the widget that set it, because
/// the review tab is usually opened (and the pressed button disposed) while
/// the call is still out.
final prReviewStarterProvider =
    NotifierProvider<PrReviewStarter, Set<PrReviewKey>>(PrReviewStarter.new);

/// Starts AI reviews and reports which ones are still starting.
///
/// The ONE client-side implementation both entry points call — the PR header's
/// overflow menu and the review tab's button — so pressing either does the same
/// thing. It lives on a notifier rather than in a helper function because the
/// call outlives the widget that made it: a `WidgetRef` read after the tab
/// switch would be a read on a disposed widget.
class PrReviewStarter extends Notifier<Set<PrReviewKey>> {
  @override
  Set<PrReviewKey> build() => const {};

  /// Starts a review of [pr] at [level] (null means the workspace default).
  ///
  /// Returns the server's result map so the caller can tell `started` from
  /// `already_running`; throws what the RPC throws so the caller can report it.
  Future<Map<String, dynamic>> start({
    required PullRequest pr,
    ReviewLevel? level,
  }) async {
    final parts = pr.repoFullName.split('/');
    if (parts.length < 2) {
      // An Exception, not an Error: callers report this to the operator
      // through the same toast as any other failed start.
      throw FormatException('Not an owner/repo name', pr.repoFullName);
    }
    final key = (repoFullName: pr.repoFullName, prNumber: pr.number);
    state = {...state, key};
    try {
      final result = await ref
          .read(reviewStudioRepositoryProvider)
          .startReview(
            owner: parts.first,
            repo: parts.sublist(1).join('/'),
            prNumber: pr.number,
            level: level,
          );
      // Refresh the association so the hub flips from the intro CTA to the
      // live review body; progress then streams through the space.
      ref.invalidate(reviewSpaceForPrProvider(pr.externalId));
      return result;
    } finally {
      // Cleared either way: on success the run is already on the stream (the
      // engine starts it before the provisioning wait), and on failure the tab
      // must fall back to the CTA rather than spin for ever.
      state = {...state}..remove(key);
    }
  }
}

/// The newest artifact published into a review space, or null when the review
/// has not produced one yet.
///
/// The review's output is an ordinary conversation artifact — published by the
/// consolidating agent through `publish_artifact`, announced in the space as an
/// `artifact` message and rendered by the same viewer a chat bubble uses. The
/// review tab reads it the same way, so there is one artifact pipeline rather
/// than a review-shaped copy of it.
final prReviewArtifactProvider = Provider.autoDispose
    .family<WorkProduct?, String?>((ref, spaceId) {
      if (spaceId == null || spaceId.isEmpty) {
        return null;
      }
      final artifacts =
          ref.watch(spaceArtifactsProvider(spaceId)).asData?.value ??
          const <WorkProduct>[];
      return artifacts.isEmpty ? null : artifacts.first;
    });
