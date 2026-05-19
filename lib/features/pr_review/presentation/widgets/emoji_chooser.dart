import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/emoji_data.dart';
import 'package:flutter/material.dart';
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.textTertiary,
                ),
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

@Deprecated('Use EmojiPopover widget instead')
/// Displays a legacy emoji chooser overlay positioned near [anchorPosition].
Future<void> showEmojiChooser({
  required BuildContext context,
  required void Function(String emoji) onEmojiSelected,
  Offset? anchorPosition,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  void dismiss() => entry.remove();

  entry = OverlayEntry(
    builder: (_) => _LegacyEmojiChooserBody(
      anchorPosition: anchorPosition,
      onSelected: (emoji) {
        onEmojiSelected(emoji);
        dismiss();
      },
      onDismiss: dismiss,
    ),
  );

  overlay.insert(entry);
}

class _LegacyEmojiChooserBody extends StatelessWidget {
  const _LegacyEmojiChooserBody({
    required this.onSelected,
    required this.onDismiss,
    this.anchorPosition,
  });

  final void Function(String emoji) onSelected;
  final VoidCallback onDismiss;
  final Offset? anchorPosition;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final mediaQuery = MediaQuery.of(context);
    final screenH = mediaQuery.size.height;
    final screenW = mediaQuery.size.width;
    const cardW = 504.0;
    const cardMaxH = 500.0;

    double? left;
    double? top;
    double? bottom;
    if (anchorPosition != null) {
      final spaceBelow = screenH - anchorPosition!.dy - 8;
      final spaceAbove = anchorPosition!.dy - 8;
      if (spaceBelow >= 280 || spaceBelow >= spaceAbove) {
        top = anchorPosition!.dy + 8;
      } else {
        bottom = screenH - anchorPosition!.dy + 8;
      }
      left = (anchorPosition!.dx - 8).clamp(12, screenW - cardW - 12);
    }

    final card = Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(12),
      color: t.bgPrimary,
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(maxHeight: cardMaxH),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.borderSecondary),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in emojiGroups) ...[
                Text(
                  group.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: t.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: group.emojis.map((emoji) {
                    return CcTappable(
                      onPressed: () => onSelected(emoji),
                      builder: (context, states) => Tooltip(
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
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        if (left != null && top != null)
          Positioned(left: left, top: top, child: card)
        else if (left != null && bottom != null)
          Positioned(left: left, bottom: bottom, child: card)
        else
          Center(child: card),
      ],
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
