import 'package:cc_domain/cc_domain.dart' show newIdempotencyKey, runBulkAction;
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_stack_ordering.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_stack_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/features/user_profiles/providers/org_members_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The floating batch-action bar shown while PRs are selected in the
/// repo-grouped table. It reports the selection count and offers three bulk
/// actions over the selected pull requests — **close**, **assign to…** and
/// **ask for review…** — plus a clear button.
///
/// Each action fans out over the selection with [runBulkAction] (per-item
/// isolation: one PR failing never aborts the batch), resolving every selected
/// key back to its `(pr, repo)` and dispatching through the repo-scoped review
/// repository so a multi-repo selection hits the right repo per item.
class PrBulkActionBar extends ConsumerWidget {
  /// Creates a [PrBulkActionBar].
  const PrBulkActionBar({super.key, required this.allItems});

  /// Every item currently in the table, so selected keys resolve back to their
  /// `(pr, repo)` even after filters change.
  final List<PrInboxItem> allItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(prTableSelectionProvider);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final selected = [
      for (final item in allItems)
        if (selection.contains(item.key)) item,
    ];
    final visible = selection.isNotEmpty;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: IgnorePointer(
          ignoring: !visible,
          child: Container(
            decoration: BoxDecoration(
              // A solid dark surface in both themes (fg inverts to near-white
              // in dark mode, which made a translucent bar white-on-white).
              color: tokens.bgPrimarySolid,
              borderRadius: AppRadii.brMd,
              boxShadow: AppShadows.golden,
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.countSelected(selection.length),
                  style: CcTypography.caption.copyWith(color: tokens.textWhite),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 1,
                  height: 20,
                  color: tokens.fgWhite.withAlpha(40),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => _confirmAndClose(context, ref, selected),
                  variant: CcButtonVariant.destructive,
                  size: CcButtonSize.sm,
                  icon: AppIcons.x,
                  child: Text(l10n.close),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => _assign(context, ref, selected),
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.userPlus,
                  child: Text(l10n.assignTo),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => _requestReview(context, ref, selected),
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.eye,
                  child: Text(l10n.askForReview),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcButton(
                  onPressed: selected.length < 2
                      ? null
                      : () => _createStack(context, ref, selected),
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.layers,
                  child: Text(l10n.createStack),
                ),
                const SizedBox(width: AppSpacing.xs),
                _DarkBarButton(
                  icon: AppIcons.x,
                  onTap: () =>
                      ref.read(prTableSelectionProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndClose(
    BuildContext context,
    WidgetRef ref,
    List<PrInboxItem> items,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.closePrsConfirmTitle,
        content: Text(l10n.closePrsConfirmBody(items.length)),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.close),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await _runOnSelected(
      context: context,
      ref: ref,
      items: items,
      op: (repo, item) => repo.closePullRequest(prNumber: item.pr.number),
      toast: l10n.closedCountPrs,
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    List<PrInboxItem> items,
  ) async {
    final l10n = AppLocalizations.of(context);
    final logins = await _pickUsers(context, title: l10n.assignTo);
    if (logins == null || logins.isEmpty || !context.mounted) {
      return;
    }
    await _runOnSelected(
      context: context,
      ref: ref,
      items: items,
      op: (repo, item) =>
          repo.addAssignees(prNumber: item.pr.number, logins: logins),
      toast: l10n.assignedCountPrs,
    );
  }

  Future<void> _requestReview(
    BuildContext context,
    WidgetRef ref,
    List<PrInboxItem> items,
  ) async {
    final l10n = AppLocalizations.of(context);
    final logins = await _pickUsers(context, title: l10n.askForReview);
    if (logins == null || logins.isEmpty || !context.mounted) {
      return;
    }
    await _runOnSelected(
      context: context,
      ref: ref,
      items: items,
      op: (repo, item) =>
          repo.requestReviewers(prNumber: item.pr.number, userLogins: logins),
      toast: l10n.requestedReviewCountPrs,
    );
  }

  Future<List<String>?> _pickUsers(
    BuildContext context, {
    required String title,
  }) {
    return showCcDialog<List<String>>(
      context: context,
      builder: (ctx) => _BulkUserPickerDialog(title: title),
    );
  }

  /// Creates a GitHub pull request stack from the selection. One call, not a
  /// fan-out: the selection must sit in ONE repo and chain by branch (each
  /// PR's base is the previous PR's head — [orderPrChain] computes that
  /// order, so the user's click order doesn't matter). A confirm dialog shows
  /// the computed bottom-to-top order before anything is sent.
  Future<void> _createStack(
    BuildContext context,
    WidgetRef ref,
    List<PrInboxItem> items,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }

    final repoIds = {for (final item in items) item.repo.id};
    if (items.length < 2 || repoIds.length != 1) {
      toaster.show(
        l10n.createStackInvalidSelection,
        variant: CcToastVariant.danger,
      );
      return;
    }
    final repo = items.first.repo;

    final stacks = await ref.read(prStacksForRepoProvider(repo).future);
    final stackedNumbers = {
      for (final stack in stacks)
        for (final entry in stack.pullRequests) entry.number,
    };
    if (items.any((item) => stackedNumbers.contains(item.pr.number))) {
      if (!context.mounted) {
        return;
      }
      toaster.show(
        l10n.createStackAlreadyStacked,
        variant: CcToastVariant.danger,
      );
      return;
    }

    final ordered = orderPrChain([for (final item in items) item.pr]);
    if (ordered == null) {
      toaster.show(l10n.createStackNotAChain, variant: CcToastVariant.danger);
      return;
    }

    if (!context.mounted) {
      return;
    }
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.createStackDialogTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createStackDialogBody(ordered.length)),
            const SizedBox(height: AppSpacing.sm),
            for (final pr in ordered)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('#${pr.number} · ${pr.title}'),
              ),
          ],
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: AppIcons.layers,
            child: Text(l10n.createStack),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final repository = ref.read(
      repoScopedPrReviewRepositoryProvider((
        workspaceId: workspaceId,
        repoFullName: repo.fullName,
      )),
    );
    try {
      await repository.createStack(
        prNumbers: [for (final pr in ordered) pr.number],
      );
    } on Exception {
      if (context.mounted) {
        toaster.show(l10n.stackCreationFailed, variant: CcToastVariant.danger);
      }
      return;
    }
    ref.read(prTableSelectionProvider.notifier).clear();
    ref.invalidate(prStacksForRepoProvider(repo));
    ref.invalidate(prsByRepoProvider);
    toaster.show(l10n.stackCreated, variant: CcToastVariant.success);
  }

  /// Fans [op] out over [items] with per-item isolation, drops the succeeded
  /// keys from the selection, refreshes the queue and toasts the count.
  Future<void> _runOnSelected({
    required BuildContext context,
    required WidgetRef ref,
    required List<PrInboxItem> items,
    required Future<void> Function(PrReviewRepository repo, PrInboxItem item)
    op,
    required String Function(int count) toast,
  }) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || items.isEmpty) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);

    // One logical bulk action; each item runs under its own derived key. Close
    // / assign / request-review are naturally idempotent on GitHub (a re-close
    // or re-request is a no-op), so a same-item retry is safe.
    final outcome = await runBulkAction<PrInboxItem>(
      bulkKey: newIdempotencyKey(),
      items: items,
      itemId: (item) => item.key,
      action: (item, _) {
        final repo = ref.read(
          repoScopedPrReviewRepositoryProvider((
            workspaceId: workspaceId,
            repoFullName: item.repo.fullName,
          )),
        );
        return op(repo, item);
      },
    );

    ref.read(prTableSelectionProvider.notifier).removeAll([
      for (final item in outcome.succeeded) item.key,
    ]);
    ref.invalidate(prsByRepoProvider);

    if (!context.mounted) {
      return;
    }
    if (outcome.successCount > 0) {
      toaster.show(
        toast(outcome.successCount),
        variant: CcToastVariant.success,
      );
    }
    if (outcome.failed.isNotEmpty) {
      toaster.show(
        l10n.bulkActionPartialFailure(outcome.failed.length),
        variant: CcToastVariant.danger,
      );
    }
  }
}

class _DarkBarButton extends StatelessWidget {
  const _DarkBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: tokens.fgWhite),
      ),
    );
  }
}

/// A searchable, multi-select picker over the workspace's org members, shown
/// as a dialog for the bulk "assign to" / "ask for review" actions. Pops the
/// chosen logins (empty/null if cancelled).
class _BulkUserPickerDialog extends ConsumerStatefulWidget {
  const _BulkUserPickerDialog({required this.title});

  final String title;

  @override
  ConsumerState<_BulkUserPickerDialog> createState() =>
      _BulkUserPickerDialogState();
}

class _BulkUserPickerDialogState extends ConsumerState<_BulkUserPickerDialog> {
  final _selected = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final membersAsync = ref.watch(orgMembersProvider);
    final q = _query.trim().toLowerCase();
    final members = [
      for (final m in membersAsync.value ?? const <GitHubUser>[])
        if (q.isEmpty ||
            m.login.toLowerCase().contains(q) ||
            (m.name?.toLowerCase().contains(q) ?? false))
          m,
    ];

    return CcDialog(
      title: widget.title,
      content: SizedBox(
        width: 360,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTextField(
              autofocus: true,
              hintText: l10n.searchUsers,
              prefix: Icon(
                AppIcons.search,
                size: 16,
                color: tokens.textTertiary,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: membersAsync.isLoading && !membersAsync.hasValue
                  ? const Center(child: CcSpinner())
                  : members.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noMatchingUsers,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final checked = _selected.contains(m.login);
                        return CcTappable(
                          onPressed: () => setState(() {
                            if (!_selected.add(m.login)) {
                              _selected.remove(m.login);
                            }
                          }),
                          builder: (context, states) {
                            final hovered = states.contains(
                              WidgetState.hovered,
                            );
                            return Container(
                              color: hovered
                                  ? tokens.hover
                                  : const Color(0x00000000),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  PickerCheckBox(
                                    selected: checked,
                                    hovered: hovered,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  GitHubUserAvatar(
                                    login: m.login,
                                    avatarUrl: m.avatarUrl,
                                    size: 20,
                                    showHoverCard: false,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      m.loginWithName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: tokens.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          variant: CcButtonVariant.primary,
          child: Text(l10n.apply),
        ),
      ],
    );
  }
}
