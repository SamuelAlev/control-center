import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_capabilities.dart';

/// Something that arrived from a chat provider, normalized.
///
/// The adapter owns everything provider-shaped about an inbound event — the
/// transport frame, the envelope, the subtypes worth ignoring, the text markup —
/// and emits one of these. The core bridge then decides what it *means*
/// (who may act, which channel it drives, whether the thread is bridged) and
/// that decision is identical for every provider.
sealed class ChatInboundEvent {
  /// Creates a [ChatInboundEvent].
  const ChatInboundEvent({required this.dedupeKey});

  /// A key that is stable across redeliveries of the *same* user action.
  ///
  /// Providers redeliver what they have not seen acknowledged, so the core keeps
  /// a bounded set of these and drops repeats. It has to be the action's id (a
  /// Slack `event_id`), never a per-frame id, or a redelivery would look new.
  final String dedupeKey;
}

/// A member said something the bot should answer.
final class ChatMessageEvent extends ChatInboundEvent {
  /// Creates a [ChatMessageEvent].
  const ChatMessageEvent({
    required super.dedupeKey,
    required this.externalTeamId,
    required this.externalChannelId,
    required this.externalMessageId,
    required this.externalUserId,
    required this.text,
    this.externalThreadId,
    this.viaMention = false,
    this.isDm = false,
  });

  /// Provider-side workspace/guild id. Empty for a provider without one.
  final String externalTeamId;

  /// The conversation the message was posted in.
  final String externalChannelId;

  /// The thread the message belongs to, or null when it is not in one. NOT the
  /// message's own id: the core anchors a bridge on
  /// `externalThreadId ?? externalMessageId` and only a real thread parent lets
  /// it recognize a reply to an already-bridged conversation.
  final String? externalThreadId;

  /// The message's own provider-side id.
  final String externalMessageId;

  /// Who sent it, provider-side.
  final String externalUserId;

  /// The body as **markdown** — the adapter has already undone the provider's
  /// own markup and stripped the bot mention.
  final String text;

  /// Whether the message explicitly addressed the bot (an `@mention`). A message
  /// that did not only counts as a request in a DM or inside a bridged thread.
  final bool viaMention;

  /// Whether this is a one-to-one conversation with the bot, which the bridge
  /// treats as one continuous conversation rather than one channel per thread.
  final bool isDm;
}

/// A member invoked the bot's command (`/cc link ABC123`).
final class ChatCommandEvent extends ChatInboundEvent {
  /// Creates a [ChatCommandEvent].
  const ChatCommandEvent({
    required super.dedupeKey,
    required this.externalTeamId,
    required this.externalChannelId,
    required this.externalUserId,
    required this.command,
    required this.verb,
    required this.rest,
    this.replyHandle,
  });

  /// Provider-side workspace/guild id. Empty for a provider without one.
  final String externalTeamId;

  /// Where the command was invoked.
  final String externalChannelId;

  /// Who invoked it.
  final String externalUserId;

  /// The command as the provider spelled it (`/cc`), so the bridge's own
  /// instructions quote whatever the app is actually called instead of a
  /// hardcoded name that may have been renamed.
  final String command;

  /// The first word of the argument, lowercased (`link`, `ticket`, `help`).
  final String verb;

  /// Everything after the verb, trimmed.
  final String rest;

  /// Opaque, adapter-owned token for answering this invocation (Slack's
  /// `response_url`). The core never inspects it — it hands it straight back to
  /// [ChatProviderAdapter.respondToCommand].
  final Object? replyHandle;
}

/// How far along the work a [ChatTaskCard] reports is.
enum ChatTaskStatus {
  /// Queued, not started.
  pending,

  /// Running now.
  inProgress,

  /// Finished successfully.
  complete,

  /// Stopped without finishing.
  error,
}

/// What the agent just did, as one line on a card.
class ChatTaskAction {
  /// Creates a [ChatTaskAction].
  const ChatTaskAction({required this.name, this.detail});

  /// The tool's name as the transcript records it (`Bash`, `Read`).
  final String name;

  /// A one-line summary of what it was called with (a command, a path), already
  /// shortened for a chat card. Never the tool's *output*.
  final String? detail;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTaskAction && name == other.name && detail == other.detail;

  @override
  int get hashCode => Object.hash(name, detail);
}

/// Where to open the full record of a card's work.
class ChatTaskLink {
  /// Creates a [ChatTaskLink].
  const ChatTaskLink({required this.label, required this.url});

  /// The call to action ("View in Control Center").
  final String label;

  /// An **http(s)** URL. Chat products reject custom schemes in a link, so the
  /// desktop's `control-center://` deep link is reached through a page the
  /// server serves rather than linked directly.
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTaskLink && label == other.label && url == other.url;

  @override
  int get hashCode => Object.hash(label, url);
}

/// One row in a Slack plan: a setup line, `Thinking…`, or a tool.
///
/// Slack's `plan` display mode shows these as rows in one grouped card. A new
/// [id] is a new row; the same id is edited in place (title and status replace).
class ChatTaskStep {
  /// Creates a [ChatTaskStep].
  const ChatTaskStep({
    required this.id,
    required this.title,
    required this.status,
    this.details,
  });

  /// Stable across updates of this row.
  final String id;

  /// Plain-text title Slack shows for this row.
  final String title;

  /// Where this row is.
  final ChatTaskStatus status;

  /// Optional body for this row (the thought on a `Thinking…` row). Sent once:
  /// Slack concatenates `details` on the same id.
  final String? details;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTaskStep &&
          id == other.id &&
          title == other.title &&
          status == other.status &&
          details == other.details;

  @override
  int get hashCode => Object.hash(id, title, status, details);
}

/// One unit of agent work, as a chat product can render it natively.
///
/// This is the provider-neutral shape of "what is the agent doing right now":
/// Slack draws it as a Thinking Steps *plan* of task cards and a provider
/// without [ChatProviderCapabilities.taskCards] never sees one at all.
///
/// It is deliberately a *summary*, not a transcript. Tool *output* and
/// reasoning prose stay in Control Center except as the `Thinking…` row's
/// details. [steps] are the rows of the plan (setup, `Thinking…`, each tool).
/// The answer is ordinary chat text beside the card.
class ChatTaskCard {
  /// Creates a [ChatTaskCard].
  const ChatTaskCard({
    required this.id,
    required this.title,
    required this.status,
    this.narration,
    this.steps = const [],
    this.actionCount = 0,
    this.latestAction,
    this.result,
    this.link,
  });

  /// Stable id for the card across its updates — the same card is *edited*
  /// while the work runs, not re-posted, so this must not change mid-turn.
  final String id;

  /// What the agent is working on, from the request that started it.
  final String title;

  /// Where the work is.
  final ChatTaskStatus status;

  /// One short line about what the agent is doing *now*, replaced as work moves
  /// on. Not a history of earlier steps. Kept for providers that show a single
  /// live line rather than [steps].
  final String? narration;

  /// Rows of the plan, in order. Empty when the card is a one-shot (a filed
  /// ticket) rather than a running turn.
  final List<ChatTaskStep> steps;

  /// How many tools the agent has run this turn.
  final int actionCount;

  /// The most recent tool call, when there is one.
  final ChatTaskAction? latestAction;

  /// The finished answer, for a provider that puts it on the card.
  ///
  /// Null while the turn is running. Slack streams the answer as markdown
  /// beside the card rather than as card `output` (same-id output concatenates).
  final String? result;

  /// The call to action back into Control Center.
  final ChatTaskLink? link;

  /// Returns a copy with selected fields overridden.
  ChatTaskCard copyWith({
    String? title,
    ChatTaskStatus? status,
    String? narration,
    List<ChatTaskStep>? steps,
    int? actionCount,
    ChatTaskAction? latestAction,
    String? result,
    ChatTaskLink? link,
  }) => ChatTaskCard(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    narration: narration ?? this.narration,
    steps: steps ?? this.steps,
    actionCount: actionCount ?? this.actionCount,
    latestAction: latestAction ?? this.latestAction,
    result: result ?? this.result,
    link: link ?? this.link,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTaskCard &&
          id == other.id &&
          title == other.title &&
          status == other.status &&
          narration == other.narration &&
          _sameSteps(steps, other.steps) &&
          actionCount == other.actionCount &&
          latestAction == other.latestAction &&
          result == other.result &&
          link == other.link;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    narration,
    Object.hashAll(steps),
    actionCount,
    latestAction,
    result,
    link,
  );
}

bool _sameSteps(List<ChatTaskStep> a, List<ChatTaskStep> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Who a streamed reply is for: the chat member whose request it answers.
///
/// Slack requires it to open a stream in a *channel* (`recipient_user_id` +
/// `recipient_team_id`) — without it the call is refused and the reader gets one
/// posted reply instead of a live one. Both ids are the provider's, never Control
/// Center's and they travel together because a user id from the wrong team
/// identifies nobody.
class ChatRecipient {
  /// Creates a [ChatRecipient].
  const ChatRecipient({required this.externalUserId, this.externalTeamId});

  /// The member the reply is for, in the provider's id space.
  final String externalUserId;

  /// The team/workspace that member belongs to, when the provider told us. On a
  /// shared (Slack Connect) channel this is the *sender's* team, which is not
  /// necessarily the team the app is installed in.
  final String? externalTeamId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRecipient &&
          externalUserId == other.externalUserId &&
          externalTeamId == other.externalTeamId;

  @override
  int get hashCode => Object.hash(externalUserId, externalTeamId);
}

/// A live streaming reply, opened by [ChatProviderAdapter.startStream].
///
/// Deliberately opaque: what identifies a stream is the provider's business (for
/// Slack it is a channel plus a message `ts`) and the core only ever passes the
/// handle back.
abstract interface class ChatStreamHandle {}

/// Thrown by [ChatProviderAdapter.startStream] when the provider will not stream
/// for this app.
///
/// The distinction matters: this is the bridge's cue to stop trying for the whole
/// connection and post whole replies instead ([permanent] true — a plan without
/// the feature), whereas an ordinary failure is worth retrying on the next turn.
class ChatStreamingUnavailable implements Exception {
  /// Creates a [ChatStreamingUnavailable].
  const ChatStreamingUnavailable(this.reason, {this.permanent = true});

  /// The provider's own error code, for the log and the settings surface.
  final String reason;

  /// Whether the refusal is a property of the app/plan rather than of this call.
  final bool permanent;

  @override
  String toString() => 'ChatStreamingUnavailable($reason)';
}

/// A chat member as the provider describes them.
class ChatUserProfile {
  /// Creates a [ChatUserProfile].
  const ChatUserProfile({
    required this.id,
    required this.label,
    this.email,
    this.isBot = false,
    this.teamId,
  });

  /// Provider-side member id.
  final String id;

  /// The best human label the provider offers.
  final String label;

  /// Verified account email, when the app is allowed to read it. The input to
  /// linking a member automatically.
  final String? email;

  /// Whether this member is a bot/app.
  final bool isBot;

  /// The member's provider-side team/guild id, when known.
  final String? teamId;
}

/// Live transport state, as the settings surface shows it.
class ChatTransportStatus {
  /// Creates a [ChatTransportStatus].
  const ChatTransportStatus({required this.state, this.error});

  /// Where the transport is.
  final ChatConnectionState state;

  /// The last failure, or null when healthy.
  final String? error;
}

/// Everything provider-specific about bridging one workspace to one chat app.
///
/// This is the seam the whole feature turns on: the bridge core is written
/// against it and contains no Slack (or Discord) knowledge at all, so adding a
/// provider is one implementation of this interface plus a descriptor — no
/// schema, RPC or UI change.
///
/// Three rules keep an implementation honest:
///
///  * **Text crossing this boundary is markdown.** Inbound, the adapter converts
///    the provider's markup to markdown and strips the bot mention; outbound it
///    converts back. The core never sees `mrkdwn`, `<@U123>` or a Discord
///    embed.
///  * **Advertised capabilities are what the core degrades on.** Anything
///    [capabilities] does not claim is never called and a call the provider
///    refuses at runtime still has to fail in a typed way
///    ([ChatStreamingUnavailable]) rather than throwing something the core would
///    have to pattern-match on a string to understand.
///  * **Ids are opaque strings, in the provider's own space.** The adapter never
///    invents Control Center ids and never reads the database; it is a transport
///    and a translator.
abstract interface class ChatProviderAdapter {
  /// Which provider this adapter speaks to.
  ChatProvider get provider;

  /// What this provider's API can do, so the core can degrade instead of
  /// failing.
  ChatProviderCapabilities get capabilities;

  /// The bot's own provider-side id, so its own messages are ignored.
  String get botUserId;

  /// The bot's display name — what members type after `@`.
  String get botName;

  /// Provider-side workspace/guild id this adapter serves. Empty for a provider
  /// with no such concept.
  String get teamId;

  /// Live transport state.
  ChatConnectionState get state;

  /// The last transport failure, or null when healthy.
  String? get lastError;

  /// Normalized inbound events. Broadcast: the bridge is the only subscriber,
  /// but a second one (a test, a future audit tap) must not steal events.
  Stream<ChatInboundEvent> get events;

  /// Transport state changes, for the settings surface and the log.
  Stream<ChatTransportStatus> get status;

  /// Opens the transport and keeps it open until [stop].
  Future<void> start();

  /// Closes the transport and releases everything it holds. Safe to call twice.
  Future<void> stop();

  /// Posts [markdown] into a conversation, optionally into a thread.
  ///
  /// [card] is rendered above the text when the provider claims
  /// [ChatProviderCapabilities.taskCards] — the whole-reply path's equivalent of
  /// the live card a stream carries.
  Future<void> postMessage({
    required String conversationId,
    required String markdown,
    String? threadId,
    ChatTaskCard? card,
  });

  /// Posts [markdown] so only [userId] sees it — the refusal path.
  ///
  /// Only called when [ChatProviderCapabilities.ephemeralMessages] is set.
  Future<void> postEphemeral({
    required String conversationId,
    required String userId,
    required String markdown,
    String? threadId,
  });

  /// Opens a reply that grows as the agent speaks.
  ///
  /// Throws [ChatStreamingUnavailable] when the provider will not stream for
  /// this app, which the core answers by posting whole replies instead.
  ///
  /// [withTaskCard] tells the provider that this stream will carry task cards,
  /// which some (Slack) need to know when the stream is opened rather than when
  /// the first card arrives.
  ///
  /// [recipient] is who asked, when it is known — Slack refuses to stream into a
  /// channel without it. Null for a turn nobody started from chat (an agent
  /// posting into a bridged channel on its own), which a provider that requires
  /// a recipient answers by refusing the stream.
  Future<ChatStreamHandle> startStream({
    required String conversationId,
    String? threadId,
    bool withTaskCard = false,
    ChatRecipient? recipient,
  });

  /// Appends to a live stream, in order: new prose as [markdown], the current
  /// state of the turn's work as [card].
  ///
  /// Both are optional but at least one is always present. A [card] replaces the
  /// one sent before it (same [ChatTaskCard.id]), so the reader sees one card
  /// that changes rather than a pile of them.
  Future<void> appendStream({
    required ChatStreamHandle handle,
    String? markdown,
    ChatTaskCard? card,
  });

  /// Closes a live stream, finalizing the message.
  Future<void> stopStream({required ChatStreamHandle handle});

  /// Sets the transient "is thinking…" line on a thread. Only called when
  /// [ChatProviderCapabilities.threadStatus] is set.
  Future<void> setThreadStatus({
    required String conversationId,
    required String threadId,
    required String status,
  });

  /// Titles a thread after the Control Center channel it drives. Only called
  /// when [ChatProviderCapabilities.threadTitle] is set.
  Future<void> setThreadTitle({
    required String conversationId,
    required String threadId,
    required String title,
  });

  /// Answers a command through [replyHandle] (a [ChatCommandEvent.replyHandle]).
  ///
  /// Providers usually offer a pre-authorized reply channel that works even
  /// where the bot is not a member, which is why the handle exists at all.
  /// Returns false when it could not be used, so the core can fall back to an
  /// ephemeral message.
  Future<bool> respondToCommand(
    Object? replyHandle, {
    required String markdown,
    ChatTaskCard? card,
  });

  /// The conversation's human name (`#engineering`), or null when unavailable.
  Future<String?> conversationName(String conversationId);

  /// Looks a member up, or null when the provider will not say.
  Future<ChatUserProfile?> userProfile(String externalUserId);
}
