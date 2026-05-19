import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

// The controls that sit under a review finding: the reply composer and the
// fix / comment / status action bar. Split out of the accordion item so that
// file stays about rendering a finding rather than also about acting on one.

/// A one-line composer for replying to a finding in its own thread.
///
/// The field IS the box. It used to sit inside a second bordered, tinted
/// container of its own — a card inside a card, which the design system rules
/// out and which read on screen as a framed grey slab with a smaller framed
/// grey slab inside it. `CcTextField` already draws the well, the underline and
/// the focus outline; wrapping it only added a frame that meant nothing.
class ReviewReplyComposer extends StatelessWidget {
  /// Creates a [ReviewReplyComposer].
  const ReviewReplyComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  /// The reply draft.
  final TextEditingController controller;

  /// Whether a send is in flight.
  final bool sending;

  /// Sends the draft.
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CcTextField(
            controller: controller,
            maxLines: 4,
            minLines: 1,
            hintText: l10n.replyEllipsis,
            enabled: !sending,
            // Enter sends, which is what every other composer in the app does.
            // Reaching for a button to post one sentence is the kind of small
            // friction that makes a reviewer stop replying at all.
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => sending ? null : onSend(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // An icon, not a labelled button: "Send" beside a one-line reply field
        // was the widest thing in the footer and outranked Fix, which is the
        // verb that actually changes the code.
        CcIconButton(
          icon: AppIcons.arrowUp,
          variant: CcButtonVariant.primary,
          size: CcButtonSize.sm,
          loading: sending,
          tooltip: l10n.send,
          semanticLabel: l10n.send,
          onPressed: sending ? null : onSend,
        ),
      ],
    );
  }
}

/// Fix / comment / status buttons for a single finding.
class ReviewFindingActionBar extends StatelessWidget {
  /// Creates a [ReviewFindingActionBar].
  const ReviewFindingActionBar({
    super.key,
    required this.status,
    required this.onSetStatus,
    required this.canComment,
    required this.onFix,
    required this.onComment,
    this.pending,
  });

  /// Where the finding currently stands, so the bar offers the move that is
  /// left rather than the one already made.
  final ReviewNodeStatus status;

  /// Moves the finding. Null while a move is in flight.
  final ValueChanged<ReviewNodeStatus>? onSetStatus;

  /// The move currently in flight, so the button that was pressed is the one
  /// that spins. Without it every status button went inert at once and none of
  /// them said which press had been taken.
  final ReviewNodeStatus? pending;

  /// Whether the finding is anchored well enough to post an inline comment.
  final bool canComment;

  /// Hands the finding to a coding agent.
  final VoidCallback onFix;

  /// Posts the finding to the pull request.
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        CcButton(
          size: CcButtonSize.sm,
          onPressed: onFix,
          icon: AppIcons.wrench,
          child: Text(l10n.fix),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!canComment)
          CcTooltip(
            message: l10n.noFileAnchor,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: null,
              icon: AppIcons.messageSquarePlus,
              child: Text(l10n.comment),
            ),
          )
        else
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            onPressed: onComment,
            icon: AppIcons.messageSquarePlus,
            child: Text(l10n.comment),
          ),
        const Spacer(),
        // The status verbs sit apart from the action verbs: Fix and Comment do
        // something to the CODE, these say what happened to the FINDING. They
        // are ghost buttons for that reason — a filled "Fixed" competed with
        // "Fix" at the other end of the same row, and the two mean opposite
        // things. A settled finding offers only the way back, because "resolve"
        // on an already-resolved row is a button that cannot mean anything.
        if (settled)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            loading: pending == ReviewNodeStatus.open,
            onPressed: onSetStatus == null
                ? null
                : () => onSetStatus!(ReviewNodeStatus.open),
            icon: AppIcons.undo2,
            child: Text(l10n.reviewFindingReopen),
          )
        else ...[
          CcTooltip(
            message: l10n.reviewFindingResolveHint,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              loading: pending == ReviewNodeStatus.resolved,
              onPressed: onSetStatus == null
                  ? null
                  : () => onSetStatus!(ReviewNodeStatus.resolved),
              icon: AppIcons.check,
              child: Text(l10n.reviewFindingResolve),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          CcTooltip(
            message: l10n.reviewFindingDismissHint,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              loading: pending == ReviewNodeStatus.dismissed,
              onPressed: onSetStatus == null
                  ? null
                  : () => onSetStatus!(ReviewNodeStatus.dismissed),
              icon: AppIcons.x,
              child: Text(l10n.reviewFindingDismiss),
            ),
          ),
        ],
      ],
    );
  }

  /// Whether a human has already had their say on this finding.
  bool get settled =>
      status == ReviewNodeStatus.resolved ||
      status == ReviewNodeStatus.dismissed;
}
