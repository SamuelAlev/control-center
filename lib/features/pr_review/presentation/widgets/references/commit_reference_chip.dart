import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/providers/commit_reference_preview_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/reference_chip_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline chip-style preview for a GitHub commit reference rendered inside
/// the PR detail markdown body / comments.
///
/// Resolves the commit's title (first line of the message) + short SHA.
/// Tapping opens the commit on GitHub in the browser — the app has no
/// in-app commit detail screen.
class CommitReferenceChip extends ConsumerWidget {
  /// Creates a [CommitReferenceChip].
  const CommitReferenceChip({
    super.key,
    required this.reference,
    this.maxTitleWidth = 320,
  });

  /// The parsed commit reference (owner / repo / sha).
  final GitHubCommitReference reference;

  /// Soft cap on the title width so long commit messages ellipsize.
  final double maxTitleWidth;

  /// The chip's link, in the vocabulary of the forge that hosts the referenced
  /// repo (GitLab prefixes commit paths with `/-/`, Bitbucket pluralizes them).
  String _href(WidgetRef ref) => ref
      .watch(
        forgeUrlsForRepoProvider((
          owner: reference.owner,
          name: reference.repo,
        )),
      )
      .commit(reference.owner, reference.repo, reference.sha);

  String get _fallbackLabel => '${reference.repo}@${reference.shortSha}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      commitReferencePreviewProvider(
        CommitReferenceKey(
          owner: reference.owner,
          repo: reference.repo,
          sha: reference.sha,
        ),
      ),
    );

    return previewAsync.when(
      loading: () => ReferenceChipShell(
        onTap: () => _open(ref),
        child: _LoadingContent(shortSha: reference.shortSha),
      ),
      error: (_, _) =>
          ReferenceFallbackLink(label: _fallbackLabel, onTap: () => _open(ref)),
      data: (preview) {
        if (preview == null) {
          return ReferenceFallbackLink(
            label: _fallbackLabel,
            onTap: () => _open(ref),
          );
        }
        return ReferenceChipShell(
          onTap: () => _open(ref),
          child: _LoadedContent(preview: preview, maxTitleWidth: maxTitleWidth),
        );
      },
    );
  }

  void _open(WidgetRef ref) {
    openExternalUrl(_href(ref));
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.shortSha});

  final String shortSha;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CcSpinner(size: 12),
        const SizedBox(width: 6),
        Text(shortSha, style: TextStyle(color: muted, fontSize: 13)),
      ],
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.preview, required this.maxTitleWidth});

  final CommitPreview preview;
  final double maxTitleWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.muted;
    final fg = tokens.textPrimary;
    final textStyle = CcTypography.body.copyWith(color: tokens.textTertiary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(AppIcons.gitCommitHorizontal, size: 14, color: muted),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTitleWidth),
          child: Text(
            preview.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(color: fg, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          preview.shortSha,
          style: textStyle.copyWith(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}
