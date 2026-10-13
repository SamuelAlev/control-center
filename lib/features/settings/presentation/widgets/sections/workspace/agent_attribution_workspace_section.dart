import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin-owned attribution policy; deleting the override restores user choices.
class AgentAttributionWorkspaceSection extends ConsumerStatefulWidget {
  /// Creates an [AgentAttributionWorkspaceSection].
  const AgentAttributionWorkspaceSection({super.key});

  @override
  ConsumerState<AgentAttributionWorkspaceSection> createState() =>
      _AgentAttributionWorkspaceSectionState();
}

class _AgentAttributionWorkspaceSectionState
    extends ConsumerState<AgentAttributionWorkspaceSection> {
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
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);
    final settings = ref.watch(workspaceSettingsProvider);
    return SectionCard(
      label: l10n.settingsAgentAttributionTitle,
      subtitle: Text(l10n.settingsWorkspaceAgentCoauthorDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CcSelect<AgentAttributionOverride>(
              key: ValueKey(workspaceId),
              semanticLabel: l10n.settingsAgentAttributionTitle,
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
                  label: l10n.settingsWorkspaceAgentCoauthorInherit,
                ),
                CcSelectOption(
                  value: AgentAttributionOverride.enabled,
                  label: l10n.settingsWorkspaceAgentCoauthorAlways,
                ),
                CcSelectOption(
                  value: AgentAttributionOverride.disabled,
                  label: l10n.settingsWorkspaceAgentCoauthorNever,
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
            Text(l10n.failedWithError('${settings.error}')),
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: () => ref.invalidate(workspaceSettingsProvider),
              child: Text(l10n.retry),
            ),
          ] else if (settings.isLoading)
            Text(l10n.settingsAgentAttributionLoading),
        ],
      ),
    );
  }
}
