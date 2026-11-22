part of 'dispatch_session.dart';

/// What the run's process starts with: its environment and the directories
/// its runner keeps state in; and the space's autonomy dial it reads.
extension _DispatchSessionEnvironment on DispatchSession {
  /// Builds the merged environment for a dispatch. Caller and adapter settings
  /// cannot replace the resolved attribution policy, the requesting human's
  /// identity or the gateway's routing. No forge token is in it: the run asks
  /// the gateway for one.
  Map<String, String> _mergedEnv({required Map<String, String> backendEnv}) {
    final merged = <String, String>{
      ...callerEnv,
      ...backendEnv,
      ...adapterEnvOverride,
      ...?wakeContext?.toEnvironment(
        runId: runLogId ?? '',
        agentId: agentId ?? '',
        workspaceId: workspaceId ?? '',
      ),
      // Which Claude Code account this run signs in as. It is the LAST word on
      // the config dir — an `adapterEnvOverride` naming a different one would
      // point the CLI somewhere the sandbox never made writable, which fails
      // as a mid-run token refresh error rather than as a visible mistake.
      if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
        'CLAUDE_CONFIG_DIR': claudeConfigDir!,
    };
    // Re-assert the identity keys LAST. The spread order above lets an
    // adapter's configured env win for its own keys (which is the point of
    // `adapterEnvOverride`), never for whose commits these are.
    merged.addAll(_run.identity.gitEnv);
    // Append gateway routing after adapter config. Shell preflight remains
    // necessary: explicit URLs or command-local Git config can avoid rewrites.
    final lease = _gatewayLease;
    if (lease != null) {
      merged.addAll(_leaseEnvironment(lease, merged));
    }
    return merged;
  }

  /// Directories the runner keeps its own state in, writable in every mode.
  ///
  /// Only the Claude Code config dir today. It is listed for EVERY transport,
  /// not just `claudeCli`: an ACP agent or a structured CLI may shell out to
  /// `claude`, and a run that can read the credential but not refresh it fails
  /// later and more confusingly than one that cannot read it at all.
  List<String> get _runnerStateDirs => {
    if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
      claudeConfigDir!,
    // EVERY pooled account, not just the active one: the sandbox profile is
    // generated once, before the spawn, and a failover re-run inside the same
    // session would otherwise land on a directory the profile never opened.
    for (final a in claudeAccounts)
      if (a.configDir.isNotEmpty) a.configDir,
  }.toList();

  /// The space's autonomy dial for this run, read per decision (an operator
  /// can turn it mid-run), or null when there is no space or no resolver.
  /// Never throws: a failed read keeps the default, fail-closed posture.
  Future<AutonomyLevel?> _resolveAutonomy() async {
    final resolve = deps.autonomyResolver;
    final ws = workspaceId;
    final space = spaceId;
    final agent = agentId;
    if (resolve == null ||
        ws == null ||
        ws.isEmpty ||
        space == null ||
        agent == null) {
      return null;
    }
    try {
      return AutonomyLevel.tryFromWire(await resolve(ws, space, agent));
    } on Object catch (e, st) {
      CcInfraLog.error('dispatch $dispatchId: autonomy lookup failed', e, st);
      return null;
    }
  }
}
