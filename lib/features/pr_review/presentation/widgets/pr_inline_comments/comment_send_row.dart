import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/comment_composer_mode_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Below this width the mode labels collapse to icons (the label stays the
/// tooltip). A side-by-side diff narrows the composer well under the labelled
/// row, and the segments cannot shrink below their labels.
const double _compactBelow = 440;

/// A diff composer's way out: pick where the comment goes, then send.
///
/// Replaces a row of labelled buttons that each posted somewhere different;
/// "Add single comment" beside "Start a review" read as two flavours of one
/// act. The destination is chosen first and one button sends, so what the
/// send does is always on screen. The choice is remembered in the user's
/// synced preferences.
class CommentSendRow extends ConsumerWidget {
  /// Creates a [CommentSendRow].
  const CommentSendRow({
    super.key,
    required this.modes,
    required this.mode,
    required this.onSend,
    required this.onCancel,
    this.reviewInProgress = false,
    this.sending = false,
  });

  /// The destinations this composer can send to, in display order.
  final List<CommentComposerMode> modes;

  /// The destination currently chosen, resolved by the composer (see
  /// [resolveCommentComposerMode]) so its placeholder and this row agree.
  final CommentComposerMode mode;

  /// Sends the draft to the chosen destination.
  final ValueChanged<CommentComposerMode> onSend;

  /// Discards the draft.
  final VoidCallback onCancel;

  /// Whether comments are already queued, which is the difference between
  /// "start a review" and "add to the one you started".
  final bool reviewInProgress;

  /// Whether a send is in flight; the send button spins and nothing else
  /// can be picked until it settles.
  final bool sending;

  String _sendLabel(AppLocalizations l10n, CommentComposerMode mode) =>
      switch (mode) {
        CommentComposerMode.agent => l10n.commentSendToAgent,
        // Alone, a comment is just "send"; beside a review it has to say it
        // skips the review.
        CommentComposerMode.comment =>
          modes.length == 1 ? l10n.send : l10n.addSingleComment,
        CommentComposerMode.review =>
          reviewInProgress ? l10n.addToReview : l10n.startAReview,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final send = CcIconButton(
      icon: AppIcons.arrowUp,
      variant: CcButtonVariant.primary,
      size: CcButtonSize.sm,
      loading: sending,
      tooltip: _sendLabel(l10n, mode),
      onPressed: sending ? null : () => onSend(mode),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _compactBelow;
        // The destination sits right beside the send it steers, so the pair
        // reads as one control: "Review ↑".
        return Row(
          children: [
            const Spacer(),
            CcButton(
              onPressed: sending ? null : onCancel,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (modes.length > 1) ...[
              CcSegmentedToggle<CommentComposerMode>(
                semanticLabel: l10n.commentDestination,
                value: mode,
                onChanged: sending
                    ? null
                    : ref.read(commentComposerModeProvider.notifier).setMode,
                segments: [
                  for (final m in modes)
                    CcSegment(
                      value: m,
                      label: _modeLabel(l10n, m),
                      icon: _modeIcon(m),
                      iconOnly: compact,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            send,
          ],
        );
      },
    );
  }
}

/// The comment field's placeholder for [mode]: it names where the words go.
String commentComposerHint(AppLocalizations l10n, CommentComposerMode mode) =>
    switch (mode) {
      CommentComposerMode.agent => l10n.commentHintAgent,
      CommentComposerMode.comment => l10n.leaveACommentEllipsis,
      CommentComposerMode.review => l10n.commentHintReview,
    };

String _modeLabel(AppLocalizations l10n, CommentComposerMode mode) =>
    switch (mode) {
      CommentComposerMode.agent => l10n.commentModeAgent,
      CommentComposerMode.comment => l10n.commentModeComment,
      CommentComposerMode.review => l10n.commentModeReview,
    };

IconData _modeIcon(CommentComposerMode mode) => switch (mode) {
  CommentComposerMode.agent => AppIcons.bot,
  CommentComposerMode.comment => AppIcons.messageSquare,
  CommentComposerMode.review => AppIcons.listChecks,
};
