import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_remote/widgets/jump_to_latest.dart';
import 'package:cc_remote/widgets/reverse_follow_physics.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Messaging tab: live spaces (`messaging.watchSpaces`), each pushing a
/// realtime thread route.
class MessagingScreen extends ConsumerWidget {
  /// Creates a [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(spacesProvider);

    return ColoredBox(
      color: t.canvas,
      child: async.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: "Couldn't load spaces",
          description: e.toString(),
        ),
        data: (spaces) {
          if (spaces.isEmpty) {
            return const CcEmptyState(
              icon: AppIcons.messageCircle,
              message: 'No spaces',
              description: 'Spaces in this workspace appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _spaceCard(context, t, spaces[i]),
          );
        },
      ),
    );
  }

  Widget _spaceCard(
    BuildContext context,
    DesignSystemTokens t,
    SpaceDto space,
  ) {
    return CcCard(
      interactive: true,
      semanticLabel: space.name,
      onPressed: () => context.push('/spaces/${space.id}'),
      child: Row(
        children: [
          Icon(AppIcons.hash, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              space.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `/spaces/:spaceId` — a realtime conversation. Messages stream live
/// (`messaging.watchMessages`); an agent turn renders its transcript (reasoning,
/// tool calls, results) as it happens. The composer dispatches the space's
/// agents (`dispatch.sendAndDispatch`) so a reply streams back.
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
  bool _sending = false;

  /// Files picked but not yet sent. Held as bytes because a browser tab has no
  /// path to hold instead, and uploaded on send rather than on pick so
  /// abandoning a draft costs the server nothing.
  final List<PickedAttachment> _pending = [];

  /// Why the last attach or send left something out. Shown above the composer
  /// and cleared on the next send — an attachment that silently vanished is
  /// the failure this whole path exists to avoid.
  String? _attachError;
  bool _didInitialLanding = false;
  String? _lastNewestId;
  int _newWhileAway = 0;
  bool _showJump = false;
  bool _programmatic = false;
  String? _announcedStartFor;
  String? _announcedDoneFor;
  bool _newestWasStreaming = false;

  /// The signed-in user's id (from `identity.me`), so "mine" means MY
  /// messages — not every human's — in a multi-member room. Null while
  /// loading; rendering then falls back to the solo-operator default.
  String? _myUserId;

  /// Display names of co-members, for attributing other members' messages.
  Map<String, String> _userNames = const {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    try {
      final client = ref.read(rpcClientProvider).value;
      if (client == null) {
        return;
      }
      final me = await client.call('identity.me', const {});
      final user = me['user'];
      final users = await client.call('users.list', const {});
      if (!mounted) {
        return;
      }
      setState(() {
        _myUserId = user is Map ? user['id'] as String? : null;
        _userNames = {
          for (final u in (users['users'] as List? ?? const []))
            if (u is Map && u['id'] is String)
              u['id'] as String: (u['display_name'] as String?) ?? '',
        };
      });
    } catch (_) {
      // Older servers without the identity surface: solo default applies.
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Any user-driven scroll/interaction is intent to stop following.
  void _releaseFollowing() {
    if (_follow.mode == FollowMode.following) {
      _follow.mode = FollowMode.free;
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _programmatic) {
      return;
    }
    final pos = _scroll.position;
    // Re-engage following when the reader returns to the live edge.
    if (pos.pixels <= kFollowPinThreshold &&
        _follow.mode != FollowMode.following) {
      _reengageFollowing();
    }
    final show = pos.pixels > kFollowPinThreshold;
    if (show != _showJump) {
      setState(() => _showJump = show);
    }
  }

  void _reengageFollowing() {
    _follow.mode = FollowMode.following;
    _follow.anchorMessageId = null;
    if (_newWhileAway != 0) {
      setState(() => _newWhileAway = 0);
    }
  }

  Future<T> _runProgrammatic<T>(Future<T> Function() task) async {
    _programmatic = true;
    try {
      return await task();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _programmatic = false;
      });
    }
  }

  /// Parks [messageId] near the top of the viewport. Leaves the previous turn
  /// peeking ~64px above when one exists (older = rendered above in the
  /// reverse list). Only applies while the row is mounted.
  Future<void> _anchorTo(String messageId, {required bool animate}) async {
    _follow.mode = FollowMode.anchored;
    _follow.anchorMessageId = messageId;
    final ctx = _rowKeys[messageId]?.currentContext;
    if (ctx == null) {
      return;
    }
    double alignment = 0.0;
    if (_scroll.hasClients) {
      final vh = _scroll.position.viewportDimension;
      if (vh > 0) {
        alignment = (64 / vh).clamp(0.0, 0.9);
      }
    }
    await _runProgrammatic(
      () => Scrollable.ensureVisible(
        ctx,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: animate
            ? CcMotion.resolve(context, const Duration(milliseconds: 250))
            : Duration.zero,
        curve: Curves.easeOut,
      ),
    );
  }

  /// First-open landing: the live edge, with no animation. Offset 0 in a
  /// reverse list IS the newest message, so opening a thread simply starts at
  /// the bottom — same as the desktop feed, so the two clients agree on where
  /// a chat opens.
  void _landOnLiveEdge() {
    _follow.mode = FollowMode.following;
    _follow.anchorMessageId = null;
    if (_scroll.hasClients && _scroll.position.pixels != 0) {
      // Guarded so the scroll listener doesn't read the reset as reader intent.
      _runProgrammatic(() async => _scroll.jumpTo(0));
    }
    // Nothing is below the fold, so the jump-to-latest affordance and its
    // missed-turn count are stale; [_onScroll] ignores programmatic movement.
    if (_newWhileAway != 0 || _showJump) {
      setState(() {
        _newWhileAway = 0;
        _showJump = false;
      });
    }
  }

  /// Paced live-region announcements (principle 15): on mobile the only signal
  /// is the per-message `streamComplete` flip in metadata. Announce "Agent
  /// responding" once when a turn starts streaming and the final answer once
  /// when it completes — never per snapshot.
  void _maybeAnnounce(List<MessageDto> messages) {
    final newest = messages.isNotEmpty ? messages.last : null;
    if (newest == null || newest.senderType == 'user') {
      _newestWasStreaming = false;
      return;
    }
    final meta = newest.metadata is Map ? newest.metadata as Map : null;
    final segments = decodeTranscript(meta?['segments']);
    final isAgentTurn = segments.isNotEmpty;
    final streaming =
        isAgentTurn && ((meta?['streamComplete'] as bool?) != true);
    if (streaming && _announcedStartFor != newest.id) {
      _announcedStartFor = newest.id;
      _announcedDoneFor = null;
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Agent responding',
        TextDirection.ltr,
      );
    } else if (!streaming &&
        _newestWasStreaming &&
        _announcedDoneFor != newest.id) {
      _announcedDoneFor = newest.id;
      final answer = newest.content.trim();
      final preview = answer.isEmpty
          ? 'Agent finished'
          : (answer.length > 160 ? '${answer.substring(0, 160)}…' : answer);
      SemanticsService.sendAnnouncement(
        View.of(context),
        preview,
        TextDirection.ltr,
      );
    }
    _newestWasStreaming = streaming;
  }

  /// React to a new snapshot from the server: anchor the user's just-sent turn,
  /// or count agent arrivals while the reader is away. This replaces the old
  /// `jumpToBottom()`-on-every-emission behavior that stole the scroll
  /// position.
  void _onMessagesChanged(List<MessageDto> messages) {
    _maybeAnnounce(messages);
    if (messages.isEmpty) {
      return;
    }
    final newest = messages.last;
    final prevId = _lastNewestId;
    _lastNewestId = newest.id;
    if (!_didInitialLanding) {
      _didInitialLanding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _landOnLiveEdge();
        }
      });
      return;
    }
    if (prevId == null || newest.id == prevId) {
      return;
    }
    if (newest.senderType == 'user') {
      _newWhileAway = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _anchorTo(newest.id, animate: true);
        }
      });
    } else if (_follow.mode != FollowMode.following) {
      setState(() => _newWhileAway += 1);
    }
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) {
      return;
    }
    _runProgrammatic(
      () => _scroll.animateTo(
        0,
        duration: CcMotion.resolve(context, const Duration(milliseconds: 300)),
        curve: Curves.easeOut,
      ),
    );
    _reengageFollowing();
  }

  /// Opens the browser's picker and keeps what comes back until send.
  ///
  /// Bytes only — a browser tab has no path to name — so anything picked here
  /// has to reach the server before the message does. Oversized files are
  /// refused now rather than after a long upload, and the ceiling named is the
  /// one this connection actually has: the relay's is far lower than the LAN's.
  Future<void> _attach() async {
    final picked = await pickAttachments();
    if (picked.isEmpty || !mounted) {
      return;
    }
    final hasHttp = ref.read(mediaEndpointProvider).value != null;
    final tooBig = picked
        .where((a) => !attachmentFitsLane(a.bytes.length, hasHttpOrigin: hasHttp))
        .toList();
    setState(() {
      _pending.addAll(picked.where((a) => !tooBig.contains(a)));
      _attachError = tooBig.isEmpty
          ? null
          : '${tooBig.map((a) => a.name).join(', ')} '
                '${tooBig.length == 1 ? 'is' : 'are'} too large to send '
                '${hasHttp ? '' : 'over the relay '}from here.';
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty && _pending.isEmpty) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) {
      return;
    }
    setState(() {
      _sending = true;
      _attachError = null;
    });
    try {
      final outgoing = List<PickedAttachment>.of(_pending);
      _composer.clear();
      setState(_pending.clear);
      // sendAndDispatch posts the user message AND wakes the space's agents;
      // the reply streams back over the live messages subscription.
      //
      // The workspace is required: the space row lives in that workspace's
      // database server-side, so a send with no bound workspace has nowhere to
      // land and is dropped here rather than failing mid-flight.
      final workspaceId = ref.read(activeWorkspaceIdProvider).value;
      if (workspaceId == null) {
        return;
      }
      // Bytes first, message second. The reference in the text is only worth
      // anything once the content behind it is on the server — sending the
      // sentence first would hand the agent a name for something that does not
      // exist yet.
      final stored = await uploadAttachments(
        picked: outgoing,
        workspaceId: workspaceId,
        client: client,
        endpoint: ref.read(mediaEndpointProvider).value,
      );
      if (outgoing.isNotEmpty && stored.isEmpty && text.isEmpty) {
        // Nothing survived and there was nothing else to say: a blank message
        // would read as sent.
        if (mounted) {
          setState(
            () => _attachError = "Couldn't upload the attachment. Try again.",
          );
        }
        return;
      }
      await RemoteMessagingDispatch(client).sendAndDispatch(
        workspaceId,
        widget.spaceId,
        _composeWithReferences(text, stored),
        metadata: stored.isEmpty
            ? null
            : {'attachments': [for (final a in stored) a.toJson()]},
      );
      if (mounted && stored.length != outgoing.length) {
        setState(
          () => _attachError =
              '${outgoing.length - stored.length} attachment(s) '
              "couldn't be uploaded and were left out.",
        );
      }
    } catch (_) {
      // The live stream reconciles state; a transient failure is non-fatal.
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// [text] with one `@[file:<name>]` reference appended per uploaded
  /// attachment.
  ///
  /// The desktop composer writes a reference AT THE CARET, because the position
  /// is the meaning there. A phone composer has no caret to write into — the
  /// picker is a separate act from typing — so the references go at the end,
  /// which is the honest version of "and these came with it". The token is what
  /// the transcript renders as a chip and what the server expands into a path
  /// for the agent, so it has to be present either way: an attachment with no
  /// reference is one the model has no reason to look at.
  String _composeWithReferences(String text, List<MessageAttachment> stored) {
    if (stored.isEmpty) {
      return text;
    }
    final refs = stored.map((a) => '@[file:${a.name}]').join(' ');
    return text.isEmpty ? refs : '$text\n\n$refs';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final messagesAsync = ref.watch(spaceMessagesProvider(widget.spaceId));
    ref.listen(spaceMessagesProvider(widget.spaceId), (_, next) {
      final msgs = next.value ?? const <MessageDto>[];
      _onMessagesChanged(msgs);
    });
    // Run logs are keyed by CONVERSATION, not by space — a conversation owns
    // its own uuid, so the space id names no stream and the live-run banner
    // never lit up. Null while the standing conversation resolves.
    final conversationId = ref
        .watch(spaceConversationIdProvider(widget.spaceId))
        .value;
    final runsAsync = conversationId == null
        ? const AsyncValue<List<AgentRunLogDto>>.loading()
        : ref.watch(activeRunLogsProvider(conversationId));
    // Keep the last value (never collapse to a spinner on reload — that would
    // destroy the ScrollController and snap the reverse list).
    final messages = messagesAsync.value ?? const <MessageDto>[];

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
            const _DetailHeader(title: 'Thread'),
            if (hasActiveRun) _activeBanner(t),
            _PendingApprovals(spaceId: widget.spaceId),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CcSpinner(size: 24)),
                error: (e, _) => CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: "Couldn't load messages",
                  description: e.toString(),
                ),
                data: (_) {
                  if (messages.isEmpty) {
                    return const CcEmptyState(
                      icon: AppIcons.messageCircle,
                      message: 'No messages yet',
                      description: 'Send a message to start the conversation.',
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
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              // Reverse mapping: index 0 = newest (bottom).
                              final m = messages[messages.length - 1 - i];
                              final key = _rowKeys.putIfAbsent(
                                m.id,
                                GlobalKey.new,
                              );
                              return KeyedSubtree(
                                key: key,
                                child: _messageTile(t, m),
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
            _composerBar(t),
          ],
        ),
      ),
    );
  }

  Widget _activeBanner(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accentSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(AppIcons.loader, size: 14, color: t.accent),
            const SizedBox(width: 8),
            Text(
              'Agent is working',
              style: TextStyle(fontSize: 13, color: t.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageTile(DesignSystemTokens t, MessageDto m) {
    final isHuman = m.senderType == 'user';
    // "Mine" is identity-scoped: another member's message renders on the
    // left with their name, exactly like an agent's — attribution stays
    // legible with N humans in the room.
    final isMine = isHuman && (_myUserId == null || m.senderId == _myUserId);
    final meta = m.metadata is Map ? m.metadata as Map : null;
    final segments = decodeTranscript(meta?['segments']);
    final isAgentTurn = !isMine && !isHuman && segments.isNotEmpty;
    final streamComplete = (meta?['streamComplete'] as bool?) ?? !isAgentTurn;
    final agentName = isHuman
        ? (_userNames[m.senderId]?.isNotEmpty ?? false
              ? _userNames[m.senderId]!
              : 'Teammate')
        : (meta?['agentName'] as String?) ?? m.senderType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.senderType == 'user' ? AppIcons.user : AppIcons.bot,
                          size: 12,
                          color: t.fgTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (agentName.isEmpty ? 'Agent' : agentName),
                          style: TextStyle(fontSize: 11, color: t.fgTertiary),
                        ),
                      ],
                    ),
                  ),
                if (isAgentTurn)
                  _agentBubble(t, m, segments, streamComplete)
                else
                  _textBubble(t, m.content, isMine),
                // What the sender attached. Renders nothing when there is
                // none, so an ordinary message is unchanged.
                _SentAttachments(
                  attachments: MessageAttachment.attachmentsFromMetadata(
                    meta?.cast<String, dynamic>(),
                  ),
                  alignEnd: isMine,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBubble(DesignSystemTokens t, String content, bool isMine) {
    final body = TextStyle(fontSize: 14, height: 1.4, color: t.textPrimary);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isMine ? t.accentSoft : t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text.rich(
          TextSpan(children: _bodySpans(t, content, body)),
          style: body,
        ),
      ),
    );
  }

  /// [content] split into ordinary text and `@[file:…]` references.
  ///
  /// The phone has no editor tab to open a preview into, so a reference here is
  /// not clickable — but it still has to READ as a file rather than as bracket
  /// syntax that leaked, and the picture it names is on the strip right below.
  /// Same accent as the desktop's chip, for the same reason.
  List<InlineSpan> _bodySpans(
    DesignSystemTokens t,
    String content,
    TextStyle body,
  ) {
    final refs = findFileRefs(content);
    if (refs.isEmpty) {
      return [TextSpan(text: content)];
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final ref in refs) {
      if (ref.start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, ref.start)));
      }
      spans.add(
        TextSpan(
          text: ref.name,
          style: body.copyWith(
            color: t.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
      cursor = ref.end;
    }
    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor)));
    }
    return spans;
  }

  Widget _agentBubble(
    DesignSystemTokens t,
    MessageDto m,
    List<TranscriptSegment> segments,
    bool streamComplete,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          // The transcript now renders the answer text inline at its
          // chronological position, so there is no separate trailing answer.
          child: AgentTranscript(segments: segments, isLive: !streamComplete),
        ),
      ),
    );
  }

  Widget _composerBar(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_attachError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _attachError!,
                  style: TextStyle(fontSize: 12, color: t.danger),
                ),
              ),
            if (_pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final attachment in _pending)
                      _PendingChip(
                        attachment: attachment,
                        onRemove: () =>
                            setState(() => _pending.remove(attachment)),
                      ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PhoneIconButton(
                  icon: AppIcons.plus,
                  semanticLabel: 'Attach a file',
                  color: t.fgSecondary,
                  onPressed: _sending ? null : _attach,
                ),
                Expanded(
                  child: CcTextField(
                    controller: _composer,
                    hintText: 'Message',
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CcButton(
                  icon: AppIcons.send,
                  loading: _sending,
                  onPressed: _send,
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What a message carried, under its text.
///
/// Pictures resolve through the host's `/blob` endpoint, signed with the device
/// PSK and gated on workspace membership — the phone can no more read the
/// sender's disk than the server can, so there is nowhere else for the bytes to
/// come from. On a relayed session there is no HTTP origin at all, and the
/// strip says the picture is unavailable rather than showing an empty frame.
class _SentAttachments extends ConsumerWidget {
  const _SentAttachments({required this.attachments, required this.alignEnd});

  final List<MessageAttachment> attachments;
  final bool alignEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final endpoint = ref.watch(mediaEndpointProvider).value;
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    String? urlFor(MessageAttachment a) {
      if (endpoint == null || workspaceId == null || !a.isUploaded) {
        return null;
      }
      final url = endpoint.blobUrl(workspaceId: workspaceId, ref: a.path);
      return url.isEmpty ? null : url;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        children: [
          for (final attachment in attachments)
            _SentAttachment(
              attachment: attachment,
              url: urlFor(attachment),
              tokens: t,
            ),
        ],
      ),
    );
  }
}

class _SentAttachment extends StatelessWidget {
  const _SentAttachment({
    required this.attachment,
    required this.url,
    required this.tokens,
  });

  final MessageAttachment attachment;
  final String? url;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));
    final resolved = url;
    if (attachment.isImage && resolved != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          resolved,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (context, _, _) => _chip(unavailable: true),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 140,
                  width: 200,
                  child: Center(child: CcSpinner(size: 14)),
                ),
        ),
      );
    }
    return _chip(unavailable: attachment.isImage && resolved == null);
  }

  Widget _chip({required bool unavailable}) => DecoratedBox(
    decoration: BoxDecoration(
      color: tokens.bgSecondary,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(color: tokens.borderSoft),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unavailable
                ? AppIcons.imageOff
                : (attachment.isImage ? AppIcons.image : AppIcons.file),
            size: 14,
            color: tokens.fgTertiary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A picked-but-not-yet-sent attachment, removable before it goes.
class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.attachment, required this.onRemove});

  final PickedAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachment.isImage ? AppIcons.image : AppIcons.file,
              size: 14,
              color: t.fgTertiary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: t.textPrimary),
              ),
            ),
            const SizedBox(width: 4),
            PhoneIconButton(
              icon: AppIcons.x,
              iconSize: 14,
              semanticLabel: 'Remove ${attachment.name}',
              color: t.fgTertiary,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            PhoneIconButton(
              icon: AppIcons.arrowLeft,
              semanticLabel: 'Back',
              onPressed: () => context.pop(),
              color: t.fgSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline approve/decline surface for destructive agent commands awaiting a
/// human decision. Streams `confirmation.watchPending` for this conversation;
/// each card resolves its request via `confirmation.respond`.
class _PendingApprovals extends ConsumerStatefulWidget {
  const _PendingApprovals({required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<_PendingApprovals> createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends ConsumerState<_PendingApprovals> {
  final Set<String> _responding = {};

  Future<void> _respond(String id, bool approved) async {
    setState(() => _responding.add(id));
    try {
      final client = ref.read(rpcClientProvider).value;
      if (client != null) {
        await RemoteConfirmationRepository(
          client,
        ).respond(id, approved: approved);
      }
    } catch (_) {
      // The live subscription reconciles state on failure.
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pending =
        ref.watch(pendingConfirmationsProvider(widget.spaceId)).value ??
        const <ConfirmationRequestDto>[];
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(children: [for (final p in pending) _card(t, p)]);
  }

  Widget _card(DesignSystemTokens t, ConfirmationRequestDto p) {
    final destructive = p.severity == 'destructive';
    final bg = destructive ? t.dangerSoft : t.warnSoft;
    final fg = destructive ? t.textErrorPrimary : t.textWarningPrimary;
    final busy = _responding.contains(p.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.triangleAlert, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (p.detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.detail,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ],
              if (p.command != null) ...[
                const SizedBox(height: 6),
                Text(
                  p.command!,
                  style: CcFonts.code(
                    textStyle: TextStyle(fontSize: 12, color: t.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.destructive,
                      size: CcButtonSize.sm,
                      loading: busy,
                      onPressed: busy ? null : () => _respond(p.id, false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.primary,
                      size: CcButtonSize.sm,
                      loading: busy,
                      onPressed: busy ? null : () => _respond(p.id, true),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
