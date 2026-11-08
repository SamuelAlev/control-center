import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_rows.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spaces the panel lists before leaving the rest to the app.
const int _maxSpaces = 6;

/// Live conversations listed under one space.
const int _maxConversations = 3;

/// The panel's clock for relative-time captions: one ticker for every row.
final _captionClockProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream<int>.periodic(const Duration(seconds: 30), (tick) => tick),
);

/// The workspace's spaces: whatever is working first, then the most recently
/// active. A working or unread space lists the conversations doing it
/// underneath. Spaces already under "Needs you" are left out.
///
/// While the connection is down the rows show their last known order and
/// age, muted, without spinners or unread marks: those would be decoration,
/// not state.
class TraySpacesSection extends ConsumerWidget {
  /// Creates a [TraySpacesSection].
  const TraySpacesSection({
    required this.workspaceId,
    required this.status,
    super.key,
  });

  /// The active workspace.
  final String workspaceId;

  /// The tray's status: the connection, and the spaces listed above.
  final TrayStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    final stale = status.connection != TrayConnection.online;
    final spaces = ref.watch(workspaceVisibleSpacesProvider(workspaceId));
    if (spaces.isEmpty) {
      return CcSidebarGroup(
        label: l10n.trayPanelSpaces,
        children: [TrayPanelNote(text: l10n.trayPanelNoSpaces)],
      );
    }
    final waiting = stale
        ? const <String>{}
        : {for (final space in status.attention) space.spaceId};
    final lastActive = ref.watch(
      workspaceSpaceActivityProvider(workspaceId).select(
        (activity) => {
          for (final entry in (activity.value ?? const {}).values)
            entry.spaceId: entry.lastMessageAt,
        },
      ),
    );
    final ranked =
        [
          for (final (index, space) in spaces.indexed)
            if (!waiting.contains(space.id))
              (
                space: space,
                working:
                    !stale &&
                    ref.watch(spaceStatusProvider(space.id)) ==
                        SpaceStatus.running,
                at: lastActive[space.id],
                index: index,
              ),
        ]..sort((a, b) {
          if (a.working != b.working) {
            return a.working ? -1 : 1;
          }
          final byRecency = switch ((a.at, b.at)) {
            (final DateTime x, final DateTime y) => y.compareTo(x),
            (null, DateTime()) => 1,
            (DateTime(), null) => -1,
            _ => 0,
          };
          return byRecency != 0 ? byRecency : a.index.compareTo(b.index);
        });

    final shown = ranked.take(_maxSpaces).toList(growable: false);
    final rows = <Widget>[];
    for (final entry in shown) {
      final space = entry.space;
      final live = stale
          ? const <_LiveConversation>[]
          : _liveConversations(ref, space.id);
      rows
        ..add(
          _SpaceItem(
            key: ValueKey(space.id),
            space: space,
            workspaceId: workspaceId,
            lastActiveAt: entry.at,
            stale: stale,
            runningShownBelow: live.any((c) => c.running),
            unreadShownBelow: live.any((c) => c.unread),
          ),
        )
        ..addAll([
          for (final c in live)
            _ConversationItem(
              key: ValueKey('${space.id}/${c.conversation.id}'),
              conversation: c.conversation,
              workspaceId: workspaceId,
              runningSince: c.runningSince,
              unread: c.unread,
            ),
        ]);
    }
    // Everything not on screen, including what "Needs you" took.
    if (spaces.length > shown.length) {
      rows.add(
        TrayPanelLinkRow(
          icon: AppIcons.layers,
          label: l10n.trayPanelAllSpaces(spaces.length),
          onPress: () => actions.openRoute(spacesRoute(workspaceId)),
        ),
      );
    }
    return CcSidebarGroup(label: l10n.trayPanelSpaces, children: rows);
  }
}

typedef _LiveConversation = ({
  Conversation conversation,
  DateTime? runningSince,
  bool unread,
  bool running,
});

/// The conversations of [spaceId] with a run in flight or unseen replies,
/// running first. None for a space with one conversation: its row already
/// says everything, and for a quiet space (no stream opened for it).
List<_LiveConversation> _liveConversations(WidgetRef ref, String spaceId) {
  final busy = ref.watch(spaceStatusProvider(spaceId)) == SpaceStatus.running;
  if (!busy && !ref.watch(spaceUnreadProvider(spaceId))) {
    return const [];
  }
  final conversations = [
    for (final c
        in ref.watch(spaceConversationsProvider(spaceId)).value ??
            const <Conversation>[])
      if (!c.isArchived) c,
  ];
  if (conversations.length < 2) {
    return const [];
  }
  final started = ref.watch(spaceRunStartedAtProvider(spaceId));
  final live =
      <_LiveConversation>[
        for (final c in conversations)
          if (started[c.id] case final since?)
            (conversation: c, runningSince: since, unread: false, running: true)
          else if (ref.watch(
            conversationUnreadProvider((
              spaceId: spaceId,
              conversationId: c.id,
            )),
          ))
            (conversation: c, runningSince: null, unread: true, running: false),
      ]..sort((a, b) {
        if (a.running != b.running) {
          return a.running ? -1 : 1;
        }
        return b.conversation.updatedAt.compareTo(a.conversation.updatedAt);
      });
  return live.take(_maxConversations).toList(growable: false);
}

/// One space: the sidebar's row, opening the space in the app.
class _SpaceItem extends ConsumerWidget implements CcFluidHoverTarget {
  const _SpaceItem({
    required this.space,
    required this.workspaceId,
    required this.lastActiveAt,
    required this.stale,
    required this.runningShownBelow,
    required this.unreadShownBelow,
    super.key,
  });

  final Space space;
  final String workspaceId;
  final DateTime? lastActiveAt;
  final bool stale;
  final bool runningShownBelow;
  final bool unreadShownBelow;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    final status = stale
        ? SpaceStatus.idle
        : ref.watch(spaceStatusProvider(space.id));
    // The signal sits on the most specific row on screen, as in the sidebar:
    // a conversation listed below that carries it takes it off this row.
    final running = status == SpaceStatus.running && !runningShownBelow;
    final unread =
        !stale && !unreadShownBelow && ref.watch(spaceUnreadProvider(space.id));
    ref.watch(_captionClockProvider);
    final at = lastActiveAt;
    return SpaceRow(
      leading: SpaceLeadingIcon(
        spaceId: space.id,
        running: running,
        selected: false,
        absent: const SpaceStatusMark(),
        unreadConversationCount: stale
            ? 0
            : ref.watch(spaceUnreadConversationCountProvider(space.id)),
      ),
      label: space.name.isNotEmpty ? space.name : l10n.spaceLabel,
      selected: false,
      status: status,
      unread: unread,
      muted: stale,
      leadingHandlesRunning: true,
      trailingLabel: at == null ? null : formatCompactAge(context, at),
      onPress: () => actions.openRoute(spaceRoute(workspaceId, space.id)),
    );
  }
}

/// One live conversation under its space: spinning while it runs (captioned
/// with how long), the accent dot while it has unseen replies.
class _ConversationItem extends ConsumerWidget implements CcFluidHoverTarget {
  const _ConversationItem({
    required this.conversation,
    required this.workspaceId,
    required this.runningSince,
    required this.unread,
    super.key,
  });

  final Conversation conversation;
  final String workspaceId;
  final DateTime? runningSince;
  final bool unread;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    ref.watch(_captionClockProvider);
    final running = runningSince != null;
    return SpaceRow(
      indent: kSpaceSidebarMarkSlot + kSpaceSidebarMarkGap,
      markSlot: kConversationMarkSlot,
      markGap: kConversationMarkGap,
      labelFontSize: kConversationLabelFontSize,
      extent: kConversationRowExtent,
      leading: conversationActivityMark(running: running, unread: unread),
      label: conversationDisplayName(conversation, l10n),
      trailingLabel: formatCompactAge(
        context,
        runningSince ?? conversation.updatedAt,
      ),
      selected: false,
      status: running ? SpaceStatus.running : SpaceStatus.idle,
      unread: false,
      leadingHandlesRunning: true,
      onPress: () => actions.openRoute(
        spaceRoute(
          workspaceId,
          conversation.spaceId,
          tab: conversationTabKey(conversation.id),
        ),
      ),
    );
  }
}
