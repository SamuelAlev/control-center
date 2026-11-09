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
  const _RunIdentity({
    required this.commitIdentity,
    required this.gitEnv,
    required this.coAuthorTrailer,
  });

  static const none = _RunIdentity(
    commitIdentity: null,
    gitEnv: {},
    coAuthorTrailer: null,
  );

  /// Who the run's commits name; the gateway holds every pushed commit to it.
  final AgentCommitIdentity? commitIdentity;

  /// The run's Git identity variables plus the co-author trailer key
  /// (empty when credit is off). Unmodifiable.
  final Map<String, String> gitEnv;

  /// Control Center's co-author trailer, only when attribution is enabled.
  final String? coAuthorTrailer;
}
