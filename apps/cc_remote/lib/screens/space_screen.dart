import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/conversation_feed.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/jump_to_latest.dart';
import 'package:cc_remote/widgets/messaging/conversation_actions.dart';
import 'package:cc_remote/widgets/messaging/conversation_chrome.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/messaging/space_composer_bar.dart';
import 'package:cc_remote/widgets/messaging/space_message_tile.dart';
import 'package:cc_remote/widgets/reverse_follow_physics.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'space_screen_composer.dart';
part 'space_screen_follow.dart';
part 'space_screen_messages.dart';
part 'space_screen_message_feed.dart';

/// Resolves exact conversation/message identities before opening a composer.
class SpaceScreen extends ConsumerWidget {
  const SpaceScreen({
    required this.spaceId,
    this.conversationId,
    this.messageId,
    super.key,
  });
  final String spaceId;
  final String? conversationId;
  final String? messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = (
      spaceId: spaceId,
      conversationId: conversationId,
      messageId: messageId,
    );
    final conversation = ref.watch(remoteConversationProvider(route));
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    return conversation.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => SafeArea(
        child: Column(
          children: [
            DetailHeader(title: AppLocalizations.of(context).thread),
            Expanded(
              child: CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: AppLocalizations.of(context).messagesLoadFailed,
                description: '$e',
              ),
            ),
            CcButton(
              onPressed: () =>
                  ref.invalidate(remoteConversationProvider(route)),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (value) => value == null || workspaceId == null
          ? const Center(child: CcSpinner())
          : _ConversationScreen(
              key: ValueKey((workspaceId, value.id, messageId)),
              workspaceId: workspaceId,
              spaceId: spaceId,
              conversation: value,
              messageId: messageId,
            ),
    );
  }
}

class _ConversationScreen extends ConsumerStatefulWidget {
  const _ConversationScreen({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.conversation,
    this.messageId,
  });
  final String workspaceId;
  final String spaceId;
  final Conversation conversation;
  final String? messageId;
  String get conversationId => conversation.id;

  @override
  ConsumerState<_ConversationScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<_ConversationScreen> {
  final ScrollController _scroll = ScrollController();
  final _follow = FollowState();
  final _rowKeys = <String, GlobalKey>{};
  final _keptTiles = <String, _KeptTile>{};
  late final ConversationDraft _draft;
  TextEditingController get _composer => _draft.controller;
  bool get _sending => _draft.sending;
  List<DraftAttachment> get _pending => _draft.attachments;
  RemoteConversationKey get _scope => (
    workspaceId: widget.workspaceId,
    spaceId: widget.spaceId,
    conversationId: widget.conversationId,
  );
  String get _feedKey => conversationFeedKey(_scope);
  String? _attachError;
  bool _didInitialLanding = false;
  String? _lastNewestId;
  int _newWhileAway = 0;
  bool _showJump = false;
  bool _programmatic = false;
  String? _announcedStartFor;
  String? _announcedDoneFor;
  bool _newestWasStreaming = false;
  bool _hasMore = false;
  int _lastMessageCount = 0;
  String? _myUserId;
  Map<String, String> _userNames = const {};
  String? _lastReadId;
  bool _markingRead = false;
  Object? _readError;

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _draftChanged() => _set(() {});

  @override
  void initState() {
    super.initState();
    _draft = ref
        .read(conversationDraftsProvider)
        .putIfAbsent(_scope, ConversationDraft.new);
    _draft.addListener(_draftChanged);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _draft.removeListener(_draftChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    _myUserId = ref.watch(remoteIdentityProvider).value?.userId;
    _userNames = ref.watch(remoteUserNamesProvider).value ?? const {};
    final feedProvider = conversationFeedProvider(_scope);
    final feed = ref.watch(feedProvider);
    ref.listen(
      feedProvider,
      (_, next) => _onMessagesChanged(
        next.value?.messages.where((message) => !_queued(message)).toList() ??
            const [],
      ),
    );
    final allMessages = feed.value?.messages ?? const <MessageDto>[];
    final messages = allMessages.where((m) => !_queued(m)).toList();
    final queued = allMessages.where(_queued).toList();
    _hasMore = feed.value?.hasMore ?? false;
    final runs = ref.watch(activeRunLogsProvider(widget.conversationId));
    final hasActiveRun = (runs.value ?? const <AgentRunLogDto>[]).any(
      (run) => const ['running', 'pending', 'paused'].contains(run.status),
    );
    final turns = ref.watch(phoneTurnRelayProvider(widget.spaceId));
    final conversation =
        ref
            .watch(remoteConversationsProvider(widget.spaceId))
            .value
            ?.where((c) => c.id == widget.conversationId)
            .firstOrNull ??
        widget.conversation;
    final writable =
        ref.watch(workspaceRoleProvider).value?.canWrite == true &&
        !conversation.isArchived &&
        ref.watch(activeWorkspaceIdProvider).value == widget.workspaceId;
    _updateWindow(messages);
    _scheduleRead(messages);
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              ConversationHeader(scope: _scope, title: conversation.title),
              ConversationAttention(
                scope: _scope,
                runs: runs,
                queued: queued,
                canWrite: writable,
                archived: conversation.isArchived,
                readError: _readError,
                onReadRetry: () {
                  _readError = null;
                  _scheduleRead(messages);
                },
                maxHeight: constraints.maxHeight * .35,
              ),
              Expanded(
                child: _messageFeed(t, feed, messages, turns, hasActiveRun),
              ),
              SpaceComposerBar(
                controller: _composer,
                sending: _sending,
                enabled: writable,
                ready: _draft.ready,
                pending: _pending,
                attachError: _attachError ?? _draft.error?.toString(),
                detailsMaxHeight: (constraints.maxHeight * .16).clamp(
                  32.0,
                  120.0,
                ),
                maxLines: constraints.maxHeight < 500 ? 2 : 5,
                onAttach: _attach,
                onSend: _send,
                onRemovePending: _removeAttachment,
                onRetryPending: _uploadDraftAttachment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _queued(MessageDto message) =>
    message.messageType == 'steering' &&
    message.metadata is Map &&
    (message.metadata as Map)['steerState'] == 'queued';
