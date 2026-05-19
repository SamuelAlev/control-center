import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server review comments for a single file, split into those still anchored to
/// a live diff row and those the current diff can no longer place.
@immutable
class PartitionedServerComments {
  /// Creates a [PartitionedServerComments].
  const PartitionedServerComments({
    required this.anchored,
    required this.outdated,
  });

  /// Comments keyed by `"<side>-<anchorLine>"`, ready to be synthesised into
  /// inline threads on the matching diff row.
  final Map<String, List<PrCodeReviewComment>> anchored;

  /// Comments whose [PrCodeReviewComment.anchorLine] is null — the diff line
  /// they referenced no longer exists (the code changed after the comment was
  /// left), so they cannot be pinned to a real row. GitHub surfaces these under
  /// a collapsed "outdated" group rather than dropping them.
  final List<PrCodeReviewComment> outdated;
}

/// Partitions the server review [comments] for [filename] into anchored and
/// outdated buckets.
///
/// A comment is *outdated* when it has no [PrCodeReviewComment.anchorLine]: the
/// diff row it referenced is gone, so it can't be anchored to a live line.
/// Previously such comments were silently dropped from the review; keeping them
/// in [PartitionedServerComments.outdated] lets the viewer surface them in a
/// collapsed group (GitHub parity). Anchored comments keep the
/// `"<side>-<anchorLine>"` grouping the inline renderer expects.
///
/// Pure and side-effect free so it can be unit-tested without a widget tree.
PartitionedServerComments partitionServerCommentsForFile(
  Iterable<PrCodeReviewComment> comments,
  String filename,
) {
  final anchored = <String, List<PrCodeReviewComment>>{};
  final outdated = <PrCodeReviewComment>[];
  for (final c in comments) {
    if (c.path != filename) {
      continue;
    }
    final anchor = c.anchorLine;
    if (anchor == null) {
      outdated.add(c);
      continue;
    }
    anchored
        .putIfAbsent('${c.side}-$anchor', () => <PrCodeReviewComment>[])
        .add(c);
  }
  return PartitionedServerComments(anchored: anchored, outdated: outdated);
}

/// A file-header affordance that surfaces a file's *outdated* review comments —
/// those whose diff line no longer exists — in a collapsed group.
///
/// Rendered as a small "outdated" badge that toggles a floating panel; the
/// panel is hidden by default, so outdated comments never compete with the live
/// diff, yet are no longer dropped. Each entry shows the comment body and the
/// original diff-hunk snippet the author saw, so the reviewer keeps the context
/// even though the line is gone. Never anchored to a real diff row.
class OutdatedCommentsGroup extends StatelessWidget {
  /// Creates an [OutdatedCommentsGroup]. [comments] must be non-empty (callers
  /// omit the group when a file has no outdated comments).
  const OutdatedCommentsGroup({super.key, required this.comments});

  /// The file's outdated comments.
  final List<PrCodeReviewComment> comments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      semanticLabel: l10n.outdatedComments,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
        child: _OutdatedPanel(comments: comments),
      ),
      target: CcBadge(
        label: l10n.outdatedCountLabel(comments.length),
        variant: CcBadgeVariant.warning,
        icon: AppIcons.clock,
      ),
    );
  }
}

/// The floating panel body listing every outdated comment for a file.
class _OutdatedPanel extends StatelessWidget {
  const _OutdatedPanel({required this.comments});

  final List<PrCodeReviewComment> comments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    // The panel floats in the root overlay, above every route's Material, so it
    // inherits no usable DefaultTextStyle — supply one (concrete size + token
    // colour + no decoration) or WidgetsApp's yellow error style leaks through.
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: tokens.textPrimary,
        fontFamily: CcFonts.uiFamily,
        decoration: TextDecoration.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.clock, size: 14, color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.outdatedComments,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: comments.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: CcDivider(),
                ),
                itemBuilder: (context, i) =>
                    _OutdatedCommentTile(comment: comments[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single outdated comment: author, an "outdated" badge, the original
/// diff-hunk snippet and the comment body.
class _OutdatedCommentTile extends ConsumerWidget {
  const _OutdatedCommentTile({required this.comment});

  final PrCodeReviewComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final login = comment.user?.login ?? l10n.unknownAuthor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GitHubUserAvatar(
              login: login,
              avatarUrl: comment.user?.avatarUrl,
              size: 18,
              showHoverCard: false,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                login,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CcBadge(
              label: l10n.outdated,
              variant: CcBadgeVariant.warning,
              icon: AppIcons.clock,
            ),
          ],
        ),
        if (comment.diffHunk.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          _DiffHunkSnippet(hunk: comment.diffHunk),
        ],
        const SizedBox(height: 6),
        GitHubMarkdownBody(
          data: comment.body,
          compact: true,
          codeFontFamily: ref.watch(codeFontFamilyProvider),
        ),
      ],
    );
  }
}

/// The read-only diff-hunk snippet the comment was left against (context only,
/// never anchored to a live row). Rendered monospace, tinting `+`/`-` lines.
class _DiffHunkSnippet extends ConsumerWidget {
  const _DiffHunkSnippet({required this.hunk});

  final String hunk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final codeFont = ref.watch(codeFontFamilyProvider);
    final lines = hunk.split('\n');
    const addBg = Color(0x332DA44E);
    const delBg = Color(0x33CF222E);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Container(
                width: double.infinity,
                color: line.startsWith('+')
                    ? addBg
                    : (line.startsWith('-') ? delBg : null),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: Text(
                  line.isEmpty ? ' ' : line,
                  maxLines: 1,
                  softWrap: false,
                  style: AppFonts.codeDynamic(
                    codeFont,
                    textStyle: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: tokens.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
