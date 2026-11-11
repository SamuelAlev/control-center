part of 'dispatch_session.dart';

/// The run log row's writes over a run: PID and start, the running mark, the
/// NDJSON path, what the run was composed of, and the terminal error.
extension _DispatchSessionRunLog on DispatchSession {
  void _updateRunLogPidAndStart(int forkedPid) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        final updated = await repo.updateRuntime(
          ws,
          id,
          pid: forkedPid,
          markRunning: true,
        );
        if (!updated) {
          _failRun('Run log $id missing when PID $forkedPid arrived');
        }
      } on Object catch (e, st) {
        CcInfraLog.error(
          'DispatchSession: Failed to persist PID $forkedPid for $id',
          e,
          st,
        );
        _failRun('Failed to persist PID: $e');
      }
    }());
  }

  /// Flips this run's row from `pending` to `running` as the harness loop starts.
  ///
  /// The PID-bearing transports get this from [_updateRunLogPidAndStart], but the
  /// built-in harness spawns no process and so has no PID — which left its row
  /// `pending` for the entire run. Anything reading status to tell "queued" apart
  /// from "working" (the sidebar's status dot, `deriveAgentLiveState` on the
  /// roster) therefore reported a busy agent as queued/idle until it finished.
  void _markRunStarted() {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        await repo.updateRuntime(ws, id, markRunning: true);
      } on Object catch (e, st) {
        // Best-effort: a lost transition only mislabels the dot, so it must not
        // fail the run the way a lost PID does.
        CcInfraLog.warning(
          'DispatchSession: Failed to mark run $id running: $e\n$st',
        );
      }
    }());
  }

  void _updateRunLogPath(String path) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    unawaited(() async {
      try {
        if (!await repo.updateRuntime(ws, id, logPath: path)) {
          _failRun('Run log $id missing when log path arrived');
        }
      } on Object catch (e, st) {
        CcInfraLog.error(
          'DispatchSession: Failed to persist log path $path for $id',
          e,
          st,
        );
        _failRun('Failed to persist log path: $e');
      }
    }());
  }

  /// Records what this run was actually composed of: the tool names handed to
  /// the loop, the mode profile, the model and the size of the assembled system
  /// prompt.
  ///
  /// This is the answer to "why did the agent not call the tool it was told to
  /// call?" — a question that previously required reading the SQLite file and
  /// replaying requests against the provider by hand, because the one column
  /// meant to hold it was never written. The tool list is the single most
  /// valuable field: nearly every mode-behavior bug reduces to a surface that
  /// did not contain what the prompt promised.
  ///
  /// The prompt is stored by length and digest, not verbatim — it can carry
  /// repo contents and memory facts and a run log is not the place for a copy
  /// of them. The digest is still enough to tell two runs apart.
  void _recordRunComposition({
    required List<String> toolNames,
    required String mode,
    required String model,
    required String adapter,
    required String systemPrompt,
    List<String> deferredToolNames = const [],
    int toolSchemaTokens = 0,
    String? effort,
  }) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to write.
    final ws = workspaceId;
    if (id == null || repo == null || ws == null || ws.isEmpty) {
      return;
    }
    final snapshot = jsonEncode({
      'mode': mode,
      'model': model,
      'adapter': adapter,
      'effort': effort ?? 'default',
      'toolCount': toolNames.length,
      'tools': toolNames,
      'deferredToolCount': deferredToolNames.length,
      'deferredTools': deferredToolNames,
      'toolSchemaTokens': toolSchemaTokens,
      'systemPromptChars': systemPrompt.length,
      'systemPromptSha256': sha256
          .convert(utf8.encode(systemPrompt))
          .toString(),
    });
    unawaited(() async {
      try {
        await repo.updateRuntime(
          ws,
          id,
          contextSnapshotJson: snapshot,
          modelId: model,
          effort: effort ?? 'default',
          taskFamily: mode,
        );
      } on Object catch (e, st) {
        // Diagnostics must never take the run down with them.
        CcInfraLog.error(
          'DispatchSession: Failed to persist run composition for $id',
          e,
          st,
        );
      }
    }());
  }

  /// Ends the run in error with [message], and [code] when the failure has
  /// one (a refusal's `AppException.code`, e.g. `sandbox_unavailable`): the
  /// run log row's `summary`/`errorCode` and the transcript's `ErrorEvent`
  /// carry the same pair, so a client can key its notice on the code.
  void _failRun(String message, {String? code}) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    // The run log lives in this session's workspace; without one there is no
    // row (the repository refuses a workspace-less run log) to stamp — the
    // error event below is still emitted.
    final ws = workspaceId;
    if (id != null && repo != null && ws != null && ws.isNotEmpty) {
      unawaited(() async {
        try {
          final existing = await repo.getById(ws, id);
          if (existing != null && existing.completedAt == null) {
            await repo.completeIfActive(
              existing.copyWith(
                status: RunStatus.error,
                summary: message,
                errorCode: code,
                completedAt: DateTime.now(),
              ),
              writeCost: false,
            );
          }
        } on Object catch (e, st) {
          CcInfraLog.error(
            'DispatchSession: Failed to mark run log $id as error',
            e,
            st,
          );
        }
      }());
    }
    addEvent(ErrorEvent(content: message, code: code));
  }
}
