/// A resource CC's MCP server advertises via `resources/list` (PRD 01 feature
/// 4): code-graph snapshots, PR state, skill docs, memory, etc.
class McpResourceDescriptor {
  /// Creates an [McpResourceDescriptor].
  const McpResourceDescriptor({
    required this.uri,
    required this.name,
    this.title,
    this.description,
    this.mimeType,
  });

  /// The resource URI (e.g. `cc://pr/123`, `cc://skill/architect`).
  final String uri;

  /// Stable resource name.
  final String name;

  /// Optional display title.
  final String? title;

  /// Optional description.
  final String? description;

  /// Optional MIME type of the contents.
  final String? mimeType;

  /// The `resources/list` entry shape.
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'name': name,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

/// The contents of a resource read via `resources/read`.
class McpResourceContents {
  /// Creates an [McpResourceContents].
  const McpResourceContents({
    required this.uri,
    required this.text,
    this.mimeType = 'text/plain',
  });

  /// The resource URI echoed back.
  final String uri;

  /// The textual contents.
  final String text;

  /// The MIME type.
  final String mimeType;

  /// The `resources/read` `contents[]` entry shape.
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'mimeType': mimeType,
    'text': text,
  };
}

/// Supplies resources to CC's MCP server. Optional — when no provider is wired,
/// the server omits the `resources` capability.
abstract interface class McpResourceProvider {
  /// Lists the available resources.
  Future<List<McpResourceDescriptor>> listResources();

  /// Reads a resource by [uri], or returns null when unknown.
  Future<McpResourceContents?> readResource(String uri);
}

/// A prompt CC's MCP server advertises via `prompts/list` (PRD 01 feature 4),
/// surfaced to agents/clients as a slash command. CC skills map naturally onto
/// these.
class McpPromptDescriptor {
  /// Creates an [McpPromptDescriptor].
  const McpPromptDescriptor({
    required this.name,
    this.title,
    this.description,
    this.arguments = const [],
  });

  /// The prompt name.
  final String name;

  /// Optional display title.
  final String? title;

  /// Optional description.
  final String? description;

  /// Declared arguments (`{name, description?, required?}`).
  final List<Map<String, dynamic>> arguments;

  /// The `prompts/list` entry shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (arguments.isNotEmpty) 'arguments': arguments,
  };
}

/// The result of `prompts/get` — the messages to seed a conversation with.
class McpPromptResult {
  /// Creates an [McpPromptResult].
  const McpPromptResult({this.description, required this.messages});

  /// Optional description.
  final String? description;

  /// The prompt messages (`{role, content: {type, text}}`).
  final List<Map<String, dynamic>> messages;

  /// The `prompts/get` result shape.
  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    'messages': messages,
  };
}

/// Supplies prompts to CC's MCP server. Optional — when no provider is wired,
/// the server omits the `prompts` capability.
abstract interface class McpPromptProvider {
  /// Lists the available prompts.
  Future<List<McpPromptDescriptor>> listPrompts();

  /// Renders a prompt by [name] with [arguments], or null when unknown.
  Future<McpPromptResult?> getPrompt(String name, Map<String, String> arguments);
}
