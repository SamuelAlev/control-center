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
      child: CcChip(
        label: '${widget.count}',
        leadingIcon: AppIcons.messageSquare,
        selected: _overlay != null,
        onPressed: _toggle,
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
          // The overlay sits outside the page's focus scope, where Tab from
          // the chip never reaches it: the trap moves focus in, keeps Tab
          // inside and hands focus back to the chip on close; Escape closes.
          // The Actions sit above the trap so its own scope, which holds
          // focus when nothing inside does, still finds them.
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  _close();
                  return null;
                },
              ),
            },
            child: CcFocusTrap(
              child: Consumer(
                builder: (context, ref, _) {
                  final ctl = widget.controller;
                  final cs = ref.watch(
                    prInlineCommentsControllerProvider(ctl.pr),
                  );
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
          ),
        ),
      ],
    );
  }
}

/// A non-interactive chip displaying the comment count.
