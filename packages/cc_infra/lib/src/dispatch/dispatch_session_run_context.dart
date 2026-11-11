part of 'dispatch_session.dart';

/// What a dispatch resolves ONCE when its run starts and every transport then
/// reads: the sandbox's network posture, the policy-owned Git identity and
/// co-author credit, and what the run may use of its space's environment.
///
/// Immutable, and assigned once per run after all of it is resolved, so two
/// transports of one run (or a transport and the sandbox spec it runs under)
/// can never see different values — they used to be five mutable fields set
/// at three points of `run()`.
final class _RunContext {
  const _RunContext({
    required this.networkEnabled,
    required this.identity,
    required this.environment,
  });

  /// Before (or without) a run start: the network on, no Git identity and no
  /// environment, which is what each field defaulted to.
  static const beforeStart = _RunContext(
    networkEnabled: true,
    identity: _RunIdentity.none,
    environment: _RunEnvironmentAccess(),
  );

  /// Whether the run's sandbox gets a network, resolved from the "network
  /// egress" rule. A sandbox can only be on or off, so "ask first" leaves it
  /// on; the harness web tools still ask per call.
  final bool networkEnabled;

  /// Who the run's commits name, and its Git environment.
  final _RunIdentity identity;

  /// What this run may use of its space's environment and gateway.
  final _RunEnvironmentAccess environment;
}

/// The run's policy-owned Git identity and co-author credit.
final class _RunIdentity {
  const _RunIdentity({required this.commitIdentity, required this.gitEnv});

  static const none = _RunIdentity(commitIdentity: null, gitEnv: {});

  /// Who the run's commits name, whom they credit and which key signs them;
  /// the gateway holds every pushed commit to it.
  final AgentCommitIdentity? commitIdentity;

  /// The run's Git identity variables plus the co-author trailer key
  /// (empty when the run credits nobody). Unmodifiable.
  final Map<String, String> gitEnv;

  /// The run's `Co-Authored-By:` lines, one per line; empty when it credits
  /// nobody.
  String get coAuthorTrailers =>
      commitIdentity?.coAuthorTrailers.join('\n') ?? '';
}

extension _RunIdentityResolution on DispatchSession {
  /// Resolves policy-owned identity before any transport starts, for a run
  /// whose worktree is on [forge] (null: not a forge checkout). Forge
  /// credentials remain the broker's, never the member's PAT.
  Future<_RunIdentity> _resolveRunIdentity(ForgeHost? forge) async {
    final resolved = await deps.resolveCommitIdentity?.call(
      requestedByUserId,
      workspaceId: workspaceId,
      runLogId: runLogId,
      forge: forge,
    );
    if (resolved == null) {
      throw StateError('The requester has no Git identity.');
    }
    // Commits are signed only where the run's git can reach the signer: the
    // gateway signs, and the sign shim runs (it is a shell script).
    final signs = (deps.agentRunGateway?.signs ?? false) && !Platform.isWindows;
    final identity = signs ? resolved : resolved.unsigned;
    final requester = requestedByUserId;
    if (!identity.isPerson && requester != null && requester.isNotEmpty) {
      // A person asked, but no forge vouches for an address of theirs: the
      // commits are the agent's, and name nobody.
      addEvent(
        DebugEvent(
          content:
              '[identity] Commits from this run are the agent\'s, not '
              'those of the person who asked for it: no forge has verified '
              'an email for them here. Signing in to '
              '${forge == null || forge == ForgeHost.local ? 'GitHub' : forge.displayName} '
              'in this workspace makes them the author.',
        ),
      );
    }
    return _RunIdentity(
      commitIdentity: identity,
      gitEnv: Map.unmodifiable({
        ...identity.environment,
        // This policy-owned key also masks stale caller and inherited
        // trailers.
        DispatchSession.coAuthorTrailerEnvKey: identity.coAuthorTrailers.join(
          '\n',
        ),
      }),
    );
  }
}
