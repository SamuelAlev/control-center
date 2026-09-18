import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/workspace_avatar.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One conversation entry: a review submission or a plain comment.
class PrTimelineEntry {
  PrTimelineEntry({
    required this.author,
    required this.body,
    required this.at,
    this.review,
    this.commentId,
    this.canEditComment = false,
  });

  final PrUser? author;
  final String body;
  final DateTime? at;
  final PrReviewSubmissionState? review;

  /// Set for top-level conversation comments so a task-list toggle can PATCH
  /// that comment. Null for review-summary bubbles.
  final int? commentId;

  /// Whether the viewer may tick GFM task-list boxes on this comment.
  final bool canEditComment;
}

/// A conversation bubble showing an author, optional review badge, and body.
class PrBubble extends StatelessWidget {
  const PrBubble({
    super.key,
    required this.author,
    required this.at,
    required this.child,
    this.review,
  });

  final PrUser? author;
  final DateTime? at;
  final Widget child;
  final PrReviewSubmissionState? review;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RemoteAvatar(
              url: author?.avatarUrl,
              fallbackLabel: author?.login ?? '',
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                author?.login ?? l10n.unknownAuthor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (review != null) ...[
              const SizedBox(width: 6),
              CcBadge(
                label: switch (review!) {
                  PrReviewSubmissionState.approved => l10n.reviewApproved,
                  PrReviewSubmissionState.changesRequested =>
                    l10n.reviewRequestedChanges,
                  PrReviewSubmissionState.commented => l10n.reviewCommented,
                  PrReviewSubmissionState.pending => l10n.reviewPending,
                },
                variant: switch (review!) {
                  PrReviewSubmissionState.approved => CcBadgeVariant.success,
                  PrReviewSubmissionState.changesRequested =>
                    CcBadgeVariant.danger,
                  _ => CcBadgeVariant.neutral,
                },
              ),
            ],
            const Spacer(),
            Text(
              shortAgo(context, at),
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 28, top: 4),
          child: child,
        ),
      ],
    );
  }
}

/// Builds a conversation tab body from PR reviews + issue comments.
List<Widget> buildConversationTimeline({
  required BuildContext context,
  required DesignSystemTokens t,
  required String prBody,
  required PrUser? prAuthor,
  required DateTime? prCreatedAt,
  required List<PrTimelineEntry> entries,
  void Function(int index, bool checked)? onPrBodyCheckboxChanged,
  void Function(int commentId, int index, bool checked)?
  onCommentCheckboxChanged,
}) {
  return [
    if (prBody.trim().isNotEmpty) ...[
      PrBubble(
        author: prAuthor,
        at: prCreatedAt,
        child: PhoneMarkdown(
          data: prBody,
          onTaskCheckboxChanged: onPrBodyCheckboxChanged,
        ),
      ),
      const SizedBox(height: 12),
    ],
    for (final e in entries) ...[
      PrBubble(
        author: e.author,
        at: e.at,
        review: e.review,
        child: e.body.trim().isEmpty
            ? const SizedBox.shrink()
            : PhoneMarkdown(
                data: e.body,
                onTaskCheckboxChanged:
                    e.commentId == null ||
                        !e.canEditComment ||
                        onCommentCheckboxChanged == null
                    ? null
                    : (index, next) => onCommentCheckboxChanged(
                        e.commentId!,
                        index,
                        next,
                      ),
              ),
      ),
      const SizedBox(height: 12),
    ],
    if (entries.isEmpty && prBody.trim().isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          AppLocalizations.of(context).noDescriptionNoComments,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: t.textTertiary),
        ),
      ),
  ];
}
