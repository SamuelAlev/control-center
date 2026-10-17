import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/messaging/space_message_tile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Keyset pages reach history beyond the bounded live subscription.
class ConversationHistoryScreen extends ConsumerStatefulWidget {
  const ConversationHistoryScreen({
    required this.spaceId,
    required this.conversationId,
    super.key,
  });
  final String spaceId;
  final String conversationId;
  @override
  ConsumerState<ConversationHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<ConversationHistoryScreen> {
  final _messages = <MessageDto>[];
  String? _workspace;
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  int _generation = 0;

  Future<void> _load() async {
    final workspace = _workspace;
    final client = ref.read(rpcClientProvider).value;
    if (workspace == null || client == null || _loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await RemoteMessagingRepository(client).getMessagePage(
        workspace,
        widget.spaceId,
        widget.conversationId,
        limit: 100,
        cursor: _cursor,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _messages.addAll(page.messages.reversed);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(activeWorkspaceIdProvider).value;
    if (_workspace != workspace) {
      _workspace = workspace;
      _messages.clear();
      _cursor = null;
      _hasMore = true;
      _error = null;
      _loading = false;
      _generation++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(remoteIdentityProvider).value?.userId;
    final turns = ref.watch(phoneTurnRelayProvider(widget.spaceId));
    return SafeArea(
      child: Column(
        children: [
          DetailHeader(title: l10n.mobileOlderMessages),
          if (_error != null)
            CcAlert(
              title: l10n.messagesLoadFailed,
              description: Text('$_error'),
              variant: CcAlertVariant.danger,
              action: CcButton(onPressed: _load, child: Text(l10n.retry)),
            ),
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CcSpinner())
                : _messages.isEmpty && !_hasMore
                ? CcEmptyState(
                    icon: AppIcons.messageCircle,
                    message: l10n.noMessagesYet,
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return CcButton(
                          size: CcButtonSize.lg,
                          loading: _loading,
                          onPressed: _loading ? null : _load,
                          child: Text(l10n.mobileOlderMessages),
                        );
                      }
                      final message = _messages[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SpaceMessageTile(
                            message: message,
                            myUserId: me,
                            userNames: const {},
                            turns: turns,
                          ),
                          CcButton(
                            size: CcButtonSize.lg,
                            variant: CcButtonVariant.secondary,
                            onPressed: workspace == null
                                ? null
                                : () => context.push(
                                    remoteSpaceLocation(
                                      workspaceId: workspace,
                                      spaceId: widget.spaceId,
                                      conversationId: widget.conversationId,
                                      messageId: message.id,
                                    ),
                                  ),
                            child: Text(l10n.openConversation),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
