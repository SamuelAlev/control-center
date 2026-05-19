import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A button that starts the canonical AI review (the Review Hub flow):
/// deterministic area computation → reviewer fan-out into the PR channel →
/// structured walkthrough → verdict. Stays on the review tab — progress
/// streams through the channel and the association status.
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
    final parts = widget.pr.repoFullName.split('/');
    if (parts.length < 2) {
      return;
    }
    final owner = parts.first;
    final repo = parts.sublist(1).join('/');

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(reviewStudioRepositoryProvider)
          .startReview(owner: owner, repo: repo, prNumber: widget.pr.number);
      if (!mounted) {
        return;
      }
      // Refresh the association so the hub flips from the intro CTA to the
      // live review body; progress then streams through the channel.
      ref.invalidate(reviewChannelForPrProvider(widget.pr.externalId));
      final status = result['status'];
      final toast = CcToastScope.maybeOf(context);
      if (status == 'already_running') {
        toast?.show(
          AppLocalizations.of(context).reviewHubAlreadyRunning,
          variant: CcToastVariant.warning,
        );
      } else {
        toast?.show(
          AppLocalizations.of(context).reviewHubStarted,
          variant: CcToastVariant.success,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
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
      child: CcButton(
        onPressed: _loading ? null : _startReview,
        size: CcButtonSize.sm,
        variant: CcButtonVariant.secondary,
        loading: _loading,
        icon: AppIcons.sparkles,
        child: Text(l10n.askAi),
      ),
    );
  }
}
