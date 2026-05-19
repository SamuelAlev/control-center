import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolves the status icon + colour for a PR. Shared between [PrStatusBadge]
/// and [PrStatusIcon] so the two stay in sync.
({IconData icon, Color color, String label}) prStatusIconData(
  PullRequest pr,
  BuildContext context,
) {
  if (pr.isDraft) {
    return (
      icon: LucideIcons.gitPullRequestDraft,
      color: context.theme.colors.mutedForeground,
      label: AppLocalizations.of(context).draft,
    );
  }
  final tokens = context.designSystem;
  if (pr.mergedAt != null) {
    return (
      icon: LucideIcons.gitMerge,
      color: tokens?.fgBrandPrimary ?? const Color(0xFFfa520f),
      label: AppLocalizations.of(context).merged,
    );
  }
  if (!pr.isOpen) {
    return (
      icon: LucideIcons.gitPullRequestClosed,
      color: tokens?.fgErrorPrimary ?? const Color(0xFFCF222E),
      label: AppLocalizations.of(context).closed,
    );
  }
  return (
    icon: LucideIcons.gitPullRequest,
    color: tokens?.fgSuccessPrimary ?? const Color(0xFF1A7F37),
    label: AppLocalizations.of(context).openStatus,
  );
}

/// Compact status logo shown to the left of a PR title. Mirrors GitHub's
/// status colours: grey draft, green open, red closed, violet merged.
class PrStatusIcon extends StatelessWidget {
  /// PrStatusIcon({super.key,.
  const PrStatusIcon({super.key, required this.pr, this.size = 16});

  /// PullRequest.
  final PullRequest pr;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final data = prStatusIconData(pr, context);
    return FTooltip(
      tipBuilder: (_, _) => Text(data.label),
      child: Icon(data.icon, size: size, color: data.color),
    );
  }
}

/// Pr status badge.
class PrStatusBadge extends StatelessWidget {
  /// PrStatusBadge({super.key,.
  const PrStatusBadge({super.key, required this.pr});

  /// PullRequest.
  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final data = prStatusIconData(pr, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: data.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 12, color: data.color),
          const SizedBox(width: 6),
          Text(
            data.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: data.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
