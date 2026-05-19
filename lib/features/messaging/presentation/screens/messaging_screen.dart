import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_layout.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Messaging screen rendered as an IDE-like surface: a fixed activity sidebar
/// (Explorer / Source control / Pull requests) plus one or more tabbed editor
/// groups (Chat / Terminal / Browser). Conversation selection stays
/// provider-driven and is set from the untouched global app sidebar.
class MessagingScreen extends ConsumerStatefulWidget {
  /// Creates a new [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedChannelIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];

    // Reset the thread panel when switching channels. The editor tab layout is
    // owned by MessagingIdeLayout (ephemeral); only the thread reset lives here.
    ref.listen(selectedChannelIdProvider, (previous, next) {
      if (previous != next) {
        ref.read(selectedThreadMessageIdProvider.notifier).state = null;
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
      child: workspaceId == null
          ? const Center(child: CcSpinner())
          : MessagingIdeLayout(
              workspaceId: workspaceId,
              selectedChannelId: selectedId,
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
  await ref.read(messagingServiceProvider).deleteChannel(channelId);
  if (context.mounted) {
    ref.read(selectedChannelIdProvider.notifier).select(null);
  }
}
