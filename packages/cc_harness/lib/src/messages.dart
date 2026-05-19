/// Unified conversation message types for the built-in agent loop (harness).
///
/// These types are pure Dart — no `dart:io`, `dio`, `drift`, or `flutter`
/// dependencies — so the agent loop can be unit-tested without HTTP or a
/// filesystem. The format is provider-agnostic: a [HarnessMessage] converts
/// cleanly to both the Anthropic Messages API and the OpenAI Chat Completions
/// API at the provider boundary.
library;

/// Who authored a [HarnessMessage].
enum HarnessRole {
  /// System / developer instructions. On the Anthropic wire the system prompt
  /// is a separate request field, not a message; on the OpenAI wire it is a
  /// `system`-role message. The provider handles the difference.
  system,

  /// A human (or upstream caller) turn.
  user,

  /// A model turn — may interleave text, thinking, and tool-use blocks.
  assistant,

  /// A tool result fed back to the model. Maps to a `user`-role content block
  /// on the Anthropic wire and a `tool`-role message on the OpenAI wire.
  tool,
}

/// A single content block inside a [HarnessMessage].
///
/// A message is a list of blocks because an assistant turn can interleave
/// streamed text, extended-thinking, and one or more tool-use requests.
sealed class HarnessContentBlock {
  /// Const base constructor.
  const HarnessContentBlock();

  /// A plain JSON map for persistence / debugging (not the provider wire form,
  /// which each provider builds itself).
  Map<String, dynamic> toJson();
}

/// Plain assistant or user text.
class HarnessTextBlock extends HarnessContentBlock {
  /// Creates a text block.
  const HarnessTextBlock(this.text);

  /// The text payload.
  final String text;

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HarnessTextBlock && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// The model is requesting a tool call.
class HarnessToolUseBlock extends HarnessContentBlock {
  /// Creates a tool-use block.
  const HarnessToolUseBlock({
    required this.id,
    required this.name,
    required this.input,
  });

  /// Provider-assigned tool-call id (used to pair the result back).
  final String id;

  /// Tool name the model wants to invoke.
  final String name;

  /// Decoded JSON arguments for the call.
  final Map<String, dynamic> input;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_use',
    'id': id,
    'name': name,
    'input': input,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessToolUseBlock && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// A tool result fed back to the model.
class HarnessToolResultBlock extends HarnessContentBlock {
  /// Creates a tool-result block.
  const HarnessToolResultBlock({
    required this.toolUseId,
    required this.content,
    this.isError = false,
  });

  /// The [HarnessToolUseBlock.id] this result answers.
  final String toolUseId;

  /// The result text shown to the model.
  final String content;

  /// Whether the tool failed (the model is told the call errored).
  final bool isError;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_result',
    'tool_use_id': toolUseId,
    'content': content,
    'is_error': isError,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessToolResultBlock &&
          other.toolUseId == toolUseId &&
          other.content == content &&
          other.isError == isError;

  @override
  int get hashCode => Object.hash(toolUseId, content, isError);
}

/// An image supplied to the model (user/tool content), carried as base64.
///
/// Enables multimodal input (screenshots, design diffs, rendered output) for
/// providers that accept images; providers that don't simply skip it. The bytes
/// are base64 so the block stays pure-Dart and JSON-serializable.
class HarnessImageBlock extends HarnessContentBlock {
  /// Creates an image block from base64 [data] of the given [mediaType]
  /// (e.g. `image/png`, `image/jpeg`).
  const HarnessImageBlock({required this.data, required this.mediaType});

  /// Base64-encoded image bytes (no data-URI prefix).
  final String data;

  /// The image MIME type (e.g. `image/png`).
  final String mediaType;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'media_type': mediaType,
    'data': data,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessImageBlock &&
          other.data == data &&
          other.mediaType == mediaType;

  @override
  int get hashCode => Object.hash(data, mediaType);
}

/// Extended-reasoning ("thinking") output from the model.
class HarnessThinkingBlock extends HarnessContentBlock {
  /// Creates a thinking block.
  const HarnessThinkingBlock(this.thinking, {this.signature});

  /// The reasoning text.
  final String thinking;

  /// Opaque provider signature required to replay thinking on later turns
  /// (Anthropic returns one per thinking block). Null when not provided.
  final String? signature;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'thinking',
    'thinking': thinking,
    if (signature != null) 'signature': signature,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessThinkingBlock &&
          other.thinking == thinking &&
          other.signature == signature;

  @override
  int get hashCode => Object.hash(thinking, signature);
}

/// One message in the conversation history.
class HarnessMessage {
  /// Creates a message from an explicit block list.
  const HarnessMessage({required this.role, required this.content});

  /// Convenience: a single-text user turn.
  factory HarnessMessage.user(String text) =>
      HarnessMessage(role: HarnessRole.user, content: [HarnessTextBlock(text)]);

  /// Convenience: a single-text system turn.
  factory HarnessMessage.system(String text) => HarnessMessage(
    role: HarnessRole.system,
    content: [HarnessTextBlock(text)],
  );

  /// Convenience: a single-text assistant turn.
  factory HarnessMessage.assistant(String text) => HarnessMessage(
    role: HarnessRole.assistant,
    content: [HarnessTextBlock(text)],
  );

  /// Convenience: a message carrying one or more tool results (role `tool`).
  factory HarnessMessage.toolResults(List<HarnessToolResultBlock> results) =>
      HarnessMessage(role: HarnessRole.tool, content: results);

  /// Author of the message.
  final HarnessRole role;

  /// Ordered content blocks (1+).
  final List<HarnessContentBlock> content;

  /// All text blocks concatenated.
  String get textContent =>
      content.whereType<HarnessTextBlock>().map((b) => b.text).join('\n');

  /// Whether this message contains any tool-use requests.
  bool get hasToolUse => content.any((b) => b is HarnessToolUseBlock);

  /// All tool-use blocks in order.
  List<HarnessToolUseBlock> get toolUses =>
      content.whereType<HarnessToolUseBlock>().toList(growable: false);

  /// JSON form for persistence / debugging.
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content.map((b) => b.toJson()).toList(),
  };
}
