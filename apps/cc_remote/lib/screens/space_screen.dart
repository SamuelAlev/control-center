import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/jump_to_latest.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/messaging/pending_approvals.dart';
import 'package:cc_remote/widgets/messaging/space_composer_bar.dart';
import 'package:cc_remote/widgets/messaging/space_message_tile.dart';
import 'package:cc_remote/widgets/reverse_follow_physics.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'space_screen_follow.dart';
part 'space_screen_composer.dart';

/// `/spaces/:spaceId` — a realtime conversation. Messages stream live
/// (`messaging.watchMessagesWindow`, newest page first); an agent turn renders
/// its transcript (reasoning, tool calls, results) as it happens. The composer
/// dispatches the space's agents (`dispatch.sendAndDispatch`) so a reply
/// streams back.
class SpaceScreen extends ConsumerStatefulWidget {
  /// Creates a [SpaceScreen].
  const SpaceScreen({required this.spaceId, super.key});

  /// The space id from the route.
  final String spaceId;

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final _follow = FollowState();
  final _rowKeys = <String, GlobalKey>{};

  /// Tiles reused when a window emission changes some other message.
  ///
  /// The list builder runs for every visible index on each snapshot. The
  /// same widget instance lets the element skip the update, so one streaming
  /// row does not lay out every other tile again.
  final _keptTiles = <String, _KeptTile>{};
  bool _sending = false;

  /// Files picked but not yet sent.
  final List<PickedAttachment> _pending = [];

  /// Why the last attach or send left something out.
  String? _attachError;
  bool _didInitialLanding = false;
  String? _lastNewestId;
  int _newWhileAway = 0;
  bool _showJump = false;
  bool _programmatic = false;
  String? _announcedStartFor;
  String? _announcedDoneFor;
  bool _newestWasStreaming = false;

  /// Whether the server has messages older than the subscribed window.
  bool _hasMore = false;

  /// Previous window length, so a grown page can release [FollowState.loadingOlder].
  int _lastMessageCount = 0;

  /// The signed-in user's id (from `identity.me`).
  String? _myUserId;

  /// Display names of co-members.
  Map<String, String> _userNames = const {};

  void _set(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    try {
      final client = ref.read(rpcClientProvider).value;
      if (client == null) return;
      final me = await client.call('identity.me', const {});
      final user = me['user'];
      final users = await client.call('users.list', const {});
      if (!mounted) return;
      setState(() {
        _myUserId = user is Map ? user['id'] as String? : null;
        _userNames = {
          for (final u in (users['users'] as List? ?? const []))
            if (u is Map && u['id'] is String)
              u['id'] as String: (u['display_name'] as String?) ?? '',
        };
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final messagesAsync = ref.watch(spaceMessagesProvider(widget.spaceId));
    ref.listen(spaceMessagesProvider(widget.spaceId), (_, next) {
      final msgs = next.value?.messages ?? const <MessageDto>[];
      _onMessagesChanged(msgs);
    });
    final conversationId = ref
        .watch(spaceConversationIdProvider(widget.spaceId))
        .value;
    final runsAsync = conversationId == null
        ? const AsyncValue<List<AgentRunLogDto>>.loading()
        : ref.watch(activeRunLogsProvider(conversationId));
    final turns = ref.watch(phoneTurnRelayProvider(widget.spaceId));
    final feed = messagesAsync.value;
    final messages = feed?.messages ?? const <MessageDto>[];
    _hasMore = feed?.hasMore ?? false;
    final liveIds = {for (final m in messages) m.id};
    _keptTiles.removeWhere((id, _) => !liveIds.contains(id));
    _rowKeys.removeWhere((id, _) => !liveIds.contains(id));
    if (messages.length != _lastMessageCount) {
      final grew = messages.length > _lastMessageCount;
      _lastMessageCount = messages.length;
      if (grew && _follow.loadingOlder) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _follow.loadingOlder = false;
          _maybeLoadOlder();
        });
      }
    }

    final hasActiveRun = (runsAsync.value ?? const <AgentRunLogDto>[]).any(
      (r) => r.status == 'running' || r.status == 'pending',
    );
    final isStreamingBelow =
        hasActiveRun &&
        _scroll.hasClients &&
        _scroll.position.pixels > kFollowPinThreshold;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DetailHeader(title: AppLocalizations.of(context).thread),
            if (hasActiveRun) _activeBanner(t),
            PendingApprovals(spaceId: widget.spaceId),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CcSpinner(size: 24)),
                error: (e, _) => CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: AppLocalizations.of(context).messagesLoadFailed,
                  description: e.toString(),
                ),
                data: (_) {
                  if (messages.isEmpty) {
                    return CcEmptyState(
                      icon: AppIcons.messageCircle,
                      message: AppLocalizations.of(context).noMessagesYet,
                      description: AppLocalizations.of(
                        context,
                      ).noMessagesDescription,
                    );
                  }
                  final platformPhysics = ScrollConfiguration.of(
                    context,
                  ).getScrollPhysics(context);
                  return NotificationListener<UserScrollNotification>(
                    onNotification: (n) {
                      if (_follow.mode == FollowMode.following &&
                          n.direction != ScrollDirection.idle) {
                        _releaseFollowing();
                      }
                      return false;
                    },
                    child: Listener(
                      onPointerDown: (_) => _releaseFollowing(),
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            physics: ReverseFollowPhysics(
                              state: _follow,
                            ).applyTo(platformPhysics),
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (_hasMore && i == messages.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: CcSpinner(size: 16)),
                                );
                              }
                              final m = messages[messages.length - 1 - i];
                              final key = _rowKeys.putIfAbsent(
                                m.id,
                                GlobalKey.new,
                              );
                              final kept = _keptTiles[m.id];
                              final Widget tile;
                              if (kept != null &&
                                  _sameMessage(kept.message, m) &&
                                  kept.myUserId == _myUserId &&
                                  identical(kept.userNames, _userNames) &&
                                  identical(kept.turns, turns)) {
                                tile = kept.child;
                              } else {
                                tile = SpaceMessageTile(
                                  message: m,
                                  myUserId: _myUserId,
                                  userNames: _userNames,
                                  turns: turns,
                                );
                                _keptTiles[m.id] = _KeptTile(
                                  message: m,
                                  myUserId: _myUserId,
                                  userNames: _userNames,
                                  turns: turns,
                                  child: tile,
                                );
                              }
                              return RepaintBoundary(
                                child: KeyedSubtree(key: key, child: tile),
                              );
                            },
                          ),
                          if (_showJump)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 12,
                              child: Center(
                                child: JumpToLatest(
                                  onTap: _jumpToLatest,
                                  isStreaming: isStreamingBelow,
                                  newCount: _newWhileAway,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SpaceComposerBar(
              controller: _composer,
              sending: _sending,
              pending: _pending,
              attachError: _attachError,
              onAttach: _attach,
              onSend: _send,
              onRemovePending: (a) => setState(() => _pending.remove(a)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One phone-feed tile kept while its message is still in the window.
class _KeptTile {
  const _KeptTile({
    required this.message,
    required this.myUserId,
    required this.userNames,
    required this.turns,
    required this.child,
  });

  final MessageDto message;
  final String? myUserId;
  final Map<String, String> userNames;
  final PhoneTurnRelay turns;
  final Widget child;
}

/// Value equality for a lite row. [MessageDto] is a wire bag and has no `==`.
bool _sameMessage(MessageDto a, MessageDto b) {
  return a.content == b.content &&
      a.senderId == b.senderId &&
      a.senderType == b.senderType &&
      a.messageType == b.messageType &&
      a.compacted == b.compacted &&
      a.createdAt == b.createdAt &&
      a.spaceId == b.spaceId &&
      a.conversationId == b.conversationId &&
      _sameValue(a.metadata, b.metadata);
}

bool _sameValue(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map<dynamic, dynamic> && b is Map<dynamic, dynamic>) {
    if (a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_sameValue(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<dynamic> && b is List<dynamic>) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_sameValue(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}
