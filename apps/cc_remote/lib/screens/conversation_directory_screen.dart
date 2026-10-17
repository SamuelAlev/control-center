import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_feed.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/conversation_directory_results.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/phone_text_editor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationDirectoryScreen extends ConsumerStatefulWidget {
  const ConversationDirectoryScreen({required this.spaceId, super.key});
  final String spaceId;
  @override
  ConsumerState<ConversationDirectoryScreen> createState() => _DirectoryState();
}

class _DirectoryState extends ConsumerState<ConversationDirectoryScreen> {
  final _search = TextEditingController();
  List<MessageDto>? _matches;
  String? _workspace;
  bool _archived = false;
  bool _busy = false;
  Object? _error;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function(String, RpcConversationRepository) action,
  ) async {
    final client = ref.read(rpcClientProvider).value;
    final workspace = ref.read(activeWorkspaceIdProvider).value;
    if (client == null || workspace == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(workspace, RpcConversationRepository(client));
    } catch (e) {
      if (mounted && _workspace == workspace) setState(() => _error = e);
    } finally {
      if (mounted && _workspace == workspace) setState(() => _busy = false);
    }
  }

  Future<void> _name(Conversation? conversation) async {
    final workspace = ref.read(activeWorkspaceIdProvider).value;
    final l10n = AppLocalizations.of(context);
    final name = await showPhoneTextEditor(
      context,
      title: conversation == null
          ? l10n.mobileNewConversation
          : l10n.mobileRename,
      label: l10n.mobileConversationName,
      initialText: conversation?.title ?? '',
    );
    if (!mounted ||
        name == null ||
        workspace != ref.read(activeWorkspaceIdProvider).value) {
      return;
    }
    await _run((workspace, repo) async {
      if (conversation != null) {
        await repo.rename(
          workspaceId: workspace,
          conversationId: conversation.id,
          title: name,
        );
      } else {
        final created = await repo.create(
          workspaceId: workspace,
          spaceId: widget.spaceId,
          title: name,
        );
        if (mounted && ref.read(activeWorkspaceIdProvider).value == workspace) {
          unawaited(
            context.push(
              remoteSpaceLocation(
                workspaceId: workspace,
                spaceId: widget.spaceId,
                conversationId: created.id,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _find() => _run((workspace, _) async {
    final query = _search.text.trim();
    final client = ref.read(rpcClientProvider).value!;
    final matches = query.isEmpty
        ? null
        : await RemoteMessagingRepository(
            client,
          ).searchInSpace(workspace, widget.spaceId, query);
    if (mounted && _workspace == workspace) setState(() => _matches = matches);
  });

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(activeWorkspaceIdProvider).value;
    if (_workspace != workspace) {
      _workspace = workspace;
      _matches = null;
      _search.clear();
      _busy = false;
      _error = null;
    }
    final l10n = AppLocalizations.of(context);
    final canWrite = ref.watch(workspaceRoleProvider).value?.canWrite == true;
    final conversations = ref.watch(
      remoteConversationsProvider(widget.spaceId),
    );
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailHeader(title: l10n.mobileConversations),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canWrite)
                      CcButton(
                        size: CcButtonSize.lg,
                        icon: AppIcons.plus,
                        onPressed: _busy ? null : () => _name(null),
                        child: Text(l10n.mobileNewConversation),
                      ),
                    CcButton(
                      size: CcButtonSize.lg,
                      variant: CcButtonVariant.secondary,
                      onPressed: workspace == null
                          ? null
                          : () => context.push(
                              remoteWorkspaceLocation(
                                '/spaces/${Uri.encodeComponent(widget.spaceId)}/manage',
                                workspace,
                              ),
                            ),
                      child: Text(l10n.mobileManageSpace),
                    ),
                    CcChip(
                      label: l10n.mobileArchived,
                      selected: _archived,
                      onPressed: () => setState(() => _archived = !_archived),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CcTextField(
                        controller: _search,
                        hintText: l10n.mobileSearchMessages,
                        onSubmitted: (_) => _find(),
                      ),
                    ),
                    CcButton(
                      size: CcButtonSize.lg,
                      loading: _busy,
                      onPressed: _busy ? null : _find,
                      child: Text(l10n.mobileSearch),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null)
            CcAlert(
              title: l10n.messagesLoadFailed,
              description: Text('$_error'),
              variant: CcAlertVariant.danger,
            ),
          Expanded(
            child: ConversationDirectoryResults(
              matches: _matches,
              conversations: conversations,
              workspaceId: workspace,
              spaceId: widget.spaceId,
              archived: _archived,
              canWrite: canWrite,
              busy: _busy,
              onRename: _name,
              onToggleArchive: (conversation) => _run(
                (workspace, repo) => repo.setStatus(
                  workspaceId: workspace,
                  conversationId: conversation.id,
                  status: conversation.isArchived
                      ? ConversationStatus.active
                      : ConversationStatus.archived,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
