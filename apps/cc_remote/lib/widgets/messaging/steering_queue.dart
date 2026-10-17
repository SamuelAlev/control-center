import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/phone_text_editor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SteeringQueue extends ConsumerStatefulWidget {
  const SteeringQueue({
    super.key,
    required this.scope,
    required this.messages,
    required this.canWrite,
  });
  final RemoteConversationKey scope;
  final List<MessageDto> messages;
  final bool canWrite;
  @override
  ConsumerState<SteeringQueue> createState() => _QueueState();
}

class _QueueState extends ConsumerState<SteeringQueue> {
  bool _acting = false;
  Object? _error;
  List<MessageDto> get _ordered => [...widget.messages]
    ..sort((a, b) {
      num order(MessageDto m) => m.metadata is Map
          ? ((m.metadata as Map)['steerOrder'] as num? ?? 0)
          : 0;
      return order(a).compareTo(order(b));
    });

  Future<void> _act(String action, MessageDto message) async {
    final scope = widget.scope;
    final l10n = AppLocalizations.of(context);
    final text = action == 'edit'
        ? await showPhoneTextEditor(
            context,
            title: l10n.mobileEditQueued,
            label: l10n.messageHint,
            initialText: message.content,
            multiline: true,
          )
        : null;
    if (!mounted ||
        !widget.canWrite ||
        _acting ||
        (action == 'edit' && text == null) ||
        ref.read(activeWorkspaceIdProvider).value != scope.workspaceId) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      final dispatch = RemoteMessagingDispatch(client);
      bool accepted;
      switch (action) {
        case 'edit':
          accepted = await dispatch.editSteering(
            workspaceId: scope.workspaceId,
            spaceId: scope.spaceId,
            conversationId: scope.conversationId,
            messageId: message.id,
            content: text!,
          );
        case 'delete':
          accepted = await dispatch.deleteSteering(
            workspaceId: scope.workspaceId,
            spaceId: scope.spaceId,
            conversationId: scope.conversationId,
            messageId: message.id,
          );
        case 'deliver':
          accepted = await dispatch.deliverSteering(
            workspaceId: scope.workspaceId,
            spaceId: scope.spaceId,
            conversationId: scope.conversationId,
            messageId: message.id,
          );
        default:
          final ordered = _ordered.map((m) => m.id).toList();
          final index = ordered.indexOf(message.id);
          final target = action == 'up' ? index - 1 : index + 1;
          if (index < 0 || target < 0 || target >= ordered.length) return;
          ordered.removeAt(index);
          ordered.insert(target, message.id);
          await dispatch.reorderSteering(
            workspaceId: scope.workspaceId,
            spaceId: scope.spaceId,
            conversationId: scope.conversationId,
            orderedIds: ordered,
          );
          accepted = true;
      }
      if (!accepted) throw StateError(l10n.mobileQueueChanged);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordered = _ordered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          CcAlert(
            title: l10n.mobileActionFailed,
            description: Text('$_error'),
            variant: CcAlertVariant.danger,
          ),
        for (var i = 0; i < ordered.length; i++)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ordered[i].content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.canWrite)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in <(String, String)>[
                        ('edit', l10n.mobileEditQueued),
                        ('deliver', l10n.mobileSteerNow),
                        if (i > 0) ('up', l10n.mobileMoveUp),
                        if (i + 1 < ordered.length)
                          ('down', l10n.mobileMoveDown),
                        ('delete', l10n.mobileRemove),
                      ])
                        CcButton(
                          size: CcButtonSize.lg,
                          variant: CcButtonVariant.secondary,
                          onPressed: _acting
                              ? null
                              : () => _act(action.$1, ordered[i]),
                          child: Text(action.$2),
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
