import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/emoji_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

final _emojiParser = EmojiParser();

/// A popover widget that displays an emoji picker grid.
class EmojiPopover extends StatefulWidget {
  /// Creates an [EmojiPopover].
  const EmojiPopover({
    super.key,
    required this.onEmojiSelected,
    required this.child,
  });

  /// Callback invoked when an emoji is selected.
  final void Function(String emoji) onEmojiSelected;

  /// The child widget that triggers the popover.
  final Widget child;

  @override
  State<EmojiPopover> createState() => _EmojiPopoverState();
}

class _EmojiPopoverState extends State<EmojiPopover> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcPopover(
      controller: _controller,
      targetAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(5),
        child: _EmojiGrid(
          onSelected: (emoji) {
            widget.onEmojiSelected(emoji);
            _controller.hide();
          },
        ),
      ),
      target: widget.child,
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.onSelected});

  final void Function(String emoji) onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 504,
      constraints: const BoxConstraints(maxHeight: 500),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final group in emojiGroups) ...[
              Text(
                group.label,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: group.emojis.map((emoji) {
                  return CcTappable(
                    onPressed: () => onSelected(emoji),
                    builder: (context, states) => CcTooltip(
                      message: _shortcodeFor(emoji),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  String _shortcodeFor(String emoji) {
    final match = _emojiParser.getEmoji(emoji);
    if (match != Emoji.None) {
      return match.full;
    }
    return '';
  }
}

