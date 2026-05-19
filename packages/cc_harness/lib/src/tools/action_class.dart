/// The closed taxonomy of agent-initiated *effects* the guardrail engine
/// governs (PRD 24 §1). Small on purpose — a human must be able to read the
/// whole policy on one screen; taxonomy sprawl is the death of this feature.
///
/// Every harness tool, MCP tool and mutating repo-op declares the classes it
/// can effect (enforced by a ratchet test). Declarations are honest about the
/// worst case.
enum ActionClass {
  /// Deleting a file (Write/Edit delete, `rm`).
  fileDelete('fileDelete', ActionDecisionDefault.prompt),

  /// Writing a file outside the isolated worktree.
  fileWriteOutsideWorktree(
    'fileWriteOutsideWorktree',
    ActionDecisionDefault.allow,
  ),

  /// Creating a git commit.
  gitCommit('gitCommit', ActionDecisionDefault.allow),

  /// Pushing to a git remote.
  gitPush('gitPush', ActionDecisionDefault.prompt),

  /// Creating a pull request.
  prCreate('prCreate', ActionDecisionDefault.prompt),

  /// Publishing a review / merging a PR.
  prPublish('prPublish', ActionDecisionDefault.prompt),

  /// Writing to an external ticket vendor (Linear/Jira/GitHub sync).
  vendorSyncWrite('vendorSyncWrite', ActionDecisionDefault.prompt),

  /// Network egress (WebFetch, arbitrary HTTP).
  networkEgress('networkEgress', ActionDecisionDefault.allow),

  /// Reading a secret / credential.
  secretAccess('secretAccess', ActionDecisionDefault.allow),

  /// Installing a package (npm/pip/pub/brew…).
  packageInstall('packageInstall', ActionDecisionDefault.allow),

  /// Spawning a process (Bash and anything shelling out).
  processSpawn('processSpawn', ActionDecisionDefault.allow),

  /// Mutating workspace-level structure (repos, channels, agents).
  workspaceMutation('workspaceMutation', ActionDecisionDefault.allow),

  /// Driving an enclosure (rig): booting a VM/microVM, sending input to a
  /// guest, installing or launching software inside it.
  ///
  /// Allowed by default because the enclosure IS the containment — an agent
  /// clicking around a disposable VM with a deny-by-default NIC is doing less
  /// damage than the same agent running `bash` on the host. What makes it
  /// worth its own class is that read-only modes must be able to deny it
  /// wholesale (a review-mode agent has no business booting machines) and the
  /// autonomy dial must be able to demote it to `prompt` per channel.
  enclosureControl('enclosureControl', ActionDecisionDefault.allow);

  const ActionClass(this.wire, this.defaultDecisionHint);

  /// Stable wire/storage string.
  final String wire;

  /// The conservative built-in default when no rule matches (§2). Four classes
  /// prompt out of the box; the rest allow (the sandbox floor still applies).
  final ActionDecisionDefault defaultDecisionHint;

  /// Parses an [ActionClass] from its [wire] string, or null if unknown.
  static ActionClass? fromWire(String value) {
    for (final c in ActionClass.values) {
      if (c.wire == value) {
        return c;
      }
    }
    return null;
  }
}

/// The built-in default decision hint for an [ActionClass] (kept separate from
/// the resolver's `ActionDecision` so the enum stays dependency-free).
enum ActionDecisionDefault {
  /// Allow by default.
  allow,

  /// Prompt (ask once) by default.
  prompt,
}
