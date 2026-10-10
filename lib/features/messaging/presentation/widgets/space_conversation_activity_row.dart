import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One 30s clock shared by every conversation row's relative-time caption,
/// instead of a periodic timer per row. Rows select the caption bucket off it
/// (see [_ageBucket]), so a tick rebuilds only the rows whose text changes.
final _captionClockProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream<int>.periodic(const Duration(seconds: 30), (tick) => tick),
);

/// The unit [formatCompactAge] renders [at] in, at that unit's resolution:
/// whole minutes under an hour, whole hours under a day, whole days beyond
/// (months and years are derived from days there). Equal buckets render the
/// same caption.
(int, int) _ageBucket(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.isNegative || diff.inMinutes < 1) {
    return (0, 0);
  }
  if (diff.inHours < 1) {
    return (1, diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return (2, diff.inHours);
  }
  return (3, diff.inDays);
}

/// One conversation of the open space's card: its activity mark, title and
/// how long ago it was active (or how long its run has lasted).
class SpaceConversationActivityRow extends ConsumerWidget {
  /// Creates a [SpaceConversationActivityRow].
  const SpaceConversationActivityRow({
    super.key,
    required this.conversation,
    required this.spaceId,
  });

  /// The conversation this row shows.
  final Conversation conversation;

  /// The space the conversation belongs to.
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only this conversation's start: a run elsewhere in the space (and the
    // run stream's once-a-second output stamps) leaves this row alone.
    final runningSince = ref.watch(
      spaceRunStartedAtProvider(
        spaceId,
      ).select((started) => started[conversation.id]),
    );
    final running = runningSince != null;
    final captionAt = runningSince ?? conversation.updatedAt;
    // Coarse enough to keep a list of conversations cheap, fine enough that
    // a minute or hour boundary shows up while the row is on screen.
    ref.watch(_captionClockProvider.select((_) => _ageBucket(captionAt)));
    final unread = ref.watch(
      conversationUnreadProvider((
        spaceId: spaceId,
        conversationId: conversation.id,
      )),
    );
    final l10n = AppLocalizations.of(context);
    // No selected fill and no overflow: rename and archive live on the tab.
    // The leading mark is the only status: hollow when idle, spinning while
    // a run is in progress, filled accent when messages are unseen.
    return SpaceRow(
      indent: kSpaceSidebarMarkSlot + kSpaceSidebarMarkGap,
      markSlot: kConversationMarkSlot,
      markGap: kConversationMarkGap,
      labelFontSize: kConversationLabelFontSize,
      extent: kConversationRowExtent,
      leading: conversationActivityMark(running: running, unread: unread),
      label: conversationDisplayName(conversation, l10n),
      labelScrambling: ref.watch(
        conversationTitleGeneratingProvider((
          spaceId: spaceId,
          conversationId: conversation.id,
        )),
      ),
      trailingLabel: formatCompactAge(context, captionAt),
      selected: false,
      status: running ? SpaceStatus.running : SpaceStatus.idle,
      // The leading mark is the unread signal, so the trailing dot stays off.
      unread: false,
      leadingHandlesRunning: true,
    );
  }
}
