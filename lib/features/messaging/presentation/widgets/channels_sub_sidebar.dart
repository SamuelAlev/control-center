import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_sidebar_item.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The channels directory's contextual sub-sidebar: a settings-like panel
/// (title row + name filter on top) listing every channel of the active
/// workspace, shown next to the content area on `/channels` routes while the
/// global sidebar is collapsed to its icon-only rail. (In the expanded sidebar
/// the inline [ConversationsSidebarSection] already carries the channel list,
/// so mounting both would duplicate it.)
///
/// Rows reuse [ChannelSidebarItem], so live status, unread dots, PR badges,
/// and the delete affordances behave exactly like the global sidebar's list;
/// tapping a row navigates to that channel ([channelRoute]).
class ChannelsSubSidebar extends ConsumerStatefulWidget {
  /// Creates a [ChannelsSubSidebar].
  const ChannelsSubSidebar({super.key});

  @override
  ConsumerState<ChannelsSubSidebar> createState() => _ChannelsSubSidebarState();
}

class _ChannelsSubSidebarState extends ConsumerState<ChannelsSubSidebar> {
  /// Free-text filter narrowing the channel list by name (mirrors the
  /// settings sub-sidebar's category filter).
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() {
      final next = _filterController.text;
      if (next != _filter) {
        setState(() => _filter = next);
      }
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Keeps the read-cursor side effect alive while the directory is mounted:
    // in rail mode the global sidebar's inline channel list is gone, so this
    // is the watcher that stamps the read cursor on selection.
    ref.watch(selectedChannelReadCursorEffectProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // The URL is the source of truth for the open channel (same derivation as
    // the global sidebar's list — the shell sits above the channel route).
    final routeChannelId = selectedChannelIdFromLocation(
      GoRouterState.of(context).uri.path,
      workspaceId,
    );
    final channels = workspaceId != null
        ? ref.watch(workspaceVisibleChannelsProvider(workspaceId))
        : ref.watch(visibleChannelsProvider);

    final filter = _filter.trim().toLowerCase();
    bool matches(Channel c) {
      if (filter.isEmpty) {
        return true;
      }
      final name = c.name.isNotEmpty ? c.name : l10n.channelLabel;
      return name.toLowerCase().contains(filter);
    }

    final humanChannels = channels
        .where((c) => !c.origin.isAgentDm && matches(c))
        .toList();
    final agentChannels = channels
        .where((c) => c.origin.isAgentDm && matches(c))
        .toList();

    void open(String channelId) {
      final wsId = workspaceId;
      if (wsId != null) {
        GoRouter.of(context).go(channelRoute(wsId, channelId));
      }
    }

    return CcSidebar(
      width: 240,
      trailingBorder: BorderSide(color: t.borderPrimary),
      header: _ChannelsSidebarHeader(controller: _filterController),
      children: [
        if (channels.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Text(
              l10n.noChannelsYet,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          )
        else if (humanChannels.isEmpty && agentChannels.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              l10n.noChannelsMatch(_filter.trim()),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          )
        else ...[
          CcSidebarGroup(
            label: l10n.channels,
            children: [
              for (final channel in humanChannels)
                ChannelSidebarItem(
                  channel: channel,
                  selected: channel.id == routeChannelId,
                  onPress: () => open(channel.id),
                ),
            ],
          ),
          if (agentChannels.isNotEmpty)
            CcSidebarGroup(
              label: l10n.agentsSectionLabel,
              children: [
                for (final channel in agentChannels)
                  ChannelSidebarItem(
                    channel: channel,
                    selected: channel.id == routeChannelId,
                    muted: true,
                    onPress: () => open(channel.id),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Header for the channels sub-sidebar: a title row (with the new-channel
/// action) plus the name filter that narrows the list below — the same shape
/// as the settings sub-sidebar header.
class _ChannelsSidebarHeader extends ConsumerWidget {
  const _ChannelsSidebarHeader({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.messagesSquare,
                size: 16,
                color: context.designSystem?.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.channels,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.ds.textPrimary,
                  ),
                ),
              ),
              CcIconButton(
                icon: AppIcons.plus,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.newChannel,
                onPressed: () => showNewChannelDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CcTextField(
            controller: controller,
            hintText: l10n.filterChannelsHint,
          ),
        ],
      ),
    );
  }
}
