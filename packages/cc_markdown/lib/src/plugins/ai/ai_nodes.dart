import 'package:cc_markdown/src/ast/nodes.dart';

/// AI reasoning content (`<thinking>…</thinking>` / `<think>…</think>`).
final class CcThinkingNode extends CcCustomBlock {
  /// Creates a [CcThinkingNode].
  const CcThinkingNode({required this.content, this.isCollapsed = true});

  /// The raw reasoning text (markdown, rendered by the registered builder).
  final String content;

  /// Whether the block should render collapsed by default.
  final bool isCollapsed;

  @override
  String get nodeType => 'thinking';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcThinkingNode &&
          content == other.content &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode => Object.hash(nodeType, content, isCollapsed);
}

/// An AI artifact block (an `artifact`-tagged region with attributes).
final class CcArtifactNode extends CcCustomBlock {
  /// Creates a [CcArtifactNode].
  const CcArtifactNode({
    required this.identifier,
    required this.artifactType,
    required this.content,
    this.title,
    this.language,
  });

  /// The artifact's unique identifier.
  final String identifier;

  /// The artifact type (e.g. `code`, `document`).
  final String artifactType;

  /// The artifact body.
  final String content;

  /// Optional display title.
  final String? title;

  /// Optional code language.
  final String? language;

  @override
  String get nodeType => 'artifact';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcArtifactNode &&
          identifier == other.identifier &&
          artifactType == other.artifactType &&
          content == other.content &&
          title == other.title &&
          language == other.language;

  @override
  int get hashCode =>
      Object.hash(nodeType, identifier, artifactType, content, title, language);
}

/// An AI tool invocation block (`<tool_call name="…">…</tool_call>`).
final class CcToolCallNode extends CcCustomBlock {
  /// Creates a [CcToolCallNode].
  const CcToolCallNode({
    required this.toolName,
    this.toolId,
    this.arguments,
    this.result,
    this.errorMessage,
  });

  /// The invoked tool's name.
  final String toolName;

  /// Optional call id.
  final String? toolId;

  /// Raw argument text (usually JSON).
  final String? arguments;

  /// Raw result text.
  final String? result;

  /// Error text when the call failed.
  final String? errorMessage;

  @override
  String get nodeType => 'tool_call';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcToolCallNode &&
          toolName == other.toolName &&
          toolId == other.toolId &&
          arguments == other.arguments &&
          result == other.result &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(nodeType, toolName, toolId, arguments, result, errorMessage);
}
