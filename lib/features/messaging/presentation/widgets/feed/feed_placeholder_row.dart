import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A message outside the loaded window: a quiet, static stand-in at the
/// height the feed expects the message to have.
///
/// The feed lists every message of the conversation so the scrollbar covers
/// all of it; only messages around the reader are loaded. Static on purpose:
/// a placeholder is on screen only while a jump or a fast scrollbar drag
/// waits for its range to load, and dozens of them sit in the list's cache
/// area, so an animation per row would tick for nothing.
class FeedPlaceholderRow extends StatelessWidget {
  /// Creates a stand-in [height] tall, aligned to the end for the reader's
  /// own messages.
  const FeedPlaceholderRow({
    super.key,
    required this.height,
    this.alignEnd = false,
  });

  /// The height the message is expected to have.
  final double height;

  /// Whether the message is the reader's own (right-aligned bubbles).
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final color = tokens.bgSecondary;
    Widget bar(double widthFactor, double barHeight) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: alignEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadiusDirectional.circular(4),
        ),
      ),
    );
    // As many 12px text bars as fit, under a short header bar.
    final lines = ((height - 44) / 22).floor().clamp(0, 6);
    return SizedBox(
      height: height,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                bar(0.18, 10),
                for (var i = 0; i < lines; i++) ...[
                  const SizedBox(height: 10),
                  bar(i == lines - 1 ? 0.55 : 0.92, 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
