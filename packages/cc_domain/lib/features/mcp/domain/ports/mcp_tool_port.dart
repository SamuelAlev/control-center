import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';

/// Tool def.
class ToolDef {
  /// Creates a new [ToolDef].
  const ToolDef({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Unique tool identifier.
  final String name;
  /// Human-readable description of what the tool does.
  final String description;
  /// JSON Schema describing the tool's expected input parameters.
  final Map<String, dynamic> inputSchema;

  /// To json.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };
}

/// Call result content.
class CallResultContent {
  /// Creates a new [CallResultContent].
  const CallResultContent({required this.type, required this.text});

  /// MIME-like content type (e.g. 'text').
  final String type;
  /// Raw content payload.
  final String text;

  /// To json.
  Map<String, dynamic> toJson() => {'type': type, 'text': text};
}

/// Call result.
class CallResult {
  /// Creates a successful result containing the given [text].
  factory CallResult.success(String text) => CallResult(
    content: [CallResultContent(type: 'text', text: text)],
  );

  /// Creates an error result containing the given error [text].
  factory CallResult.error(String text) => CallResult(
    content: [CallResultContent(type: 'text', text: text)],
    isError: true,
  );
  /// Creates a new [CallResult].
  const CallResult({required this.content, this.isError = false});

  /// Ordered list of content pieces returned by the tool.
  final List<CallResultContent> content;
  /// Whether this result represents an error.
  final bool isError;

  /// To json.
  Map<String, dynamic> toJson() => {
    'content': content.map((c) => c.toJson()).toList(),
    'isError': isError,
  };
}

/// Mcp tool.
abstract class McpTool {
  /// Name.
  String get name;
  /// Description.
  String get description;
  /// Input schema.
  Map<String, dynamic> get inputSchema;

  /// Whether this tool mutates user-visible or external state and should
  /// route through `ConfirmationPort.requestApproval` before running.
  ///
  /// Defaults to `false`. Override `true` on tools that publish, mutate
  /// org-wide state (agent hire/fire), or change external systems (tickets,
  /// GitHub PR state).
  bool get requiresApproval => false;

  /// Builds the confirmation payload surfaced to the user when
  /// [requiresApproval] is true. Return `null` to skip the confirmation
  /// for these specific [arguments] (e.g. internal-only channels). The
  /// dispatcher provides a fallback when this returns `null` despite
  /// [requiresApproval] being `true`.
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      null;

  /// The capability tier of this tool for the given [arguments].
  ///
  /// This is the per-args approval primitive (PRD 01 phase 1.5): the same tool
  /// can resolve to a different [CapabilityTier] depending on its arguments
  /// (e.g. a `gh` wrapper is `read` for `gh pr view` but `exec` for
  /// `gh pr merge`). The approval gate auto-approves any tier at or below the
  /// active `ApprovalMode` ceiling and prompts above it.
  ///
  /// The default preserves CC's historical behaviour: a tool that opts into
  /// [requiresApproval] is `write` (prompts under the default `always-ask`
  /// mode); everything else is `read` (never prompts). Tools with argument-
  /// dependent risk override this.
  ToolApproval toolApproval(Map<String, dynamic> arguments) =>
      requiresApproval ? ToolApproval.write : ToolApproval.read;

  /// Definition.
  ToolDef get definition =>
      ToolDef(name: name, description: description, inputSchema: inputSchema);

  /// Call.
  Future<CallResult> call(Map<String, dynamic> arguments) async {
    try {
      return await run(arguments);
    } catch (e) {
      return CallResult.error('$e');
    }
  }

  /// Run.
  Future<CallResult> run(Map<String, dynamic> arguments);
}

/// Lightweight, transport-agnostic confirmation payload returned by
/// [McpTool.buildConfirmationRequest]. The dispatcher wraps it in a
/// `ConfirmationRequest` once it knows the conversation id.
class ApprovalPayload {
  /// Creates an [ApprovalPayload].
  const ApprovalPayload({
    required this.title,
    required this.detail,
    this.isDestructive = false,
  });

  /// Short headline shown in the prompt.
  final String title;

  /// Longer explanation of what the agent is about to do.
  final String detail;

  /// When true, the UI styles the prompt as destructive.
  final bool isDestructive;
}

