import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/presentation/widgets/messaging_inner_sidebar.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_panel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/string_utils.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Messaging screen with a resizable sidebar + conversation + optional terminal.
class MessagingScreen extends ConsumerStatefulWidget {
  /// Creates a new [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final double _sidebarWidth = 240;
  final double _terminalWidth = 420;
  bool _showTerminal = false;
  TerminalSession? _terminalSession;

  void _closeTerminal() {
    setState(() {
      _showTerminal = false;
      _terminalSession = null;
    });
  }

  Future<void> _toggleTerminal() async {
    final l10n = AppLocalizations.of(context);
    final selectedId = ref.read(selectedChannelIdProvider);
    if (selectedId == null) {
      return;
    }

    if (_showTerminal) {
      _closeTerminal();
      return;
    }
    final session = await _resolveTerminalSession(selectedId);
    if (!mounted) {
      return;
    }
    if (session == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noAgentAssigned)));
      return;
    }
    setState(() {
      _terminalSession = session;
      _showTerminal = true;
    });
  }

  Future<TerminalSession?> _resolveTerminalSession(String channelId) async {
    final participants =
        ref.read(channelParticipantsProvider(channelId)).value ?? const [];
    final agentEntry = participants
        .where((p) => !p.isUser)
        .cast<ChannelParticipant>()
        .firstOrNull;
    if (agentEntry == null) {
      return null;
    }
    final agent = await ref
        .read(agentRepositoryProvider)
        .getById(agentEntry.agentId);
    if (agent == null) {
      return null;
    }
    final fs = ref.read(workspaceFilesystemPortProvider);
    final slug = slugify(agent.name);
    final dir = await fs.agentDir(agent.workspaceId, slug);
    if (!dir.existsSync()) {
      await fs.ensureAgentDir(agent.workspaceId, slug);
    }
    return TerminalSession(
      sessionId: channelId,
      agentDirHostPath: dir.path,
      workspaceId: agent.workspaceId,
      agentId: agent.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedChannelIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];

    ref.listen(selectedChannelIdProvider, (previous, next) {
      if (previous != next) {
        // Close thread panel when switching channels
        ref.read(selectedThreadMessageIdProvider.notifier).state = null;
        setState(() {
          _showTerminal = false;
          _terminalSession = null;
        });
      }
    });

    void cycleChannel({required int delta}) {
      if (channels.isEmpty) {
        return;
      }
      final currentIndex = channels.indexWhere((c) => c.id == selectedId);
      final base = currentIndex < 0 ? 0 : currentIndex;
      final raw = (base + delta) % channels.length;
      final next = raw < 0 ? raw + channels.length : raw;
      ref.read(selectedChannelIdProvider.notifier).select(channels[next].id);
    }

    return ScopedShortcuts(
      scope: '/messaging',
      bindings: {
        'msg.new-dm': () => showNewDmDialog(context, ref),
        'msg.new-group': () => showNewGroupDialog(context, ref),
        'msg.next-channel': () => cycleChannel(delta: 1),
        'msg.prev-channel': () => cycleChannel(delta: -1),
        if (selectedId != null)
          'msg.delete-channel': () =>
              _confirmDeleteSelectedChannel(context, ref, selectedId),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final hasTerminal =
              _showTerminal && _terminalSession != null && selectedId != null;
          final sidebarW = _sidebarWidth;
          final terminalW = hasTerminal ? _terminalWidth : 0.0;
          final convW = totalWidth - sidebarW - terminalW;

          final children = <FResizableRegion>[
            FResizableRegion.region(
              initialExtent: sidebarW,
              minExtent: 180,
              builder: (context, data, _) {
                final w = data.extent.current;
                return FSidebar(
                  style: FSidebarStyleDelta.delta(
                    constraints: BoxConstraints(minWidth: w, maxWidth: w),
                  ),
                  header: const MessagingInnerSidebarHeader(),
                  children: const [MessagingInnerSidebar()],
                );
              },
            ),
            FResizableRegion.region(
              initialExtent: convW,
              minExtent: 300,
              builder: (context, data, _) {
                if (selectedId == null) {
                  return const _EmptyState();
                }
                return _ActiveChannelPane(
                  channelId: selectedId,
                  onToggleTerminal: _toggleTerminal,
                  showTerminal: _showTerminal,
                );
              },
            ),
          ];

          if (hasTerminal) {
            children.add(
              FResizableRegion.region(
                initialExtent: terminalW,
                minExtent: 200,
                builder: (context, data, _) => TerminalPanel(
                  session: _terminalSession!,
                  onShellExit: _closeTerminal,
                ),
              ),
            );
          }

          return FResizable(
            axis: Axis.horizontal,
            divider: FResizableDivider.divider,
            children: children,
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteSelectedChannel(
  BuildContext context,
  WidgetRef ref,
  String channelId,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.deleteConversation),
      body: Text(l10n.deleteConversationConfirm),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  await ref.read(messagingServiceProvider).deleteChannel(channelId);
  if (context.mounted) {
    ref.read(selectedChannelIdProvider.notifier).select(null);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.messageSquareDashed,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.selectConversation, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.startDmWithAgent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChannelPane extends ConsumerStatefulWidget {
  const _ActiveChannelPane({
    required this.channelId,
    required this.onToggleTerminal,
    required this.showTerminal,
  });

  final String channelId;
  final VoidCallback onToggleTerminal;
  final bool showTerminal;

  @override
  ConsumerState<_ActiveChannelPane> createState() => _ActiveChannelPaneState();
}

class _ActiveChannelPaneState extends ConsumerState<_ActiveChannelPane> {
  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channelsAsync = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId))
        : ref.watch(channelsProvider);

    if (channelsAsync.isLoading) {
      return const Center(child: FCircularProgress());
    }

    final channel = channelsAsync.value
        ?.where((c) => c.id == widget.channelId)
        .firstOrNull;

    if (channel == null) {
      return const _EmptyState();
    }

    final threadParentId = ref.watch(selectedThreadMessageIdProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              ChannelHeader(
                channel: channel,
                onManage: () => _handleManage(context, ref, channel.isDm),
                onDelete: () => _handleDeleteChannel(context, ref),
                onToggleTerminal: widget.onToggleTerminal,
                terminalOpen: widget.showTerminal,
              ),
              const Divider(height: 1),
              Expanded(
                child: ChannelMessageFeed(
                  channelId: widget.channelId,
                  onReplyInThread: (messageId) {
                    ref.read(selectedThreadMessageIdProvider.notifier).state =
                        messageId;
                  },
                ),
              ),
              const Divider(height: 1),
              ChannelInputBar(channelId: widget.channelId),
            ],
          ),
        ),
        if (threadParentId != null)
          ThreadPanel(
            channelId: widget.channelId,
            parentMessageId: threadParentId,
            onClose: () {
              ref.read(selectedThreadMessageIdProvider.notifier).state = null;
            },
          ),
      ],
    );
  }

  void _handleManage(BuildContext context, WidgetRef ref, bool isDm) {
    showDialog(
      context: context,
      builder: (_) =>
          ManageChannelDialog(channelId: widget.channelId, isDm: isDm),
    );
  }

  Future<void> _handleDeleteChannel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteConversation),
        body: Text(l10n.deleteConversationConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  variant: FButtonVariant.destructive,
                  onPress: () => Navigator.pop(ctx, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(messagingServiceProvider).deleteChannel(widget.channelId);
    if (context.mounted) {
      ref.read(selectedChannelIdProvider.notifier).select(null);
    }
  }
}
