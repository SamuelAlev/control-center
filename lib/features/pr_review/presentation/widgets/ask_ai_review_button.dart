import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A button that triggers an AI-powered code review pipeline for a pull request.
class AskAiReviewButton extends ConsumerStatefulWidget {
  /// Creates an [AskAiReviewButton].
  const AskAiReviewButton({super.key, required this.pr});

  /// The pull request to review.
  final PullRequest pr;

  @override
  ConsumerState<AskAiReviewButton> createState() => _AskAiReviewButtonState();
}

class _AskAiReviewButtonState extends ConsumerState<AskAiReviewButton> {
  bool _loading = false;

  Future<void> _startReview() async {
    if (_loading) {
      return;
    }

    final workspace = ref.read(activeWorkspaceProvider);
    final repo = ref.read(activeRepoProvider);
    if (workspace == null || repo == null) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        AppLocalizations.of(context).noActiveWorkspace,
        variant: CcToastVariant.danger,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Start the PR review pipeline — this orchestrates the full review
      // flow (repo clone, brief, specialist dispatch) instead of the old
      // conversation-based approach.
      final engine = ref.read(pipelineEngineProvider);
      final run = await engine.start(
        'pr_review',
        workspaceId: workspace.id,
        triggerEventType: 'manual',
        triggerPayload: {
          'workspaceId': workspace.id,
          'repoOwner': repo.githubOwner,
          'repoName': repo.githubRepoName,
          'repoFullName': repo.fullName,
          'prNumber': widget.pr.number,
          'prNodeId': widget.pr.nodeId,
          'prTitle': widget.pr.title,
          'author': widget.pr.author?.login ?? '',
        },
      );
      if (!mounted) {
        return;
      }

      if (run == null) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedToStartAiReview('duplicate run'),
          variant: CcToastVariant.danger,
        );
        return;
      }

      // Navigate to the pipeline run detail screen so the user can
      // watch the review progress in real time.
      context.go(pipelineRunRoute(run.id));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        AppLocalizations.of(context).failedToStartAiReview('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      message: l10n.askAiReviewDescription,
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.bottomCenter,
      child: CcButton(
        onPressed: _loading ? null : _startReview,
        size: CcButtonSize.sm,
        variant: CcButtonVariant.secondary,
        loading: _loading,
        icon: LucideIcons.sparkles,
        child: Text(l10n.askAi),
      ),
    );
  }
}
