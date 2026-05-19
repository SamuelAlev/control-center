import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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

  @override
  ConsumerState<FocusableBubble> createState() => _FocusableBubbleState();
}

class _FocusableBubbleState extends ConsumerState<FocusableBubble> {
  bool _focused = false;
  bool _hoverBubble = false;
  bool _hoverIcon = false;

  bool get _showIcon => _hoverBubble || _hoverIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final showReply = !widget.isThreadReply &&
        widget.messageId != null &&
        widget.onReplyInThread != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverBubble = true),
      onExit: (_) => setState(() => _hoverBubble = false),
      child: Focus(
        onFocusChange: (focused) {
          if (_focused != focused) {
            setState(() => _focused = focused);
          }
        },
        child: FFocusedOutline(
          focused: _focused,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (showReply)
                Positioned(
                  top: 0,
                  // Icon's edge is flush against the bubble so the cursor
                  // can travel from bubble to icon without crossing a
                  // dead zone that would unmount the icon.
                  right: widget.alignRight ? null : -28,
                  left: widget.alignRight ? -28 : null,
                  // Icon stays mounted with its own MouseRegion so the
                  // cursor entering it keeps the hover state alive even
                  // after the parent bubble's MouseRegion has reported
                  // onExit. Visibility is driven by opacity; clicks are
                  // gated by IgnorePointer so an invisible icon can't
                  // be triggered.
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoverIcon = true),
                    onExit: (_) => setState(() => _hoverIcon = false),
                    child: AnimatedOpacity(
                      opacity: _showIcon ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 80),
                      child: IgnorePointer(
                        ignoring: !_showIcon,
                        child: _ReplyIconButton(
                          onTap: () =>
                              widget.onReplyInThread?.call(widget.messageId!),
                          tokens: tokens,
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

class _ReplyIconButton extends StatelessWidget {
  const _ReplyIconButton({required this.onTap, required this.tokens});

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
          child: Icon(
            LucideIcons.messageSquare,
            size: 14,
            color: tokens.fgTertiary,
          ),
        ),
      ),
    );
  }
}
