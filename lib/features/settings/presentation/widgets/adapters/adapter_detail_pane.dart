import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/adapter_enforcement_section.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_launch_controls.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_accounts_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The detail pane for the runner selected in the rail: detection state,
/// version and path on top (the two facts that differ between one machine and
/// another), what the runner's transport actually enforces, and the launch
/// configuration. Claude Code also owns its logins here — which account
/// `claude -p` signs in as is an adapter fact, not a page-level one.
///
/// Everything shows regardless of detection status, as the old expanded row
/// did: what a transport enforces is a property of our integration and the
/// launch config can be set ahead of installing the CLI — both are worth
/// reading before the runner ever turns up on the filesystem.
class AdapterDetailPane extends StatelessWidget {
  /// Creates an [AdapterDetailPane].
  const AdapterDetailPane({super.key, required this.detected});

  /// The runner shown.
  final DetectedAdapter detected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final status = detected.status;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  detected.adapter.name,
                  style: CcTypography.title.copyWith(color: tokens.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcStatusTag(
                tone: switch (status) {
                  DetectionStatus.found => CcStatusTone.positive,
                  DetectionStatus.checking => CcStatusTone.neutral,
                  DetectionStatus.notFound => CcStatusTone.neutral,
                },
                label: switch (status) {
                  DetectionStatus.found => l10n.available,
                  DetectionStatus.checking => l10n.checking,
                  DetectionStatus.notFound => l10n.unavailable,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            switch (status) {
              DetectionStatus.found => l10n.installedVersion(
                detected.version ?? 'unknown',
              ),
              DetectionStatus.checking => l10n.checkingEllipsis,
              DetectionStatus.notFound => l10n.notFoundLabel,
            },
            style: CcTypography.caption.copyWith(
              color: detected.isFound
                  ? tokens.textSuccessPrimary
                  : tokens.textTertiary,
            ),
          ),
          if (detected.isFound && detected.path != null) ...[
            const SizedBox(height: 2),
            Text(
              detected.path!,
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ],
          if (detected.isFound && detected.capabilities != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _CapabilityChip(
                  label: l10n.capabilityJsonMode,
                  enabled: detected.capabilities!.supportsJsonMode,
                  tokens: tokens,
                ),
                _CapabilityChip(
                  label: l10n.capabilityModelSelection,
                  enabled: detected.capabilities!.supportsModelSelection,
                  tokens: tokens,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AdapterEnforcementSection(transport: detected.adapter.transport),
          if (detected.adapter.transport == AdapterTransport.claudeCli) ...[
            const SizedBox(height: AppSpacing.lg),
            const ClaudeAccountsSection(),
          ],
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: l10n.adaptersLaunchGroup,
            description: l10n.adaptersLaunchGroupDescription,
            showRule: true,
            gap: AppSpacing.md,
            children: [AdapterLaunchControls(adapterId: detected.adapter.id)],
          ),
        ],
      ),
    );
  }
}

/// A compact on/off capability chip (✓ / ✗ + label).
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.enabled,
    required this.tokens,
  });

  final String label;
  final bool enabled;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? tokens.textSecondary : tokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(enabled ? AppIcons.check : AppIcons.x, size: 12, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: CcTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
