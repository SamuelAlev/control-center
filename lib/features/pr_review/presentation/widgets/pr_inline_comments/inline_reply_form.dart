import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pr inline thread dot.
class PrInlineThreadDot extends StatelessWidget {
  /// Creates a [PrInlineThreadDot].
  const PrInlineThreadDot({super.key, this.resolved = false});

  /// Whether the thread is resolved.
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: resolved ? const Color(0xFF2DA44E) : const Color(0xFF1F75FE),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Pr comments inbox.
class PrCommentsInbox extends StatelessWidget {
  /// Creates a [PrCommentsInbox].
  const PrCommentsInbox({
    super.key,
    required this.threads,
    required this.onToggleResolved,
    required this.onClose,
    this.onJumpTo,
    this.issueComments = const [],
    this.reviewComments = const [],
  });

  /// Threads to display.
  final List<PrInlineThread> threads;

  /// Called when a thread's resolved state is toggled.
  final void Function(String threadId) onToggleResolved;

  /// Called to close the inbox.
  final VoidCallback onClose;

  /// Called to jump to a thread's location in the diff.
  final void Function(PrInlineThread thread)? onJumpTo;

  /// Issue-level comments on this PR.
  final List<IssueComment> issueComments;

  /// Review-level comments on this PR.
  final List<PrCodeReviewComment> reviewComments;

  @override
  Widget build(BuildContext context) {
    return _InboxView(
      threads: threads,
      issueComments: issueComments,
      reviewComments: reviewComments,
      onToggleResolved: onToggleResolved,
      onClose: onClose,
      onJumpTo: onJumpTo,
    );
  }
}

class _InboxView extends ConsumerStatefulWidget {
  const _InboxView({
    required this.threads,
    required this.issueComments,
    required this.reviewComments,
    required this.onToggleResolved,
    required this.onClose,
    this.onJumpTo,
  });
  final List<PrInlineThread> threads;
  final List<IssueComment> issueComments;
  final List<PrCodeReviewComment> reviewComments;
  final void Function(String threadId) onToggleResolved;
  final VoidCallback onClose;
  final void Function(PrInlineThread thread)? onJumpTo;
  @override
  ConsumerState<_InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends ConsumerState<_InboxView> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final all = widget.threads;
    final open = all.where((t) => !t.resolved).toList();
    final resolved = all.where((t) => t.resolved).toList();
    final visible = _showResolved ? all : open;
    final topLevelCount =
        widget.issueComments.length + widget.reviewComments.length;
    final commentCount = topLevelCount + open.length;
    final hasContent = topLevelCount > 0 || visible.isNotEmpty;

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.borderSecondary),
        boxShadow: AppShadows.golden,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasContent
                        ? '$commentCount comment${commentCount == 1 ? '' : 's'}'
                        : 'No open conversations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (resolved.isNotEmpty) ...[
                  Text(
                    'Show ${resolved.length} resolved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Switch(
                    value: _showResolved,
                    onChanged: (v) => setState(() => _showResolved = v),
                  ),
                ],
              ],
            ),
          ),
          const CcDivider(),
          if (!hasContent)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 24,
                    color: tokens.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No comments or conversations yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: topLevelCount + visible.length,
                separatorBuilder: (_, _) => const CcDivider(),
                itemBuilder: (context, i) {
                  final issueCount = widget.issueComments.length;
                  if (i < issueCount) {
                    return _buildIssueCommentRow(
                      context,
                      tokens,
                      widget.issueComments[i],
                    );
                  }
                  final reviewIdx = i - issueCount;
                  if (reviewIdx < widget.reviewComments.length) {
                    return _buildReviewCommentRow(
                      context,
                      tokens,
                      widget.reviewComments[reviewIdx],
                    );
                  }
                  final t = visible[reviewIdx - widget.reviewComments.length];
                  return _buildThreadRow(context, tokens, t);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueCommentRow(
    BuildContext context,
    DesignSystemTokens tokens,
    IssueComment comment,
  ) {
    final author = comment.user?.login ?? 'unknown';
    final avatarUrl = comment.user?.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GitHubUserAvatar(login: author, avatarUrl: avatarUrl, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (comment.createdAt != null)
                      Text(
                        formatRelative(comment.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCommentRow(
    BuildContext context,
    DesignSystemTokens tokens,
    PrCodeReviewComment comment,
  ) {
    final author = comment.user?.login ?? 'unknown';
    final avatarUrl = comment.user?.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GitHubUserAvatar(login: author, avatarUrl: avatarUrl, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (comment.createdAt != null)
                      Text(
                        formatRelative(comment.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  comment.path.isNotEmpty
                      ? '${comment.path}${comment.anchorLine != null ? ' : line ${comment.anchorLine}' : ''}'
                      : '',
                  style: AppFonts.codeStyleDynamic(
                    ref.watch(codeFontFamilyProvider),
                    fontSize: 12,
                    height: 1.4,
                    color: tokens.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadRow(
    BuildContext context,
    DesignSystemTokens tokens,
    PrInlineThread t,
  ) {
    final last = t.entries.last;
    return InkWell(
      onTap: widget.onJumpTo == null
          ? null
          : () {
              widget.onClose();
              widget.onJumpTo!(t);
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GitHubUserAvatar(
              login: last.author,
              size: 22,
              showHoverCard: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        last.author,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatRelative(last.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                      if (t.isSuggestion) ...[
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.diff,
                          size: 12,
                          color: tokens.textTertiary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    last.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.filePath} : line ${t.line}',
                    style: AppFonts.codeStyleDynamic(
                      ref.watch(codeFontFamilyProvider),
                      fontSize: 12,
                      height: 1.4,
                      color: tokens.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            CcIconButton(
              onPressed: () => widget.onToggleResolved(t.id),
              icon: t.resolved ? LucideIcons.checkCircle2 : LucideIcons.check,
              tooltip: t.resolved
                  ? AppLocalizations.of(context).reopen
                  : AppLocalizations.of(context).resolve,
            ),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return CcSwitch(value: value, onChanged: onChanged);
  }
}
