import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → General: the admin-owned co-author credit policy.
/// "Each member decides" deletes the override and restores members' own
/// choices.
class CoauthorCreditWorkspaceSection extends ConsumerStatefulWidget {
  /// Creates a [CoauthorCreditWorkspaceSection].
  const CoauthorCreditWorkspaceSection({super.key});

  @override
  ConsumerState<CoauthorCreditWorkspaceSection> createState() =>
      _CoauthorCreditWorkspaceSectionState();
}

class _CoauthorCreditWorkspaceSectionState
    extends ConsumerState<CoauthorCreditWorkspaceSection> {
  bool _saving = false;

  Future<void> _save(String workspaceId, AgentAttributionOverride value) async {
    if (ref.read(activeWorkspaceIdProvider) != workspaceId) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(workspaceSettingsRepositoryProvider)
          .set(
            workspaceId,
            agentCommitAttributionSettingKey,
            value.storedValue,
          );
    } on Object catch (error) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedWithError('$error'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);
    final settings = ref.watch(workspaceSettingsProvider);
    final note = CcTypography.caption.copyWith(color: t.textTertiary);
    return SectionCard(
      label: l10n.settingsWorkspaceCoauthorCreditTitle,
      subtitle: Text(l10n.settingsWorkspaceCoauthorCreditDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CcSelect<AgentAttributionOverride>(
              // A new workspace rebuilds the select, which closes a menu
              // opened for the previous one.
              key: ValueKey(workspaceId),
              semanticLabel: l10n.settingsWorkspaceCoauthorCreditTitle,
              value: AgentAttributionOverride.fromStored(
                settings.value?[agentCommitAttributionSettingKey],
              ),
              enabled:
                  isAdmin &&
                  !_saving &&
                  settings.hasValue &&
                  !settings.isLoading &&
                  !settings.hasError,
              options: [
                CcSelectOption(
                  value: AgentAttributionOverride.inherit,
                  label: l10n.settingsWorkspaceCoauthorCreditInherit,
                ),
                CcSelectOption(
                  value: AgentAttributionOverride.enabled,
                  label: l10n.settingsWorkspaceCoauthorCreditAlways,
                ),
                CcSelectOption(
                  value: AgentAttributionOverride.disabled,
                  label: l10n.settingsWorkspaceCoauthorCreditNever,
                ),
              ],
              onChanged: (value) async {
                if (workspaceId != null) {
                  await _save(workspaceId, value);
                }
              },
            ),
          ),
          if (settings.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.failedWithError('${settings.error}'),
                  style: CcTypography.caption.copyWith(
                    color: t.textErrorPrimary,
                  ),
                ),
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: () => ref.invalidate(workspaceSettingsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ] else if (settings.isLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.settingsCoauthorCreditLoading, style: note),
          ] else if (!isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.settingsWorkspaceAdminOnly, style: note),
          ],
        ],
      ),
    );
  }
}
