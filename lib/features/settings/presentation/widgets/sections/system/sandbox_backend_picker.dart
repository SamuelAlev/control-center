import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/extensions/sandbox_backend_ext.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The backend choice: Auto plus each backend this host reports, with the
/// reason an unavailable one is unavailable.
class SandboxBackendPicker extends ConsumerWidget {
  /// Creates a [SandboxBackendPicker].
  const SandboxBackendPicker({
    super.key,
    required this.detection,
    required this.pinned,
    required this.enabled,
  });

  /// The host probe.
  final AsyncValue<SandboxDetectionResult> detection;

  /// The pinned backend, or null for Auto.
  final SandboxBackend? pinned;

  /// Whether sandboxing is on at all.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsField(
      label: l10n.backend,
      description: l10n.sandboxBackendFieldDescription,
      layout: SettingsFieldLayout.stacked,
      child: detection.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: CcProgressBar(),
        ),
        error: (e, _) => CcAlert(
          title: l10n.detectionFailed('$e'),
          variant: CcAlertVariant.danger,
        ),
        data: (result) {
          final caps = result.capabilities;
          const orderedBackends = <SandboxBackend>[
            SandboxBackend.native,
            SandboxBackend.none,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _BackendOption(
                title: l10n.autoRecommended,
                subtitle: l10n.detectedBackend(
                  result.recommendation.resolvedLabel(l10n),
                ),
                icon: AppIcons.sparkles,
                selected: pinned == null,
                available: true,
                enabled: enabled,
                onSelect: () async {
                  await ref.read(sandboxPreferencesProvider).setBackend(null);
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
                      await ref.read(sandboxPreferencesProvider).setBackend(b);
                      ref.invalidate(sandboxPreferencesProvider);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  String _subtitleFor(
    BuildContext context,
    SandboxBackend b,
    String? probeNote,
  ) {
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
      // A real kernel boundary earns the strongest mark in the ramp; the
      // native sandbox is namespace isolation and reads one step down.
      case SandboxBackend.microvm:
        return AppIcons.shieldCheck;
      case SandboxBackend.native:
        return AppIcons.shield;
      case SandboxBackend.none:
        return AppIcons.shieldOff;
    }
  }
}

/// How to get the native sandbox on the host that runs agents.
///
/// It branches on the DETECTED platform (the local machine on desktop
/// self-serve; the connected cc_server over RPC on a thin/web client) — never
/// `dart:io` `Platform`, which throws on web. Hidden until detection resolves so
/// it never flashes a wrong platform's copy.
class SandboxInstallHint extends StatelessWidget {
  /// Creates a [SandboxInstallHint].
  const SandboxInstallHint({super.key, required this.platform});

  /// The detected host platform, or null while the probe is in flight.
  final String? platform;

  @override
  Widget build(BuildContext context) {
    final platform = this.platform;
    if (platform == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final p = platform.toLowerCase();
    final isLinux = p.contains('linux') || p.contains('wsl');
    final String text;
    if (p.contains('mac') || p.contains('darwin')) {
      text = l10n.sandboxMacosBuiltIn;
    } else if (isLinux) {
      text = l10n.sandboxLinuxInstall;
    } else {
      text = l10n.sandboxUnsupported;
    }
    // Linux's copy is a shell command, so it renders in the mono face — the
    // Machine-Truth rule, and the difference between "read this" and "run
    // this".
    return SettingsField(
      label: l10n.requirements,
      layout: SettingsFieldLayout.stacked,
      child: isLinux
          ? SettingsCopyField(value: text)
          : Text(
              text,
              style: CcTypography.caption.copyWith(
                color: tokens.textTertiary,
                height: 1.5,
              ),
            ),
    );
  }
}

/// One selectable backend. A bordered, tappable option — flat and ripple-free
/// like every other control in the system, and painted only from tokens so it
/// follows the theme rather than a hardcoded grey.
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
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final interactive = enabled && available;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CcTappable(
        onPressed: interactive ? onSelect : null,
        semanticLabel: title,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered) && interactive;
          return AnimatedContainer(
            duration: CcMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? t.accentSoft
                  : hovered
                  ? t.hover
                  : const Color(0x00000000),
              border: Border.all(
                color: selected ? t.accent : t.borderSecondary,
              ),
              borderRadius: AppRadii.brSm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: interactive ? t.fgTertiary : t.fgDisabled,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: CcTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: interactive ? t.textPrimary : t.textDisabled,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: CcTypography.caption.copyWith(
                            color: t.textTertiary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Selection is a glyph AND the border, never the tint alone.
                if (selected)
                  Icon(AppIcons.circleCheck, size: 18, color: t.accent)
                else if (!available)
                  CcBadge(
                    label: l10n.notAvailable,
                    variant: CcBadgeVariant.neutral,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
