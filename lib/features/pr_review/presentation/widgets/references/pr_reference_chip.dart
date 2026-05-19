import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_reference_preview_provider.dart';
import 'package:control_center/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:control_center/shared/widgets/github_link_handler.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:control_center/shared/widgets/reference_chip_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Inline chip-style preview for a GitHub PR reference rendered inside the
/// PR detail markdown body / comments.
///
/// Resolves the PR's title + state and renders an inline button. Tapping
/// routes through [handleGitHubLink] so the existing same-repo / cross-repo
/// switching rules apply.
class PrReferenceChip extends ConsumerWidget {
  /// Creates a [PrReferenceChip].
  const PrReferenceChip({
    super.key,
    required this.reference,
    required this.currentOwner,
    required this.currentRepo,
    this.onSwitchToRepo,
    this.maxTitleWidth = 320,
  });

  /// The parsed PR reference (owner / repo / number).
  final GitHubPrReference reference;

  /// Owner of the host PR — used to detect same-repo links for tap routing.
  final String currentOwner;

  /// Repo of the host PR — used to detect same-repo links for tap routing.
  final String currentRepo;

  /// Forwarded to [handleGitHubLink] when the chip targets a different repo
  /// that exists in the active workspace.
  final Future<void> Function(String workspaceId, String repoId)?
  onSwitchToRepo;

  /// Soft cap on the chip's title width so very long PR titles ellipsize
  /// rather than push the line off-screen.
  final double maxTitleWidth;

  bool get _isSameRepo =>
      reference.owner.toLowerCase() == currentOwner.toLowerCase() &&
      reference.repo.toLowerCase() == currentRepo.toLowerCase();

  String get _suffix => _isSameRepo
      ? '#${reference.number}'
      : '${reference.repo}#${reference.number}';

  String get _href =>
      'https://github.com/${reference.owner}/${reference.repo}/pull/${reference.number}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      prReferencePreviewProvider(
        PrReferenceKey(
          owner: reference.owner,
          repo: reference.repo,
          number: reference.number,
        ),
      ),
    );

    return previewAsync.when(
      loading: () => ReferenceChipShell(
        onTap: () => _handleTap(context, ref),
        child: _LoadingContent(suffix: _suffix),
      ),
      error: (_, _) => ReferenceFallbackLink(
        label: _suffix,
        onTap: () => _handleTap(context, ref),
      ),
      data: (preview) {
        if (preview == null) {
          return ReferenceFallbackLink(
            label: _suffix,
            onTap: () => _handleTap(context, ref),
          );
        }
        return ReferenceChipShell(
          onTap: () => _handleTap(context, ref),
          child: _LoadedContent(
            preview: preview,
            suffix: _suffix,
            maxTitleWidth: maxTitleWidth,
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    handleGitHubLink(
      context: context,
      ref: ref,
      href: _href,
      currentOwner: currentOwner,
      currentRepo: currentRepo,
      onSwitchToRepo: onSwitchToRepo,
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.suffix});

  final String suffix;

  @override
  Widget build(BuildContext context) {
    final muted = context.designSystem!.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12, height: 12, child: CcSpinner()),
        const SizedBox(width: 6),
        Text(suffix, style: TextStyle(color: muted, fontSize: 13)),
      ],
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({
    required this.preview,
    required this.suffix,
    required this.maxTitleWidth,
  });

  final PrPreview preview;
  final String suffix;
  final double maxTitleWidth;

  @override
  Widget build(BuildContext context) {
    final data = _statusVisuals(preview, context);
    final muted = context.designSystem!.textTertiary;
    final titleColor = data.color;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CcTooltip(
          message: data.label,
          child: Icon(data.icon, size: 14, color: data.color),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTitleWidth),
          child: PrTitleText(
            preview.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(suffix, style: textStyle?.copyWith(color: muted, fontSize: 12)),
      ],
    );
  }
}

/// Status icon/colour/label derived from the lightweight [PrPreview] without
/// needing a full PullRequest domain entity. Mirrors the rules in
/// `prStatusIconData` from `pr_status_badge.dart`.
({IconData icon, Color color, String label}) _statusVisuals(
  PrPreview preview,
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context);
  final tokens = context.designSystem;
  if (preview.isDraft) {
    return (
      icon: LucideIcons.gitPullRequestDraft,
      color: tokens?.textTertiary ?? const Color(0xFF656D76),
      label: l10n.draft,
    );
  }
  if (preview.isMerged) {
    return (
      icon: LucideIcons.gitMerge,
      color: tokens?.fgBrandPrimary ?? const Color(0xFF8957E5),
      label: l10n.merged,
    );
  }
  if (preview.state == 'closed') {
    return (
      icon: LucideIcons.gitPullRequestClosed,
      color: tokens?.fgErrorPrimary ?? const Color(0xFFCF222E),
      label: l10n.closed,
    );
  }
  return (
    icon: LucideIcons.gitPullRequest,
    color: tokens?.fgSuccessPrimary ?? const Color(0xFF1A7F37),
    label: l10n.openStatus,
  );
}
