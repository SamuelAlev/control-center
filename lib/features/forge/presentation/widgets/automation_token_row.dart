import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_automation_token.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/presentation/widgets/automation_token_dialog.dart';
import 'package:control_center/features/forge/providers/automation_token_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One automation-token slot: a GitLab or Bitbucket repository's own, or a
/// workspace's for one forge. Says which bot automation acts as there (or
/// that it borrows the workspace's token, or that there is none and
/// automation is paused) and offers add, update and remove. Admin-only; the
/// caller decides whether to show it.
class AutomationTokenRow extends ConsumerWidget {
  /// Creates an [AutomationTokenRow].
  const AutomationTokenRow({
    super.key,
    required this.workspaceId,
    required this.forge,
    required this.title,
    this.repoId,
    this.token,
    this.inherited = false,
  });

  /// The workspace.
  final String workspaceId;

  /// GitLab or Bitbucket.
  final ForgeHost forge;

  /// The slot's name: the repository, or the forge for the workspace slot.
  final String title;

  /// The repository, or null for the workspace's slot.
  final String? repoId;

  /// The token stored in this slot, or null.
  final ForgeAutomationToken? token;

  /// Whether a repository without its own token is covered by the
  /// workspace's.
  final bool inherited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final token = this.token;
    final (status, color) = switch (token) {
      ForgeAutomationToken(rejected: true) => (
        l10n.automationTokenRejected,
        t.textErrorPrimary,
      ),
      ForgeAutomationToken(:final botLabel) when botLabel.isNotEmpty => (
        l10n.automationTokenActsAs(botLabel),
        t.textSecondary,
      ),
      ForgeAutomationToken() => (l10n.automationTokenStored, t.textSecondary),
      null when inherited => (
        l10n.automationTokenFromWorkspace,
        t.textTertiary,
      ),
      null => (l10n.automationTokenNone, t.textWarningPrimary),
    };
    return CcTile(
      title: title,
      subtitle: Text(
        status,
        style: CcTypography.caption.copyWith(color: color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: () => unawaited(
              showAutomationTokenDialog(
                context,
                workspaceId: workspaceId,
                forge: forge,
                target: repoId == null
                    ? l10n.automationTokenWorkspaceTarget(forge.displayName)
                    : title,
                repoId: repoId,
              ),
            ),
            child: Text(token == null ? l10n.addToken : l10n.updateToken),
          ),
          if (token != null)
            CcIconButton(
              icon: AppIcons.trash2,
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              tooltip: l10n.remove,
              semanticLabel: l10n.remove,
              onPressed: () => unawaited(_remove(context, ref)),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.automationTokenRemoveTitle,
        content: Text(l10n.automationTokenRemoveBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await clearAutomationToken(
        ref,
        workspaceId: workspaceId,
        forge: forge,
        repoId: repoId,
      );
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
      }
    }
  }
}
