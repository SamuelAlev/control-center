/// Trusted identity scope for an MCP `tools/call`, derived from the transport
/// (dispatch-written `X-CC-*` headers on the loopback HTTP server), never from
/// model-supplied arguments.
///
/// Mirrors the built-in harness's `McpToolBridge` scoping semantics so the two
/// transports enforce the same invariant: `workspace_id` is the isolation
/// boundary and is FORCED to the scope's value when the tool schema declares
/// it; `agent_id` / `conversation_id` / `space_id` are conveniences injected
/// only when the caller omitted them.
class McpCallScope {
  /// Creates a call scope. Empty strings are treated as absent.
  const McpCallScope({
    this.workspaceId,
    this.agentId,
    this.conversationId,
    this.spaceId,
  });

  /// The workspace the calling agent runs in. When set, tools that declare a
  /// `workspace_id` argument have it overridden to this value.
  final String? workspaceId;

  /// The calling agent's id, injected into an empty `agent_id` argument.
  final String? agentId;

  /// The conversation (message stream) the agent's run belongs to, injected
  /// into an empty `conversation_id` argument.
  final String? conversationId;

  /// The space that conversation lives in, injected into an empty `space_id`
  /// argument.
  ///
  /// Carried separately from [conversationId] on purpose: a conversation owns
  /// its own uuid, so filling `space_id` from the conversation id — as this
  /// did while the two were aliased — names no space. Guardrail resolution
  /// keys on the space, so that made every `ActionScopeType.space` rule
  /// unmatchable for MCP tool calls.
  final String? spaceId;

  /// Whether any component is present.
  bool get isEmpty =>
      (workspaceId == null || workspaceId!.isEmpty) &&
      (agentId == null || agentId!.isEmpty) &&
      (conversationId == null || conversationId!.isEmpty) &&
      (spaceId == null || spaceId!.isEmpty);

  /// Applies this scope to [args] for a tool whose input schema is [schema].
  ///
  /// Returns a new map; [args] is not mutated. Only argument names the schema
  /// declares under `properties` are touched.
  Map<String, dynamic> apply(
    Map<String, dynamic> args,
    Map<String, dynamic> schema,
  ) {
    final props = schema['properties'];
    if (props is! Map<String, dynamic> || isEmpty) {
      return args;
    }
    final scoped = Map<String, dynamic>.from(args);
    final ws = workspaceId;
    // workspace_id is the isolation boundary: FORCE it, overriding any value
    // the model supplied. A dispatched agent must never be able to name a
    // different workspace than the one it runs in.
    if (ws != null && ws.isNotEmpty && props.containsKey('workspace_id')) {
      scoped['workspace_id'] = ws;
    }
    void fillIfEmpty(String key, String? value) {
      if (value == null || value.isEmpty || !props.containsKey(key)) {
        return;
      }
      final existing = scoped[key];
      if (existing == null || existing == '') {
        scoped[key] = value;
      }
    }

    fillIfEmpty('agent_id', agentId);
    fillIfEmpty('conversation_id', conversationId);
    fillIfEmpty('space_id', spaceId);
    return scoped;
  }
}
