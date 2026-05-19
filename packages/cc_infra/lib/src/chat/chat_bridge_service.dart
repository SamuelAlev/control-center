import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_channel_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_capabilities.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';
import 'package:cc_infra/src/chat/chat_deep_links.dart';
import 'package:cc_infra/src/chat/chat_link_code_store.dart';
import 'package:cc_infra/src/chat/chat_provider_adapter.dart';
import 'package:cc_infra/src/chat/chat_text.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:uuid/uuid.dart';

/// Creates the Control Center channel that mirrors an external chat
/// conversation.
///
/// Injected rather than called directly because *which agents* a fresh chat
/// conversation should wake is a composition decision (the workspace's front-door
/// agent), and the bridge has no business holding that policy.
typedef ChatChannelFactory =
    Future<Channel> Function({
      required String workspaceId,
      required String name,
      required String createdByUserId,
    });

/// Creates a ticket from `/cc ticket`. Returns the ticket's id, display key and
/// title, so the chat confirmation can name what was filed.
typedef ChatTicketCreator =
    Future<({String id, String key, String title})> Function({
      required String workspaceId,
      required String title,
      required String reporterUserId,
      String? description,
    });

/// What a task card is titled when the turn was not started from the chat app
/// (somebody typed in Control Center, or the server restarted mid-conversation),
/// so there is no request to name it after.
const String _genericCardTitle = 'Agent activity';

/// What the card says the instant a chat request is accepted, before setup or
/// the agent has anything more specific to report.
const String _ackNote = 'Working on it…';

/// What the card says once the agent is running but has not called a tool yet.
const String _thinkingNote = 'Thinking…';

/// Ceiling on the answer copied onto the finished card. Slack's streaming form
/// then fits that further into a 256-character chunk; this is the source text.
const int _maxCardResultLength = 500;

/// Bridges one Control Center workspace to one chat app, whatever the product.
///
/// Inbound, it turns `@mention`s, thread replies and bot DMs into Control Center
/// messages that wake an agent; outbound, it relays the agent's turn back as a
/// **live streaming reply** where the provider supports one. Both directions run
/// entirely server-side over outbound connections, which is what lets the whole
/// feature work on a laptop with no public endpoint.
///
/// Everything product-specific lives behind [ChatProviderAdapter]: this class
/// knows about markdown, conversations, threads and members, and nothing about
/// Slack envelopes, Discord gateway intents or `mrkdwn`. Five rules keep it
/// honest:
///
///  * **Access is membership, not token possession.** A chat member must be
///    linked to a Control Center user *and* be a member of this workspace with a
///    writing role. Anything else is refused with an explanation — never silently
///    attributed to the workspace owner.
///  * **Every crossing is deduped.** Providers redeliver unacknowledged events,
///    so the bridge keys on the event's own id.
///  * **Provenance is stamped, so nothing echoes.** A message the bridge creates
///    carries `metadata['chat']`; the outbound mirror skips those, which is what
///    stops an inbound chat message from being posted straight back.
///  * **Capabilities are honored, not assumed.** Streaming, ephemeral replies,
///    thread status and titles are each attempted only when the adapter claims
///    them, and streaming that is refused at runtime degrades to whole replies
///    for the rest of the connection's life.
///  * **Copy comes from the descriptor.** Every instruction the bridge writes
///    names the provider and the command the app actually uses, so a second
///    provider reads correctly without a new string.
///  * **A card reports state; the text is still the message.** Where the provider
///    renders task cards, the turn also carries one that says what the agent is
///    doing (the current line on the card: a clone step, a thought, a tool)
///    and links back into Control Center. Tool *output* never crosses — the card
///    is a summary, and the transcript stays in the app.
class ChatBridgeService {
  /// Creates a [ChatBridgeService] for [connection]'s workspace.
  ChatBridgeService({
    required ChatBridgeConnection connection,
    required ChatProviderAdapter adapter,
    required ChatProviderDescriptor descriptor,
    required ActiveStreamRegistry streamRegistry,
    required MessagingPort messaging,
    required MessagingRepository messages,
    required ChatChannelFactory createChannel,
    required ChatChannelLinkRepository channelLinks,
    required ChatUserLinkRepository userLinks,
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required ChatLinkCodeStore linkCodes,
    DomainEventBus? eventBus,
    ChatTicketCreator? createTicket,
    ChatDeepLinks? deepLinks,
    String Function()? newId,
    DateTime Function()? clock,
    Duration flushInterval = const Duration(seconds: 1),
    void Function(bool available)? onStreamingAvailability,
  }) : _connection = connection,
       _adapter = adapter,
       _descriptor = descriptor,
       _registry = streamRegistry,
       _messaging = messaging,
       _messages = messages,
       _createChannel = createChannel,
       _channelLinks = channelLinks,
       _userLinks = userLinks,
       _users = users,
       _members = members,
       _linkCodes = linkCodes,
       _eventBus = eventBus,
       _createTicket = createTicket,
       _deepLinks = deepLinks,
       _newId = newId ?? _uuidV4,
       _clock = clock ?? DateTime.now,
       _flushInterval = flushInterval,
       _onStreamingAvailability = onStreamingAvailability,
       _command = '/${descriptor.commandName}';

  final ChatBridgeConnection _connection;
  final ChatProviderAdapter _adapter;
  final ChatProviderDescriptor _descriptor;
  final ActiveStreamRegistry _registry;
  final MessagingPort _messaging;
  final MessagingRepository _messages;
  final ChatChannelFactory _createChannel;
  final ChatChannelLinkRepository _channelLinks;
  final ChatUserLinkRepository _userLinks;
  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final ChatLinkCodeStore _linkCodes;
  final DomainEventBus? _eventBus;
  final ChatTicketCreator? _createTicket;
  final ChatDeepLinks? _deepLinks;
  final String Function() _newId;
  final DateTime Function() _clock;
  final Duration _flushInterval;
  final void Function(bool available)? _onStreamingAvailability;

  /// The Control Center workspace this bridge serves.
  String get workspaceId => _connection.workspaceId;

  /// Which chat product is on the other side.
  ChatProvider get provider => _connection.provider;

  ChatProviderCapabilities get _can => _adapter.capabilities;

  /// Whether the provider accepted native streaming for this app. Null until the
  /// first reply has been attempted; false means whole replies are being posted.
  bool? get streamingAvailable => _streamingAvailable;
  bool? _streamingAvailable;

  /// Whether cards are worth attaching: the provider renders them and has not
  /// refused one. A card the provider will not take is dropped for the life of
  /// the connection rather than retried on every flush — the reply is the
  /// product, the card is a rendering of it.
  bool get _cardsOn => _can.taskCards && _cardsAccepted != false;
  bool? _cardsAccepted;

  /// Recently handled event ids, newest last. Bounded — a redelivery arrives
  /// within seconds, so remembering the last few hundred is plenty and an
  /// unbounded set would be a slow leak on a busy chat workspace.
  final Set<String> _seen = {};
  static const _seenLimit = 512;

  /// Where a reply for a Control Center channel goes, refreshed on every inbound
  /// message so a DM's reply lands in the thread that asked.
  final Map<String, _ChatTarget> _targets = {};

  /// One subscription per bridged Control Center channel.
  final Map<String, StreamSubscription<ChannelTurnUpdate>> _channelSubs = {};

  /// One relay per in-flight agent turn.
  final Map<String, _TurnRelay> _relays = {};

  /// A card per channel whose workspace is still being built, keyed by Control
  /// Center channel id. A fresh channel clones its repos before the agent can
  /// say anything, which is minutes of nothing in the thread; this reports it,
  /// and the turn that follows adopts the same card and stream.
  final Map<String, _TurnRelay> _setupRelays = {};

  /// Channels with a chat request in flight. Setup is only worth reporting for
  /// one: provisioning also runs where nobody in chat is waiting (a channel
  /// opened in the app, a stranded one resumed at boot), and a card for that
  /// would be the bridge talking to itself.
  final Set<String> _awaitingRequest = {};

  final Map<String, String> _conversationNames = {};
  final Map<String, ChatUserProfile> _profiles = {};

  StreamSubscription<MessageReceived>? _mirrorSub;
  StreamSubscription<ChannelProvisioningChanged>? _setupSub;
  StreamSubscription<ChatInboundEvent>? _inboundSub;
  bool _started = false;

  /// The command as this app spells it. The descriptor's default is what the
  /// guided setup ships, but the owner can rename it on the provider, so every
  /// instruction the bridge writes uses whatever was last invoked instead of a
  /// name that may no longer exist.
  String _command;

  /// The provider's product name, for user-facing copy.
  String get _productName => _descriptor.displayName;

  /// Arms the bridge: relays for already-linked channels, the inbound event
  /// subscription, the outbound mirror for human messages typed in Control
  /// Center, and finally the provider transport.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    try {
      for (final link in await _channelLinks.forWorkspace(
        workspaceId,
        provider: provider,
      )) {
        _targets[link.ccChannelId] = _ChatTarget(
          conversationId: link.externalChannelId,
          threadId: link.externalThreadId,
          // Nobody has asked anything through this link yet this run, but a turn
          // started from Control Center still has to reach the thread live —
          // Slack needs a recipient for that, so the reader it belongs to is the
          // member who opened the link.
          recipient: await _recipientFor(link),
        );
        _watchChannel(link.ccChannelId);
      }
    } on Object catch (e) {
      _warn('arming links failed: $e');
    }
    // Both subscriptions are stored and cancelled in stop(); the lint's
    // same-scope heuristic cannot see that.
    // ignore: cancel_subscriptions
    _inboundSub = _adapter.events.listen(
      (event) => unawaited(_handle(event)),
      onError: (Object e) => _warn('inbound stream error: $e'),
    );
    // ignore: cancel_subscriptions
    _mirrorSub = _eventBus?.on<MessageReceived>().listen(
      (event) => unawaited(_mirrorOut(event)),
    );
    // ignore: cancel_subscriptions
    _setupSub = _eventBus?.on<ChannelProvisioningChanged>().listen(_onSetup);
    await _adapter.start();
  }

  /// Releases the transport, every subscription and every pending flush. Safe to
  /// call twice.
  Future<void> stop() async {
    _started = false;
    await _adapter.stop();
    await _inboundSub?.cancel();
    _inboundSub = null;
    await _mirrorSub?.cancel();
    _mirrorSub = null;
    await _setupSub?.cancel();
    _setupSub = null;
    for (final sub in _channelSubs.values) {
      await sub.cancel();
    }
    _channelSubs.clear();
    for (final relay in [..._relays.values, ..._setupRelays.values]) {
      relay.dispose();
    }
    _relays.clear();
    _setupRelays.clear();
    _awaitingRequest.clear();
  }

  /// Handles one normalized inbound event. Exposed for tests and for an adapter
  /// that delivers events by hand; the ordinary path is the [start] subscription.
  Future<void> handleInbound(ChatInboundEvent event) => _handle(event);

  Future<void> _handle(ChatInboundEvent event) async {
    if (!_remember(event.dedupeKey)) {
      return;
    }
    try {
      switch (event) {
        case ChatMessageEvent():
          await _onMessage(event);
        case ChatCommandEvent():
          await _onCommand(event);
      }
    } on Object catch (e, s) {
      // One bad event must never take the bridge down; the connection keeps
      // serving every other conversation.
      CcInfraLog.error('${_tag()}: handling ${event.runtimeType} failed', e, s);
    }
  }

  bool _remember(String key) {
    if (!_seen.add(key)) {
      return false;
    }
    if (_seen.length > _seenLimit) {
      _seen.remove(_seen.first);
    }
    return true;
  }

  // ── Inbound: chat → Control Center ──

  Future<void> _onMessage(ChatMessageEvent event) async {
    final conversationId = event.externalChannelId;
    final externalUserId = event.externalUserId;
    if (conversationId.isEmpty ||
        externalUserId.isEmpty ||
        externalUserId == _adapter.botUserId) {
      return;
    }

    // The reply anchor: the thread the message is in, else the message itself
    // (which is how a mention opens a new thread).
    final anchor = event.externalThreadId ?? event.externalMessageId;

    // A message that did not address the bot is only a request in a DM or as a
    // reply inside a thread this bridge already owns. Everything else is other
    // people's conversation.
    if (!event.viaMention && !event.isDm) {
      if (event.externalThreadId == null) {
        return;
      }
      final bridged = await _channelLinks.forExternalThread(
        workspaceId,
        provider: provider,
        externalChannelId: conversationId,
        externalThreadId: event.externalThreadId,
      );
      if (bridged == null) {
        return;
      }
    }

    if (event.text.isEmpty) {
      await _sayInThread(
        conversationId,
        anchor,
        'Tell me what you need and I will put an agent on it — for example '
        '“@${_adapter.botName} summarize the open PRs”.',
      );
      return;
    }

    final actor = await _resolveActor(externalUserId);
    if (actor.refusal != null) {
      await _sayInThread(conversationId, anchor, actor.refusal!);
      return;
    }
    final userId = actor.userId!;

    final link = await _linkFor(
      conversationId: conversationId,
      // A bot DM is one continuous conversation, so it anchors on the
      // conversation itself (null thread) and every thread in it drives the same
      // Control Center channel. A shared channel anchors per thread.
      threadId: event.isDm ? null : anchor,
      replyThreadId: anchor,
      userId: userId,
      seedText: event.text,
      isDm: event.isDm,
    );
    _targets[link.ccChannelId] = _ChatTarget(
      conversationId: conversationId,
      threadId: anchor,
      // What the agent was asked, so the card that reports on the turn is titled
      // after the request instead of a generic label.
      requestTitle: ChatText.titleFrom(
        event.text,
        fallback: _genericCardTitle,
        maxLength: 80,
      ),
      // Who the streamed reply is for. Slack will not open a stream in a channel
      // without it, and the asker's team is not always the app's own (a shared
      // channel), so it comes from the message rather than from the connection.
      recipient: ChatRecipient(
        externalUserId: externalUserId,
        externalTeamId: event.externalTeamId,
      ),
    );
    _watchChannel(link.ccChannelId);

    if (event.isDm && _can.threadStatus) {
      // The provider's transient status line. It is cleared when the reply
      // lands, and a plan without the feature simply refuses the call.
      unawaited(
        _swallow(
          () => _adapter.setThreadStatus(
            conversationId: conversationId,
            threadId: anchor,
            status: 'is thinking…',
          ),
        ),
      );
    }

    _awaitingRequest.add(link.ccChannelId);
    // The reader should see activity the moment we accepted the request, not
    // when a clone step happens to fire or the agent produces its first token.
    // Setup events and the turn that follows adopt this same card.
    await _openRequestCard(link.ccChannelId);
    // ChannelCreated starts provisioning during `_linkFor`, so the first
    // "Cloning…" event can land before this set is armed. Read the row we just
    // created (or already had) and paint whatever is already in flight.
    await _catchUpSetup(link.ccChannelId);
    try {
      await _messaging.sendAndDispatch(
        workspaceId,
        link.ccChannelId,
        event.text,
        senderUserId: userId,
        metadata: {
          'chat': {
            'provider': provider.wire,
            'teamId': event.externalTeamId,
            'channelId': conversationId,
            'threadId': anchor,
            'messageId': event.externalMessageId,
            'userId': externalUserId,
            'userLabel': _profiles[externalUserId]?.label ?? externalUserId,
          },
        },
      );
    } on Object {
      // Dispatch itself failed: nothing will adopt the card. Provisioning that
      // is still running is reported until it fails, but a throw here means the
      // request produced no turn and never will.
      _awaitingRequest.remove(link.ccChannelId);
      await _closeUnclaimedSetupCard(link.ccChannelId);
      rethrow;
    }
    // Deliberately not closing here. `sendAndDispatch` posts the user message
    // and fires the agent run unawaited — the clone that run is gated on is
    // still going, and the card has to stay open for it.
  }

  /// Resolves a chat member to a writing member of this workspace.
  ///
  /// Fails closed and *explains*: an unlinked member is told how to link, a
  /// linked non-member is told they have no access, and a viewer/guest is told
  /// their role is read-only. None of those proceed — a chat message is never
  /// attributed to somebody who did not send it.
  Future<({String? userId, String? refusal})> _resolveActor(
    String externalUserId,
  ) async {
    var link = await _userLinks.forExternalUser(
      workspaceId,
      provider: provider,
      externalTeamId: _adapter.teamId,
      externalUserId: externalUserId,
    );
    link ??= await _autoLinkByEmail(externalUserId);
    if (link == null) {
      return (
        userId: null,
        refusal:
            'I do not know who you are in Control Center yet. Open Settings → '
            'Accounts → Chat bridges, press “Link my $_productName account”, '
            'then send me `$_command link CODE` with the code it shows.',
      );
    }
    final member = await _members.getMember(workspaceId, link.userId);
    if (member == null) {
      return (
        userId: null,
        refusal:
            'Your $_productName account is linked, but you are not a member of '
            'this Control Center workspace. Ask an admin to invite you.',
      );
    }
    if (!member.role.canWrite) {
      return (
        userId: null,
        refusal:
            'Your role in this workspace is read-only (${member.role.name}), '
            'so I cannot start work on your behalf.',
      );
    }
    return (userId: link.userId, refusal: null);
  }

  /// Links a chat member by their verified provider email, when it matches a user
  /// who is already a member of this workspace.
  ///
  /// The membership check is the point: matching an email to a *user* proves
  /// identity, but only membership grants access, so a stranger whose email
  /// happens to exist on the server links to nothing.
  Future<ChatUserLink?> _autoLinkByEmail(String externalUserId) async {
    final profile = await _profile(externalUserId);
    final email = profile?.email;
    if (profile == null || profile.isBot || email == null || email.isEmpty) {
      return null;
    }
    final user = await _users.getByEmail(email);
    if (user == null) {
      return null;
    }
    if (await _members.getMember(workspaceId, user.id) == null) {
      return null;
    }
    final link = ChatUserLink(
      id: _newId(),
      workspaceId: workspaceId,
      provider: provider,
      externalTeamId: profile.teamId ?? _adapter.teamId,
      externalUserId: externalUserId,
      userId: user.id,
      method: ChatLinkMethod.email,
      linkedAt: _clock(),
    );
    await _userLinks.upsert(link);
    _linkCodes.revokeForUser(workspaceId, user.id, provider: provider);
    CcInfraLog.info(
      '${_tag()}: linked $externalUserId to ${user.handle} by email',
    );
    return link;
  }

  Future<ChatChannelLink> _linkFor({
    required String conversationId,
    required String? threadId,
    required String replyThreadId,
    required String userId,
    required String seedText,
    required bool isDm,
  }) async {
    final existing = await _channelLinks.forExternalThread(
      workspaceId,
      provider: provider,
      externalChannelId: conversationId,
      externalThreadId: threadId,
    );
    if (existing != null &&
        await _messaging.channelExists(workspaceId, existing.ccChannelId)) {
      await _channelLinks.upsert(existing.copyWith(lastActivityAt: _clock()));
      return existing;
    }

    final name = await _channelName(
      conversationId: conversationId,
      seedText: seedText,
      isDm: isDm,
    );
    final created = await _createChannel(
      workspaceId: workspaceId,
      name: name,
      createdByUserId: userId,
    );
    final link = ChatChannelLink(
      // Reusing the id of a stale link matters: the row is unique on the
      // external tuple, so inserting a *new* id for the same thread would
      // collide.
      id: existing?.id ?? _newId(),
      workspaceId: workspaceId,
      provider: provider,
      externalTeamId: _adapter.teamId,
      externalChannelId: conversationId,
      externalThreadId: threadId,
      ccChannelId: created.id,
      createdByUserId: userId,
      createdAt: _clock(),
      lastActivityAt: _clock(),
    );
    await _channelLinks.upsert(link);
    if (isDm && _can.threadTitle) {
      unawaited(
        _swallow(
          () => _adapter.setThreadTitle(
            conversationId: conversationId,
            threadId: replyThreadId,
            title: name,
          ),
        ),
      );
    }
    CcInfraLog.info(
      '${_tag()}: bridged $conversationId'
      '${threadId == null ? '' : '/$threadId'} → channel ${created.id}',
    );
    return link;
  }

  Future<String> _channelName({
    required String conversationId,
    required String seedText,
    required bool isDm,
  }) async {
    final title = ChatText.titleFrom(
      seedText,
      fallback: '$_productName conversation',
      maxLength: 48,
    );
    if (isDm) {
      return '$_productName DM · $title';
    }
    final conversation = await _conversationName(conversationId);
    return conversation == null
        ? '$_productName · $title'
        : '#$conversation · $title';
  }

  Future<String?> _conversationName(String conversationId) async {
    final cached = _conversationNames[conversationId];
    if (cached != null) {
      return cached.isEmpty ? null : cached;
    }
    try {
      final name = await _adapter.conversationName(conversationId) ?? '';
      _conversationNames[conversationId] = name;
      return name.isEmpty ? null : name;
    } on Object {
      _conversationNames[conversationId] = '';
      return null;
    }
  }

  Future<ChatUserProfile?> _profile(String externalUserId) async {
    final cached = _profiles[externalUserId];
    if (cached != null) {
      return cached;
    }
    try {
      final profile = await _adapter.userProfile(externalUserId);
      if (profile != null) {
        _profiles[externalUserId] = profile;
      }
      return profile;
    } on Object catch (e) {
      // A provider that will not disclose a profile (a missing email scope) is a
      // configuration gap, not an error worth failing the message over — the
      // code flow still links the user.
      _warn('profile($externalUserId) failed: $e');
      return null;
    }
  }

  // ── Commands ──

  Future<void> _onCommand(ChatCommandEvent event) async {
    final invoked = event.command.trim();
    if (invoked.startsWith('/')) {
      _command = invoked;
    }
    if (event.externalUserId.isEmpty) {
      return;
    }
    final answer = switch (event.verb) {
      'link' => _Answer(
        await _redeemLinkCode(event.externalUserId, event.rest),
      ),
      'ticket' => await _createTicketFromCommand(
        event.externalUserId,
        event.rest,
      ),
      'help' || '' => _Answer(_helpText),
      _ => _Answer('I do not know `${event.verb}`.\n$_helpText'),
    };
    await _reply(event, answer);
  }

  String get _helpText =>
      'What I can do:\n'
      '• `$_command ticket <title> | <description>` — file a ticket in Control '
      'Center\n'
      '• `$_command link <code>` — link this $_productName account to your '
      'Control Center user\n'
      '• mention me (`@${_adapter.botName}`) or send me a direct message to put '
      'an agent on something';

  Future<String> _redeemLinkCode(String externalUserId, String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      return 'Send `$_command link CODE`, using the code from Settings → '
          'Accounts → Chat bridges.';
    }
    final claim = _linkCodes.consume(workspaceId, code, provider: provider);
    if (claim == null) {
      return 'That code is not valid (or has expired). Generate a fresh one in '
          'Settings → Accounts → Chat bridges.';
    }
    final member = await _members.getMember(workspaceId, claim.userId);
    if (member == null) {
      return 'That code belongs to someone who is no longer a member of this '
          'workspace.';
    }
    final existing = await _userLinks.forExternalUser(
      workspaceId,
      provider: provider,
      externalTeamId: _adapter.teamId,
      externalUserId: externalUserId,
    );
    await _userLinks.upsert(
      ChatUserLink(
        id: existing?.id ?? _newId(),
        workspaceId: workspaceId,
        provider: provider,
        externalTeamId: _adapter.teamId,
        externalUserId: externalUserId,
        userId: claim.userId,
        method: ChatLinkMethod.code,
        linkedAt: _clock(),
      ),
    );
    final user = await _users.getById(claim.userId);
    CcInfraLog.info(
      '${_tag()}: linked $externalUserId to ${user?.handle ?? claim.userId} by '
      'code',
    );
    return 'Linked — you are ${user?.displayName ?? claim.userId} in Control '
        'Center. Mention me any time.';
  }

  Future<_Answer> _createTicketFromCommand(
    String externalUserId,
    String rest,
  ) async {
    final creator = _createTicket;
    if (creator == null) {
      return const _Answer('Ticket creation is not available on this server.');
    }
    if (rest.isEmpty) {
      return _Answer(
        'Give the ticket a title: `$_command ticket Fix the flaky login '
        'test | It fails on CI about once a day.`',
      );
    }
    final actor = await _resolveActor(externalUserId);
    if (actor.refusal != null) {
      return _Answer(actor.refusal!);
    }
    final pipe = rest.indexOf('|');
    final title = (pipe == -1 ? rest : rest.substring(0, pipe)).trim();
    final description = pipe == -1 ? null : rest.substring(pipe + 1).trim();
    if (title.isEmpty) {
      return const _Answer('A ticket needs a title before the `|`.');
    }
    try {
      final ticket = await creator(
        workspaceId: workspaceId,
        title: title,
        reporterUserId: actor.userId!,
        description: (description == null || description.isEmpty)
            ? null
            : description,
      );
      final url = _deepLinks?.ticket(workspaceId, ticket.id);
      return _Answer(
        'Filed *${ticket.key}* — ${ticket.title}.',
        // A filed ticket is finished work, so its card opens complete — and it
        // exists for the link: the reply's whole job is to hand the reporter the
        // ticket they just created.
        card: !_cardsOn
            ? null
            : ChatTaskCard(
                id: 'ticket-${ticket.id}',
                title: '${ticket.key} — ${ticket.title}',
                status: ChatTaskStatus.complete,
                link: url == null
                    ? null
                    : ChatTaskLink(label: 'View in Control Center', url: url),
              ),
      );
    } on Object catch (e) {
      CcInfraLog.error('${_tag()}: ticket creation failed', e);
      return _Answer('I could not file that ticket: $e');
    }
  }

  /// Answers a command, preferring the adapter's own reply channel (which works
  /// in a conversation the bot is not a member of) and falling back to an
  /// ephemeral message.
  Future<void> _reply(ChatCommandEvent event, _Answer answer) async {
    try {
      if (await _adapter.respondToCommand(
        event.replyHandle,
        markdown: answer.markdown,
        card: answer.card,
      )) {
        return;
      }
    } on Object catch (e) {
      _warn('command reply failed: $e');
    }
    // The ephemeral fallback carries text only: it exists for the case where the
    // provider's reply channel is gone, and the text already says everything the
    // card would.
    await _ephemeral(
      event.externalChannelId,
      event.externalUserId,
      answer.markdown,
    );
  }

  /// Answers the person who wrote, in the thread their message opened.
  ///
  /// Deliberately a real reply and not an ephemeral one. An ephemeral message
  /// anchored to a thread nobody has opened yet is invisible — the provider
  /// raises no unread for it — so a mention the bridge cannot serve (an unlinked
  /// account, most often) looked exactly like a bot that was down. A threaded
  /// reply badges the message it answers, and still keeps the refusal out of the
  /// channel.
  Future<void> _sayInThread(
    String conversationId,
    String threadId,
    String markdown,
  ) async {
    if (conversationId.isEmpty) {
      return;
    }
    try {
      await _adapter.postMessage(
        conversationId: conversationId,
        markdown: markdown,
        threadId: threadId,
      );
    } on Object catch (e) {
      // Somebody is waiting on this one, so a failure is silence rather than a
      // missing nicety: log it loudly enough to be found.
      _warn('reply in $conversationId/$threadId failed: $e');
    }
  }

  /// Says something only [externalUserId] can see — the fallback for a slash
  /// command whose own reply channel is gone.
  ///
  /// A command is typed by one person and its answer belongs to them, so a
  /// provider without ephemeral messages stays **silent** rather than posting it
  /// into the channel everyone is reading.
  Future<void> _ephemeral(
    String conversationId,
    String externalUserId,
    String markdown, {
    String? threadId,
  }) async {
    if (conversationId.isEmpty) {
      return;
    }
    if (!_can.ephemeralMessages) {
      CcInfraLog.debug(
        '${_tag()}: no ephemeral messages on $_productName, staying silent',
      );
      return;
    }
    await _swallow(
      () => _adapter.postEphemeral(
        conversationId: conversationId,
        userId: externalUserId,
        markdown: markdown,
        threadId: threadId,
      ),
    );
  }

  // ── Outbound: Control Center → chat ──

  void _watchChannel(String ccChannelId) {
    _channelSubs.putIfAbsent(
      ccChannelId,
      () => _registry
          .channelUpdates(ccChannelId)
          .listen((update) => _onTurnUpdate(ccChannelId, update)),
    );
  }

  void _onTurnUpdate(String ccChannelId, ChannelTurnUpdate event) {
    final target = _targets[ccChannelId];
    if (target == null) {
      return;
    }
    _awaitingRequest.remove(ccChannelId);
    final relay = _relays.putIfAbsent(
      event.messageId,
      // A card already reporting this channel's setup IS this turn's card: the
      // reader is watching it, and the stream it opened is where the answer
      // belongs. Otherwise the turn starts its own.
      //
      // The reply anchor is captured when the turn opens, not when it flushes:
      // in a bot DM several threads share one Control Center channel, and the
      // answer belongs to the thread that asked.
      () =>
          _setupRelays.remove(ccChannelId) ??
          _TurnRelay(
            target: target,
            ccChannelId: ccChannelId,
            // One card per turn, edited in place — so its id is the turn's.
            cardId: event.messageId,
            title: target.requestTitle ?? _genericCardTitle,
            link: _cardLink(ccChannelId),
          ),
    );
    final update = event.update;
    switch (update) {
      case SegmentOpened(:final index, :final segment):
        switch (segment) {
          case TextSegment(:final text):
            relay.setText(index, text);
          case ReasoningSegment(:final text):
            relay.noteThinking(index: index, text: text);
          case ToolSegment():
            relay.noteToolCall(segment);
          case ErrorSegment() || ViolationSegment():
            break;
        }
      case SegmentDelta(:final index, :final delta):
        relay.append(index, delta);
      case SegmentClosed(:final index, :final segment):
        switch (segment) {
          case TextSegment(:final text):
            relay.setText(index, text);
          case ReasoningSegment(:final text):
            relay.finishThinking(index: index, text: text);
          case ToolSegment():
            relay.noteToolResult(segment);
          case ErrorSegment() || ViolationSegment():
            break;
        }
      case TurnFinished(:final outcome):
        unawaited(_finish(event.messageId, relay, outcome));
        return;
    }
    if (relay.hasPending || (_cardsOn && relay.hasCardUpdate)) {
      // Thinking can last a long time with no tokens. Flush that line now so
      // Slack is not still showing "Starting the agent…" the whole wait.
      if (_cardsOn && relay.hasCardUpdate && relay.isThinking) {
        unawaited(
          relay.sequence(() => _flush(relay, finish: false, outcome: null)),
        );
      } else {
        relay.scheduleFlush(
          _flushInterval,
          () => _flush(relay, finish: false, outcome: null),
        );
      }
    }
  }

  /// Opens the request's card the moment the mention is accepted.
  ///
  /// Flushed immediately rather than throttled: a one-second wait after "I heard
  /// you" is the whole problem this exists to close. Later setup steps and the
  /// turn edit this same card in place.
  Future<void> _openRequestCard(String ccChannelId) async {
    if (!_cardsOn || !_can.streaming || _streamingAvailable == false) {
      return;
    }
    final target = _targets[ccChannelId];
    if (target == null) {
      return;
    }
    final relay = _setupRelays.putIfAbsent(
      ccChannelId,
      () => _TurnRelay(
        target: target,
        ccChannelId: ccChannelId,
        cardId: 'setup-$ccChannelId',
        title: target.requestTitle ?? _genericCardTitle,
        link: _cardLink(ccChannelId),
      ),
    );
    relay.setSetupNote(_ackNote);
    if (relay.hasCardUpdate) {
      await relay.sequence(() => _flush(relay, finish: false, outcome: null));
    }
  }

  /// Reports a channel's workspace setup on the card the request already opened.
  ///
  /// A first mention clones every repo the agent will work in — minutes, during
  /// which the agent has said nothing. The card that said "Working on it…" now
  /// says "Cloning acme/widgets…", and the turn that follows takes it over.
  void _onSetup(ChannelProvisioningChanged event) {
    // Setup only reaches the reader as a card on an open stream: a whole post
    // would be a second message that the answer then arrives beneath.
    if (!_cardsOn ||
        !_can.streaming ||
        _streamingAvailable == false ||
        event.workspaceId != workspaceId) {
      return;
    }
    final target = _targets[event.channelId];
    if (target == null || !_awaitingRequest.contains(event.channelId)) {
      return;
    }
    // A card is already reporting a turn in this channel, and its own narration
    // is newer than anything setup has to say. Deliberately not "a run is
    // registered": dispatch registers the run and *then* waits for the workspace
    // it is being cloned for, and a run that has not said a word yet is exactly
    // the silence this card exists to fill.
    if (_relays.values.any((relay) => relay.ccChannelId == event.channelId)) {
      return;
    }
    // A mention already opened a card; `ready` on a warm channel that somehow
    // never did is left quiet rather than flashing "Starting the agent…".
    if (event.status == ChannelProvisioningStatus.ready &&
        !_setupRelays.containsKey(event.channelId)) {
      return;
    }
    final relay = _setupRelays.putIfAbsent(
      event.channelId,
      () => _TurnRelay(
        target: target,
        ccChannelId: event.channelId,
        // Not the turn's id — there is no turn yet. The card outlives setup, so
        // its id must survive being adopted by the turn that follows.
        cardId: 'setup-${event.channelId}',
        title: target.requestTitle ?? _genericCardTitle,
        link: _cardLink(event.channelId),
      ),
    );
    relay.setSetupNote(_setupNote(event));
    if (event.status == ChannelProvisioningStatus.failed) {
      _awaitingRequest.remove(event.channelId);
      unawaited(_closeUnclaimedSetupCard(event.channelId));
      return;
    }
    if (relay.hasCardUpdate) {
      relay.scheduleFlush(
        _flushInterval,
        () => _flush(relay, finish: false, outcome: null),
      );
    }
  }

  /// Paints a setup card from the channel row when events raced the inbound
  /// handler: provisioning starts in `createChannel`, the first announce can
  /// land before `_awaitingRequest` contains the id.
  Future<void> _catchUpSetup(String ccChannelId) async {
    try {
      final channel = await _messages.getChannelById(workspaceId, ccChannelId);
      if (channel == null ||
          channel.provisioningStatus == ChannelProvisioningStatus.ready) {
        return;
      }
      _onSetup(
        ChannelProvisioningChanged(
          workspaceId: workspaceId,
          channelId: ccChannelId,
          status: channel.provisioningStatus,
          step: channel.provisioningStep,
          occurredAt: _clock(),
        ),
      );
    } on Object catch (e) {
      _warn('catching up on setup for $ccChannelId failed: $e');
    }
  }

  /// What the card says while a channel's workspace is being built.
  ///
  /// Server-side copy, like every other line the bridge writes: there is no
  /// `BuildContext` here, and the provider does not tell us the reader's
  /// language. The desktop's localized banner says the same things.
  static String? _setupNote(ChannelProvisioningChanged event) =>
      switch (event.status) {
        ChannelProvisioningStatus.provisioning => switch (event.step) {
          ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.repo,
            :final subject,
          )
              when subject.isNotEmpty =>
            'Cloning $subject…',
          ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.prCheckout,
            :final subject,
          )
              when subject.isNotEmpty =>
            'Checking out the pull request in $subject…',
          ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.agent,
            :final subject,
          )
              when subject.isNotEmpty =>
            'Setting up $subject…',
          _ => 'Preparing the workspace…',
        },
        // Setup is done but the agent has not spoken yet, which is the same
        // wait a warm channel has — so the card says what it is waiting for.
        ChannelProvisioningStatus.ready => 'Starting the agent…',
        ChannelProvisioningStatus.failed =>
          'Workspace setup failed — details are in Control Center.',
      };

  /// Closes a setup card that no turn ever adopted.
  ///
  /// Called when dispatch throws or provisioning fails. A card that was never
  /// sent is dropped: nothing was shown, so there is nothing to correct. One
  /// that already reached the reader is finished as an error rather than left
  /// spinning on an open stream.
  Future<void> _closeUnclaimedSetupCard(String ccChannelId) async {
    if (_registry.activeIn(ccChannelId).isNotEmpty) {
      return;
    }
    final relay = _setupRelays.remove(ccChannelId);
    if (relay == null) {
      return;
    }
    relay.cancelFlush();
    if (relay.handle != null || relay.hasCardUpdate) {
      await relay.sequence(
        () => _flush(relay, finish: true, outcome: TurnOutcome.failed),
      );
    }
    relay.dispose();
  }

  /// Who a stream on a stored link is for: the chat account of the member who
  /// created it, or null when they have since unlinked.
  Future<ChatRecipient?> _recipientFor(ChatChannelLink link) async {
    final creator = link.createdByUserId;
    if (creator == null) {
      return null;
    }
    try {
      final user = await _userLinks.forUser(
        workspaceId,
        creator,
        provider: provider,
      );
      return user == null
          ? null
          : ChatRecipient(
              externalUserId: user.externalUserId,
              externalTeamId: user.externalTeamId,
            );
    } on Object catch (e) {
      // A missing recipient costs a live reply, not the reply — arming must not
      // fail over it.
      _warn('resolving the reader of ${link.ccChannelId} failed: $e');
      return null;
    }
  }

  /// The way back into Control Center a card offers, or null when this server
  /// cannot be reached by a link (no public URL configured).
  ChatTaskLink? _cardLink(String ccChannelId) {
    final url = _deepLinks?.channel(workspaceId, ccChannelId);
    return url == null
        ? null
        : ChatTaskLink(label: 'View in Control Center', url: url);
  }

  /// The card's state for this flush, or null when the provider has no cards or
  /// nothing about the card changed since the last one.
  ChatTaskCard? _cardUpdate(
    _TurnRelay relay, {
    required bool finish,
    required TurnOutcome? outcome,
  }) {
    if (!_cardsOn) {
      return null;
    }
    return relay.takeCard(
      finish ? _cardStatus(outcome) : ChatTaskStatus.inProgress,
      result: finish ? _cardResult(relay, outcome) : null,
    );
  }

  /// The answer the finished card should show, or the short note a silent
  /// failure would otherwise leave the thread without.
  String? _cardResult(_TurnRelay relay, TurnOutcome? outcome) {
    final rendered = relay.rendered.trim();
    final text = rendered.isNotEmpty ? rendered : _outcomeNote(outcome);
    if (text == null || text.isEmpty) {
      return null;
    }
    if (text.length <= _maxCardResultLength) {
      return text;
    }
    return '${text.substring(0, _maxCardResultLength - 1).trimRight()}…';
  }

  static ChatTaskStatus _cardStatus(TurnOutcome? outcome) => switch (outcome) {
    TurnOutcome.completed => ChatTaskStatus.complete,
    TurnOutcome.failed ||
    TurnOutcome.interrupted ||
    TurnOutcome.maxTurns => ChatTaskStatus.error,
    null => ChatTaskStatus.inProgress,
  };

  Future<void> _finish(
    String messageId,
    _TurnRelay relay,
    TurnOutcome outcome,
  ) async {
    _relays.remove(messageId);
    relay.cancelFlush();
    await relay.sequence(() => _flush(relay, finish: true, outcome: outcome));
    relay.dispose();
  }

  /// Sends whatever the turn has produced since the last flush: new text, and
  /// the card that reports where the work is.
  ///
  /// The first flush opens the stream, later ones append, and the last one closes
  /// it. Both travel in one call so the card never disagrees with the words
  /// beside it. When the provider has no streaming — or refused it for this app —
  /// the whole reply is posted once at the end instead.
  Future<void> _flush(
    _TurnRelay relay, {
    required bool finish,
    required TurnOutcome? outcome,
  }) async {
    final target = relay.target;
    // Streaming may be a threaded surface (Slack's is): a target without a
    // thread anchor posts a whole reply instead.
    final threadless = _can.streamingRequiresThread && target.threadId == null;
    if (!_can.streaming ||
        _streamingAvailable == false ||
        threadless ||
        relay.abandonedStream) {
      if (finish) {
        await _postWhole(relay, outcome);
      }
      return;
    }

    var chunk = relay.takePending();
    final card = _cardUpdate(relay, finish: finish, outcome: outcome);
    var handle = relay.handle;
    if (handle == null) {
      // A card alone is worth opening a stream for while the turn runs: it is
      // what says the agent is working, before there is any answer to show. At
      // the *end* of a wordless turn it is not — a whole post can carry both the
      // card and the note explaining why nothing was said.
      if (chunk.trim().isEmpty && (finish || card == null)) {
        if (finish) {
          await _postWhole(relay, outcome);
        }
        return;
      }
      try {
        handle = await _adapter.startStream(
          conversationId: target.conversationId,
          threadId: target.threadId,
          withTaskCard: card != null,
          recipient: target.recipient,
        );
        relay.handle = handle;
        _setStreamingAvailable(true);
      } on ChatStreamingUnavailable catch (e) {
        relay.restore(chunk);
        relay.restoreCard();
        if (e.permanent) {
          CcInfraLog.info(
            '${_tag()}: streaming unavailable (${e.reason}); posting whole '
            'replies instead',
          );
          _setStreamingAvailable(false);
        } else {
          _warn('startStream refused: ${e.reason}');
        }
        if (finish) {
          await _postWhole(relay, outcome);
        }
        return;
      } on Object catch (e) {
        relay.restore(chunk);
        relay.restoreCard();
        _warn('startStream failed: $e');
        if (finish) {
          await _postWhole(relay, outcome);
        }
        return;
      }
    }

    // The mention already opened this stream with "Working on it…". A wordless
    // finish still has to say why, or the card just closes with no words.
    if (finish && chunk.trim().isEmpty) {
      chunk = _outcomeNote(outcome) ?? '';
    }

    // The card rides the first append of the flush; the rest is text the
    // provider's chunk ceiling forced us to split. A flush with a card and no new
    // words is still one append — that is how a turn that is only thinking so far
    // reports itself.
    final parts = chunk.isEmpty
        ? const <String>[]
        : _split(chunk, max: _can.maxStreamChunkLength);
    var pending = card;
    final appends = parts.isEmpty
        ? [if (card != null) null]
        : parts.map<String?>((part) => part);
    for (final part in appends) {
      try {
        await _adapter.appendStream(
          handle: handle,
          markdown: part,
          card: pending,
        );
        pending = null;
        relay.markDelivered();
      } on Object catch (e) {
        _warn('appendStream failed: $e');
        if (relay.delivered) {
          // Part of the reply already reached the reader, so re-posting the whole
          // thing would duplicate it: close the stream and let the transcript in
          // Control Center be the complete record.
          break;
        }
        // The card is the only part of this append the provider has never taken
        // before, so try the same words without it. Sending them is the product;
        // the card is a rendering of them.
        if (pending != null &&
            part != null &&
            await _appendPlain(handle, part)) {
          _warn('the task card was refused; continuing without cards');
          _cardsAccepted = false;
          relay.restoreCard();
          pending = null;
          relay.markDelivered();
          continue;
        }
        // A card-only append (the ack, a clone step) has no words to retry
        // without. Keep the stream — the answer still has to land here — and
        // stop asking for cards.
        if (pending != null && part == null) {
          _warn('the task card was refused; continuing without cards');
          _cardsAccepted = false;
          relay.restoreCard();
          pending = null;
          continue;
        }
        // Nothing has ever landed on this stream, so finishing it would leave an
        // empty message where the answer should be. Abandon it and let the reply
        // be posted whole.
        relay.restore(chunk);
        relay.restoreCard();
        relay.abandonStream();
        await _swallow(() => _adapter.stopStream(handle: handle!));
        if (finish) {
          await _postWhole(relay, outcome);
        }
        return;
      }
    }
    if (finish) {
      await _swallow(() => _adapter.stopStream(handle: handle!));
    }
  }

  /// Re-sends [markdown] alone, to find out whether the card was what the
  /// provider refused. True when the words got through.
  Future<bool> _appendPlain(ChatStreamHandle handle, String markdown) async {
    try {
      await _adapter.appendStream(handle: handle, markdown: markdown);
      return true;
    } on Object catch (e) {
      _warn('appendStream failed without the card: $e');
      return false;
    }
  }

  Future<void> _postWhole(_TurnRelay relay, TurnOutcome? outcome) async {
    final rendered = relay.rendered;
    final body = rendered.trim().isEmpty ? _outcomeNote(outcome) : rendered;
    if (body == null) {
      return;
    }
    // A long agent answer is truncated with a pointer rather than rejected
    // outright by the provider.
    final limit = _can.maxMessageLength;
    final text = body.length <= limit
        ? body
        : '${body.substring(0, limit)}\n\n…truncated — the full reply is in '
              'Control Center.';
    final card = _cardsOn ? relay.buildCard(_cardStatus(outcome)) : null;
    await _swallow(
      () => _adapter.postMessage(
        conversationId: relay.target.conversationId,
        markdown: text,
        threadId: relay.target.threadId,
        card: card,
      ),
    );
  }

  /// What to say when a turn produced no text at all. A silent failure looks
  /// like the bot ignored the request, which is worse than a short note.
  String? _outcomeNote(TurnOutcome? outcome) => switch (outcome) {
    TurnOutcome.failed =>
      'The agent run failed — details are in Control '
          'Center.',
    TurnOutcome.interrupted => 'The agent run was interrupted.',
    TurnOutcome.maxTurns => 'The agent stopped at its turn limit.',
    TurnOutcome.completed => null,
    null => null,
  };

  /// Splits an append into pieces the provider accepts (its stream chunks are
  /// capped, and a 1s throttle can accumulate a lot of text).
  static Iterable<String> _split(String text, {required int max}) {
    if (text.length <= max) {
      return [text];
    }
    final parts = <String>[];
    var rest = text;
    while (rest.length > max) {
      final window = rest.substring(0, max);
      // Prefer a paragraph, then a line, then a space — splitting mid-word in a
      // live card is visible to the reader.
      final cut = [
        window.lastIndexOf('\n\n'),
        window.lastIndexOf('\n'),
        window.lastIndexOf(' '),
      ].firstWhere((i) => i > max ~/ 2, orElse: () => max);
      parts.add(rest.substring(0, cut));
      rest = rest.substring(cut);
    }
    if (rest.isNotEmpty) {
      parts.add(rest);
    }
    return parts;
  }

  void _setStreamingAvailable(bool available) {
    if (_streamingAvailable == available) {
      return;
    }
    _streamingAvailable = available;
    _onStreamingAvailability?.call(available);
  }

  /// Mirrors a human message typed in Control Center out to the linked chat
  /// thread, so a conversation reads the same on both sides.
  Future<void> _mirrorOut(MessageReceived event) async {
    if (event.isAgentMessage || event.workspaceId != workspaceId) {
      return;
    }
    final target = _targets[event.channelId];
    if (target == null) {
      return;
    }
    try {
      final message = await _messages.getMessageById(
        workspaceId,
        event.messageId,
      );
      if (message == null || message.senderType != ChannelSenderType.user) {
        return;
      }
      // The bridge stamps `metadata['chat']` on everything it brings in, so this
      // is where an inbound chat message stops instead of echoing back.
      if (message.metadata?['chat'] != null) {
        return;
      }
      final author = await _users.getById(message.senderId);
      final label = author?.displayName ?? author?.handle;
      await _swallow(
        () => _adapter.postMessage(
          conversationId: target.conversationId,
          threadId: target.threadId,
          markdown: label == null
              ? message.content
              : '**$label**: ${message.content}',
        ),
      );
    } on Object catch (e) {
      _warn('mirror failed: $e');
    }
  }

  /// Runs a provider call whose failure must not break the flow around it (a
  /// status line, an ephemeral hint, a stream close).
  Future<void> _swallow(Future<void> Function() op) async {
    try {
      await op();
    } on Object catch (e) {
      CcInfraLog.debug('${_tag()}: ignored $_productName error: $e');
    }
  }

  void _warn(String message) => CcInfraLog.warning('${_tag()}: $message');

  String _tag() => 'ChatBridge(${provider.wire}/$workspaceId)';

  static String _uuidV4() => const Uuid().v4();
}

/// What the bridge answers a command with: the words, plus the card that gives
/// the reader somewhere to go.
class _Answer {
  const _Answer(this.markdown, {this.card});

  final String markdown;
  final ChatTaskCard? card;
}

/// Where in the chat product a Control Center channel's traffic goes.
class _ChatTarget {
  const _ChatTarget({
    required this.conversationId,
    this.threadId,
    this.requestTitle,
    this.recipient,
  });

  final String conversationId;
  final String? threadId;

  /// The last thing asked here, as a card title. Null for a channel armed from a
  /// stored link at boot — nobody has asked anything through it yet this run.
  final String? requestTitle;

  /// Who asked, in the provider's id space. Null for a channel armed from a
  /// stored link at boot; a provider that needs a recipient to stream (Slack, in
  /// a channel) then posts the reply whole instead.
  final ChatRecipient? recipient;
}

/// Accumulates one agent turn: the answer text that is relayed verbatim, and the
/// summary that becomes its card.
///
/// Only [TextSegment]s are *relayed*: tool output is a wall of diffs, which
/// does not belong in a chat thread. Text is kept per segment index so a
/// [SegmentClosed] can *replace* a partially-streamed segment (which is how
/// atomic segments arrive) while the bytes already sent stay accounted for.
///
/// The card's title is the *current* line — a setup note, "Thinking…", or the
/// latest tool — replaced in place. The thought is that row's details, once
/// reasoning finishes; tool output stays in Control Center.
class _TurnRelay {
  _TurnRelay({
    required this.target,
    required this.ccChannelId,
    required this.cardId,
    required this.title,
    this.link,
  });

  final _ChatTarget target;

  /// The Control Center channel this relay reports on.
  final String ccChannelId;

  /// Stable id of this turn's card, so every update edits the same one.
  final String cardId;

  /// What the turn is working on.
  final String title;

  /// Where the card points back to, when the server is reachable by link.
  final ChatTaskLink? link;

  final SplayTreeMap<int, StringBuffer> _text = SplayTreeMap();
  int _sent = 0;
  int _actions = 0;
  String? _bullet;
  final List<_LiveStep> _steps = [];
  final StringBuffer _reasoning = StringBuffer();
  int? _reasoningIndex;
  ChatTaskAction? _latestAction;
  String? _latestCallId;
  ChatTaskCard? _sentCard;
  ChatTaskCard? _cardBeforeSend;
  Timer? _flushTimer;
  Future<void> _lock = Future<void>.value();

  /// The live stream, once opened.
  ChatStreamHandle? handle;

  /// Whether anything at all has reached the reader on [handle]. A stream that
  /// never delivered can still be given up on without duplicating a prefix.
  bool get delivered => _delivered;
  bool _delivered = false;

  /// Whether the stream was given up on: it opened but would not take anything,
  /// so the reply is posted whole instead of finishing an empty message.
  bool get abandonedStream => _abandonedStream;
  bool _abandonedStream = false;

  void markDelivered() => _delivered = true;

  void abandonStream() => _abandonedStream = true;

  /// Everything the turn has said so far.
  String get rendered => _text.values.join('\n\n');

  bool get hasPending => rendered.length > _sent;

  /// Whether the card would say something new if it were sent now.
  bool get hasCardUpdate => buildCard(ChatTaskStatus.inProgress) != _sentCard;

  /// Whether the live line is currently "Thinking…".
  bool get isThinking => _bullet == _thinkingNote;

  /// What the workspace is doing while the turn has not started ("Cloning
  /// acme/widgets…"). Replaces the setup row in place; a later thought or tool
  /// is a new row.
  void setSetupNote(String? note) {
    if (note != null && note.isNotEmpty) {
      _bullet = note;
      _upsertStep(cardId, note, ChatTaskStatus.inProgress);
    }
  }

  void setText(int index, String text) {
    _text[index] = StringBuffer(text);
    _completeThinking();
  }

  /// The agent is reasoning. The row says `Thinking…`; the thought is the
  /// row's details, filled in when reasoning closes.
  void noteThinking({required int index, String? text}) {
    _reasoningIndex = index;
    _bullet = _thinkingNote;
    if (text != null) {
      _reasoning
        ..clear()
        ..write(text);
    }
    _upsertStep(
      _thinkId,
      _thinkingNote,
      ChatTaskStatus.inProgress,
      completeOthers: true,
    );
  }

  /// Reasoning finished. The thought becomes this row's details, once.
  void finishThinking({required int index, required String text}) {
    _reasoningIndex = index;
    _reasoning
      ..clear()
      ..write(text);
    _completeThinking();
  }

  /// Records that the agent started a tool. Counted here, on the call, so a tool
  /// still running is already visible.
  void noteToolCall(ToolSegment segment) {
    _actions++;
    _latestCallId = segment.toolCallId;
    _latestAction = _actionFrom(segment);
    _bullet = _actionLine(_latestAction!);
    _upsertStep(
      _toolStepId(segment),
      _bullet!,
      ChatTaskStatus.inProgress,
      completeOthers: true,
    );
  }

  /// Refreshes the latest action when *its* result lands — a call's arguments can
  /// arrive with the result rather than with the call.
  void noteToolResult(ToolSegment segment) {
    final action = _actionFrom(segment);
    if (_latestCallId == segment.toolCallId) {
      _latestAction = action;
      _bullet = _actionLine(action);
    }
    final id = _toolStepId(segment);
    if (_steps.any((step) => step.id == id)) {
      _upsertStep(
        id,
        _actionLine(action),
        segment.isError ? ChatTaskStatus.error : ChatTaskStatus.complete,
      );
    }
  }

  void append(int index, String delta) {
    _text[index]?.write(delta);
    if (_reasoningIndex == index) {
      _reasoning.write(delta);
    }
  }

  void _completeThinking() {
    final body = _reasoning.toString().trim();
    for (final step in _steps) {
      if (step.id == _thinkId && step.status == ChatTaskStatus.inProgress) {
        step.status = ChatTaskStatus.complete;
        if (body.isNotEmpty) {
          step.details = body;
        }
      }
    }
  }

  String get _thinkId => '$cardId-think';

  String _toolStepId(ToolSegment segment) => segment.toolCallId.isNotEmpty
      ? segment.toolCallId
      : '$cardId-tool-$_actions';

  void _upsertStep(
    String id,
    String title,
    ChatTaskStatus status, {
    bool completeOthers = false,
  }) {
    if (completeOthers) {
      for (final step in _steps) {
        if (step.id != id && step.status == ChatTaskStatus.inProgress) {
          step.status = ChatTaskStatus.complete;
          if (step.id == _thinkId) {
            final body = _reasoning.toString().trim();
            if (body.isNotEmpty) {
              step.details = body;
            }
          }
        }
      }
    }
    for (final step in _steps) {
      if (step.id == id) {
        step
          ..title = title
          ..status = status;
        return;
      }
    }
    _steps.add(_LiveStep(id: id, title: title, status: status));
  }

  /// The card as it stands, at [status].
  ChatTaskCard buildCard(ChatTaskStatus status, {String? result}) {
    final finished =
        status == ChatTaskStatus.complete || status == ChatTaskStatus.error;
    if (finished) {
      _completeThinking();
    }
    return ChatTaskCard(
      id: cardId,
      title: title,
      status: status,
      // One live bullet, replaced as work moves on. A finished turn with an
      // answer drops it so the card is not still showing the last tool; a
      // failed setup has no answer, so the excuse stays on the bullet.
      narration: finished && rendered.trim().isNotEmpty ? null : _bullet,
      steps: [
        for (final step in _steps)
          ChatTaskStep(
            id: step.id,
            title: step.title,
            status: finished && step.status == ChatTaskStatus.inProgress
                ? status
                : step.status,
            details: step.details,
          ),
      ],
      actionCount: _actions,
      latestAction: _latestAction,
      result: result,
      link: link,
    );
  }

  /// The card to send now, or null when nothing about it changed since the last
  /// one the provider was given.
  ChatTaskCard? takeCard(ChatTaskStatus status, {String? result}) {
    final next = buildCard(status, result: result);
    if (next == _sentCard) {
      return null;
    }
    _cardBeforeSend = _sentCard;
    _sentCard = next;
    return next;
  }

  /// Un-marks the last card as sent after a failed send, so the next flush
  /// carries it again.
  void restoreCard() => _sentCard = _cardBeforeSend;

  static ChatTaskAction _actionFrom(ToolSegment segment) => ChatTaskAction(
    name: segment.toolName,
    detail: _detailFrom(segment.inputs),
  );

  static String _actionLine(ChatTaskAction action) {
    final detail = action.detail?.trim() ?? '';
    return detail.isEmpty ? action.name : '${action.name} $detail';
  }

  /// The one argument worth showing for a tool call.
  ///
  /// Deliberately a short allow-list rather than "the first string in the map": an
  /// unknown tool's arguments can be an entire prompt or file body, and a card is
  /// a status line. Anything not named here shows as the tool's name alone.
  static String? _detailFrom(Map<String, dynamic>? inputs) {
    if (inputs == null) {
      return null;
    }
    for (final key in const [
      'command',
      'file_path',
      'path',
      'pattern',
      'url',
      'query',
      'title',
      'name',
    ]) {
      final value = inputs[key];
      if (value is String && value.trim().isNotEmpty) {
        return _cap(value.trim().replaceAll('\n', ' '), _maxDetailLength);
      }
    }
    return null;
  }

  /// Shortens [value] to [max], keeping the end of a path (the file name is what
  /// identifies it) and the start of anything else.
  static String _cap(String value, int max) {
    if (value.length <= max) {
      return value;
    }
    if (value.contains('/')) {
      return '…${value.substring(value.length - max + 1)}';
    }
    return '${value.substring(0, max - 1).trimRight()}…';
  }

  static const int _maxDetailLength = 80;

  /// Text not yet handed to the provider, marking it as sent.
  String takePending() {
    final all = rendered;
    if (all.length <= _sent) {
      return '';
    }
    final chunk = all.substring(_sent);
    _sent = all.length;
    return chunk;
  }

  /// Un-marks [chunk] as sent after a failed send, so the next flush retries.
  void restore(String chunk) => _sent = (_sent - chunk.length).clamp(0, _sent);

  void scheduleFlush(Duration interval, Future<void> Function() flush) {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer(interval, () {
      _flushTimer = null;
      unawaited(sequence(flush));
    });
  }

  void cancelFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Serializes provider calls for this turn: appends must arrive in order, and a
  /// throttled flush can fire while the previous one is still in flight.
  Future<void> sequence(Future<void> Function() op) {
    final next = _lock.then((_) => op());
    _lock = next.catchError((Object _) {});
    return next;
  }

  void dispose() => cancelFlush();
}

/// One plan row while the turn is running. Title and status are edited in place.
class _LiveStep {
  _LiveStep({required this.id, required this.title, required this.status});

  final String id;
  String title;
  ChatTaskStatus status;
  String? details;
}
