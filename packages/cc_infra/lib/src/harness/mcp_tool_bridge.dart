import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_harness/tools.dart';

/// Media types a tool result's image piece may declare.
///
/// An ALLOW-list, not a sanity check: this string is copied verbatim into the
/// provider request, so anything outside what every provider actually decodes
/// is either a 400 the model cannot act on or — for `image/svg+xml` — an XML
/// document being presented to a model as a picture. Matches the raster
/// formats Anthropic and the OpenAI-compatible providers both accept.
const Set<String> kBridgeableImageMediaTypes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
};

/// The largest base64 payload one bridged image may carry (~5 MB, the
/// providers' own per-image ceiling).
///
/// Token accounting charges a FLAT ~1200 tokens per image, so size is invisible
/// to every budget in the loop: without this, one misbehaving tool can put an
/// arbitrarily large blob on the wire and nothing in the harness notices until
/// the provider rejects the whole request.
const int kMaxBridgedImageBase64Chars = 5 * 1024 * 1024;

/// Adapts a Control Center [McpTool] into a [HarnessTool] so the built-in agent
/// loop can call CC's orchestration tools (orchestration, recall_facts,
/// create_ticket, send_message, list_prs, …) natively, alongside the built-in
/// filesystem tools.
///
/// Workspace scoping: when the tool's schema declares `workspace_id`,
/// `agent_id`, or `conversation_id` and the model omitted it, the bridge injects
/// the value from the [HarnessToolContext], so the loop never escapes its
/// workspace and the model is not burdened with repeating ids it already
/// operates under (e.g. `todo_write` gets its conversation for free).
///
/// Because those arguments are injected, they are also HIDDEN from the schema
/// the model sees ([hiddenScopeParams]) — advertising a parameter whose value
/// the bridge overrides anyway costs context on every request and invites the
/// model to guess an id it must not choose. The MCP tool's own schema is
/// untouched: external MCP clients still see the full contract, and
/// [_withScope] still reads the ORIGINAL schema to decide what to inject.
class McpToolBridge extends HarnessTool {
  /// Creates an [McpToolBridge] wrapping [mcpTool].
  ///
  /// [hiddenScopeParams] names the context-injected arguments to strip from the
  /// model-facing schema. The caller passes only the ones the run's context can
  /// actually supply — hiding a parameter nothing fills would leave the tool
  /// unable to receive it at all.
  McpToolBridge(this.mcpTool, {this.hiddenScopeParams = const {}});

  /// The wrapped Control Center MCP tool.
  final McpTool mcpTool;

  /// Context-injected argument names hidden from the model-facing schema.
  final Set<String> hiddenScopeParams;

  Map<String, dynamic>? _cachedSchema;

  @override
  String get name => mcpTool.name;

  @override
  String get description => mcpTool.description;

  @override
  Map<String, dynamic> get inputSchema =>
      _cachedSchema ??= _hideScopeParams(mcpTool.inputSchema);

  /// Returns [schema] without the [hiddenScopeParams] the run injects itself.
  ///
  /// Key order is preserved throughout: the tools array is the head of the
  /// provider's prompt-cache prefix, so a schema that serializes differently
  /// between two runs of the same registry would cost a full cache write.
  Map<String, dynamic> _hideScopeParams(Map<String, dynamic> schema) {
    if (hiddenScopeParams.isEmpty) {
      return schema;
    }
    final props = schema['properties'];
    if (props is! Map<String, dynamic>) {
      return schema;
    }
    final hidden = hiddenScopeParams.where(props.containsKey).toSet();
    if (hidden.isEmpty) {
      return schema;
    }
    final out = Map<String, dynamic>.from(schema);
    out['properties'] = {
      for (final e in props.entries)
        if (!hidden.contains(e.key)) e.key: e.value,
    };
    final required = schema['required'];
    if (required is List) {
      out['required'] = [
        for (final r in required)
          if (!hidden.contains(r)) r,
      ];
    }
    return out;
  }

  @override
  ToolApprovalTier get approvalTier {
    // Use the args-independent default tier as the registry-time classification.
    return _mapTier(mcpTool.toolApproval(const {}).tier);
  }

  @override
  Set<ActionClass> get actionClasses => mcpTool.actionClasses;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final scoped = _withScope(args, context);
    final result = await mcpTool.call(scoped);
    final text = result.content
        .where((c) => c.text.isNotEmpty)
        .map((c) => c.text)
        .join('\n');
    // Image pieces (rig screenshots, rendered output) ride through to the
    // model instead of being dropped on the floor here. The loop applies the
    // per-tool image COUNT budget; size and media type are this bridge's to
    // check, because it is the ingress and nothing downstream looks again.
    final images = <HarnessImageBlock>[];
    final rejected = <String>[];
    for (final piece in result.content) {
      if (!piece.isImage) {
        continue;
      }
      final mediaType = (piece.mimeType ?? 'image/png').trim().toLowerCase();
      if (!kBridgeableImageMediaTypes.contains(mediaType)) {
        // The media type is copied VERBATIM into the provider request
        // (Anthropic's `source.media_type`, OpenAI's data URI). An arbitrary
        // string there is at best a 400 the model cannot act on; `image/svg+xml`
        // is an XML document, not a raster, and has no business being described
        // to a model as a screenshot.
        rejected.add('an image with unsupported media type "$mediaType"');
        continue;
      }
      final data = piece.data!;
      if (data.length > kMaxBridgedImageBase64Chars) {
        // Token accounting charges a FLAT ~1200 per image, so an oversized one
        // is invisible to every budget in the loop while being very real on
        // the wire.
        rejected.add(
          'an image of ${(data.length / (1024 * 1024)).toStringAsFixed(1)} MB '
          '(the limit is ${kMaxBridgedImageBase64Chars ~/ (1024 * 1024)} MB)',
        );
        continue;
      }
      images.add(HarnessImageBlock(data: data, mediaType: mediaType));
    }
    // Said out loud rather than dropped silently: a model that asked for a
    // screenshot and got none needs to know why, or it retries forever.
    final notice = rejected.isEmpty
        ? ''
        : '\n[${mcpTool.name} returned ${rejected.join('; ')}; '
              'not included.]';
    return HarnessToolResult(
      content: '$text$notice',
      isError: result.isError,
      images: images,
    );
  }

  Map<String, dynamic> _withScope(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    final props = mcpTool.inputSchema['properties'];
    if (props is! Map<String, dynamic>) {
      return args;
    }
    final scoped = Map<String, dynamic>.from(args);
    final wsId = context.workspaceId;
    // workspace_id is the isolation boundary: FORCE it to the run's workspace,
    // overriding any value the model supplied. A harness agent must never be
    // able to name a different workspace than the one it runs in (a
    // model-supplied foreign id would otherwise be an isolation escape).
    if (wsId != null && wsId.isNotEmpty && props.containsKey('workspace_id')) {
      scoped['workspace_id'] = wsId;
    }
    final agentId = context.agentId;
    if (agentId != null &&
        agentId.isNotEmpty &&
        props.containsKey('agent_id') &&
        (scoped['agent_id'] == null || scoped['agent_id'] == '')) {
      scoped['agent_id'] = agentId;
    }
    final convId = context.conversationId;
    if (convId != null &&
        convId.isNotEmpty &&
        props.containsKey('conversation_id') &&
        (scoped['conversation_id'] == null ||
            scoped['conversation_id'] == '')) {
      scoped['conversation_id'] = convId;
    }
    // space_id comes from the run's SPACE, never from its conversation id. A
    // conversation owns its own uuid, so filling a space-scoped argument from
    // it names no space: `todo_write`/`todo_read` failed their ownership check
    // on every call and the agent's task list never worked.
    final spaceId = context.spaceId;
    if (spaceId != null &&
        spaceId.isNotEmpty &&
        props.containsKey('space_id') &&
        (scoped['space_id'] == null || scoped['space_id'] == '')) {
      scoped['space_id'] = spaceId;
    }
    return scoped;
  }

  static ToolApprovalTier _mapTier(CapabilityTier tier) {
    switch (tier) {
      case CapabilityTier.read:
        return ToolApprovalTier.read;
      case CapabilityTier.write:
        return ToolApprovalTier.write;
      case CapabilityTier.exec:
        return ToolApprovalTier.exec;
    }
  }
}
