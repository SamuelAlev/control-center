/// Unified conversation message types for the built-in agent loop (harness).
///
/// These types are pure Dart — no `dart:io`, `rhttp`, `drift`, or `flutter`
/// dependencies — so the agent loop can be unit-tested without HTTP or a
/// filesystem. The format is provider-agnostic: a [HarnessMessage] converts
/// cleanly to both the Anthropic Messages API and the OpenAI Chat Completions
/// API at the provider boundary.
library;

import 'dart:convert';

import 'package:cc_harness/src/context/tool_output_reference.dart';

/// Who authored a [HarnessMessage].
enum HarnessRole {
  /// System / developer instructions. On the Anthropic wire the system prompt
  /// is a separate request field, not a message; on the OpenAI wire it is a
  /// `system`-role message. The provider handles the difference.
  system,

  /// A human (or upstream caller) turn.
  user,

  /// A model turn — may interleave text, thinking and tool-use blocks.
  assistant,

  /// A tool result fed back to the model. Maps to a `user`-role content block
  /// on the Anthropic wire and a `tool`-role message on the OpenAI wire.
  tool,
}

/// A single content block inside a [HarnessMessage].
///
/// A message is a list of blocks because an assistant turn can interleave
/// streamed text, extended-thinking and one or more tool-use requests.
sealed class HarnessContentBlock {
  /// Const base constructor.
  const HarnessContentBlock();

  /// Rebuilds a block from [toJson]'s output.
  ///
  /// The model had a serializer and no parser, so a persisted history was
  /// write-only: every host that stored one had to hand-roll the read back,
  /// and each hand-rolled reader is a place the `type` discriminator can drift
  /// from this file. An unknown `type` degrades to a text block carrying the
  /// raw JSON rather than throwing — a history that cannot be fully understood
  /// is still worth more than one that cannot be loaded.
  factory HarnessContentBlock.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'text':
        return HarnessTextBlock(json['text'] as String? ?? '');
      case 'tool_use':
        return HarnessToolUseBlock(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? '',
          input: (json['input'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      case 'tool_result':
        final rawReference = json['output_reference'];
        return HarnessToolResultBlock(
          toolUseId: json['tool_use_id'] as String? ?? '',
          content: json['content'] as String? ?? '',
          isError: json['is_error'] == true,
          images: [
            for (final raw in (json['images'] as List?) ?? const [])
              if (raw is Map)
                HarnessImageBlock(
                  data: raw['data'] as String? ?? '',
                  mediaType: raw['media_type'] as String? ?? '',
                ),
          ],
          // Absent/null/non-map all mean "no handle": a transcript written
          // before references existed must still load.
          outputReference: rawReference is Map
              ? ToolOutputReference.fromJson(
                  rawReference.cast<String, dynamic>(),
                )
              : null,
          toolReferences: [
            for (final raw in (json['tool_references'] as List?) ?? const [])
              if (raw is String) raw,
          ],
        );
      case 'image':
        return HarnessImageBlock(
          data: json['data'] as String? ?? '',
          mediaType: json['media_type'] as String? ?? '',
        );
      case 'thinking':
        return HarnessThinkingBlock(
          json['thinking'] as String? ?? '',
          signature: json['signature'] as String?,
        );
      default:
        return HarnessTextBlock(jsonEncode(json));
    }
  }

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

  /// [input] as a JSON string, computed once per block.
  ///
  /// The OpenAI wire needs `function.arguments` as a string and the token
  /// estimator needs the same serialization; without the memo both re-encode
  /// every accumulated argument map on every turn.
  String get encodedInput => _encodedInputMemo[this] ??= jsonEncode(input);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_use',
    'id': id,
    'name': name,
    'input': input,
  };

  /// Value equality INCLUDING the arguments.
  ///
  /// It used to compare `id` + `name` only, so two calls to the same tool with
  /// different arguments were equal — which is exactly backwards for anything
  /// built on it: a dedupe would collapse two distinct calls, and a diff of a
  /// rewritten history would report no change when the arguments were the only
  /// thing that changed. [encodedInput] is the memoized serialization, so this
  /// costs one string compare rather than a deep map walk.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessToolUseBlock &&
          other.id == id &&
          other.name == name &&
          other.encodedInput == encodedInput;

  @override
  int get hashCode => Object.hash(id, name, encodedInput);
}

/// A tool result fed back to the model.
class HarnessToolResultBlock extends HarnessContentBlock {
  /// Creates a tool-result block.
  const HarnessToolResultBlock({
    required this.toolUseId,
    required this.content,
    this.isError = false,
    this.images = const [],
    this.outputReference,
    this.toolReferences = const [],
  });

  /// The [HarnessToolUseBlock.id] this result answers.
  final String toolUseId;

  /// The result text shown to the model.
  final String content;

  /// Whether the tool failed (the model is told the call errored).
  final bool isError;

  /// Images the tool returned alongside [content] (screenshots from an
  /// enclosure, rendered output, visual diffs).
  ///
  /// Empty for the overwhelming majority of tools. Providers that accept
  /// images in a tool result emit them inline; providers that cannot must
  /// relay them some other way rather than dropping them silently (the OpenAI
  /// Chat Completions wire has no image slot in a `tool` message, so its
  /// provider follows the result with a `user` turn carrying the images).
  final List<HarnessImageBlock> images;

  /// A durable handle to the tool's ORIGINAL output, when it was stored.
  ///
  /// Set when [content] is a bounded/compacted copy of something bigger and the
  /// full text is still retrievable. This never travels on the provider wire —
  /// the marker already inside [content] names the handle to the model, and an
  /// unknown field would be rejected — so this exists for the transcript, the
  /// compactor's accounting and the retrieval tool.
  final ToolOutputReference? outputReference;

  /// Names of tools this result ACTIVATED (Anthropic `tool_reference` blocks).
  ///
  /// A client-side tool search returns references instead of schemas so the
  /// provider can expand them in place without rewriting the cached tools
  /// prefix. Providers without a native reference mechanism render these as a
  /// plain-text note (see [portableContent]) rather than failing or dropping
  /// the activation, which would leave the model told about a tool it cannot
  /// then find.
  final List<String> toolReferences;

  /// Returns a copy with selected fields overridden.
  ///
  /// [outputReference] and [toolReferences] are replaced when supplied — a
  /// null [outputReference] cannot be expressed as "clear it" (use the
  /// constructor for that), which matches every current caller: a store writes
  /// a handle onto a block that had none.
  HarnessToolResultBlock copyWith({
    String? content,
    bool? isError,
    List<HarnessImageBlock>? images,
    ToolOutputReference? outputReference,
    List<String>? toolReferences,
  }) => HarnessToolResultBlock(
    toolUseId: toolUseId,
    content: content ?? this.content,
    isError: isError ?? this.isError,
    images: images ?? this.images,
    outputReference: outputReference ?? this.outputReference,
    toolReferences: toolReferences ?? this.toolReferences,
  );

  /// [content] plus, when tools were activated, a plain-text note naming them.
  ///
  /// The portable form used by providers whose wire has no `tool_reference`
  /// block (and by the OpenAI-compatible family generally): the model must
  /// still learn that new tools became callable, and a `tool`/`function` message
  /// carries text and nothing else.
  String get portableContent {
    if (toolReferences.isEmpty) {
      return content;
    }
    final names = toolReferences.join(', ');
    return content.isEmpty
        ? 'Activated tools: $names.'
        : '$content\n\nActivated tools: $names.';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_result',
    'tool_use_id': toolUseId,
    'content': content,
    'is_error': isError,
    if (images.isNotEmpty) 'images': [for (final i in images) i.toJson()],
    if (outputReference != null) 'output_reference': outputReference!.toJson(),
    if (toolReferences.isNotEmpty) 'tool_references': toolReferences,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarnessToolResultBlock &&
          other.toolUseId == toolUseId &&
          other.content == content &&
          other.isError == isError &&
          other.outputReference == outputReference &&
          _sameStrings(other.toolReferences, toolReferences) &&
          _sameImages(other.images, images);

  @override
  int get hashCode => Object.hash(
    toolUseId,
    content,
    isError,
    outputReference,
    Object.hashAll(toolReferences),
    Object.hashAll(images),
  );

  static bool _sameStrings(List<String> a, List<String> b) {
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

  static bool _sameImages(
    List<HarnessImageBlock> a,
    List<HarnessImageBlock> b,
  ) {
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

/// Derived-value memos for [HarnessMessage], kept off the type so a message
/// folded away by compaction is still collected normally.
final Expando<String> _textContentMemo = Expando<String>('harnessTextContent');
final Expando<List<HarnessToolUseBlock>> _toolUsesMemo =
    Expando<List<HarnessToolUseBlock>>('harnessToolUses');

/// The normalized (sorted) activation metadata of a [HarnessMessage], memoized
/// so equality and hashing do not re-sort on every comparison.
final Expando<List<String>> _activatedNamesMemo = Expando<List<String>>(
  'harnessActivatedToolNames',
);

/// The serialized `input` of a [HarnessToolUseBlock], memoized: the providers
/// re-`jsonEncode` every accumulated tool-call argument map on every turn,
/// which is O(n²) over a run.
final Expando<String> _encodedInputMemo = Expando<String>(
  'harnessToolUseInput',
);

/// One message in the conversation history.
class HarnessMessage {
  /// Creates a message from an explicit block list.
  const HarnessMessage({
    required this.role,
    required this.content,
    this.activatedToolNames = const [],
    this.isSnapshotCarrier = false,
  });

  /// Convenience: a single-text user turn.
  factory HarnessMessage.user(
    String text, {
    List<String> activatedToolNames = const [],
  }) => HarnessMessage(
    role: HarnessRole.user,
    content: [HarnessTextBlock(text)],
    activatedToolNames: activatedToolNames,
  );

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
  ///
  /// [activatedToolNames] records the deferred tools this turn activated —
  /// see [activatedToolNames] for why the activation cannot live only in the
  /// result blocks.
  factory HarnessMessage.toolResults(
    List<HarnessToolResultBlock> results, {
    List<String> activatedToolNames = const [],
  }) => HarnessMessage(
    role: HarnessRole.tool,
    content: results,
    activatedToolNames: activatedToolNames,
  );

  /// Rebuilds a message from [toJson]'s output.
  ///
  /// An unrecognised role falls back to `user`: an unreadable role is a
  /// corrupt record, and dropping the turn silently would leave a history with
  /// a hole in it that reads as a model that never answered.
  factory HarnessMessage.fromJson(Map<String, dynamic> json) => HarnessMessage(
    role: HarnessRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => HarnessRole.user,
    ),
    content: [
      for (final raw in (json['content'] as List?) ?? const [])
        if (raw is Map)
          HarnessContentBlock.fromJson(raw.cast<String, dynamic>()),
    ],
    // Tolerant: an older transcript has no such key, and a non-string entry is
    // ignored rather than failing the whole history load.
    activatedToolNames: [
      for (final raw in (json['activated_tool_names'] as List?) ?? const [])
        if (raw is String) raw,
    ],
    isSnapshotCarrier: json['snapshot_carrier'] == true,
  );

  /// Author of the message.
  final HarnessRole role;

  /// Ordered content blocks (1+).
  final List<HarnessContentBlock> content;

  /// Deferred-tool names this message's turn made callable, as machine-read able
  /// metadata rather than prose.
  ///
  /// **Why this is not derived from the content.** A native activation is
  /// carried by a `tool_reference` inside the search tool's result, and a text
  /// or snapshot FOLD replaces that whole result with a summary — so the
  /// reference, the only thing the provider can expand into a schema, is gone.
  /// The tool then stays nominally active while no request can obtain its
  /// definition, and a restart from the compacted transcript cannot recover it
  /// at all. Persisting the names on the message that activated them lets a
  /// fold carry them forward as a union and lets the loop re-admit a real,
  /// callable definition for a name whose reference was folded away.
  ///
  /// Internal metadata: it is persisted with the message but never serialized
  /// to a provider wire (each provider builds its own request JSON).
  final List<String> activatedToolNames;

  /// Whether this message IS the snapshot page whose text the persisted
  /// `HarnessTranscript.retainedSnapshotSource` describes.
  ///
  /// **Why an explicit identity.** The source must be cleared when the page it
  /// describes leaves the history, and cleared only then. Counting images is
  /// not the same question: a rewind can drop the page while keeping an
  /// unrelated screenshot, and an image count then says "a carrier survived"
  /// while the source is stale — so a later refusal rehydrates text the rewind
  /// explicitly discarded. Which message is the page is a fact only the
  /// producer knows, so the producer stamps it here and the kernel keys on the
  /// stamp.
  ///
  /// Internal metadata: persisted with the message, never sent to a provider,
  /// and set ONLY by the snapshot compactor that renders the page (a
  /// rehydration builds a plain text message and therefore drops the marker,
  /// which is what tells the kernel the page is gone).
  final bool isSnapshotCarrier;

  /// [activatedToolNames] in a stable order, memoized.
  ///
  /// Activation is a set semantically — the same tools activated in a different
  /// order are the same activation — so equality and hashing compare this
  /// normalized form, and it is computed once per message rather than on every
  /// comparison.
  List<String> get normalizedActivatedToolNames {
    final cached = _activatedNamesMemo[this];
    if (cached != null) {
      return cached;
    }
    final value = activatedToolNames.length < 2
        ? activatedToolNames
        : ([...activatedToolNames]..sort());
    _activatedNamesMemo[this] = value;
    return value;
  }

  /// All text blocks concatenated.
  ///
  /// Memoized: every provider re-reads this for EVERY message on every turn
  /// when building the request, so the `whereType…map…join` chain would run
  /// n times per turn over an n-message history. Messages are immutable once
  /// constructed, so the memo can never go stale.
  String get textContent {
    final cached = _textContentMemo[this];
    if (cached != null) {
      return cached;
    }
    final String value;
    if (content.length == 1) {
      final only = content[0];
      value = only is HarnessTextBlock ? only.text : '';
    } else {
      value = content
          .whereType<HarnessTextBlock>()
          .map((b) => b.text)
          .join('\n');
    }
    _textContentMemo[this] = value;
    return value;
  }

  /// Whether this message contains any tool-use requests.
  bool get hasToolUse => content.any((b) => b is HarnessToolUseBlock);

  /// All tool-use blocks in order. Memoized for the same reason as
  /// [textContent] — the providers walk it per message per turn.
  List<HarnessToolUseBlock> get toolUses {
    final cached = _toolUsesMemo[this];
    if (cached != null) {
      return cached;
    }
    final value = content.whereType<HarnessToolUseBlock>().toList(
      growable: false,
    );
    _toolUsesMemo[this] = value;
    return value;
  }

  /// Returns a copy with selected fields overridden.
  ///
  /// [activatedToolNames] replaces the metadata when supplied, which is how a
  /// fold hands the union of a whole folded span to its single replacement
  /// message — without fabricating the assistant tool calls and results the
  /// span contained.
  HarnessMessage copyWith({
    HarnessRole? role,
    List<HarnessContentBlock>? content,
    List<String>? activatedToolNames,
    bool? isSnapshotCarrier,
  }) => HarnessMessage(
    role: role ?? this.role,
    content: content ?? this.content,
    activatedToolNames: activatedToolNames ?? this.activatedToolNames,
    isSnapshotCarrier: isSnapshotCarrier ?? this.isSnapshotCarrier,
  );

  /// JSON form for persistence / debugging.
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content.map((b) => b.toJson()).toList(),
    if (activatedToolNames.isNotEmpty)
      'activated_tool_names': activatedToolNames,
    if (isSnapshotCarrier) 'snapshot_carrier': true,
  };

  /// Value equality over the role, every block in order, and the activation
  /// metadata as a set.
  ///
  /// The blocks all defined `==`; the message did not, so two identical turns
  /// compared unequal and anything keyed on a message (a dedupe, a
  /// "did compaction change this?" diff, a test expectation) had to compare
  /// `toJson()` strings instead. The activation metadata is part of that
  /// identity: two histories whose messages differ only in which tools they
  /// activated are NOT the same history, and a diff that ignored it would
  /// report "no change" for a fold that silently dropped an activation.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! HarnessMessage ||
        other.role != role ||
        other.content.length != content.length ||
        other.isSnapshotCarrier != isSnapshotCarrier) {
      return false;
    }
    final mine = normalizedActivatedToolNames;
    final theirs = other.normalizedActivatedToolNames;
    if (mine.length != theirs.length) {
      return false;
    }
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] != theirs[i]) {
        return false;
      }
    }
    for (var i = 0; i < content.length; i++) {
      if (other.content[i] != content[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    role,
    Object.hashAll(content),
    Object.hashAll(normalizedActivatedToolNames),
    isSnapshotCarrier,
  );
}
