/// The commit half of the VS Code-style Source Control surface: a commit
/// message field joined to a split button whose primary action commits and
/// whose chevron opens the other commit variants.
///
/// Shared by the PR workbench tab and the messaging IDE panel so "commit" reads
/// and behaves identically wherever it appears. Like the `ScmGroup` /
/// `ScmFileRow` rows it sits above, it stays off Material (`flutter/widgets.dart`
/// plus `foundation.dart` for the commit-chord glyph).
library;

import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

/// The commit variants the commit box offers, mirroring VS Code's split-button
/// dropdown. Each maps to one `worktree.commitAndPush` call.
enum ScmCommitAction {
  /// Commit the staged index locally — no push.
  commit,

  /// Commit then push to the tracked branch.
  commitAndPush,

  /// Amend the previous commit (keeps its message when the box is empty).
  amend,

  /// Commit, integrate the remote branch (fetch + rebase), then push.
  commitAndSync,
}

/// One dropdown row: a [ScmCommitAction] with its label, icon and resolved
/// enablement.
typedef ScmCommitMenuItem = ({
  ScmCommitAction action,
  String label,
  IconData icon,
  bool enabled,
});

/// What replaces the Commit button when the working tree is clean.
///
/// VS Code swaps the button rather than leaving a disabled Commit: Publish
/// branch when the branch has no upstream, Sync changes when it is ahead or
/// behind. Null keeps the disabled Commit (the PR workbench tab).
class ScmIdleAction {
  /// Creates an [ScmIdleAction].
  const ScmIdleAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  /// Button label, already localized ("Publish branch", "Sync changes 2↓").
  final String label;

  /// Leading icon.
  final IconData icon;

  /// Runs the action.
  final VoidCallback onPressed;

  /// Whether the button accepts a press.
  final bool enabled;
}

/// The commit message field + Commit split button, pinned above the
/// changed-file groups. The primary button commits locally; the chevron opens
/// a [CcMenu] of the other variants (commit & push, amend, commit & sync).
/// Enablement is re-derived on every keystroke so an empty message greys the
/// commit actions out.
class ScmCommitBox extends StatelessWidget {
  /// Creates an [ScmCommitBox].
  const ScmCommitBox({
    super.key,
    required this.controller,
    required this.busy,
    required this.stagedCount,
    required this.unstagedCount,
    required this.canPush,
    required this.onAction,
    this.branch,
    this.idleAction,
    this.dense = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.sm,
    ),
  });

  /// The commit message being edited. A [Listenable], so the button enablement
  /// re-derives on every keystroke.
  final TextEditingController controller;

  /// Whether a commit is in flight (disables the field and the actions).
  final bool busy;

  /// How many files are in the git index.
  final int stagedCount;

  /// Working-tree changes that are not in the index, including untracked
  /// files. When this is non-zero and [stagedCount] is zero, commit stays
  /// available: the caller stages everything before committing (VS Code's
  /// `git.enableSmartCommit`). A non-zero [stagedCount] still commits only
  /// the index.
  final int unstagedCount;

  /// Whether a push target exists (a forge remote / PR head branch). False
  /// leaves the push variants out of the menu but keeps the local commit.
  final bool canPush;

  /// Runs the chosen commit variant.
  final ValueChanged<ScmCommitAction> onAction;

  /// Checked-out branch, used in the VS Code message placeholder
  /// (`Message (⌘↩ to commit on "main")`). Null keeps the shorter hint.
  final String? branch;

  /// Shown in place of the Commit button when there is nothing to commit.
  final ScmIdleAction? idleAction;

  /// Compact sizing (32px controls) for narrow surfaces like the IDE sidebar.
  final bool dense;

  /// Padding around the field + button pair.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding,
      // The controller is a Listenable — rebuild the button enablement as the
      // message text changes.
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final hasChanges = stagedCount > 0 || unstagedCount > 0;
          final hasMessage = controller.text.trim().isNotEmpty;
          bool enabled(ScmCommitAction action) {
            if (busy) {
              return false;
            }
            return switch (action) {
              ScmCommitAction.commit => hasChanges && hasMessage,
              ScmCommitAction.commitAndPush =>
                hasChanges && hasMessage && canPush,
              ScmCommitAction.commitAndSync =>
                hasChanges && hasMessage && canPush,
              // An amend can rewrite just the message, so a dirty tree is
              // not required — but there must be something to do. Unstaged
              // changes count: the caller stages them into the amend.
              ScmCommitAction.amend => hasChanges || hasMessage,
            };
          }

          // Commit is the primary action. Push lives in the menu, matching
          // VS Code's split button (a check, then Commit & push in the chevron).
          const primaryAction = ScmCommitAction.commit;
          final primaryEnabled = enabled(primaryAction);
          final branchName = branch?.trim() ?? '';
          final hint = branchName.isEmpty
              ? (hasChanges
                    ? l10n.commitMessageHint
                    : l10n.stageChangesToCommit)
              : l10n.commitMessageOnBranch(scmCommitShortcut(), branchName);
          final idle = !hasChanges ? idleAction : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextField(
                controller: controller,
                size: dense ? CcTextFieldSize.sm : CcTextFieldSize.md,
                hintText: hint,
                enabled: !busy,
                onSubmitted: (_) {
                  if (primaryEnabled) {
                    onAction(primaryAction);
                  }
                },
              ),
              SizedBox(height: dense ? AppSpacing.xs : AppSpacing.sm),
              if (idle != null)
                CcButton(
                  variant: CcButtonVariant.primary,
                  size: dense ? CcButtonSize.sm : CcButtonSize.md,
                  icon: idle.icon,
                  loading: busy,
                  fullWidth: true,
                  onPressed: !busy && idle.enabled ? idle.onPressed : null,
                  child: Text(idle.label),
                )
              else
                _CommitSplitButton(
                  label: busy ? l10n.saving : l10n.commit,
                  busy: busy,
                  dense: dense,
                  primaryEnabled: primaryEnabled,
                  onPrimary: () => onAction(primaryAction),
                  items: [
                    if (canPush)
                      (
                        action: ScmCommitAction.commitAndPush,
                        label: l10n.commitAndPush,
                        icon: AppIcons.upload,
                        enabled: enabled(ScmCommitAction.commitAndPush),
                      ),
                    if (canPush)
                      (
                        action: ScmCommitAction.commitAndSync,
                        label: l10n.commitAndSync,
                        icon: AppIcons.repeat,
                        enabled: enabled(ScmCommitAction.commitAndSync),
                      ),
                    (
                      action: ScmCommitAction.amend,
                      label: l10n.commitAmend,
                      icon: AppIcons.squarePen,
                      enabled: enabled(ScmCommitAction.amend),
                    ),
                  ],
                  onSelected: onAction,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A VS Code-style split button: a full-width primary [CcButton] joined to a
/// chevron segment that opens a [CcMenu] of alternative commit [items].
class _CommitSplitButton extends StatelessWidget {
  const _CommitSplitButton({
    required this.label,
    required this.busy,
    required this.dense,
    required this.primaryEnabled,
    required this.onPrimary,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final bool busy;
  final bool dense;
  final bool primaryEnabled;
  final VoidCallback onPrimary;
  final List<ScmCommitMenuItem> items;
  final ValueChanged<ScmCommitAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final primary = CcButtonTokens.primary(t);
    return Row(
      children: [
        Expanded(
          child: CcButton(
            variant: CcButtonVariant.primary,
            size: dense ? CcButtonSize.sm : CcButtonSize.md,
            icon: AppIcons.check,
            loading: busy,
            fullWidth: true,
            onPressed: primaryEnabled ? onPrimary : null,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 2),
        CcMenu(
          semanticLabel: l10n.moreCommitActions,
          targetAnchor: AlignmentDirectional.bottomEnd,
          followerAnchor: AlignmentDirectional.topEnd,
          minWidth: 200,
          items: [
            for (final item in items)
              CcMenuItem(
                label: item.label,
                icon: item.icon,
                enabled: item.enabled,
                onSelected: () => onSelected(item.action),
              ),
          ],
          target: _ChevronSegment(
            tokens: primary,
            enabled: !busy,
            t: t,
            dense: dense,
          ),
        ),
      ],
    );
  }
}

/// The chevron half of the split button — an inert visual matched to the
/// primary button's resting fill (the enclosing [CcMenu] owns the tap).
class _ChevronSegment extends StatelessWidget {
  const _ChevronSegment({
    required this.tokens,
    required this.enabled,
    required this.t,
    required this.dense,
  });

  final CcButtonTokens tokens;
  final bool enabled;
  final DesignSystemTokens t;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dense ? 28 : 34,
      // Matches the CcButtonSize.sm (32px) / .md (40px) primary button height.
      height: dense ? 32 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? tokens.bg : t.bgDisabled,
        borderRadius: AppRadii.brSm,
      ),
      child: Icon(
        AppIcons.chevronDown,
        size: dense ? 14 : 16,
        color: enabled ? tokens.fg : t.textDisabled,
      ),
    );
  }
}

/// The commit chord shown in the message placeholder. ⌘↩ on Apple platforms,
/// Ctrl+Enter everywhere else — the same primary modifier the rest of the
/// app uses.
String scmCommitShortcut() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => '⌘↩',
    _ => 'Ctrl+Enter',
  };
}

/// The count suffix on VS Code's sync button. Zeros are omitted so a branch
/// that is only behind reads `36↓`, not `36↓ 0↑`.
String scmSyncCounts({required int ahead, required int behind}) {
  return [if (behind > 0) '$behind↓', if (ahead > 0) '$ahead↑'].join(' ');
}

/// Whether Source Control should offer Create pull request.
///
/// Being in sync with the branch's own upstream is not "nothing to propose":
/// publishing drops [ahead] to 0 while the commits are still ahead of the
/// default branch, and that is the pull request. [aheadOfBase] is that count.
/// When the connected server does not report it, a published non-default
/// branch still qualifies.
bool scmCanOpenPullRequest({
  required bool hasForgeRemote,
  required bool hasExistingPr,
  required int dirtyFiles,
  required bool statusKnown,
  required bool hasUpstream,
  required int ahead,
  required int aheadOfBase,
  required bool aheadOfBaseKnown,
  required String branch,
}) {
  if (!hasForgeRemote) {
    return false;
  }
  if (hasExistingPr || dirtyFiles > 0) {
    return true;
  }
  if (!statusKnown) {
    return branch.startsWith(kSpaceScratchBranchPrefix);
  }
  if (aheadOfBaseKnown) {
    return aheadOfBase > 0;
  }
  if (ahead > 0) {
    return true;
  }
  return hasUpstream && !_scmIsDefaultBranch(branch);
}

bool _scmIsDefaultBranch(String branch) {
  final name = branch.trim();
  return name == 'main' || name == 'master';
}
