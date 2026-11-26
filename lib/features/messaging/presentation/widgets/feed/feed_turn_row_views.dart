import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/agent_turn.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/message_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_rows.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_turn_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reports hover over one row of a turn into its [TurnHover] group.
class _TurnHoverRegion extends StatelessWidget {
  const _TurnHoverRegion({required this.hover, required this.child});

  final TurnHover hover;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => hover.enter(),
    onExit: (_) => hover.exit(),
    child: child,
  );
}

/// The header row of an agent turn laid out row by row: the turn-boundary
/// spacing, the name header and the turn's accessibility label.
class TurnHeadRowView extends ConsumerWidget {
  /// Creates the header row for [row].
  const TurnHeadRowView({super.key, required this.row, required this.turn});

  /// The row.
  final TurnHeadRow row;

  /// The turn's shared state.
  final FeedTurnState turn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = row.item.message;
    final collapse = row.item.collapseHeader;
    final name = agentTurnName(ref, message);
    // Capped so a long answer doesn't force the semantics tree to re-diff a
    // multi-KB string per update. While live, just the name — the feed
    // already paces live announcements.
    final content = message.content;
    final label = turn.live.isLive
        ? name
        : '$name: ${content.length > 200 ? '${content.substring(0, 200)}…' : content}';
    return Padding(
      // Flat turns breathe between turn boundaries; grouped turns stay tight.
      padding: EdgeInsetsDirectional.only(
        top: collapse ? AppSpacing.xxs : AppSpacing.xl,
      ),
      child: Semantics(
        label: label,
        child: _TurnHoverRegion(
          hover: turn.hover,
          child: SizedBox(
            width: double.infinity,
            child: AgentTurnHeader(message: message, collapseHeader: collapse),
          ),
        ),
      ),
    );
  }
}

/// One transcript row of an agent turn laid out row by row.
class TurnPartRowView extends ConsumerWidget {
  /// Creates the transcript row for [row].
  const TurnPartRowView({super.key, required this.row, required this.turn});

  /// The row.
  final TurnPartRow row;

  /// The turn's shared state.
  final FeedTurnState turn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TurnHoverRegion(
      hover: turn.hover,
      child: Padding(
        // The first row sits under the header the way a turn's body does;
        // the rest keep the transcript's own rhythm.
        padding: EdgeInsetsDirectional.only(
          top: row.isFirst ? AppSpacing.sm : row.plan.gapBefore,
        ),
        child: SizedBox(
          width: double.infinity,
          child: turn.rows.build(
            row.plan,
            segments: row.segments,
            codeFont: ref.watch(codeFontFamilyProvider),
            live: row.isLive ? turn.live : null,
          ),
        ),
      ),
    );
  }
}

/// The footer row of an agent turn laid out row by row: trailer, badges,
/// reactions and the message's hover rail, revealed by hovering any of the
/// turn's rows.
class TurnFootRowView extends ConsumerWidget {
  /// Creates the footer row for [row].
  const TurnFootRowView({
    super.key,
    required this.row,
    required this.turn,
    this.onStartThread,
    this.onOpenThread,
  });

  /// The row.
  final TurnFootRow row;

  /// The turn's shared state.
  final FeedTurnState turn;

  /// Hover-rail "start thread" action; null hides it.
  final VoidCallback? onStartThread;

  /// Opens the thread the turn started; null hides the replies row.
  final void Function(String threadId)? onOpenThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = row.item.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FocusableBubble(
          messageId: message.id,
          spaceId: message.spaceId,
          copyText: message.content,
          canRevert: true,
          onStartThread: onStartThread,
          groupHover: turn.hover,
          child: SizedBox(
            width: double.infinity,
            child: AgentTurnFooter(
              listed: message,
              shown: message,
              canRetry: row.item.canRetry,
            ),
          ),
        ),
        MessageFootnotes(message: message, onOpenThread: onOpenThread),
      ],
    );
  }
}
