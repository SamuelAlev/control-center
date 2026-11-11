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

  /// The credential as env vars (`GH_TOKEN`, `GITHUB_TOKEN`): what a pipeline
  /// shell step or a rig is launched with. The agent run gateway reads the
  /// token out of it and never puts it in an agent's environment.
  final Map<String, String> environment;

  /// Wall-clock time after which the credentials should be considered dead.
  /// Used by the UI to show "expires in N min" and by the broker to auto-
  /// revoke if the sandbox outlives the credential.
  final DateTime? expiresAt;

  /// Human-readable notes shown in the UI (which repository and scope the
  /// token covers, or why none was minted).
  final List<String> notes;
}

/// What a minted forge token may do.
///
/// There is no "none": whether an agent may push, open a PR or reach the
/// network is decided by the action policy (allow / ask / deny), not by
/// withholding a token up front.
enum ForgeTokenScope {
  /// Read the repository, its pull requests and CI — and nothing else.
  /// Pipeline shell steps, clones and enclosures.
  read,

  /// What an agent run reads with: [read] plus reading issues, and nothing
  /// that writes. The agent run gateway mints it when the run's git or `gh`
  /// asks, only for a repository the run works on, and revokes it when the
  /// run ends; a run starts with no forge token at all. Pushes go through the
  /// gateway too (which consults the push rule before using a [write]
  /// token); agents open a pull request through the server's
  /// `open_pull_request` tool (on the requesting person's own token) and
  /// comment on their own one through `comment_on_pull_request` (as the bot).
  review,

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
  /// Null means "no human asked" — a schedule, a reconciler — and the bound
  /// is the workspace's accountable human (its owner, when a member), never
  /// an unrelated server owner.
  ///
  /// [personal] marks a person's own interactive session (a terminal rig):
  /// the token is that person's own sign-in narrowed to the one repository,
  /// so what they do there is theirs on the forge, never an App's.
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  });

  /// Revokes a previously-minted grant. Idempotent.
  Future<void> revoke(String handle);
}
