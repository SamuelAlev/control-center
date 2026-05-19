import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/shared/emoji_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:forui/forui.dart';

final _emojiParser = EmojiParser();

/// A popover widget that displays an emoji picker grid.
class EmojiPopover extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FPopover(
      popoverAnchor: Alignment.topCenter,
      childAnchor: Alignment.bottomCenter,
      style: FPopoverStyle(
        popoverPadding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border),
          boxShadow: AppShadows.golden,
        ),
      ),
      hideRegion: FPopoverHideRegion.excludeChild,
      popoverBuilder: (context, controller) => _EmojiGrid(
        onSelected: (emoji) {
          onEmojiSelected(emoji);
          controller.hide();
        },
      ),
      builder: (context, controller, child) =>
          _EmojiTrigger(controller: controller, child: child!),
      child: child,
    );
  }
}

class _EmojiTrigger extends StatelessWidget {
  const _EmojiTrigger({required this.controller, required this.child});

  final FPopoverController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      onPress: controller.toggle,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      child: child,
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.onSelected});

  final void Function(String emoji) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: group.emojis.map((emoji) {
                  return FTappable.static(
                    onPress: () => onSelected(emoji),
                    focusedOutlineStyle:
                        const FFocusedOutlineStyleDelta.context(),
                    child: FTooltip(
                      tipBuilder: (_, _) => Text(_shortcodeFor(emoji)),
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
    final theme = context.theme;
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
      color: theme.colors.background,
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(maxHeight: cardMaxH),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border),
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
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: group.emojis.map((emoji) {
                    return FTappable.static(
                      onPress: () => onSelected(emoji),
                      focusedOutlineStyle:
                          const FFocusedOutlineStyleDelta.context(),
                      child: Tooltip(
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
