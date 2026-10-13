import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_toggle.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Personal preference, shown read-only while the active workspace overrides it.
class AgentAttributionSection extends ConsumerStatefulWidget {
  /// Creates an [AgentAttributionSection].
  const AgentAttributionSection({super.key});

  @override
  ConsumerState<AgentAttributionSection> createState() =>
      _AgentAttributionSectionState();
}

class _AgentAttributionSectionState
    extends ConsumerState<AgentAttributionSection> {
  bool _saving = false;

  Future<void> _save(bool value) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(identityRepositoryProvider)
          .prefsSet(agentCommitAttributionSettingKey, '$value');
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
    final prefs = ref.watch(ownServerPrefsProvider);
    final workspace = ref.watch(workspaceSettingsProvider);
    final ready =
        prefs.hasValue &&
        workspace.hasValue &&
        !prefs.isLoading &&
        !workspace.isLoading &&
        !prefs.hasError &&
        !workspace.hasError;
    final override = AgentAttributionOverride.fromStored(
      workspace.value?[agentCommitAttributionSettingKey],
    );
    final error = prefs.error ?? workspace.error;
    return SectionCard(
      label: l10n.settingsAgentCoauthorSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsToggle(
            icon: AppIcons.gitCommit,
            title: l10n.settingsAgentCoauthorTitle,
            description: l10n.settingsAgentCoauthorDescription,
            value: resolveAgentCommitAttribution(
              userPreference: prefs.value?[agentCommitAttributionSettingKey],
              workspaceOverride:
                  workspace.value?[agentCommitAttributionSettingKey],
            ),
            onChanged:
                ready &&
                    !_saving &&
                    override == AgentAttributionOverride.inherit
                ? _save
                : null,
          ),
          if (error != null) ...[
            Text(l10n.failedWithError('$error')),
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: () {
                ref.invalidate(ownServerPrefsProvider);
                ref.invalidate(workspaceSettingsProvider);
              },
              child: Text(l10n.retry),
            ),
          ] else if (!ready)
            Text(l10n.settingsAgentAttributionLoading)
          else if (override != AgentAttributionOverride.inherit) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.settingsAgentCoauthorWorkspaceOverride),
          ],
        ],
      ),
    );
  }
}
