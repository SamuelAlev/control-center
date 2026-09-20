part of 'toolbar_chips.dart';

/// Toolbar chip that opens the PR comment inbox overlay.
class CommentInboxChip extends StatefulWidget {
  /// Creates a [CommentInboxChip].
  const CommentInboxChip({
    super.key,
    required this.count,
    required this.controller,
    this.issueComments = const [],
    this.reviewComments = const [],
  });

  /// Number of inline comments.
  final int count;

  /// Controller for inline comment state.
  final PrInlineCommentsController controller;

  /// Issue-level comments to display in the inbox.
  final List<IssueComment> issueComments;

  /// Review-level comments to display in the inbox.
  final List<PrCodeReviewComment> reviewComments;
  @override
  State<CommentInboxChip> createState() => _CommentInboxChipState();
}

class _CommentInboxChipState extends State<CommentInboxChip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CcTappable(
        onPressed: _toggle,
        borderRadius: BorderRadius.circular(999),
        builder: (context, states) => CommentCountChip(count: widget.count),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: AlignmentDirectional.bottomStart.resolve(
            Directionality.of(overlayContext),
          ),
          followerAnchor: AlignmentDirectional.topStart.resolve(
            Directionality.of(overlayContext),
          ),
          offset: const Offset(0, 8),
          child: Consumer(
            builder: (context, ref, _) {
              final ctl = widget.controller;
              final cs = ref.watch(prInlineCommentsControllerProvider(ctl.pr));
              return PrCommentsInbox(
                threads: cs.threads,
                onToggleResolved: ctl.toggleResolved,
                onClose: _close,
                issueComments: widget.issueComments,
                reviewComments: widget.reviewComments,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A non-interactive chip displaying the comment count.
