/// What a chat provider's API can actually do, as the bridge must assume.
///
/// The bridge is written against the richest surface (a live streaming reply in
/// a thread, an ephemeral refusal only the sender sees, a transient status line)
/// and degrades per capability, so a provider that has none of it still works —
/// it just posts whole replies into the channel.
///
/// Every limit here was a hardcoded number in the Slack bridge. They belong to
/// the provider, not to the relay logic: Slack caps a message at 40k characters
/// and a stream chunk well below that and a different product will not.
class ChatProviderCapabilities {
  /// Creates a [ChatProviderCapabilities].
  const ChatProviderCapabilities({
    this.streaming = false,
    this.streamingRequiresThread = false,
    this.ephemeralMessages = false,
    this.threadStatus = false,
    this.threadTitle = false,
    this.slashCommands = false,
    this.taskCards = false,
    this.maxMessageLength = 2000,
    this.maxStreamChunkLength = 2000,
  });

  /// Rebuilds from the wire map.
  factory ChatProviderCapabilities.fromJson(Map<String, dynamic> json) =>
      ChatProviderCapabilities(
        streaming: json['streaming'] as bool? ?? false,
        streamingRequiresThread:
            json['streamingRequiresThread'] as bool? ?? false,
        ephemeralMessages: json['ephemeralMessages'] as bool? ?? false,
        threadStatus: json['threadStatus'] as bool? ?? false,
        threadTitle: json['threadTitle'] as bool? ?? false,
        slashCommands: json['slashCommands'] as bool? ?? false,
        taskCards: json['taskCards'] as bool? ?? false,
        maxMessageLength: json['maxMessageLength'] as int? ?? 2000,
        maxStreamChunkLength: json['maxStreamChunkLength'] as int? ?? 2000,
      );

  /// Whether the provider can render a reply that grows as the agent speaks.
  ///
  /// Advertising it is not a promise: the provider may still refuse at call
  /// time (Slack's streaming needs a paid plan), which the bridge remembers for
  /// the connection and reports through `streamingAvailable`.
  final bool streaming;

  /// Whether a stream can only be opened inside a thread. Slack's can, so a
  /// reply target without a thread anchor posts whole replies instead.
  final bool streamingRequiresThread;

  /// Whether a message can be addressed to one member only. The refusal path
  /// depends on it: without ephemerals, "you are not linked" would be shouted
  /// into the channel, so the bridge stays silent instead.
  final bool ephemeralMessages;

  /// Whether a transient "is thinking…" line can be set on a thread.
  final bool threadStatus;

  /// Whether a thread can be titled after the conversation it drives.
  final bool threadTitle;

  /// Whether the provider delivers slash commands (`/cc link …`).
  final bool slashCommands;

  /// Whether the provider can render a structured card for a unit of work — a
  /// title, a status, a narration line and what the agent just did — that is
  /// updated in place as the work progresses.
  ///
  /// Without it the bridge relays prose only, which is what every provider can
  /// do. It is never a second copy of the answer: a card reports *state* and
  /// the agent's text stays the message.
  final bool taskCards;

  /// Hard ceiling on one posted message, in characters.
  final int maxMessageLength;

  /// Hard ceiling on one appended stream chunk, in characters.
  final int maxStreamChunkLength;

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'streaming': streaming,
    'streamingRequiresThread': streamingRequiresThread,
    'ephemeralMessages': ephemeralMessages,
    'threadStatus': threadStatus,
    'threadTitle': threadTitle,
    'slashCommands': slashCommands,
    'taskCards': taskCards,
    'maxMessageLength': maxMessageLength,
    'maxStreamChunkLength': maxStreamChunkLength,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatProviderCapabilities &&
          runtimeType == other.runtimeType &&
          streaming == other.streaming &&
          streamingRequiresThread == other.streamingRequiresThread &&
          ephemeralMessages == other.ephemeralMessages &&
          threadStatus == other.threadStatus &&
          threadTitle == other.threadTitle &&
          slashCommands == other.slashCommands &&
          taskCards == other.taskCards &&
          maxMessageLength == other.maxMessageLength &&
          maxStreamChunkLength == other.maxStreamChunkLength;

  @override
  int get hashCode => Object.hash(
    streaming,
    streamingRequiresThread,
    ephemeralMessages,
    threadStatus,
    threadTitle,
    slashCommands,
    taskCards,
    maxMessageLength,
    maxStreamChunkLength,
  );
}
