import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/sandbox_backend_picker.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/extensions/sandbox_backend_ext.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The sandboxing configuration: whether agent work is isolated from the host and which
/// backend does the isolating. It is one card that opens with the resolved posture (on/off,
/// the backend actually in force, the host it was detected on) and then reads top to bottom
/// as one decision: isolate or not, and with what.
///
/// What an agent may DO (push, open a pull request, reach the network) is not decided here:
/// the allow/ask/deny action policy is the only permission system, so the card ends with a
/// pointer to Agent permissions instead of a second, competing set of toggles.
class SandboxingSections extends ConsumerWidget {
  /// Creates [SandboxingSections].
  const SandboxingSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(sandboxPreferencesProvider);
    final detection = ref.watch(sandboxDetectionProvider);
    final active = ref.watch(activeSandboxBackendProvider);
    final isEnabled = prefs.isEnabled;
    final platform = detection.maybeWhen(
      data: (r) => r.platform,
      orElse: () => null,
    );

    return SectionCard(
      label: l10n.sandboxingCardLabel,
      subtitle: Text(l10n.sandboxingCardDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSummary(
            facts: [
              SettingsFact(
                label: l10n.sandboxingCardLabel,
                value: isEnabled ? l10n.enabled : l10n.disabled,
                tone: isEnabled ? CcStatusTone.positive : CcStatusTone.caution,
                mono: false,
              ),
              SettingsFact(
                // "In force", not "Backend": this is the RESOLVED backend, which
                // with Auto selected is not the same thing as the one picked in
                // the field below.
                label: l10n.sandboxSummaryInForce,
                value: isEnabled
                    ? active.resolvedLabel(l10n)
                    : l10n.sandboxBackendNoneActive,
                mono: false,
              ),
              if (platform != null)
                SettingsFact(label: l10n.sandboxSummaryHost, value: platform),
            ],
            // Deliberately no note: the toggle immediately below carries the
            // consequence sentence, and repeating it here would be the same
            // words twice in 200 vertical pixels.
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: l10n.sandboxGroupIsolation,
            description: l10n.sandboxGroupIsolationDescription,
            showRule: true,
            gap: AppSpacing.md,
            children: [
              SettingsToggle(
                title: l10n.enableSandboxing,
                description: isEnabled
                    ? l10n.sandboxingEnabledDescription(
                        active.resolvedLabel(l10n),
                      )
                    : l10n.sandboxingDisabledDescription,
                icon: isEnabled ? AppIcons.shieldCheck : AppIcons.shieldAlert,
                value: isEnabled,
                onChanged: (v) async {
                  await ref.read(sandboxPreferencesProvider).setEnabled(v);
                  // Force the watching provider to re-emit.
                  ref.invalidate(sandboxPreferencesProvider);
                },
              ),
              SandboxBackendPicker(
                detection: detection,
                pinned: prefs.backend,
                enabled: isEnabled,
              ),
              SandboxInstallHint(platform: platform),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: l10n.sandboxGroupAgentActions,
            description: l10n.sandboxGroupAgentActionsDescription,
            showRule: true,
            trailing: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.scale,
              onPressed: () {
                final workspaceId = context.currentWorkspaceId;
                if (workspaceId != null) {
                  context.go(settingsGuardrailsRoute(workspaceId));
                }
              },
              child: Text(l10n.agentPermissions),
            ),
            children: const [],
          ),
        ],
      ),
    );
  }
}
