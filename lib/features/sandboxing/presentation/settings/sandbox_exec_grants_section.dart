import 'package:cc_data/cc_data.dart' show SandboxExecGrantView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandbox_exec_grant_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Sandbox → Executable grants.
///
/// The audit surface for a decision the operator can only ever have made by
/// answering a prompt: which working copies agents may run programs from.
///
/// Blocked trees are listed alongside allowed ones on purpose — "you already
/// said no" is why a prompt stopped appearing, and with no row for it that is
/// indistinguishable from the feature being broken.
class SandboxExecGrantsSection extends ConsumerWidget {
  /// Creates a [SandboxExecGrantsSection].
  const SandboxExecGrantsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final grants = ref.watch(sandboxExecGrantsProvider(workspaceId));

    return SectionCard(
      label: l10n.sandboxExecGrantsTitle,
      subtitle: Text(l10n.sandboxExecGrantsSubtitle),
      child: grants.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => CcAlert(
          title: l10n.failedWithError('$e'),
          variant: CcAlertVariant.danger,
        ),
        data: (rows) => rows.isEmpty
            ? CcEmptyState(
                icon: AppIcons.shield,
                message: l10n.sandboxExecGrantsEmpty,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final g in rows)
                    _GrantRow(grant: g, workspaceId: workspaceId),
                ],
              ),
      ),
    );
  }
}

class _GrantRow extends ConsumerWidget {
  const _GrantRow({required this.grant, required this.workspaceId});

  final SandboxExecGrantView grant;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Status never rides on colour alone — the badge carries its word.
          CcBadge(
            label: grant.allowed
                ? l10n.sandboxExecGrantAllowed
                : l10n.sandboxExecGrantBlocked,
            variant: grant.allowed
                ? CcBadgeVariant.warning
                : CcBadgeVariant.neutral,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.path,
                  style: CcFonts.code(
                    textStyle: TextStyle(fontSize: 12, color: t.textPrimary),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AppTimestamp.relative(
                  grant.createdAt,
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _revoke(context, ref, l10n),
            child: Text(l10n.sandboxExecGrantRevoke),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.sandboxExecGrantRevokeConfirmTitle,
        content: Text(l10n.sandboxExecGrantRevokeConfirmBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sandboxExecGrantRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(sandboxExecGrantRepositoryProvider)
        .revoke(workspaceId, grant.id);
    ref.invalidate(sandboxExecGrantsProvider(workspaceId));
  }
}
