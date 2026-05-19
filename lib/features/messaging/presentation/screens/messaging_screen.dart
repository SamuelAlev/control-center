import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_layout.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Messaging screen rendered as an IDE-like surface: a fixed activity sidebar
/// (Explorer / Source control / Pull requests) plus one or more tabbed editor
/// groups (Chat / Terminal / Browser). The selected conversation comes from the
/// URL (`/channels/:channelId`) and is mirrored into [selectedChannelIdProvider]
/// so the breadcrumbs, read-cursor effect, and IDE layout read one source.
class MessagingScreen extends ConsumerStatefulWidget {
  /// Creates a new [MessagingScreen].
  const MessagingScreen({
    super.key,
    this.selectedChannelId,
    this.pendingMessageId,
    this.focusedTabKey,
  });

  /// The channel id from the route, or null on the bare `/channels` location.
  final String? selectedChannelId;

  /// A message id deep-linked via `?m=<id>` (a permalink target), or null.
  final String? pendingMessageId;

  /// The focused editor tab's key, deep-linked via `?tab=<key>`, or null when
  /// the URL names no tab (the IDE then keeps its seeded/restored selection).
  final String? focusedTabKey;

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  /// IDE editor action sink — owned by this state so the keyboard shortcuts
  /// (⌘T/⌘W/⌘B) can drive the layout without coupling to its private state.
  ///
  /// MUST be a state field, never rebuilt in [build]: [MessagingIdeLayout]
  /// wires its callbacks onto this instance in its `initState`, so a fresh sink
  /// per build would hand the dispatcher an unwired object (every callback
  /// null) on the first rebuild — the shortcut then matches, consumes the key,
  /// and silently does nothing.
  ///
  /// Note: on web ⌘T (new tab) and ⌘W (close tab) are browser accelerators the
  /// page never receives, so those two fire on desktop only; ⌘B still works.
  final MessagingIdeActions _ideActions = MessagingIdeActions();

  @override
  void initState() {
    super.initState();
    _syncSelectionFromRoute();
  }

  @override
  void didUpdateWidget(MessagingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChannelId != widget.selectedChannelId ||
        oldWidget.pendingMessageId != widget.pendingMessageId) {
      _syncSelectionFromRoute();
    }
  }

  /// Mirrors the URL's channel id into [selectedChannelIdProvider], and forwards
  /// a `?m=<id>` deep link into [pendingFocusMessageProvider] for the channel
  /// feed to consume. Deferred a frame so we never mutate a provider mid-build
  /// of the route's page.
  void _syncSelectionFromRoute() {
    final id = widget.selectedChannelId;
    final messageId = widget.pendingMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(selectedChannelIdProvider) != id) {
        ref.read(selectedChannelIdProvider.notifier).select(id);
      }
      if (id != null && messageId != null && messageId.isNotEmpty) {
        ref.read(pendingFocusMessageProvider.notifier).set((
          channelId: id,
          messageId: messageId,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedChannelIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];

    void cycleChannel({required int delta}) {
      if (channels.isEmpty || workspaceId == null) {
        return;
      }
      final currentIndex = channels.indexWhere((c) => c.id == selectedId);
      final base = currentIndex < 0 ? 0 : currentIndex;
      final raw = (base + delta) % channels.length;
      final next = raw < 0 ? raw + channels.length : raw;
      // The URL is the source of truth: navigate, and the screen mirrors it
      // into [selectedChannelIdProvider].
      GoRouter.of(context).go(channelRoute(workspaceId, channels[next].id));
    }

    return ScopedShortcuts(
      scope: '/channels',
      bindings: {
        'msg.new-channel': () => showNewChannelDialog(context, ref),
        'msg.next-channel': () => cycleChannel(delta: 1),
        'msg.prev-channel': () => cycleChannel(delta: -1),
        if (selectedId != null)
          'msg.delete-channel': () =>
              _confirmDeleteSelectedChannel(context, ref, selectedId),
        'msg.ide-new-tab': () => _ideActions.openEditor?.call(),
        'msg.ide-close-tab': () => _ideActions.closeActiveTab?.call(),
        'msg.ide-toggle-sidebar': () => _ideActions.toggleSidebar?.call(),
      },
      child: workspaceId == null
          ? const Center(child: CcSpinner())
          : MessagingIdeLayout(
              workspaceId: workspaceId,
              selectedChannelId: selectedId,
              focusedTabKey: widget.focusedTabKey,
              actions: _ideActions,
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
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: l10n.deleteConversation,
      content: Text(l10n.deleteConversationConfirm),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  await ref
      .read(messagingServiceProvider)
      .deleteChannel(ref.requireWorkspaceId(), channelId);
  if (context.mounted && workspaceId != null) {
    // URL is the source of truth: drop back to the channel list (no selection).
    GoRouter.of(context).go(channelsRoute(workspaceId));
  }
}
