import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Resolves the status icon + colour for a PR. Shared between [PrStatusBadge]
/// and [PrStatusIcon] so the two stay in sync.
({IconData icon, Color color, String label}) prStatusIconData(
  PullRequest pr,
  BuildContext context,
) {
  final tokens = context.designSystem;
  if (pr.isDraft) {
    return (
      icon: AppIcons.gitPullRequestDraft,
      color: tokens?.textTertiary ?? const Color(0xFF6B7280),
      label: AppLocalizations.of(context).draft,
    );
  }
  if (pr.mergedAt != null) {
    return (
      icon: AppIcons.gitMerge,
      color: tokens?.fgMergedPrimary ?? const Color(0xFF8957E5),
      label: AppLocalizations.of(context).merged,
    );
  }
  if (!pr.isOpen) {
    return (
      icon: AppIcons.gitPullRequestClosed,
      color: tokens?.fgErrorPrimary ?? const Color(0xFFCF222E),
      label: AppLocalizations.of(context).closed,
    );
  }
  return (
    icon: AppIcons.gitPullRequest,
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
    return CcTooltip(
      message: data.label,
      child: Icon(data.icon, size: size, color: data.color),
    );
  }
}

/// The PR state as a plain tag ("Open", "Draft", "Merged", "Closed"): a
/// tinted capsule carrying the label alone.
///
/// No leading icon and no uppercasing — the tint reports the state and the
/// label names it, so it reads as a tag beside its siblings rather than as a
/// decorated badge. The icon form lives in [PrStatusIcon].
class PrStatusBadge extends StatelessWidget {
  /// PrStatusBadge({super.key,.
  const PrStatusBadge({super.key, required this.pr});

  /// PullRequest.
  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final data = prStatusIconData(pr, context);
    final variant = pr.isDraft
        ? CcBadgeVariant.neutral
        : pr.mergedAt != null
        ? CcBadgeVariant.brand
        : !pr.isOpen
        ? CcBadgeVariant.danger
        : CcBadgeVariant.success;
    return CcBadge(label: data.label, variant: variant);
  }
}
