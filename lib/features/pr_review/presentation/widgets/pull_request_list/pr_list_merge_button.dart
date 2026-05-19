import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Merge method understood by the GitHub merge endpoint.
enum PrMergeMethod {
  /// Squash all commits into one.
  squash,

  /// Create a merge commit.
  merge,

  /// Rebase the commits onto the base branch.
  rebase;

  /// The API name expected by GitHub.
  String get apiName => switch (this) {
    PrMergeMethod.squash => 'squash',
    PrMergeMethod.merge => 'merge',
    PrMergeMethod.rebase => 'rebase',
  };
}

/// Merges [prNumber] in [repo] via the repo-scoped PR review repository.
///
/// The review repository resolves owner/repo from the active repo, so we set it
/// first — this is what lets a single multi-repo list merge the right PR. The
/// caller is responsible for refreshing the list and surfacing errors.
Future<void> performPrMerge(
  WidgetRef ref,
  Repo repo, {
  required int prNumber,
  required PrMergeMethod method,
  String? commitTitle,
  String? commitMessage,
}) async {
  // Await: setActive persists before updating state, and the repo-scoped
  // review repository only re-resolves once the active-repo state has changed.
  await ref.read(activeRepoIdProvider.notifier).setActive(repo.id);
  final repository = ref.read(prReviewRepositoryProvider);
  await repository.mergePullRequest(
    prNumber: prNumber,
    mergeMethod: method.apiName,
    commitTitle: method != PrMergeMethod.rebase ? commitTitle : null,
    commitMessage: method != PrMergeMethod.rebase ? commitMessage : null,
  );
}

/// The dark "Merge" action shown on ready rows. Opens the same merge
/// confirmation used on the PR detail page (method selector + commit message +
/// a warning when checks aren't green), then merges inline and refreshes.
class PrListMergeButton extends ConsumerWidget {
  /// Creates a [PrListMergeButton].
  const PrListMergeButton({super.key, required this.pr, required this.repo});

  /// The pull request to merge.
  final PullRequest pr;

  /// The repo the PR belongs to (sets the active repo before merging).
  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return CcButton(
      onPressed: () => _openDialog(context, ref),
      size: CcButtonSize.sm,
      variant: CcButtonVariant.primary,
      icon: LucideIcons.gitMerge,
      child: Text(l10n.merge),
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final merged = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => _MergeDialog(pr: pr, repo: repo),
    );
    if (merged == true) {
      ref.invalidate(prsByRepoProvider);
    }
  }
}

class _MergeDialog extends ConsumerStatefulWidget {
  const _MergeDialog({
    required this.pr,
    required this.repo,
  });

  final PullRequest pr;
  final Repo repo;

  @override
  ConsumerState<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<_MergeDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  PrMergeMethod _method = PrMergeMethod.squash;
  bool _merging = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _prefill() {
    switch (_method) {
      case PrMergeMethod.squash:
        _titleCtrl.text = widget.pr.title;
        _descCtrl.text = widget.pr.body;
      case PrMergeMethod.merge:
        _titleCtrl.text =
            'Merge pull request #${widget.pr.number} from ${widget.pr.headRef}';
        _descCtrl.text = widget.pr.title;
      case PrMergeMethod.rebase:
        _titleCtrl.clear();
        _descCtrl.clear();
    }
  }

  Future<void> _merge() async {
    if (_merging) {
      return;
    }
    setState(() => _merging = true);
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    try {
      await performPrMerge(
        ref,
        widget.repo,
        prNumber: widget.pr.number,
        method: _method,
        commitTitle: _titleCtrl.text,
        commitMessage: _descCtrl.text,
      );
      ref.read(prSelectionProvider.notifier).removeAll([widget.pr.number]);
      navigator.pop(true);
      toaster.show(l10n.pullRequestMerged, variant: CcToastVariant.success);
    } on Exception catch (e) {
      toaster.show(l10n.failedToMergePr('$e'), variant: CcToastVariant.danger);
      if (mounted) {
        setState(() => _merging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final showFields = _method != PrMergeMethod.rebase;
    final notGreen =
        widget.pr.checksStatus != PrChecksStatus.passing &&
        widget.pr.checksStatus != PrChecksStatus.none;

    return CcDialog(
      maxWidth: 460,
      title: l10n.mergePullRequest,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrTitleText(
              widget.pr.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textTertiary,
              ),
              leading: [
                TextSpan(
                  text: '#${widget.pr.number}  ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MethodSelector(
              method: _method,
              onChanged: (m) => setState(() {
                _method = m;
                _prefill();
              }),
            ),
            if (showFields) ...[
              const SizedBox(height: AppSpacing.sm),
              _CommitField(controller: _titleCtrl, hint: l10n.commitTitle),
              const SizedBox(height: AppSpacing.sm),
              _CommitField(
                controller: _descCtrl,
                hint: l10n.commitDescription,
                maxLines: 3,
              ),
            ],
            if (notGreen) ...[
              const SizedBox(height: AppSpacing.md),
              _ChecksWarning(status: widget.pr.checksStatus),
            ],
          ],
      ),
      actions: [
        CcButton(
          onPressed: _merging ? null : () => Navigator.of(context).pop(false),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _merging ? null : _merge,
          variant: notGreen
              ? CcButtonVariant.destructive
              : CcButtonVariant.primary,
          child: _merging
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CcSpinner(),
                )
              : Text(notGreen ? l10n.forceMergePullRequest : l10n.merge),
        ),
      ],
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.method, required this.onChanged});

  final PrMergeMethod method;
  final ValueChanged<PrMergeMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final labels = {
      PrMergeMethod.squash: l10n.squashAndMerge,
      PrMergeMethod.merge: l10n.createMergeCommit,
      PrMergeMethod.rebase: l10n.rebaseAndMerge,
    };
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          for (final m in PrMergeMethod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  margin: EdgeInsets.only(
                    right: m == PrMergeMethod.rebase ? 0 : AppSpacing.xs,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: m == method ? tokens.panel : Colors.transparent,
                    borderRadius: AppRadii.brSm,
                    border: Border.all(
                      color: m == method
                          ? tokens.borderSecondary
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[m]!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: m == method
                          ? tokens.textPrimary
                          : tokens.textSecondary,
                      fontWeight: m == method
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommitField extends StatelessWidget {
  const _CommitField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.textPlaceholder),
        ),
      ),
    );
  }
}

class _ChecksWarning extends StatelessWidget {
  const _ChecksWarning({required this.status});

  final PrChecksStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = status == PrChecksStatus.failing
        ? l10n.checksFailing
        : l10n.checksRunning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.bgWarningPrimary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderErrorSubtle),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 14,
            color: tokens.fgWarningPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textWarningPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
