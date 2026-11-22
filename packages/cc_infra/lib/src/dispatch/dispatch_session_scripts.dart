part of 'dispatch_session.dart';

/// What a run's `repl` runs as: the identity its scripts are recorded under
/// and the past they read (`history`, `outputs`, `loadOutput`, `keep`),
/// both from the run itself, never from a script.
extension _DispatchSessionScripts on DispatchSession {
  /// Binds how this harness run calls its tools, from its materialized
  /// surface: a script-only tool from a script, a resident or deferred one
  /// directly (a deferred tool is callable by name). The texts that name a
  /// tool read it: a wake pushed into the run ([toolForms]) and the
  /// background command texts (`bash_output`, `bash_kill`). A run whose
  /// scripts are withdrawn later keeps these forms; its tools then answer a
  /// script call with the withdrawal notice.
  void _bindToolForms(
    List<HarnessTool> tools,
    List<HarnessTool> deferred,
    List<HarnessTool> scriptOnly,
  ) {
    final forms = toolFormsOver(
      callable: [for (final t in [...tools, ...deferred]) t.name],
      scriptOnly: [for (final t in scriptOnly) t.name],
    );
    _toolForms = forms;
    backgroundCommandsOf([
      ...tools,
      ...deferred,
      ...scriptOnly,
    ])?.bindCallForms(forms);
  }

  /// Drops what a read-only run stored under its own scopes
  /// ([RunPrivateOutputStore]) once its harness run has ended; nothing can
  /// name them after. Other runs store into the conversation's scope and
  /// keep it.
  Future<void> _retireOutputs() async {
    if (_outputs case final RunPrivateOutputStore own) {
      await own.retire();
    }
  }

  /// The identity of this run's own `repl` (a main run): its conversation's
  /// transcript and the outputs stored for its conversation and agent.
  ReplRunIdentity _replRun(String wsId, String runId) => ReplRunIdentity(
    workspaceId: wsId,
    runId: runId,
    readOnly: readOnly,
    past: deps.scriptPast?.forRun(
      workspaceId: wsId,
      conversationId: conversationId,
      spaceId: spaceId,
      store: _outputs,
      scope: _scriptOutputScope(wsId, agentId),
    ),
    conversationId: _DispatchSessionHarness._realId(conversationId),
    agentId: _DispatchSessionHarness._realId(agentId),
    spaceId: _DispatchSessionHarness._realId(spaceId),
  );

  /// The identity of subagent run [childRunId]'s `repl`.
  ///
  /// A subagent's scripts get no store. The store is keyed by the
  /// conversation and the agent, and a child runs as its parent's agent, so
  /// a child (which may be reading untrusted content) could otherwise
  /// overwrite what the parent's later scripts load(). The record still
  /// names the conversation, the agent and the child's own run. Its past is
  /// its own run's: its transcript, and the outputs [outputs] saw it store
  /// (the store scope is its parent's).
  ReplRunIdentity _subagentReplRun(
    String ws,
    String childRunId,
    String childAgentId,
    RunOutputLedger outputs,
  ) => ReplRunIdentity(
    workspaceId: ws,
    runId: childRunId,
    readOnly: readOnly,
    past: deps.scriptPast?.forSubagent(
      workspaceId: ws,
      runId: childRunId,
      conversationId: conversationId,
      spaceId: spaceId,
      store: _outputs,
      scope: _scriptOutputScope(ws, childAgentId),
      ledger: outputs,
    ),
    conversationId: _DispatchSessionHarness._realId(conversationId),
    agentId: _DispatchSessionHarness._realId(agentId),
    spaceId: _DispatchSessionHarness._realId(spaceId),
    storeEnabled: false,
  );

  /// The store scope `read_output` reads with for a tool context whose agent
  /// is [contextAgentId], as `_replOutputSink` writes under it.
  ToolOutputScope _scriptOutputScope(String ws, String? contextAgentId) =>
      ToolOutputScope(
        workspaceId: ws,
        conversationId: conversationId,
        agentId: contextAgentId,
      );
}
