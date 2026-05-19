import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the viewer may move [pr] between draft and ready-for-review.
///
/// Three conditions, all necessary: the pull request is still open, the forge
/// can toggle draft state after creation (`draftToggle` — Bitbucket has no
/// draft concept at all), and the viewer authored it or holds write access.
///
/// Shared by the Overview action cluster, the Diff toolbar and the overflow
/// menu so the affordance appears and disappears in the same conditions
/// everywhere: three copies of this predicate would drift.
bool canToggleDraft(WidgetRef ref, PullRequest pr, PrRef prRef) {
  if (!pr.isOpen) {
    return false;
  }
  final repo = ref.watch(prRepoRowProvider(prRef));
  if (repo == null) {
    return false;
  }
  if (!ref.watch(capabilitiesForProvider(repo.forge)).draftToggle) {
    return false;
  }
  final login = ref.watch(currentUserLoginForPrProvider(prRef));
  final isAuthor = login.isNotEmpty && pr.author?.login.toLowerCase() == login;
  if (isAuthor) {
    return true;
  }
  return ref
          .watch(
            repoPermissionProvider((
              owner: repo.remoteOwner,
              repo: repo.remoteName,
            )),
          )
          .whenOrNull(data: (perm) => perm == 'admin' || perm == 'write') ??
      false;
}

/// The primary action on a draft pull request: take it out of draft so
/// reviewers are notified and required checks start gating the merge.
///
/// Sits in the slot the Review button occupies on a non-draft PR — on a draft
/// the viewer owns, reviewing is not the next step; publishing is.
class MarkReadyForReviewButton extends ConsumerStatefulWidget {
  /// Creates a [MarkReadyForReviewButton] for [pr].
  const MarkReadyForReviewButton({super.key, required this.pr, required this.prRef});

  /// The draft pull request to mark ready.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number).
  final PrRef prRef;

  @override
  ConsumerState<MarkReadyForReviewButton> createState() =>
      _MarkReadyForReviewButtonState();
}

class _MarkReadyForReviewButtonState
    extends ConsumerState<MarkReadyForReviewButton> {
  bool _busy = false;

  Future<void> _markReady() async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);

    if (!await confirmDraftChange(
      context,
      title: l10n.markReadyForReview,
      body: l10n.markReadyForReviewConfirm,
    )) {
      return;
    }
    if (!mounted) {
      return;
    }

    final repo = ref.read(prRepositoryProvider(widget.prRef));
    if (repo == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await repo.setPullRequestDraft(
        prNumber: widget.prRef.number,
        draft: false,
      );
      toaster.show(
        l10n.pullRequestMarkedReady,
        variant: CcToastVariant.success,
      );
    } on Exception catch (e) {
      toaster.show(
        l10n.failedToMarkPrReady('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcButton(
      onPressed: _busy ? null : _markReady,
      size: CcButtonSize.sm,
      icon: AppIcons.gitPullRequest,
      loading: _busy,
      child: Text(l10n.markReadyForReview),
    );
  }
}

/// Asks the viewer to confirm a move between draft and ready-for-review.
///
/// BOTH directions are confirmed, and neither is a formality. Going back to
/// draft dismisses the pull request's pending review requests, which a second
/// click cannot restore. Coming out of draft notifies every reviewer and
/// triggers whatever automation watches for a ready pull request — sending that
/// on a mis-click is not undone by converting straight back.
///
/// Returns true only on an explicit confirm; a dismissed dialog is a no.
Future<bool> confirmDraftChange(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: title,
      content: Text(body),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Converts [pr] back to a draft after confirming.
///
/// Returns true when the conversion was made, so a caller holding an overlay
/// can react. Reports its own outcome as a toast.
Future<bool> confirmAndConvertToDraft(
  BuildContext context,
  WidgetRef ref,
  PullRequest pr,
  PrRef prRef,
) async {
  final l10n = AppLocalizations.of(context);
  final toaster = CcToastScope.of(context);

  if (!await confirmDraftChange(
    context,
    title: l10n.convertToDraft,
    body: l10n.convertToDraftConfirm,
  )) {
    return false;
  }

  final repo = ref.read(prRepositoryProvider(prRef));
  if (repo == null) {
    return false;
  }
  try {
    await repo.setPullRequestDraft(prNumber: prRef.number, draft: true);
    toaster.show(
      l10n.pullRequestConvertedToDraft,
      variant: CcToastVariant.success,
    );
    return true;
  } on Exception catch (e) {
    toaster.show(
      l10n.failedToConvertPrToDraft('$e'),
      variant: CcToastVariant.danger,
    );
    return false;
  }
}
