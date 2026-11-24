part of 'agent_run_gateway.dart';

/// Who a registered agent run is, as the action policy needs to know it.
class AgentRunGrant {
  /// Creates an [AgentRunGrant].
  const AgentRunGrant({
    required this.workspaceId,
    required this.conversationId,
    required this.mcpEndpoint,
    required this.claudeHook,
    required this.readOnly,
    this.claudeTurnHooks,
    this.agentId,
    this.spaceId,
    this.mode = Mode.chat,
    this.actingUserId,
    this.runId,
    this.repos = const [],
    this.identity,
    this.signProgram,
    this.worktreeRoot,
    this.sharedWorktreeRoots = const [],
    this.readOnlyWorktrees = const [],
    this.runnerStateDirs = const [],
    this.autonomy,
    this.personalMcpUserId,
    this.runLogId,
  });

  /// Workspace the run belongs to — every rule is resolved against it.
  final String workspaceId;

  /// Conversation the run serves; names minted credentials.
  final String conversationId;

  /// The agent, for agent-scoped rules.
  final String? agentId;

  /// The space, for space-scoped rules and the approval prompt's target.
  final String? spaceId;

  /// The run's mode: read-only modes deny pushes outright.
  final Mode mode;

  /// Whether the run is read-only (`ReadOnlyRunProfile`): its MCP calls and
  /// Claude Code's own tools are admitted only when they change nothing.
  final bool readOnly;

  /// The member the run acts for; bounds the forge credential to their reach.
  final String? actingUserId;

  /// The member whose own MCP servers the run may use through the Control
  /// Center MCP endpoint: the person who started it, decided once, when the
  /// run starts (`HostExecutionGate.startedBy`). Null for none.
  final String? personalMcpUserId;

  /// The dispatch id. It names the run's nested-call events
  /// (`McpCallScope.runId`) and its log lines; it names no row, so the guard
  /// audit carries [runLogId] instead.
  final String? runId;

  /// Whether the run's agent calls the server's MCP endpoint with the run's
  /// secret: an agent CLI the run hands an MCP config. Only then does the
  /// secret prove a run there ([AgentRunGateway.mcpScopeFor]). The built-in
  /// harness calls its tools in-process, so its secret, which every process
  /// of the run can read from its environment, opens no MCP call: a command
  /// (and so a code mode script's `bash`) cannot reach a tool there as a call
  /// of the run, outside the harness gate and a script's limits.
  final bool mcpEndpoint;

  /// Whether the run's agent is Claude Code with the gateway's PreToolUse
  /// hook installed ([AgentRunLease.claudeHookSettings]). Only then does the
  /// secret open the hook route: any other run's secret is refused there as
  /// one that names no run, so no process of it can ask the gateway's policy
  /// about a command, or raise a card, outside its own gate.
  final bool claudeHook;

  /// The server owner's `stop` and `preCompact` scripts for a Claude Code
  /// run ([claudeHook]), or null when the owner configured neither. When set,
  /// the settings file registers Claude Code's `Stop` and `PreCompact` hooks
  /// ([AgentRunLease.claudeHookSettings]) and the gateway answers them by
  /// running these scripts, sandboxed like the harness's hooks.
  final ClaudeTurnHookScripts? claudeTurnHooks;

  /// The run's `agent_run_logs` row, when it has one. Rows that cascade with
  /// the run, such as its code executions, are keyed by it, and every guard
  /// row the gateway writes names it, as the harness's own rows do; [runId]
  /// is the dispatch id and names no row.
  final String? runLogId;

  /// The repositories the run works on, on every forge: its space's
  /// checkouts, or the checkout it started in. It fetches these through the
  /// gateway on a credential the server keeps ([AgentRunLease.fetchGitConfig]),
  /// its `gh` reads the GitHub ones ([AgentRunForgeTokens]), and a push is
  /// held to the same repo check wherever it goes.
  final List<ForgeRemote> repos;

  /// [owner]/[name] on [forge] as the run's own repository spells it, or null
  /// when the run does not work on it. Forge paths are case-insensitive.
  ForgeRemote? repoOn(ForgeHost forge, String owner, String name) {
    for (final repo in repos) {
      if (repo.forge == forge &&
          repo.owner.toLowerCase() == owner.toLowerCase() &&
          repo.name.toLowerCase() == name.toLowerCase()) {
        return repo;
      }
    }
    return null;
  }

  /// The run's GitHub repositories: what its `gh` may read.
  List<ForgeRemote> get gitHubRepos => [
    for (final repo in repos)
      if (repo.forge == ForgeHost.github) repo,
  ];

  /// The run's one GitHub repository, when it works on exactly one: what
  /// "this run's repository" means to `gh` and `open_pull_request` when they
  /// were not told which.
  ForgeRemote? get soleGitHubRepo {
    final github = gitHubRepos;
    return github.length == 1 ? github.single : null;
  }

  /// Who the run's commits name, whom they credit and which key signs them.
  /// Every pushed commit must match it, and only commits that do are signed;
  /// null pushes no commits and signs nothing.
  final AgentCommitIdentity? identity;

  /// The program the run's git signs with ([AgentRunSigning.shim], written
  /// where the run can execute it). Set exactly when [identity] has a
  /// signing key: the run's commits are then signed through the gateway.
  final String? signProgram;

  /// The run's working tree. A native write inside it is the agent's own work.
  final String? worktreeRoot;

  /// The space's shared worktrees the run's overlay links to (`repos/`).
  ///
  /// A write through the overlay's `repos` symlink resolves to these, outside
  /// [worktreeRoot] — so without them every edit of a checked-out repo was
  /// classed as a write outside the worktree and asked about.
  final List<String> sharedWorktreeRoots;

  /// The worktrees in [sharedWorktreeRoots] the person this run acts for may
  /// not change ([ReadOnlyWorktrees]). Claude Code's own write tools are
  /// refused there before any policy check.
  final List<String> readOnlyWorktrees;

  /// Reads the run's space autonomy dial, per decision (the operator can turn
  /// it mid-run). Null applies the policy alone.
  final Future<AutonomyLevel?> Function()? autonomy;

  /// Directories the runner keeps its own state in, such as a Claude account's
  /// config dir. Plan mode writes its plan file there.
  final List<String> runnerStateDirs;
}
