/// Trusted identity scope for an MCP `tools/call`, derived from the transport
/// (dispatch-written `X-CC-*` headers on the loopback HTTP server), never from
/// model-supplied arguments.
///
/// Mirrors the built-in harness's `McpToolBridge` scoping semantics so the two
/// transports enforce the same invariant: `workspace_id` is the isolation
/// boundary and is FORCED to the scope's value when the tool schema declares
/// it; other identity fields are filled when omitted unless the tool requires
/// or forces them as identifiers of the current run.
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

  /// The first required identity field absent from this trusted context.
  String? firstMissing(Iterable<String> keys) {
    for (final key in keys) {
      final value = switch (key) {
        'workspace_id' => workspaceId,
        'agent_id' => agentId,
        'conversation_id' => conversationId,
        'space_id' => spaceId,
        _ => null,
      };
      if (value == null || value.isEmpty) {
        return key;
      }
    }
    return null;
  }

  /// Applies this scope to [args] for a tool whose input schema is [schema].
  ///
  /// Returns a new map; [args] is not mutated. Only argument names the schema
  /// declares under `properties` are touched. Keys in [force] are overwritten
  /// with the scope's value, or removed when it has no trusted value. Tools
  /// opt in per argument when the argument names this run rather than a target.
  Map<String, dynamic> apply(
    Map<String, dynamic> args,
    Map<String, dynamic> schema, {
    Set<String> force = const {},
  }) {
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
      if (!props.containsKey(key)) {
        return;
      }
      if (value == null || value.isEmpty) {
        if (force.contains(key)) {
          scoped.remove(key);
        }
        return;
      }
      final existing = scoped[key];
      // Forced keys name this run, not a model-selected target.
      if (force.contains(key) || existing == null || existing == '') {
        scoped[key] = value;
      }
    }

    fillIfEmpty('agent_id', agentId);
    fillIfEmpty('conversation_id', conversationId);
    fillIfEmpty('space_id', spaceId);
    return scoped;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpCallScope &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          conversationId == other.conversationId &&
          spaceId == other.spaceId;

  @override
  int get hashCode =>
      Object.hash(workspaceId, agentId, conversationId, spaceId);
}
