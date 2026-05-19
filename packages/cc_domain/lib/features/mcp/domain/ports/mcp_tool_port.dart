import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_harness/tools.dart';

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
  const CallResultContent({
    required this.type,
    required this.text,
    this.data,
    this.mimeType,
  });

  /// Creates an image content piece carrying base64 [data] of [mimeType]
  /// (MCP's `{type: 'image', data, mimeType}` shape).
  ///
  /// [text] stays empty: a text-only consumer joins the text pieces and must
  /// not end up with a megabyte of base64 spliced into the transcript.
  factory CallResultContent.image({
    required String data,
    required String mimeType,
  }) => CallResultContent(
    type: 'image',
    text: '',
    data: data,
    mimeType: mimeType,
  );

  /// MIME-like content type (e.g. 'text', 'image').
  final String type;

  /// Raw content payload. Empty for image pieces.
  final String text;

  /// Base64 payload for an image piece; null for text.
  final String? data;

  /// MIME type for an image piece (e.g. `image/png`); null for text.
  final String? mimeType;

  /// Whether this piece carries a usable image payload.
  bool get isImage => type == 'image' && (data?.isNotEmpty ?? false);

  /// To json.
  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    if (data != null) 'data': data,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

/// Call result.
class CallResult {
  /// Creates a successful result containing the given [text].
  factory CallResult.success(String text) => CallResult(
    content: [CallResultContent(type: 'text', text: text)],
  );

  /// Creates a successful result pairing [text] with one or more images
  /// (base64 `data` keyed by its MIME type, in order).
  factory CallResult.withImages(
    String text,
    List<({String data, String mimeType})> images,
  ) => CallResult(
    content: [
      CallResultContent(type: 'text', text: text),
      for (final image in images)
        CallResultContent.image(data: image.data, mimeType: image.mimeType),
    ],
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
  /// The ONE phrasing for a missing/invalid required argument.
  ///
  /// Agents pattern-match error text to self-correct, so four spellings of one
  /// failure is four things a model has to have learned. This surface had
  /// exactly that for `workspace_id` alone: `Missing or invalid argument:
  /// workspace_id` (83), `Missing workspace_id` (15), the same with
  /// ` (expected string)` appended (11), and one with a trailing period (3).
  /// Compose new messages from [missingArgument] so the next tool cannot
  /// invent a fifth.
  static String missingArgument(String name) =>
      'Missing or invalid argument: $name';

  /// Reads a required string argument, or the canonical error for it.
  ///
  /// Returns `(value, null)` on success and `(null, error)` otherwise, so a
  /// call site reads:
  ///
  /// ```dart
  /// final (workspaceId, err) = McpTool.requireString(args, 'workspace_id');
  /// if (err != null) return err;
  /// ```
  ///
  /// An empty string counts as missing: every one of these arguments is an id
  /// or a name, and `''` is never a valid one — accepting it only moves the
  /// failure somewhere less legible.
  static (String?, CallResult?) requireString(
    Map<String, dynamic> args,
    String name,
  ) {
    final value = args[name];
    if (value is! String || value.isEmpty) {
      return (null, CallResult.error(missingArgument(name)));
    }
    return (value, null);
  }

  /// Reads a caller-supplied `limit`, clamped to `1..max`.
  ///
  /// Every list tool read `arguments['limit']` verbatim, so a model (or
  /// anything speaking MCP) could ask for a million rows and get them —
  /// through the context window on one side and the phone's WebSocket on the
  /// other. Clamping rather than rejecting is deliberate: an over-large limit
  /// is an optimistic guess, not an attack, and the honest answer to it is the
  /// first [max] rows.
  ///
  /// A non-numeric or absent value falls back to [fallback]; zero and
  /// negatives clamp up to 1, because "give me nothing" is never what a caller
  /// means and an empty result reads as "there is nothing there".
  static int clampLimit(
    Map<String, dynamic> args,
    int fallback, {
    int max = 500,
  }) {
    final raw = args['limit'];
    final value = raw is num ? raw.toInt() : fallback;
    if (value < 1) {
      return 1;
    }
    return value > max ? max : value;
  }

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

  /// The unified-guardrail effect classes this tool can produce (PRD 24 §1).
  /// Every MCP tool DECLARES its worst-case classes; a ratchet test holds the
  /// line. Default is empty (a pure read/query tool); mutating tools (PR
  /// create/publish, ticket sync writes, skill install, file writes) override.
  Set<ActionClass> get actionClasses => const {};

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
