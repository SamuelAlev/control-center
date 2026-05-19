import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_deployment_previews_use_case.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _detector = DetectDeploymentPreviewsUseCase();

/// Derives the live deployment previews for a PR by running the detector over
/// the structured commit statuses (primary) and the PR body + issue comments
/// (fallback). Recomputes whenever any source stream ticks — a redeploy that
/// posts a fresh status/comment updates the previews in place.
///
/// Returns an empty list (not loading) once the primary source has resolved so
/// the review surface simply shows no preview tab when there is none.
final prPreviewDeploymentsProvider = Provider.autoDispose
    .family<List<DeploymentPreview>, PrRef>((ref, pr) {
      final statusesAsync = ref.watch(prCommitStatusesProvider(pr));
      final comments = ref.watch(prIssueCommentsProvider(pr)).value;
      final prEntity = ref.watch(prDetailProvider(pr)).value;

      // The Statuses stream is the primary signal; hold off until it has first
      // resolved (data OR error) so a comment-only false positive can't flash a
      // tab the more-authoritative status would supersede. Once it errors we
      // still fall back to comment detection rather than show nothing.
      if (statusesAsync.isLoading && !statusesAsync.hasValue) {
        return const [];
      }
      final statuses = statusesAsync.value ?? const [];

      final texts = <String>[
        if (prEntity != null && prEntity.body.isNotEmpty) prEntity.body,
        for (final c in comments ?? const <IssueComment>[]) c.body,
      ];

      return _detector.detect(statuses: statuses, texts: texts);
    });
