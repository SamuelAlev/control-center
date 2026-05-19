import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/sandbox_backend_picker.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/extensions/sandbox_backend_ext.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sandboxing configuration: whether agent work is isolated from the host,
/// which backend does the isolating, and what an isolated agent is still
/// allowed to reach.
///
/// ## Why it is one card
///
/// This was five cards — "Master toggle", "Backend", "Requirements", "Default
/// capabilities", "Maintenance" — for what is one question with one answer. A
/// card boundary says "different subject"; five of them said it four times when
/// it was not true, and the master toggle that governs all of the rest sat in
/// its own box with a single row in it.
///
/// It is now one card that opens with the resolved posture (on/off, the backend
/// actually in force, the host it was detected on) and then reads top to bottom
/// as one decision: isolate or not, with what, and with which holes punched
/// through it.
///
/// The old "Maintenance → reset all sandboxes" row was removed rather than
/// restyled: it showed a success toast and destroyed nothing, because no reset
/// op exists behind it. A control that reports work it did not do is worse than
/// no control.
class SandboxingSections extends ConsumerWidget {
  /// Creates [SandboxingSections].
  const SandboxingSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(sandboxPreferencesProvider);
    final detection = ref.watch(sandboxDetectionProvider);
    final active = ref.watch(activeSandboxBackendProvider);
    final caps = prefs.defaultCapabilities;
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
            title: l10n.defaultCapabilities,
            description: l10n.sandboxCapabilitiesDescription,
            showRule: true,
            separator: SettingsGroupSeparator.none,
            children: [_Capabilities(caps: caps, enabled: isEnabled)],
          ),
        ],
      ),
    );
  }
}

class _Capabilities extends ConsumerWidget {
  const _Capabilities({required this.caps, required this.enabled});

  final AgentCapabilities caps;
  final bool enabled;

  Future<void> _update(WidgetRef ref, AgentCapabilities next) async {
    await ref.read(sandboxPreferencesProvider).setDefaultCapabilities(next);
    ref.invalidate(sandboxPreferencesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsToggle(
          title: l10n.allowGitPush,
          description: l10n.gatesGithubPatPush,
          icon: AppIcons.gitBranch,
          value: caps.canPushToRepo,
          onChanged: enabled
              ? (v) => _update(ref, caps.copyWith(canPushToRepo: v))
              : null,
        ),
        SettingsToggle(
          title: l10n.allowGithubApi,
          description: l10n.readPrsIssuesMetadata,
          icon: AppIcons.gitPullRequest,
          value: caps.canCallGitHubApi,
          onChanged: enabled
              ? (v) => _update(ref, caps.copyWith(canCallGitHubApi: v))
              : null,
        ),
        SettingsToggle(
          title: l10n.allowTicketingApi,
          description: l10n.ticketingApiKeySubtitle,
          icon: AppIcons.listTodo,
          value: caps.canCallTicketing,
          onChanged: enabled
              ? (v) => _update(ref, caps.copyWith(canCallTicketing: v))
              : null,
        ),
        SettingsToggle(
          title: l10n.allowNetwork,
          description: l10n.whenOffNoDefaultRoute,
          icon: AppIcons.globe,
          value: caps.canAccessNetwork,
          onChanged: enabled
              ? (v) => _update(ref, caps.copyWith(canAccessNetwork: v))
              : null,
        ),
      ],
    );
  }
}
