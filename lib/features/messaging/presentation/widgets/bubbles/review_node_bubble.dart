import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/focusable_bubble.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/anchored_code_block.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_controls.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_header.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_status_action.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline chat rendering of a `reviewNode` space message.
///
/// One finding, one bordered card. It used to be neither: the header row and
/// its body hung directly in the conversation column with nothing around them,
/// so a run of nine findings read as loose lines of metadata floating at
/// irregular intervals rather than as a list of things. The frame is what makes
/// them a list; the shared [ReviewFindingHeader] is what makes each one the
/// same object the review tab shows.
///
/// Collapsed by default (the review tab opens findings, because that surface IS
/// the review; here the finding is one message among many). Expanding reveals
/// the body, the anchored source snippet and the same Fix / Comment / status
/// verbs the review tab offers.
class ReviewNodeBubble extends ConsumerStatefulWidget {
  /// Creates a [ReviewNodeBubble].
  const ReviewNodeBubble({
    super.key,
    required this.message,
    this.fetchFileContent,
    this.prNumber,
    this.onFix,
    this.onComment,
  });

  /// The reviewNode space message.
  final Message message;

  /// Resolves a repo-relative path to its full file contents for the anchor
  /// snippet. When null, the anchor renders as a path-only badge.
  final Future<String> Function(String path)? fetchFileContent;

  /// PR number the finding belongs to, when known. Used by `Comment` to post
  /// the finding back as an inline PR comment.
  final int? prNumber;

  /// Optional handler for the Fix action. When null, a toast is shown.
  final VoidCallback? onFix;

  /// Optional handler for the Comment action. When null, a toast is shown.
  final VoidCallback? onComment;

  @override
  ConsumerState<ReviewNodeBubble> createState() => _ReviewNodeBubbleState();
}

class _ReviewNodeBubbleState extends ConsumerState<ReviewNodeBubble> {
  bool _expanded = false;

  /// The status move in flight, so the pressed button is the one that spins.
  ReviewNodeStatus? _pendingStatus;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final payload = ReviewNodePayload.fromMetadata(widget.message.metadata);
    if (payload == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      // Findings arrive in runs, so the gap between two of them is a list gap,
      // not a speaker change. At the old `xl` each card floated on its own
      // island and the run stopped reading as one report.
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Opacity(
        opacity: reviewSettledOpacity(payload.status),
        child: FocusableBubble(
          messageId: widget.message.id,
          child: DecoratedBox(
            // `bgPrimary`, the same data surface the review tab's rows sit on
            // — not `surface`. That token is a SUNKEN block (gray100 on a
            // gray50 canvas in light, gray800 in dark): the card would read as
            // a well rather than a card, and worse, in dark it collides
            // exactly with the `bgSecondary` fill of the status pill sitting
            // on it, so the pill would disappear again in one theme only.
            decoration: BoxDecoration(
              color: tokens.bgPrimary,
              border: Border.all(color: tokens.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ReviewFindingHeader(
                  payload: payload,
                  summary: reviewFindingSummary(widget.message.content),
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                  background: tokens.bgPrimary,
                  divider: _expanded,
                ),
                if (_expanded)
                  _ExpandedBody(
                    message: widget.message,
                    payload: payload,
                    fetchFileContent: widget.fetchFileContent,
                    prNumber: widget.prNumber,
                    onFix: _handleFix,
                    onComment: _handleComment,
                    onSetStatus: _pendingStatus != null ? null : _setStatus,
                    pendingStatus: _pendingStatus,
                    tokens: tokens,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFix() {
    if (widget.onFix != null) {
      widget.onFix!();
      return;
    }
    _toast(AppLocalizations.of(context).fix);
  }

  void _handleComment() {
    if (widget.onComment != null) {
      widget.onComment!();
      return;
    }
    _toast(AppLocalizations.of(context).comment);
  }

  /// Moves the finding through the SAME path the review tab uses.
  ///
  /// This used to write `status: dismissed` straight into the message metadata,
  /// which skipped the dismissal reason (the fact future reviews are matched
  /// against, so the pattern came back on the next pull request) and left
  /// nothing in the undo journal. A finding dismissed from the chat and one
  /// dismissed from the review tab are the same act and now take the same route.
  Future<void> _setStatus(ReviewNodeStatus status) async {
    setState(() => _pendingStatus = status);
    try {
      await applyReviewFindingStatus(
        ref,
        context,
        spaceId: widget.message.spaceId,
        nodeMessageId: widget.message.id,
        status: status,
      );
    } finally {
      if (mounted) {
        setState(() => _pendingStatus = null);
      }
    }
  }

  void _toast(String action) {
    CcToastScope.of(
      context,
    ).show('$action — no handler bound', variant: CcToastVariant.neutral);
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.message,
    required this.payload,
    required this.fetchFileContent,
    required this.prNumber,
    required this.onFix,
    required this.onComment,
    required this.onSetStatus,
    required this.pendingStatus,
    required this.tokens,
  });

  final Message message;
  final ReviewNodePayload payload;
  final Future<String> Function(String path)? fetchFileContent;
  final int? prNumber;
  final VoidCallback onFix;
  final VoidCallback onComment;
  final ValueChanged<ReviewNodeStatus>? onSetStatus;
  final ReviewNodeStatus? pendingStatus;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final canComment =
        payload.anchor.filePath != null && payload.anchor.lineNumber != null;
    final l10n = AppLocalizations.of(context);
    final path = payload.anchor.filePath;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            GitHubMarkdownBody(data: message.content, compact: true),
          // The header shows the basename so the finding's headline gets the
          // width; the full path belongs with the body it describes.
          if (path != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$path${payload.anchor.lineNumber != null ? ':${payload.anchor.lineNumber}' : ''}',
              style: CcFonts.code(
                textStyle: CcTypography.caption,
              ).copyWith(color: tokens.textTertiary),
            ),
          ],
          if (payload.anchor.hasAnchor &&
              fetchFileContent != null &&
              path != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AnchoredCodeBlock(
              filePath: path,
              lineNumber: payload.anchor.lineNumber ?? 1,
              lineEnd: payload.anchor.lineEnd,
              fetchFileContent: fetchFileContent!,
              prNumber: prNumber,
            ),
          ],
          if (payload.confirmedBy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.confirmedBy.toUpperCase(),
              style: CcTypography.label.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final id in payload.confirmedBy)
                  CcBadge(label: '@$id', variant: CcBadgeVariant.brand),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const CcDivider(),
          const SizedBox(height: AppSpacing.md),
          // The same bar the review tab renders: one finding has one set of
          // verbs, whichever surface you happen to meet it on.
          ReviewFindingActionBar(
            status: payload.status,
            onSetStatus: onSetStatus,
            pending: pendingStatus,
            canComment: canComment,
            onFix: onFix,
            onComment: onComment,
          ),
        ],
      ),
    );
  }
}
