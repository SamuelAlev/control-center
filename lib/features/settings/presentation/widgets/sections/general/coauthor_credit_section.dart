import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Commits: whose name a commit carries, and the person's
/// co-author credit preference.
///
/// The rule is the server's (`AgentCommitIdentities`); this card states it so
/// nobody has to guess why a commit names them or the bot. The preference is
/// stored in the caller's own preferences and shown read-only while the
/// active workspace overrides it.
class CoauthorCreditSection extends ConsumerStatefulWidget {
  /// Creates a [CoauthorCreditSection].
  const CoauthorCreditSection({super.key});

  @override
  ConsumerState<CoauthorCreditSection> createState() =>
      _CoauthorCreditSectionState();
}

class _CoauthorCreditSectionState extends ConsumerState<CoauthorCreditSection> {
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
          failureMessage(AppLocalizations.of(context), error),
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
    final note = CcTypography.caption.copyWith(
      color: t.textTertiary,
      height: 1.45,
    );
    return SectionCard(
      label: l10n.settingsCommitAuthorshipSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            gap: AppSpacing.md,
            children: [
              SettingsField(
                label: l10n.settingsCommitAuthorshipYoursLabel,
                child: Text(
                  l10n.settingsCommitAuthorshipYoursBody,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
              ),
              SettingsField(
                label: l10n.settingsCommitAuthorshipBotLabel,
                child: Text(
                  l10n.settingsCommitAuthorshipBotBody,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
              ),
              Text(l10n.settingsCommitAuthorshipSignInNote, style: note),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            showRule: true,
            gap: AppSpacing.sm,
            children: [
              SettingsToggle(
                icon: AppIcons.gitCommit,
                title: l10n.settingsCoauthorCreditTitle,
                description: l10n.settingsCoauthorCreditDescription,
                value: resolveAgentCommitAttribution(
                  userPreference:
                      prefs.value?[agentCommitAttributionSettingKey],
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
              if (error != null)
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      failureMessage(l10n, error),
                      style: CcTypography.caption.copyWith(
                        color: t.textErrorPrimary,
                      ),
                    ),
                    CcButton(
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      onPressed: () {
                        ref.invalidate(ownServerPrefsProvider);
                        ref.invalidate(workspaceSettingsProvider);
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                )
              else if (!ready)
                Text(l10n.settingsCoauthorCreditLoading, style: note)
              else if (override != AgentAttributionOverride.inherit)
                Text(l10n.settingsCoauthorCreditWorkspaceOverride, style: note),
            ],
          ),
        ],
      ),
    );
  }
}
