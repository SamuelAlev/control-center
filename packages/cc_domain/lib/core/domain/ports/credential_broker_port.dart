/// Outcome of a [CredentialBrokerPort.mint] call.
class ScopedCredentials {
  /// Creates a new [ScopedCredentials].
  const ScopedCredentials({
    required this.handle,
    required this.environment,
    this.expiresAt,
    this.notes = const [],
  });

  /// Opaque token used to [CredentialBrokerPort.revoke] this grant later.
  final String handle;

  /// Env vars to inject into the sandbox guest process (`GH_TOKEN`,
  /// `GITHUB_TOKEN`).
  final Map<String, String> environment;

  /// Wall-clock time after which the credentials should be considered dead.
  /// Used by the UI to show "expires in N min" and by the broker to auto-
  /// revoke if the sandbox outlives the credential.
  final DateTime? expiresAt;

  /// Human-readable notes shown in the UI (e.g. "Using raw PAT — swap in
  /// fine-grained tokens for production").
  final List<String> notes;
}

/// What a minted forge token may do.
///
/// There is no "none": whether an agent may push, open a PR or reach the
/// network is decided by the action policy (allow / ask / deny), not by
/// withholding a token up front.
enum ForgeTokenScope {
  /// Read the repository and work with pull requests — what lands in an
  /// agent's own environment. It cannot push: pushes go through the agent run
  /// gateway, which consults the push rule before using a [write] token.
  read,

  /// Write the repository contents. Held server-side by whatever applies the
  /// push rule (the agent run gateway, a rig's credential endpoint); never
  /// placed in an agent's environment.
  write,
}

/// Port that mints scoped credentials for a sandbox launch and revokes them on
/// teardown.
abstract interface class CredentialBrokerPort {
  /// Mints a [scope]d credential for one launch of [conversationId]'s sandbox.
  /// Returns an env map to merge into the guest environment plus a revoke
  /// handle.
  ///
  /// [actingUserId] is the human this launch is being performed FOR — the
  /// member who dispatched the agent or opened the shell. It is what bounds the
  /// credential to that person's own forge access instead of the server
  /// owner's, so a member who cannot push cannot obtain a token that can.
  /// Without it the only boundary is between servers, and every member of one
  /// server shares whatever its owner can reach.
  ///
  /// Null means "no human asked" — a webhook, a reconciler, a scheduled run —
  /// and falls back to the server's own identity, which is the same behaviour
  /// as before this parameter existed.
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  });

  /// Revokes a previously-minted grant. Idempotent.
  Future<void> revoke(String handle);
}
