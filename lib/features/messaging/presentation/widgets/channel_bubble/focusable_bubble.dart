import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A bubble wrapper that shows a focus outline and an optional hover reply
/// icon for top-level messages (not thread replies).
class FocusableBubble extends ConsumerStatefulWidget {
  /// Creates a [FocusableBubble].
  const FocusableBubble({
    required this.child,
    super.key,
    this.isThreadReply = false,
    this.messageId,
    this.onReplyInThread,
    this.alignRight = false,
    this.copyText,
  });

  /// The wrapped child widget.
  final Widget child;

  /// Whether this bubble is inside a thread panel (suppresses reply icon).
  final bool isThreadReply;

  /// Message ID for the reply-in-thread callback.
  final String? messageId;

  /// Callback when user clicks the reply-in-thread icon.
  final void Function(String messageId)? onReplyInThread;

  /// Whether this is a right-aligned (user) bubble.
  final bool alignRight;

  /// When non-empty, a copy-to-clipboard action is shown in the hover toolbar.
  final String? copyText;

  @override
  ConsumerState<FocusableBubble> createState() => _FocusableBubbleState();
}

class _FocusableBubbleState extends ConsumerState<FocusableBubble> {
  final FocusNode _focusNode = FocusNode();
  bool _hoverBubble = false;
  bool _hoverIcon = false;

  bool get _showIcon => _hoverBubble || _hoverIcon;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final showReply = !widget.isThreadReply &&
        widget.messageId != null &&
        widget.onReplyInThread != null;
    final showCopy =
        widget.copyText != null && widget.copyText!.trim().isNotEmpty;
    final showToolbar = showReply || showCopy;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverBubble = true),
      onExit: (_) => setState(() => _hoverBubble = false),
      child: Focus(
        focusNode: _focusNode,
        child: FocusRing(
          focusNode: _focusNode,
          borderRadius: BorderRadius.circular(bubbleRadius),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (showToolbar)
                Positioned(
                  top: 0,
                  // Icon's edge is flush against the bubble so the cursor
                  // can travel from bubble to icon without crossing a
                  // dead zone that would unmount the icon.
                  right: widget.alignRight ? null : -28,
                  left: widget.alignRight ? -28 : null,
                  // Icons stay mounted with their own MouseRegion so the
                  // cursor entering them keeps the hover state alive even
                  // after the parent bubble's MouseRegion has reported
                  // onExit. Visibility is driven by opacity; clicks are
                  // gated by IgnorePointer so invisible icons can't
                  // be triggered.
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoverIcon = true),
                    onExit: (_) => setState(() => _hoverIcon = false),
                    child: AnimatedOpacity(
                      opacity: _showIcon ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 80),
                      child: IgnorePointer(
                        ignoring: !_showIcon,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showCopy)
                              _HoverIconButton(
                                icon: LucideIcons.copy,
                                tokens: tokens,
                                onTap: () => Clipboard.setData(
                                  ClipboardData(text: widget.copyText!),
                                ),
                              ),
                            if (showReply)
                              _HoverIconButton(
                                icon: LucideIcons.messageSquare,
                                tokens: tokens,
                                onTap: () => widget.onReplyInThread!(
                                  widget.messageId!,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatelessWidget {
  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    required this.tokens,
  });

  final IconData icon;
  final VoidCallback onTap;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: tokens.fgTertiary),
        ),
      ),
    );
  }
}
