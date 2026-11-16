part of 'focusable_bubble.dart';

/// Hover-toolbar "add reaction" affordance: a small icon that opens a
/// [CcPopover] with the fixed emoji palette (PRD 16 §15). Tapping an emoji
/// toggles it via `reactions.toggle` and closes the popover.
class _AddReactionButton extends ConsumerStatefulWidget {
  const _AddReactionButton({
    required this.spaceId,
    required this.messageId,
    required this.tokens,
    required this.onOpenChanged,
  });

  final String spaceId;
  final String messageId;
  final DesignSystemTokens tokens;

  /// Reports overlay-open so the rail stays revealed while the pointer is off the message.
  final ValueChanged<bool> onOpenChanged;

  @override
  ConsumerState<_AddReactionButton> createState() => _AddReactionButtonState();
}

class _AddReactionButtonState extends ConsumerState<_AddReactionButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() => widget.onOpenChanged(_controller.isOpen);

  @override
  void dispose() {
    _controller.removeListener(_onOverlayChanged);
    _controller.dispose();
    super.dispose();
  }

  void _pick(String emoji) {
    toggleSpaceReaction(
      ref.read(rpcClientProvider),
      spaceId: widget.spaceId,
      messageId: widget.messageId,
      emoji: emoji,
    );
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      controller: _controller,
      // The target is a rail button, so it drives the controller itself: the
      // popover's own trigger would compete for the tap and paint a second wash.
      toggleOnTargetTap: false,
      target: BubbleIconButton(
        icon: AppIcons.smile,
        tokens: widget.tokens,
        tooltip: l10n.reactionAddTooltip,
        onTap: _controller.toggle,
      ),
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in kReactionPalette)
              CcTappable(
                onPressed: () => _pick(emoji),
                semanticLabel: l10n.reactionToggleTooltip(emoji),
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
