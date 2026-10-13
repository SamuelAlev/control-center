import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
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

/// Adapts a CC [McpTool] into a [HarnessTool] for the built-in agent loop.
///
/// Applies the same trusted scope contract as the external MCP dispatcher.
/// Context-injected parameters can be hidden from the model schema through
/// [hiddenScopeParams]; [_withScope] uses the original schema.
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
    final scope = McpCallScope(
      workspaceId: context.workspaceId,
      agentId: context.agentId,
      conversationId: context.conversationId,
      spaceId: context.spaceId,
    );
    final missingScope = scope.firstMissing(mcpTool.requiredScopeKeys);
    if (missingScope != null) {
      return HarnessToolResult(
        content: '$name requires a session $missingScope.',
        isError: true,
      );
    }
    final scoped = _withScope(args, scope);
    final result = await mcpTool.call(
      scoped,
      abandoned: context.cancel?.whenCancelled,
    );
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
    McpCallScope scope,
  ) {
    final scoped = scope.apply(
      args,
      mcpTool.inputSchema,
      force: mcpTool.forcedScopeKeys,
    );
    final props = mcpTool.inputSchema['properties'];
    final agentId = scope.agentId;
    // Delegation identities always name the caller, not an arbitrary target.
    if (props is Map<String, dynamic> &&
        agentId != null &&
        agentId.isNotEmpty) {
      for (final callerId in const ['from_agent_id', 'delegated_by_agent_id']) {
        if (props.containsKey(callerId)) {
          scoped[callerId] = agentId;
        }
      }
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
