import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:control_center/features/sandboxing/providers/is_wsl2_provider.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/extensions/sandbox_backend_ext.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings → Security → Sandboxing.
///
/// Master enable toggle, backend picker, default capabilities for new
/// conversations, and a "reset all sandboxes" escape hatch.
class SandboxingSettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SandboxingSettingsScreen].
  const SandboxingSettingsScreen({super.key});

  @override
  ConsumerState<SandboxingSettingsScreen> createState() =>
      _SandboxingSettingsScreenState();
}

class _SandboxingSettingsScreenState
    extends ConsumerState<SandboxingSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(sandboxPreferencesProvider);
    final detection = ref.watch(sandboxDetectionProvider);
    final active = ref.watch(activeSandboxBackendProvider);
    final caps = prefs.defaultCapabilities;
    final isEnabled = prefs.isEnabled;

    return PageWrapper(
      title: l10n.sandboxing,
      subtitle: l10n.sandboxingDescription,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          _MasterToggleSection(enabled: isEnabled, active: active),
          const SizedBox(height: 16),
          _BackendSection(
            detection: detection,
            pinned: prefs.backend,
            enabled: isEnabled,
          ),
          const SizedBox(height: 16),
          const _InstallHintSection(),
          const SizedBox(height: 16),
          _CapabilitiesSection(caps: caps, enabled: isEnabled),
          const SizedBox(height: 16),
          const _ResetSection(),
        ],
      ),
    );
  }
}

class _MasterToggleSection extends ConsumerWidget {
  const _MasterToggleSection({required this.enabled, required this.active});

  final bool enabled;
  final SandboxBackend active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.masterToggle,
      child: SettingsRow(
        icon: enabled ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
        title: l10n.enableSandboxing,
        subtitle: enabled
            ? l10n.sandboxingEnabledDescription(active.resolvedLabel(l10n))
            : l10n.sandboxingDisabledDescription,
        trailing: CcSwitch(
          value: enabled,
          onChanged: (v) async {
            await ref.read(sandboxPreferencesProvider).setEnabled(v);
            // Force the watching provider to re-emit.
            ref.invalidate(sandboxPreferencesProvider);
          },
        ),
      ),
    );
  }
}

class _BackendSection extends ConsumerWidget {
  const _BackendSection({
    required this.detection,
    required this.pinned,
    required this.enabled,
  });

  final AsyncValue<SandboxDetectionResult> detection;
  final SandboxBackend? pinned;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.backend,
      child: detection.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CcProgressBar()),
        ),
        error: (e, _) => _ErrorText(l10n.detectionFailed('$e')),
        data: (result) {
          final caps = result.capabilities;
          final orderedBackends = <SandboxBackend>[
            SandboxBackend.native,
            SandboxBackend.none,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackendOption(
                title: l10n.autoRecommended,
                subtitle: l10n.detectedBackend(
                  result.recommendation.resolvedLabel(l10n),
                ),
                icon: LucideIcons.sparkles,
                selected: pinned == null,
                available: true,
                enabled: enabled,
                onSelect: () async {
                  await ref
                      .read(sandboxPreferencesProvider)
                      .setBackend(null);
                  ref.invalidate(sandboxPreferencesProvider);
                },
              ),
              for (final b in orderedBackends)
                if (caps[b] != null)
                  _BackendOption(
                    title: b.resolvedLabel(l10n),
                    subtitle: _subtitleFor(context, b, caps[b]?.note),
                    icon: _iconFor(b),
                    selected: pinned == b,
                    available: caps[b]!.available,
                    enabled: enabled,
                    onSelect: () async {
                      await ref
                          .read(sandboxPreferencesProvider)
                          .setBackend(b);
                      ref.invalidate(sandboxPreferencesProvider);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  String _subtitleFor(BuildContext context, SandboxBackend b, String? probeNote) {
    final lines = <String>[];
    if (probeNote != null && probeNote.isNotEmpty) {
      lines.add(probeNote);
    }
    if (b == SandboxBackend.native) {
      lines.add(AppLocalizations.of(context).weakIsolationDescription);
    }
    return lines.join(' ');
  }

  IconData _iconFor(SandboxBackend b) {
    switch (b) {
      case SandboxBackend.native:
        return LucideIcons.shield;
      case SandboxBackend.none:
        return LucideIcons.shieldOff;
    }
  }
}

class _InstallHintSection extends ConsumerWidget {
  const _InstallHintSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final isWsl2 = ref.read(isWsl2Provider);
    String text;
    if (Platform.isMacOS) {
      text = l10n.sandboxMacosBuiltIn;
    } else if (Platform.isLinux || isWsl2) {
      text = l10n.sandboxLinuxInstall;
    } else {
      text = l10n.sandboxUnsupported;
    }
    return SectionCard(
      label: l10n.requirements,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: tokens?.textTertiary ?? const Color(0xFF656D76),
            fontFamily: Platform.isLinux ? 'monospace' : null,
          ),
        ),
      ),
    );
  }
}

class _BackendOption extends StatelessWidget {
  const _BackendOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.available,
    required this.enabled,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool available;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    const mutedFallback = Color(0xFF656D76);
    const primaryFallback = Color(0xFF1A1A1A);
    const borderFallback = Color(0xFFE0E0E0);
    final interactive = enabled && available;
    final primary = tokens?.textPrimary ?? primaryFallback;

    final borderColor = selected
        ? primary
        : (tokens?.borderSecondary ?? borderFallback);
    final bg = selected
        ? primary.withValues(alpha: 0.08)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: interactive ? onSelect : null,
        borderRadius: AppRadii.brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor),
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: interactive
                    ? (tokens?.fgTertiary ?? mutedFallback)
                    : (tokens?.fgTertiary ?? mutedFallback).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: interactive
                            ? (tokens?.textPrimary ?? primaryFallback)
                            : (tokens?.textTertiary ?? mutedFallback),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: tokens?.textTertiary ?? mutedFallback,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (selected)
                Icon(
                  LucideIcons.circleCheck,
                  size: 18,
                  color: primary,
                )
              else if (!available)
                Text(
                  AppLocalizations.of(context).notAvailable,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens?.textTertiary ?? mutedFallback,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapabilitiesSection extends ConsumerWidget {
  const _CapabilitiesSection({required this.caps, required this.enabled});

  final AgentCapabilities caps;
  final bool enabled;

  Future<void> _update(WidgetRef ref, AgentCapabilities next) async {
    await ref.read(sandboxPreferencesProvider).setDefaultCapabilities(next);
    ref.invalidate(sandboxPreferencesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.defaultCapabilities,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.gitBranch,
            title: l10n.allowGitPush,
            subtitle: l10n.gatesGithubPatPush,
            trailing: CcSwitch(
              value: caps.canPushToRepo,
              onChanged: enabled
                  ? (v) => _update(ref, caps.copyWith(canPushToRepo: v))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.gitPullRequest,
            title: l10n.allowGithubApi,
            subtitle: l10n.readPrsIssuesMetadata,
            trailing: CcSwitch(
              value: caps.canCallGitHubApi,
              onChanged: enabled
                  ? (v) => _update(ref, caps.copyWith(canCallGitHubApi: v))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.listTodo,
            title: l10n.allowTicketingApi,
            subtitle: l10n.ticketingApiKeySubtitle,
            trailing: CcSwitch(
              value: caps.canCallTicketing,
              onChanged: enabled
                  ? (v) => _update(ref, caps.copyWith(canCallTicketing: v))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.globe,
            title: l10n.allowNetwork,
            subtitle: l10n.whenOffNoDefaultRoute,
            trailing: CcSwitch(
              value: caps.canAccessNetwork,
              onChanged: enabled
                  ? (v) => _update(ref, caps.copyWith(canAccessNetwork: v))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetSection extends ConsumerWidget {
  const _ResetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.maintenance,
      child: SettingsRow(
        icon: LucideIcons.refreshCw,
        title: l10n.resetAllSandboxes,
        subtitle:
            'Destroys every running and suspended sandbox session. '
            'Conversations stay intact.',
        trailing: CcButton(
          onPressed: () {
            CcToastScope.of(context).show(
              l10n.allSessionsReset,
              variant: CcToastVariant.success,
            );
          },
          variant: CcButtonVariant.destructive,
          child: Text(l10n.reset),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: tokens?.textErrorPrimary ?? const Color(0xFFCF222E),
      ),
    );
  }
}
