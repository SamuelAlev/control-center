import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart'
    show McpToolView;

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
    this.attested = false,
    this.personalMcp = false,
    this.runId,
    this.runLogId,
    this.readOnly = false,
  }) : assert(
         !personalMcp || attested,
         'only a run grant can hand out the owner\'s personal MCP servers',
       ),
       assert(!readOnly || attested, 'only a run grant names a read-only run');

  /// Header carrying a run's own secret to the MCP transport.
  static const String runGrantHeader = 'X-CC-Agent-Run';

  /// Whether these values came from the run's grant rather than from headers
  /// the caller wrote.
  ///
  /// The `X-CC-*` identity headers live in a `.mcp.json` the agent can read
  /// and the bearer token is server-wide, so a sandboxed process can send any
  /// values it likes. A per-run secret can only name its own run.
  final bool attested;

  /// Whether the run this scope proves may use the server owner's personal
  /// MCP servers: decided once per run, from whether the owner is accountable
  /// for it. Only an [attested] scope can say so.
  final bool personalMcp;

  /// The run this scope proves (its dispatch id), or null for a caller that
  /// is not an attested run. Only the agent run gateway sets it, from the
  /// run's grant.
  final String? runId;

  /// Whether the run this scope proves is read-only: every call is admitted
  /// only when `ReadOnlyRunProfile.admits` it, and `tools/list` shows only
  /// those tools. Only an [attested] scope sets it, from the run's grant.
  final bool readOnly;

  /// The run's `agent_run_logs` row, when it has one. What audit rows that
  /// cascade with the run (code executions) are keyed by; a run without a
  /// run-log row writes none.
  final String? runLogId;

  /// The external MCP layers this caller may see: an attested run gets its
  /// own workspace's servers, and the owner's when [personalMcp]; any other
  /// caller (the owner's token, a paired device) gets none.
  McpToolView get toolView => attested
      ? McpToolView(workspaceId: workspaceId, includePersonal: personalMcp)
      : McpToolView.shared;

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
  /// [callerIdentityKeys] are always forced.
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
    // The calling run's own conversation, for a tool that bounds what it
    // reads by whom the run acts for. Only an attested scope names it:
    // header-only values are whatever the caller chose to write.
    if (props.containsKey(callerConversationKey)) {
      final caller = conversationId;
      if (attested && caller != null && caller.isNotEmpty) {
        scoped[callerConversationKey] = caller;
      } else {
        scoped.remove(callerConversationKey);
      }
    }
    // Delegation identities name the CALLER on every tool that declares them,
    // never a model-chosen value: they drive sender attribution, the per-pair
    // rate limit, the cycle chain and the autonomy/budget lookups. With no
    // trusted caller the model's value is dropped, so the tool refuses for a
    // missing argument instead of acting as whoever the model named.
    for (final key in callerIdentityKeys) {
      if (!props.containsKey(key)) {
        continue;
      }
      final caller = agentId;
      if (caller == null || caller.isEmpty) {
        scoped.remove(key);
      } else {
        scoped[key] = caller;
      }
    }
    return scoped;
  }

  /// The argument that always names the calling run's conversation: FORCED
  /// to [conversationId] by [apply] when the scope is [attested], removed
  /// otherwise. Unlike `conversation_id` (a target most tools let the model
  /// choose), the model can never set it.
  static const String callerConversationKey = 'caller_conversation_id';

  /// Arguments that always name the calling agent and are therefore FORCED to
  /// [agentId] by [apply], whatever the tool's `forcedScopeKeys` say.
  ///
  /// A tool that names its caller under one of these keys gets the forcing,
  /// and the hiding from the model-facing schema wherever the run can supply
  /// the agent, by declaring the key; nothing else to opt into. A tool whose
  /// caller argument is called `agent_id` lists it in `forcedScopeKeys`
  /// instead (most tools use `agent_id` for a target). Every tool declaring
  /// one of these keys means "the agent calling": the sender of a message
  /// (`send_message`, `add_review_node`), the asker of a peer review, the
  /// reviewer recording a verdict.
  static const Set<String> callerIdentityKeys = {
    'from_agent_id',
    'delegated_by_agent_id',
    'sender_id',
    'requester_id',
    'reviewer_id',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpCallScope &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          conversationId == other.conversationId &&
          spaceId == other.spaceId &&
          attested == other.attested &&
          personalMcp == other.personalMcp &&
          runId == other.runId &&
          runLogId == other.runLogId;

  @override
  int get hashCode => Object.hash(
    workspaceId,
    agentId,
    conversationId,
    spaceId,
    attested,
    personalMcp,
    runId,
    runLogId,
  );
}
