/// The commit half of the VS Code-style Source Control surface: a commit
/// message field joined to a split button whose primary action commits (and
/// pushes) and whose chevron opens the other commit variants.
///
/// Shared by the PR workbench tab and the messaging IDE panel so "commit" reads
/// and behaves identically wherever it appears. Like the `ScmGroup` /
/// `ScmFileRow` rows it sits above, it is cc_ui-pure (`flutter/widgets.dart`
/// only).
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The commit variants the commit box offers, mirroring VS Code's split-button
/// dropdown. Each maps to one `worktree.commitAndPush` call.
enum ScmCommitAction {
  /// Commit the staged index locally — no push.
  commit,

  /// Commit then push to the tracked branch (the default primary action).
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

/// The commit message field + "Commit & push" split button, pinned above the
/// changed-file groups. The primary button pushes; the chevron opens a [CcMenu]
/// of the other commit variants (commit-only, amend, commit & sync).
/// Enablement is re-derived on every keystroke so an empty message greys the
/// commit actions out.
class ScmCommitBox extends StatelessWidget {
  /// Creates an [ScmCommitBox].
  const ScmCommitBox({
    super.key,
    required this.controller,
    required this.busy,
    required this.stagedCount,
    required this.canPush,
    required this.onAction,
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

  /// How many files are staged — nothing but an amend can run at zero.
  final int stagedCount;

  /// Whether a push target exists (a forge remote / PR head branch). False
  /// leaves the push variants disabled but keeps the local commit available.
  final bool canPush;

  /// Runs the chosen commit variant.
  final ValueChanged<ScmCommitAction> onAction;

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
          final hasStaged = stagedCount > 0;
          final hasMessage = controller.text.trim().isNotEmpty;
          bool enabled(ScmCommitAction action) {
            if (busy) {
              return false;
            }
            return switch (action) {
              ScmCommitAction.commit => hasStaged && hasMessage,
              ScmCommitAction.commitAndPush =>
                hasStaged && hasMessage && canPush,
              ScmCommitAction.commitAndSync =>
                hasStaged && hasMessage && canPush,
              // An amend can rewrite just the message, so staged changes are
              // not required — but there must be something to do.
              ScmCommitAction.amend => hasStaged || hasMessage,
            };
          }

          // With no push target the split button commits locally instead of
          // offering a push it cannot perform — the same button, one honest
          // action, rather than a permanently disabled primary.
          final primaryAction = canPush
              ? ScmCommitAction.commitAndPush
              : ScmCommitAction.commit;
          final primaryEnabled = enabled(primaryAction);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextField(
                controller: controller,
                size: dense ? CcTextFieldSize.sm : CcTextFieldSize.md,
                hintText: hasStaged
                    ? l10n.commitMessageHint
                    : l10n.stageChangesToCommit,
                enabled: !busy,
                onSubmitted: (_) {
                  if (primaryEnabled) {
                    onAction(primaryAction);
                  }
                },
              ),
              SizedBox(height: dense ? AppSpacing.xs : AppSpacing.sm),
              _CommitSplitButton(
                label: busy
                    ? l10n.saving
                    : (canPush ? l10n.commitAndPush : l10n.commit),
                busy: busy,
                dense: dense,
                primaryEnabled: primaryEnabled,
                onPrimary: () => onAction(primaryAction),
                items: [
                  if (canPush)
                    (
                      action: ScmCommitAction.commit,
                      label: l10n.commit,
                      icon: AppIcons.gitCommitHorizontal,
                      enabled: enabled(ScmCommitAction.commit),
                    ),
                  (
                    action: ScmCommitAction.amend,
                    label: l10n.commitAmend,
                    icon: AppIcons.squarePen,
                    enabled: enabled(ScmCommitAction.amend),
                  ),
                  if (canPush)
                    (
                      action: ScmCommitAction.commitAndSync,
                      label: l10n.commitAndSync,
                      icon: AppIcons.repeat,
                      enabled: enabled(ScmCommitAction.commitAndSync),
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
            icon: AppIcons.gitCommitHorizontal,
            loading: busy,
            fullWidth: true,
            onPressed: primaryEnabled ? onPrimary : null,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 2),
        CcMenu(
          semanticLabel: l10n.moreCommitActions,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
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
