import 'dart:async';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_capabilities.dart';
import 'package:cc_infra/src/chat/chat_provider_adapter.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/slack_api_client.dart';
import 'package:cc_infra/src/slack/slack_socket.dart';
import 'package:cc_infra/src/slack/slack_socket_mode_client.dart';
import 'package:cc_infra/src/slack/slack_task_card.dart';
import 'package:cc_infra/src/slack/slack_text.dart';

/// What the Slack API can do for the bridge.
///
/// The two limits were hardcoded in the bridge before the port existed: 40k is
/// Slack's per-message ceiling (39000 leaves room for the truncation note) and a
/// `chat.appendStream` chunk has to stay well under it.
const slackChatCapabilities = ChatProviderCapabilities(
  streaming: true,
  streamingRequiresThread: true,
  ephemeralMessages: true,
  threadStatus: true,
  threadTitle: true,
  slashCommands: true,
  taskCards: true,
  maxMessageLength: 39000,
  maxStreamChunkLength: 3800,
);

/// Slack's implementation of [ChatProviderAdapter].
///
/// Everything Slack-shaped about the bridge lives here: Socket Mode as the
/// transport (which is what lets the whole feature work from a laptop with no
/// public endpoint), the Web API calls, the mrkdwn codec and the envelope
/// normalization — including two details that would otherwise leak into the
/// generic core:
///
///  * **A channel mention arrives twice**, once as `app_mention` and once as
///    `message`. `app_mention` wins; the plain copy is dropped here, so the core
///    never has to know that Slack double-delivers.
///  * **Subtypes are mostly chrome.** Joins, edits, deletions and thread
///    broadcasts of our own replies are not new requests. `file_share` is the one
///    exception — an ordinary message that happens to carry an upload.
class SlackChatAdapter implements ChatProviderAdapter {
  /// Creates a [SlackChatAdapter] for one workspace's Slack app.
  ///
  /// [api] must already be authorized with the app's bot token; [appToken] is the
  /// app-level (`xapp-`) token Socket Mode dials with.
  SlackChatAdapter({
    required this.workspaceId,
    required SlackApiClient api,
    required String appToken,
    required this.botUserId,
    required this.botName,
    required this.teamId,
    SlackSocketConnector? connector,
    bool debugReconnects = false,
  }) : _api = api {
    _client = SlackSocketModeClient(
      workspaceId: workspaceId,
      appToken: appToken,
      api: api,
      connector: connector,
      debugReconnects: debugReconnects,
      onEnvelope: handleEnvelope,
      onStateChanged: (state, error) {
        CcInfraLog.info(
          'Slack($workspaceId): ${state.wire}${error == null ? '' : ' ($error)'}',
        );
        if (!_status.isClosed) {
          _status.add(ChatTransportStatus(state: state, error: error));
        }
      },
    );
  }

  /// The Control Center workspace this adapter serves.
  final String workspaceId;

  final SlackApiClient _api;
  late final SlackSocketModeClient _client;

  final _events = StreamController<ChatInboundEvent>.broadcast();
  final _status = StreamController<ChatTransportStatus>.broadcast();

  /// Whether Slack accepted a task display mode on this app. Null until a stream
  /// has asked for one; false parks the request for the connection's life.
  bool? _taskDisplayModeAccepted;

  /// Per-stream task-card state: CTA sources go on the trailing row once.
  /// Slack concatenates `details` on the same id, so they leave once.
  final Map<String, _CardStream> _cardStreams = {};

  @override
  ChatProvider get provider => ChatProvider.slack;

  @override
  ChatProviderCapabilities get capabilities => slackChatCapabilities;

  @override
  final String botUserId;

  @override
  final String botName;

  @override
  final String teamId;

  @override
  ChatConnectionState get state => _client.state;

  @override
  String? get lastError => _client.lastError;

  @override
  Stream<ChatInboundEvent> get events => _events.stream;

  @override
  Stream<ChatTransportStatus> get status => _status.stream;

  @override
  Future<void> start() => _client.start();

  @override
  Future<void> stop() async {
    await _client.stop();
    _cardStreams.clear();
    await _events.close();
    await _status.close();
  }

  // ── Inbound: Slack envelopes → normalized events ──

  /// Handles one Socket Mode envelope, emitting normalized events.
  ///
  /// Called by the socket client after it has acked, so it may take as long as a
  /// dispatch takes. Public because normalization is the part of this adapter
  /// worth testing directly.
  Future<void> handleEnvelope(SlackEnvelope envelope) async {
    final team = envelope.teamId;
    if (team != null && teamId.isNotEmpty && team != teamId) {
      // Another Slack team on the same app: not ours to serve.
      return;
    }
    switch (envelope.type) {
      case 'events_api':
        _onEvent(envelope);
      case 'slash_commands':
        _onCommand(envelope);
      default:
        // `interactive` (buttons, modals) is not wired yet.
        break;
    }
  }

  void _onEvent(SlackEnvelope envelope) {
    final event = envelope.event;
    if (event == null) {
      return;
    }
    switch (event['type'] as String?) {
      case 'app_mention':
        _onInbound(envelope, event, viaMention: true);
      case 'message':
        _onInbound(envelope, event, viaMention: false);
      default:
        break;
    }
  }

  void _onInbound(
    SlackEnvelope envelope,
    Map<String, dynamic> event, {
    required bool viaMention,
  }) {
    final subtype = event['subtype'] as String?;
    if (subtype != null && subtype != 'file_share') {
      return;
    }
    if (event['bot_id'] != null) {
      return;
    }
    final slackUserId = event['user'] as String?;
    final channel = event['channel'] as String?;
    final ts = event['ts'] as String?;
    if (slackUserId == null ||
        slackUserId.isEmpty ||
        slackUserId == botUserId ||
        channel == null ||
        channel.isEmpty ||
        ts == null ||
        ts.isEmpty) {
      return;
    }

    final raw = event['text'] as String? ?? '';
    final addressesBot = SlackText.mentionsBot(raw, botUserId);
    // The `message` copy of a channel mention is a duplicate of the
    // `app_mention` that will arrive (or already has) with the same event id in a
    // different envelope, so it is dropped here rather than deduped downstream.
    if (!viaMention && addressesBot) {
      return;
    }

    _emit(
      ChatMessageEvent(
        dedupeKey: envelope.dedupeKey,
        externalTeamId: _team(event),
        externalChannelId: channel,
        externalThreadId: event['thread_ts'] as String?,
        externalMessageId: ts,
        externalUserId: slackUserId,
        text: SlackText.toMarkdown(raw, botUserId: botUserId),
        viaMention: viaMention,
        isDm:
            (event['channel_type'] as String?) == 'im' ||
            channel.startsWith('D'),
      ),
    );
  }

  /// The team an event names, falling back to this adapter's own — a DM event
  /// omits `team` in some payload shapes.
  String _team(Map<String, dynamic> event) =>
      (event['team'] as String?) ?? teamId;

  void _onCommand(SlackEnvelope envelope) {
    final payload = envelope.payload;
    final text = (payload['text'] as String? ?? '').trim();
    final slackUserId = payload['user_id'] as String? ?? '';
    if (slackUserId.isEmpty) {
      return;
    }
    final space = text.indexOf(' ');
    _emit(
      ChatCommandEvent(
        dedupeKey: envelope.dedupeKey,
        externalTeamId: payload['team_id'] as String? ?? teamId,
        externalChannelId: payload['channel_id'] as String? ?? '',
        externalUserId: slackUserId,
        command: (payload['command'] as String? ?? '').trim(),
        verb: (space == -1 ? text : text.substring(0, space)).toLowerCase(),
        rest: space == -1 ? '' : text.substring(space + 1).trim(),
        // Slack's pre-authorized reply channel: it works in a conversation the
        // bot is not a member of, where `chat.postEphemeral` fails outright.
        replyHandle: payload['response_url'] as String?,
      ),
    );
  }

  void _emit(ChatInboundEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  // ── Outbound: markdown → Slack ──

  @override
  Future<void> postMessage({
    required String conversationId,
    required String markdown,
    String? threadId,
    ChatTaskCard? card,
  }) {
    final text = SlackText.toMrkdwn(markdown);
    return _api.postMessage(
      channel: conversationId,
      // With blocks, `text` is what a push notification and a screen reader
      // read, so it stays the whole reply either way.
      text: text,
      threadTs: threadId,
      blocks: card == null
          ? null
          : [SlackTaskCard.block(card), ..._markdownBlocks(markdown)],
    );
  }

  /// The reply as `markdown` blocks, split to stay under Slack's per-block text
  /// limit.
  ///
  /// A whole-reply post is already capped at the message ceiling by the bridge,
  /// but one block accepts far less than one message, so a long answer that has
  /// to ride beside a card is carried by several blocks rather than truncated a
  /// second time.
  static Iterable<Map<String, dynamic>> _markdownBlocks(String markdown) {
    final body = markdown.trim();
    if (body.isEmpty) {
      return const [];
    }
    final blocks = <Map<String, dynamic>>[];
    var rest = body;
    while (rest.length > _maxBlockTextLength) {
      final window = rest.substring(0, _maxBlockTextLength);
      final cut = [window.lastIndexOf('\n\n'), window.lastIndexOf('\n')]
          .firstWhere(
            (i) => i > _maxBlockTextLength ~/ 2,
            orElse: () => _maxBlockTextLength,
          );
      blocks.add({'type': 'markdown', 'text': rest.substring(0, cut)});
      rest = rest.substring(cut);
    }
    if (rest.trim().isNotEmpty) {
      blocks.add({'type': 'markdown', 'text': rest});
    }
    return blocks;
  }

  /// Slack's ceiling on one `markdown` block's text.
  static const int _maxBlockTextLength = 11900;

  @override
  Future<void> postEphemeral({
    required String conversationId,
    required String userId,
    required String markdown,
    String? threadId,
  }) => _api.postEphemeral(
    channel: conversationId,
    user: userId,
    text: SlackText.toMrkdwn(markdown),
    threadTs: threadId,
  );

  @override
  Future<ChatStreamHandle> startStream({
    required String conversationId,
    String? threadId,
    bool withTaskCard = false,
    ChatRecipient? recipient,
  }) async {
    if (threadId == null) {
      // Guarded by `streamingRequiresThread`, so reaching this means a bug in
      // the core rather than a Slack refusal — say which.
      throw const ChatStreamingUnavailable('thread_required', permanent: false);
    }
    final withMode = withTaskCard && _taskDisplayModeAccepted != false;
    try {
      final handle = await _api.startStream(
        channel: conversationId,
        threadTs: threadId,
        // Required to stream into a channel: without them Slack answers
        // `missing_recipient_user_id` / `missing_recipient_team_id` and the reply
        // degrades to a single post. A DM does not need them and passing them
        // there is harmless.
        recipientUserId: recipient?.externalUserId,
        recipientTeamId: recipient?.externalTeamId,
        taskDisplayMode: withMode ? SlackTaskCard.displayMode : null,
      );
      if (withMode) {
        _taskDisplayModeAccepted = true;
      }
      return _SlackStream(handle);
    } on SlackApiException catch (e) {
      // Thinking Steps is new enough that its display modes are not worth
      // betting the whole reply on: if Slack refused the *call* while we were
      // asking for one, drop the mode for this connection and open the stream
      // without it. Losing a card is a worse rendering; losing the stream is a
      // worse product.
      if (withMode && !e.isStreamingUnavailable && !e.isAuthFailure) {
        CcInfraLog.info(
          'Slack($workspaceId): task display mode refused (${e.error}); '
          'streaming without it',
        );
        _taskDisplayModeAccepted = false;
        return startStream(
          conversationId: conversationId,
          threadId: threadId,
          withTaskCard: withTaskCard,
          recipient: recipient,
        );
      }
      // A plan without the Agents feature refuses every call, so the bridge must
      // stop asking; anything else is worth trying again next turn.
      throw ChatStreamingUnavailable(
        e.error,
        permanent: e.isStreamingUnavailable,
      );
    }
  }

  @override
  Future<void> appendStream({
    required ChatStreamHandle handle,
    String? markdown,
    ChatTaskCard? card,
  }) async {
    final stream = _unwrap(handle);
    // Text is standard markdown on both forms (`markdown_text`), so the mrkdwn
    // codec is deliberately not applied on this path.
    final text = markdown != null && markdown.isNotEmpty ? markdown : null;
    if (card != null) {
      await _api.appendStream(
        handle: stream,
        chunks: _taskChunks(stream.ts, card),
      );
    }
    if (text == null) {
      if (card == null) {
        await _api.appendStream(handle: stream, markdownText: markdown ?? '');
      }
      return;
    }
    // Slack's plan view ignores markdown mixed into task updates and it
    // refuses `markdown_text` and `chunks` on the same call
    // (`cannot_provide_both_markdown_text_and_chunks`). A plan stream's
    // answer is therefore a later chunks-only `markdown_text` append. A
    // stream that never grew a card still uses the top-level field.
    if (_cardStreams.containsKey(stream.ts)) {
      await _api.appendStream(
        handle: stream,
        chunks: [SlackTaskCard.markdown(text)],
      );
    } else {
      await _api.appendStream(handle: stream, markdownText: text);
    }
  }

  /// A `plan` of tasks. Hermes's working draft (and Slack's streaming guide):
  /// `plan_update` for the request title, then one `task_update` per row.
  /// The answer is a later append of its own. Details are sent once per id —
  /// Slack concatenates them on later sends.
  List<Map<String, dynamic>> _taskChunks(String streamTs, ChatTaskCard card) {
    final state = _cardStreams.putIfAbsent(streamTs, _CardStream.new);
    final steps = SlackTaskCard.rows(card);
    final last = steps.length - 1;
    final sendLink =
        !state.sentLink &&
        card.link != null &&
        steps.last.id == '${card.id}-open';
    if (sendLink) {
      state.sentLink = true;
    }
    return [
      SlackTaskCard.plan(title: card.title),
      for (var i = 0; i < steps.length; i++)
        SlackTaskCard.task(
          id: steps[i].id,
          title: steps[i].title,
          status: steps[i].status,
          details: _takeDetails(state, steps[i]),
          link: i == last && sendLink ? card.link : null,
        ),
    ];
  }

  /// Details on a given id concatenate, so they leave once.
  String? _takeDetails(_CardStream state, ChatTaskStep step) {
    final details = step.details?.trim() ?? '';
    if (details.isEmpty || state.sentDetails.contains(step.id)) {
      return null;
    }
    state.sentDetails.add(step.id);
    return details;
  }

  @override
  Future<void> stopStream({required ChatStreamHandle handle}) {
    final stream = _unwrap(handle);
    _cardStreams.remove(stream.ts);
    return _api.stopStream(handle: stream);
  }

  @override
  Future<void> setThreadStatus({
    required String conversationId,
    required String threadId,
    required String status,
  }) => _api.setThreadStatus(
    channel: conversationId,
    threadTs: threadId,
    status: status,
  );

  @override
  Future<void> setThreadTitle({
    required String conversationId,
    required String threadId,
    required String title,
  }) => _api.setThreadTitle(
    channel: conversationId,
    threadTs: threadId,
    title: title,
  );

  @override
  Future<bool> respondToCommand(
    Object? replyHandle, {
    required String markdown,
    ChatTaskCard? card,
  }) async {
    final responseUrl = replyHandle is String ? replyHandle : '';
    if (responseUrl.isEmpty) {
      return false;
    }
    await _api.respondToCommand(
      responseUrl,
      text: SlackText.toMrkdwn(markdown),
      blocks: card == null ? null : [SlackTaskCard.block(card)],
    );
    return true;
  }

  @override
  Future<String?> conversationName(String conversationId) async {
    final info = await _api.conversationInfo(conversationId);
    final name = info?['name'] as String? ?? '';
    return name.isEmpty ? null : name;
  }

  @override
  Future<ChatUserProfile?> userProfile(String externalUserId) async {
    final profile = await _api.userInfo(externalUserId);
    if (profile == null) {
      return null;
    }
    return ChatUserProfile(
      id: profile.id,
      label: profile.label,
      email: profile.email,
      isBot: profile.isBot,
      teamId: profile.teamId,
    );
  }

  static SlackStreamHandle _unwrap(ChatStreamHandle handle) =>
      (handle as _SlackStream).handle;
}

/// A Slack streaming reply behind the port's opaque handle.
class _SlackStream implements ChatStreamHandle {
  const _SlackStream(this.handle);

  final SlackStreamHandle handle;
}

/// One live stream's task-card bookkeeping.
class _CardStream {
  bool sentLink = false;
  final Set<String> sentDetails = {};
}
