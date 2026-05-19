import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Reusable capability picker. Used in:
///   * Settings → Sandboxing (defaults for new conversations)
///   * Agent edit dialog (per-agent default)
///   * Per-conversation override dialog opened from the chat header badge
class CapabilityToggles extends StatelessWidget {
  /// Creates a [CapabilityToggles].
  const CapabilityToggles({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
    super.key,
  });

  /// Current capability snapshot.
  final AgentCapabilities value;

  /// Called whenever any toggle flips.
  final ValueChanged<AgentCapabilities> onChanged;

  /// When false the toggles render disabled (used by the settings page when
  /// the master sandbox toggle is off).
  final bool enabled;

  /// When true uses tighter vertical rhythm — good for dialogs.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 4.0 : 8.0;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _Row(
          icon: LucideIcons.gitBranch,
          title: l10n.allowGitPush,
          subtitle: l10n.gatesGithubPatPush,
          value: value.canPushToRepo,
          enabled: enabled,
          onChange: (v) => onChanged(value.copyWith(canPushToRepo: v)),
          compact: compact,
        ),
        SizedBox(height: gap),
        _Row(
          icon: LucideIcons.gitPullRequest,
          title: l10n.allowGithubApi,
          subtitle: l10n.readPrsIssuesMetadata,
          value: value.canCallGitHubApi,
          enabled: enabled,
          onChange: (v) => onChanged(value.copyWith(canCallGitHubApi: v)),
          compact: compact,
        ),
        SizedBox(height: gap),
        _Row(
          icon: LucideIcons.listTodo,
          title: l10n.allowTicketingApi,
          subtitle: l10n.ticketingApiKeySubtitle,
          value: value.canCallTicketing,
          enabled: enabled,
          onChange: (v) => onChanged(value.copyWith(canCallTicketing: v)),
          compact: compact,
        ),
        SizedBox(height: gap),
        _Row(
          icon: LucideIcons.globe,
          title: l10n.allowNetwork,
          subtitle: l10n.whenOffNoDefaultRoute,
          value: value.canAccessNetwork,
          enabled: enabled,
          onChange: (v) => onChanged(value.copyWith(canAccessNetwork: v)),
          compact: compact,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChange,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    const mutedFallback = Color(0xFF656D76);
    const fgFallback = Color(0xFF1A1A1A);
    final titleSize = compact ? 13.0 : 14.0;
    final subSize = compact ? 11.5 : 12.0;
    final iconColor = tokens?.fgTertiary ?? mutedFallback;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: compact ? 16 : 18,
            color: enabled ? iconColor : iconColor.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? (tokens?.textPrimary ?? fgFallback)
                        : (tokens?.textTertiary ?? mutedFallback),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subSize,
                    height: 1.45,
                    color: tokens?.textTertiary ?? mutedFallback,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcSwitch(value: value, onChanged: enabled ? onChange : null),
        ],
      ),
    );
  }
}
