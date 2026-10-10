part of 'pr_source_control_tab.dart';

// The tab's placeholder states: nothing changed, the worktree is still being
// prepared, or it could not be prepared.

Widget _empty(DesignSystemTokens t, AppLocalizations l10n) => ColoredBox(
  color: t.bgPrimary,
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.gitBranch, size: 22, color: t.textTertiary),
        const SizedBox(height: 10),
        Text(
          l10n.ideSourceControlNoChanges,
          style: TextStyle(fontSize: 12, color: t.textTertiary),
        ),
      ],
    ),
  ),
);

Widget _preparing(DesignSystemTokens t, String label) => ColoredBox(
  color: t.bgPrimary,
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CcSpinner(),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: TextStyle(fontSize: 12, color: t.textTertiary)),
      ],
    ),
  ),
);

Widget _failed(DesignSystemTokens t, AppLocalizations l10n) => ColoredBox(
  color: t.bgPrimary,
  child: Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.triangleAlert, size: 22, color: t.textTertiary),
          const SizedBox(height: 10),
          Text(
            l10n.prWorktreeUnavailable,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.prWorktreeUnavailableHint,
            style: TextStyle(fontSize: 12, color: t.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ),
);
