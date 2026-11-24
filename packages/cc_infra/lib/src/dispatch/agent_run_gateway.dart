import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show ForgeRemote, parseForgeRemote;
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart'
    show kAgentShellGitHubWriteRefusal;
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart'
    show kAgentShellPrCreateRefusal;
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart'
    show kBaselineAllowedDomains;
import 'package:cc_harness/tools.dart' show ActionClass, PersonWaitListener;
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:cc_infra/src/dispatch/read_only_worktrees.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart'
    show CommandWait, CommandWaitRelay;
import 'package:cc_infra/src/harness/script_approval_check.dart'
    show checkWithinScriptApprovals;
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/forge_git_auth.dart'
    show forgeGitBasicAuthorization;
import 'package:cc_infra/src/process/agent_run_client_launcher.dart';
import 'package:path/path.dart' as p;

part 'agent_run_forge_tokens.dart';
part 'agent_run_git_objects.dart';
part 'agent_run_native_tools.dart';
part 'agent_run_signing.dart';
part 'agent_run_tool_hooks.dart';
part 'agent_run_call_waits.dart';
part 'agent_run_environment_commands.dart';
part 'agent_run_fetch.dart';
part 'agent_run_view.dart';
part 'agent_run_grant.dart';

/// A registered run's handle on the gateway: what to put in its environment
/// and how to point Claude Code's hooks at it.
///
/// It is also where a harness `bash` command registers its tool call's
/// person-wait listener ([register]), so a push the gateway holds for
/// approval stops that call's clocks instead of running them down.
class AgentRunLease implements CommandWaitRelay {
  AgentRunLease._(
    this.secret,
    this.base,
    this.client, {
    required this._gateway,
    this.repos = const [],
    this.signingKey,
    this.signProgram,
  });

  /// Env var carrying [secret] to the agent process.
  static const String tokenEnvKey = 'CC_AGENT_RUN_TOKEN';

  /// Header the gateway authenticates a run by.
  static const String tokenHeader = McpCallScope.runGrantHeader;

  /// Env var carrying one command's call token ([register]) to the processes
  /// that command starts. The agent run client sends it as [callTokenHeader].
  static const String callTokenEnvKey = 'CC_AGENT_CALL_TOKEN';

  /// Header naming the command a request comes from, so the gateway can tell
  /// that command's tool call when it asks a person about the request. It
  /// authenticates nothing: [tokenHeader] does, and a missing, unknown or
  /// foreign call token changes nothing about what is decided.
  static const String callTokenHeader = 'X-CC-Agent-Call';

  final AgentRunGateway _gateway;

  /// Env var carrying [base] to the agent process, for the run's shims.
  static const String gatewayEnvKey = 'CC_AGENT_GATEWAY';

  /// What one segment of an owner or a repo name may contain before it
  /// enters a git config key or an upstream URL.
  static final RegExp _repoPathPart = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.-]*$');

  /// `<owner>/<name>` of [repo] as the gateway's git paths spell it, or null
  /// when it is not a repository on a supported forge with names fit for a
  /// URL and a config key. Only GitLab nests owners (`group/sub`).
  static String? gitPath(ForgeRemote repo) {
    final owner = repo.owner.split('/');
    if (!ForgeHost.supported.contains(repo.forge) ||
        (owner.length > 1 && repo.forge != ForgeHost.gitlab) ||
        !owner.every(_repoPathPart.hasMatch) ||
        !_repoPathPart.hasMatch(repo.name)) {
      return null;
    }
    return '${repo.owner}/${repo.name}';
  }

  /// An MCP client config as it reads without this run's secret.
  ///
  /// Every run has its own, which is no change of policy: comparing configs
  /// with it left in would start a fresh native session on every turn.
  static String withoutRunSecret(String config) =>
      config.replaceAll(RegExp('"$tokenHeader"\\s*:\\s*"[^"]*",?'), '');

  /// The per-run secret. Knowing it lets a process ASK the gateway on the
  /// run's behalf — every answer still comes from the action policy.
  final String secret;

  /// Loopback base the run reaches the gateway at (`http://127.0.0.1:<port>`).
  final Uri base;

  /// How the run's shims and Claude Code's hook start the agent run client.
  final AgentRunClientLauncher client;

  /// The repositories the run works on ([AgentRunGrant.repos]): the ones its
  /// git fetches through the gateway.
  final List<ForgeRemote> repos;

  /// The `ssh-ed25519 <base64>` key the run's commits are signed with, or
  /// null when they are unsigned.
  final String? signingKey;

  /// The program the run's git signs with; see [AgentRunGrant.signProgram].
  final String? signProgram;

  String get _gitBase => '$base/agent/git/';

  /// `git -c` pairs that keep a run from signing at all. The user's global
  /// `commit.gpgsign` would otherwise make every commit fail (or sign with
  /// their own key where a signer is reachable), and an explicit `-S` still
  /// reaches nothing that signs.
  static const List<(String, String)> unsignedGitConfig = [
    ('commit.gpgsign', 'false'),
    ('tag.gpgsign', 'false'),
    ('push.gpgsign', 'false'),
    ('gpg.program', 'false'),
    ('gpg.ssh.program', 'false'),
    ('gpg.x509.program', 'false'),
  ];

  /// `git -c` pairs that route conventional GitHub PUSH URLs through the gateway.
  ///
  /// `pushInsteadOf` rewrites push URLs only; it is routing, not authorization.
  /// Credential-bearing URLs and overridden Git configuration can bypass it,
  /// so shell preflight also checks pushes. The secret rides an `extraHeader`
  /// scoped to the gateway, never a remote URL.
  List<(String, String)> get gitConfig => [
    for (final origin in const [
      'https://github.com/',
      'git@github.com:',
      'ssh://git@github.com/',
    ])
      ('url.${_gitBase}github.com/.pushInsteadOf', origin),
    (_gatewayHeaderKey, '$tokenHeader: $secret'),
    ...AgentRunSigning.gitConfig(signingKey, signProgram),
  ];

  /// The git setting whose values git sends as headers to the gateway only.
  String get _gatewayHeaderKey => 'http.$_gitBase.extraHeader';

  /// `git -c` pairs that send the run's fetches of the repositories it works
  /// on through the gateway, on every forge.
  ///
  /// A sandbox never reaches the user's SSH agent or `~/.ssh`, and the run
  /// holds no forge credential: each of the run's repositories, in every URL
  /// shape, is rewritten to the gateway, which forwards the fetch with a
  /// credential it keeps ([AgentRunGateway]). Nothing here names one. A
  /// GitHub push still goes by [gitConfig]'s `pushInsteadOf`, which git
  /// prefers for pushes.
  ///
  /// The rewrites name the repo so they outrank a user's global host-wide
  /// rewrite (to SSH, say): git takes the longest match. They are prefix
  /// matches, so a sibling (`widgets-extra`) reaches the gateway too; it is
  /// not the run's, so the gateway forwards it with no credential.
  List<(String, String)> get fetchGitConfig => [
    for (final repo in repos)
      if (gitPath(repo) case final path?)
        for (final origin in [
          'https://${repo.forge.gitHost}/$path',
          'git@${repo.forge.gitHost}:$path',
          'ssh://git@${repo.forge.gitHost}/$path',
        ])
          ('url.$_gitBase${repo.forge.gitHost}/$path.insteadOf', origin),
  ];

  /// Registers [listener] for one command of this run, which runs with
  /// [env] (this lease's [environment] among it).
  ///
  /// The registration lasts until [CommandWait.release]. While it does, a
  /// request carrying its token on this run's secret that the gateway asks a
  /// person about tells [listener] `true` when the ask starts and `false`
  /// when it ends, and [decided] hears what the gateway decided about it
  /// ([CommandWaitRelay.register]). A closed lease registers nothing.
  @override
  CommandWait register(
    PersonWaitListener listener,
    Map<String, String> env, {
    required void Function(bool approved) decided,
  }) => _gateway._registerCallWait(this, listener, env, decided);

  /// Holds a running script's [approvals] against every card the gateway
  /// raises for this run. See [CommandWaitRelay.holdScriptApprovals].
  @override
  void Function() holdScriptApprovals(ScriptApprovalBudget approvals) =>
      _gateway._holdScriptApprovals(secret, approvals);

  /// Environment for the agent process: the secret plus [gitConfig] and
  /// [fetchGitConfig] appended to whatever `GIT_CONFIG_*` entries [env]
  /// already carries.
  Map<String, String> environment(Map<String, String> env) {
    final out = <String, String>{tokenEnvKey: secret, gatewayEnvKey: '$base'};
    var count = int.tryParse(env['GIT_CONFIG_COUNT'] ?? '') ?? 0;
    for (final (key, value) in [...gitConfig, ...fetchGitConfig]) {
      out['GIT_CONFIG_KEY_$count'] = key;
      out['GIT_CONFIG_VALUE_$count'] = value;
      count++;
    }
    out['GIT_CONFIG_COUNT'] = '$count';
    return out;
  }

  /// Every Claude Code tool the action policy has a rule for. Reading tools
  /// have none: the sandbox decides what they can see.
  static const guardedClaudeTools =
      'Bash|Write|Edit|MultiEdit|NotebookEdit|WebFetch|WebSearch';

  /// What a blocked tool call says when the gateway gave no verdict.
  static const String _checkFailed =
      'Control Center permission check failed; command blocked.';

  /// Claude's command hook blocks with exit 2 unless the gateway explicitly
  /// allows the call. A command hook that exits with anything but 0 or 2
  /// does not block, so every other outcome, the agent run client failing to
  /// start included, becomes exit 2 here. The client has its own deadline
  /// inside the hook timeout, so a gateway that never answers denies too.
  ///
  /// A missing lease installs a blocking hook, never an unguarded Bash tool.
  /// Only Bash: the file and web tools stay usable, because the OS sandbox
  /// bounds them without help from the gateway and Bash it cannot.
  ///
  /// A [readOnly] run's hook matches every tool, so the gateway admits only
  /// what `ReadOnlyRunProfile.admitsClaudeTool` passes; without a lease
  /// that hook blocks every tool.
  static String claudeHookSettings(
    AgentRunLease? lease, {
    required bool readOnly,
  }) {
    final command = lease == null
        ? "printf '%s\\n' 'Control Center permission gateway is unavailable.' >&2; exit 2"
        : '''
$gatewayEnvKey=${AgentRunClientLauncher.shellQuote('${lease.base}')} ${lease.client.shellCommand} hook
case \$? in
  0) exit 0 ;;
  2) exit 2 ;;
esac
printf '%s\\n' '$_checkFailed' >&2
exit 2
''';
    final turnHooks = lease == null
        ? null
        : lease._gateway._grants[lease.secret]?.claudeTurnHooks;
    // The owner's `stop` and `preCompact` scripts, through the gateway like
    // PreToolUse (the scripts live on the host). Neither fails closed: a
    // client that cannot reach the gateway exits 0, which lets the turn end
    // and the compaction run without extra instructions.
    Map<String, Object?> turnHook(String verb) => {
      'hooks': [
        {
          'type': 'command',
          'command':
              '$gatewayEnvKey='
              '${AgentRunClientLauncher.shellQuote('${lease!.base}')} '
              '${lease.client.shellCommand} $verb',
          'timeout': AgentRunGateway.turnHookTimeout.inSeconds,
        },
      ],
    };
    return jsonEncode({
      'disableAllHooks': false,
      'hooks': {
        'PreToolUse': [
          {
            'matcher': readOnly
                ? '*'
                : lease == null
                ? 'Bash'
                : guardedClaudeTools,
            'hooks': [
              {
                'type': 'command',
                'command': command,
                'timeout': AgentRunGateway.hookTimeout.inSeconds,
              },
            ],
          },
        ],
        if (turnHooks?.hasStop ?? false) 'Stop': [turnHook('stop')],
        if (turnHooks?.hasPreCompact ?? false)
          'PreCompact': [turnHook('pre-compact')],
      },
    });
  }
}

/// The host side of the action policy for code running inside an agent's
/// sandbox: a fetch and push proxy and a Claude Code hook endpoint, served on
/// the same loopback listener agents already dial for MCP.
///
/// **Fetch proxy.** The run's git fetches the repositories it works on, on
/// GitHub, GitLab and Bitbucket, through here ([AgentRunLease.fetchGitConfig])
/// and the gateway forwards each fetch on a credential the run never sees
/// (`agent_run_fetch.dart`).
///
/// **Push proxy.** Conventional GitHub push URLs route here. The gateway
/// reads the ref updates, asks policy with the actual refs, then forwards
/// using a server-held write credential. GitLab and Bitbucket pushes are
/// refused: agents publish there with `stack_publish`.
///
/// **Commit signing.** A run a person asked for signs its commits with that
/// person's signing key when they set one up ([CommitSigningPort]). The key
/// never enters the sandbox: git's signer there ([AgentRunSigning.shim])
/// posts the commit object here, and it is signed only when it is the run's
/// own commit (its author, committer and co-author lines are the run's
/// identity). Every other run turns signing off
/// ([AgentRunLease.unsignedGitConfig]), and the push proxy holds every
/// pushed commit to the same rule ([PushedCommitInspector]).
///
/// **Shell commands (soft).** Claude Code runs its own `Bash` tool; the
/// PreToolUse hook posts each command here, the [ShellActionClassifier] names
/// the rules it falls under (`git push` → "Push to a remote"), and the
/// answer comes back as the hook's allow/deny. Opening a pull request from
/// the shell is refused outright with directions to the server's
/// `open_pull_request` tool: the run's token cannot open one, and the
/// server opens it as the person who requested the run ([openRuns] tells it
/// who that is and which branches the run pushed).
///
/// Every request is authenticated by a per-run secret ([AgentRunLease]) and
/// every scope comes from the registered [AgentRunGrant] — never from the
/// request — so one run cannot ask with another's identity.
class AgentRunGateway {
  /// Creates an [AgentRunGateway].
  ///
  /// The loopback-base resolver says where runs reach this gateway (the MCP
  /// loopback listener); null means it is not being served, and runs then get
  /// no lease. The repo check ([AgentPushRepoCheck]) decides whether a run
  /// may push to a repo, its own worktree's included. The fetch credential
  /// ([AgentFetchCredential]) answers for a run's GitLab and Bitbucket
  /// repositories; without one they are not fetched.
  ///
  /// `forgeBases` replaces a forge's `https://<host>` for tests; `client`
  /// replaces how the run's shims start the agent run client.
  AgentRunGateway({
    required this._guard,
    required this._broker,
    required this._loopbackBase,
    this._repoAllowed,
    this._fetchCredential,
    this._signing,
    this._ancestry,
    HttpClient Function()? httpClient,
    this._forgeBases = const {},
    this._client,
    Future<List<PushedGitObject>> Function(File pack)? inspectPack,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _httpClient = httpClient ?? HttpClient.new,
       _inspectPack = inspectPack ?? PushedCommitInspector.inspect;

  /// How long Claude Code waits on the hook. Generous, because "ask first"
  /// waits on a human.
  static const Duration hookTimeout = Duration(hours: 1);

  /// When the gateway stops waiting for a human and denies. This expires
  /// before the hook client's deadline, which itself expires before Claude's
  /// hook timeout.
  static const Duration hookDecisionDeadline = Duration(minutes: 55);

  /// The hook's HTTP client must exit with a blocking result before Claude
  /// times out the command hook (a timeout is not an authorization decision).
  static const Duration hookTransportDeadline = Duration(minutes: 56);

  /// How long an operator's "yes" to a pushing shell command also answers the
  /// push gateway's own ask for that run, so one push is one prompt. Long
  /// enough for a command that builds or tests before it pushes. The same
  /// window lets a "yes" to a committing command answer the signing route's
  /// ask for the commits that command creates.
  static const Duration shellPushApprovalWindow = Duration(minutes: 15);

  /// Cap on the ref-update preamble read before a push is decided. The
  /// commands are a few hundred bytes; anything this large is not a push.
  static const int _maxPreambleBytes = 1024 * 1024;

  /// Cap on a hook request body. Generous because a `Write` carries the whole
  /// file: refusing a large one here would block work no rule objected to.
  static const int _maxHookBodyBytes = 32 * 1024 * 1024;

  final ActionGuardService _guard;
  final CredentialBrokerPort _broker;
  final Future<Uri?> Function() _loopbackBase;
  final AgentPushRepoCheck? _repoAllowed;

  /// The server-held credential a fetch of the run's GitLab or Bitbucket
  /// repository is forwarded on. Null fetches none of them.
  final AgentFetchCredential? _fetchCredential;

  /// Answers whether a commit a push stands on is already published in the
  /// repository. Null answers nothing: such a push is then refused.
  final AgentPushAncestryCheck? _ancestry;

  /// Signs commits for people with a signing key. Null signs nothing.
  final CommitSigningPort? _signing;
  final DateTime Function() _now;
  final HttpClient Function() _httpClient;
  final Map<ForgeHost, Uri> _forgeBases;
  final AgentRunClientLauncher? _client;

  /// How the run's shims and Claude Code's hook start the agent run client.
  AgentRunClientLauncher get client =>
      _client ?? AgentRunClientLauncher.current;

  /// Reads the commits and tags out of a pushed pack.
  final Future<List<PushedGitObject>> Function(File pack) _inspectPack;

  final Map<String, AgentRunGrant> _grants = {};

  /// secret → the pushing shell command the operator last approved.
  final Map<String, _ShellPushApproval> _shellPushApprovals = {};

  /// secret → until when the operator's "yes" to a committing shell command
  /// also answers the signing route's ask for that run.
  final Map<String, DateTime> _shellCommitApprovals = {};

  /// secret → how many commits the run asked this gateway to sign.
  final Map<String, int> _signatures = {};

  /// secret → the credentials minted for the run per scope and `owner/name`,
  /// revoked on [close].
  final Map<String, Map<_ForgeTokenKey, ScopedCredentials>> _tokens = {};

  /// secret → the mint in flight per scope and `owner/name`, so concurrent
  /// requests share one credential instead of each minting and overwriting
  /// the last.
  final Map<String, Map<_ForgeTokenKey, Future<String?>>> _tokenMints = {};

  /// secret → why the last mint per scope and `owner/name` was refused (the
  /// broker's note), so git prints the reason: a run nobody requested on a
  /// Control Center Connect lane, a member without push, no GitHub App.
  final Map<String, Map<_ForgeTokenKey, String>> _tokenRefusals = {};

  /// secret → the routes whose refusal of a run that may not use them was
  /// already logged ([_ToolHooks._logRouteRefusal]): once per run and route.
  final Map<String, Set<String>> _routeRefusalsLogged = {};

  /// secret → withdrawals of approvals still waiting on a human, completed
  /// when the run's lease closes so its prompts come down with it.
  final Map<String, Set<Completer<void>>> _pendingAsks = {};

  /// secret → the branches the run pushed through this gateway, per
  /// repository: what "the run's own branch" means when it asks the server
  /// to open a pull request.
  final Map<String, Set<AgentRunPushedBranch>> _pushedBranches = {};

  /// secret → call token → the person-wait listener of the command that
  /// token was handed to ([AgentRunLease.register]), while it runs.
  final Map<String, Map<String, _CallWait>> _callWaits = {};

  /// secret → the approval budgets of the run's code mode scripts in flight
  /// ([AgentRunLease.holdScriptApprovals]).
  final Map<String, List<ScriptApprovalBudget>> _scriptApprovals = {};

  static final Random _random = Random.secure();

  /// Registers a run and returns its lease, or null when the gateway is not
  /// reachable. Claude must then install the blocking hook for a missing lease.
  Future<AgentRunLease?> open(AgentRunGrant grant) async {
    final base = await _loopbackBase();
    if (base == null) {
      return null;
    }
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final secret = base64Url.encode(bytes).replaceAll('=', '');
    // Whether a run signs is decided once, by whoever builds the grant: its
    // identity carries a signing key exactly when its git was given the
    // signer. A grant that says one without the other would hold pushes to
    // signatures git was never able to make, or sign for a run whose pushes
    // are checked as unsigned.
    final signingKey = grant.identity?.signingKey;
    if ((signingKey != null) != (grant.signProgram != null) ||
        (signingKey != null && _signing == null)) {
      throw StateError(
        'A run signs its commits exactly when it has a signing key, a signer '
        'program and a gateway that signs.',
      );
    }
    _grants[secret] = grant;
    return AgentRunLease._(
      secret,
      base,
      client,
      gateway: this,
      repos: grant.repos,
      signingKey: signingKey,
      signProgram: grant.signProgram,
    );
  }

  /// The MCP scope [secret] proves, or null when it names no open run.
  /// A run whose agent does not call the MCP endpoint
  /// ([AgentRunGrant.mcpEndpoint]) proves none, and the refusal is logged
  /// once for the run.
  McpCallScope? mcpScopeFor(String secret) {
    final grant = _grants[secret];
    if (grant != null && !grant.mcpEndpoint) {
      _logRouteRefusal(secret, grant, '/mcp');
    }
    return grant == null || !grant.mcpEndpoint
        ? null
        : McpCallScope(
            workspaceId: grant.workspaceId,
            agentId: grant.agentId,
            conversationId: grant.conversationId,
            spaceId: grant.spaceId,
            attested: true,
            personalMcpUserId: grant.personalMcpUserId,
            runId: grant.runId,
            runLogId: grant.runLogId,
            readOnly: grant.readOnly,
          );
  }

  /// The runs open in [conversationId] of [workspaceId], each with the
  /// branches it pushed through this gateway so far.
  ///
  /// How a server-side tool learns who an agent run acts for: the MCP call
  /// was attested by one of these runs' secrets (`McpCallScope.attested`),
  /// which forces its workspace and conversation, so the model never names
  /// the requester or the run.
  List<AgentRunView> openRuns({
    required String workspaceId,
    required String conversationId,
  }) => [
    for (final entry in _grants.entries)
      if (entry.value.workspaceId == workspaceId &&
          entry.value.conversationId == conversationId)
        AgentRunView(
          grant: entry.value,
          pushedBranches: Set.unmodifiable(
            _pushedBranches[entry.key] ?? const <AgentRunPushedBranch>{},
          ),
        ),
  ];

  /// Forgets a run and revokes every token minted for it.
  Future<void> close(AgentRunLease? lease) async {
    if (lease == null) {
      return;
    }
    _grants.remove(lease.secret);
    _pushedBranches.remove(lease.secret);
    _shellPushApprovals.remove(lease.secret);
    _shellCommitApprovals.remove(lease.secret);
    _signatures.remove(lease.secret);
    _tokenMints.remove(lease.secret);
    _tokenRefusals.remove(lease.secret);
    _routeRefusalsLogged.remove(lease.secret);
    for (final wait
        in _callWaits.remove(lease.secret)?.values ?? const <_CallWait>[]) {
      wait.release();
    }
    _scriptApprovals.remove(lease.secret);
    for (final ask
        in _pendingAsks.remove(lease.secret) ?? const <Completer<void>>{}) {
      if (!ask.isCompleted) {
        ask.complete();
      }
    }
    final minted = _tokens.remove(lease.secret);
    for (final credentials in minted?.values ?? const <ScopedCredentials>[]) {
      try {
        await _broker.revoke(credentials.handle);
      } on Object catch (e) {
        CcInfraLog.warning('agent gateway: revoke failed: $e');
      }
    }
  }

  /// Whether this gateway signs commits for people with a signing key. A
  /// run's identity keeps its signing key only when it does.
  bool get signs => _signing != null;

  /// Claude Code's PreToolUse hook ([AgentRunGrant.claudeHook]).
  static const String hookPath = '/agent/hooks/pre-tool-use';

  /// Claude Code's Stop hook ([AgentRunGrant.claudeTurnHooks]).
  static const String stopHookPath = '/agent/hooks/stop';

  /// Claude Code's PreCompact hook ([AgentRunGrant.claudeTurnHooks]).
  static const String preCompactHookPath = '/agent/hooks/pre-compact';

  /// How long Claude Code waits for the `Stop` and `PreCompact` hooks: the
  /// owner's script has 30 seconds, and the agent run client gives up a
  /// little before this.
  static const Duration turnHookTimeout = Duration(seconds: 90);

  /// Whether [path] is one this gateway serves.
  static bool owns(String path) => path.startsWith('/agent/');

  /// Serves one request under `/agent/`. Loopback only: these endpoints exist
  /// for processes on this host, whatever listener they are mounted on.
  Future<void> handle(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress;
    if (remote == null || !remote.isLoopback) {
      return _plain(request, HttpStatus.forbidden, 'Loopback only.');
    }
    final secret = request.headers.value(AgentRunLease.tokenHeader);
    final grant = secret == null ? null : _grants[secret];
    if (secret == null || grant == null) {
      return _plain(request, HttpStatus.unauthorized, 'Unknown agent run.');
    }
    final path = request.uri.path;
    try {
      if (path == hookPath && request.method == 'POST') {
        return await _preToolUse(request, grant, secret);
      }
      if (path == stopHookPath && request.method == 'POST') {
        return await _stopHook(request, grant, secret);
      }
      if (path == preCompactHookPath && request.method == 'POST') {
        return await _preCompactHook(request, grant, secret);
      }
      if (path == AgentRunSigning.path && request.method == 'POST') {
        return await _sign(request, grant, secret);
      }
      if (path.startsWith('/agent/git/')) {
        return await _git(request, grant, secret);
      }
      if (path == AgentRunForgeTokens.path && request.method == 'GET') {
        return await _forgeToken(request, grant, secret);
      }
      if (path == envPath && request.method == 'POST') {
        return await _environmentCommand(request, grant, secret);
      }
      return await _plain(request, HttpStatus.notFound, 'Not found.');
    } on Object catch (e, st) {
      CcInfraLog.warning('agent gateway: $path failed: $e\n$st');
      try {
        // The detail stays in the server log. An exception from the forward
        // or the broker can carry a credential, and this body is read by the
        // agent the request came from.
        return await _plain(
          request,
          HttpStatus.internalServerError,
          'The Control Center gateway failed; the server log has the details.',
        );
      } on Object {
        // Headers were already sent; the client sees a cut connection.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Environment shims

  /// `cc-env`, the `docker` shim and declared pass-through tools.
  static const String envPath = '/agent/env';

  /// Serves environment commands. Set once the environment service exists.
  AgentEnvironmentGateway? environments;

  /// The run's autonomy dial, or null when it has none or the read failed
  /// (the policy alone then decides, which is the fail-closed default).
  static Future<AutonomyLevel?> _autonomyOf(AgentRunGrant grant) async {
    final read = grant.autonomy;
    if (read == null) {
      return null;
    }
    try {
      return await read();
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: autonomy lookup failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Push proxy

  /// Serves `/agent/git/<host>/<owner…>/<repo>[.git]/<suffix>`: a fetch on
  /// any supported forge ([_fetch]), a push on GitHub, and a refusal for
  /// everything else.
  Future<void> _git(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final (:route, :refusal) = _GitRoute.parse(request.method, request.uri);
    if (route == null) {
      return _plain(request, HttpStatus.forbidden, refusal);
    }
    if (!route.push) {
      return _fetch(request, grant, secret, route);
    }
    if (route.forge != ForgeHost.github) {
      return _plain(
        request,
        HttpStatus.forbidden,
        'Control Center does not proxy pushes to '
        '${route.forge.displayName}: agents publish there with the '
        'stack_publish tool.',
      );
    }
    final owner = route.owner;
    final name = route.name;
    final isAdvertisement = route.advertisement;
    final rest = route.rest;

    if (!await _mayTouchRepo(grant, owner, name)) {
      return _plain(
        request,
        HttpStatus.forbidden,
        'Control Center: $owner/$name is not linked to this workspace, so '
        'agents here cannot push to it.',
      );
    }

    if (isAdvertisement) {
      // Refuse early when the answer is already a flat no, so git prints the
      // reason (it shows a text/plain body from ref discovery as `remote:`).
      // Anything that might be allowed — an ask, a branch-constrained rule —
      // is decided on the push itself, once the refs are known.
      final resolution = await _guard.resolve(
        workspaceId: grant.workspaceId,
        classes: const {ActionClass.gitPush},
        spaceId: grant.spaceId,
        agentId: grant.agentId,
        mode: grant.mode,
      );
      if (resolution.decision == ActionDecision.deny &&
          resolution.driving.rule?.constraint == null) {
        // Discovery ends the push before check() can run. Record the applied
        // denial here too, so the operator sees why the agent was blocked.
        _guard.recordOutcome(
          workspaceId: grant.workspaceId,
          resolution: resolution,
          applied: ActionDecision.deny,
          classes: const {ActionClass.gitPush},
          agentId: grant.agentId,
          spaceId: grant.spaceId,
          actionSummary: 'git push to $owner/$name',
          onBehalfOfUserId: grant.actingUserId,
          runId: grant.runLogId,
        );
        return _plain(
          request,
          HttpStatus.forbidden,
          'Control Center policy: ${resolution.driving.reason}',
        );
      }
      const write = ForgeTokenScope.write;
      final token = await _token(grant, secret, owner, name, write);
      if (token == null) {
        return _plain(
          request,
          HttpStatus.serviceUnavailable,
          _tokenRefusal(secret, owner, name, write) ??
              'Control Center has no GitHub credential that can push to '
                  '$owner/$name. Install the GitHub App on it or connect '
                  'GitHub.',
        );
      }
      // `no-thin`: the push that follows must carry every object it names, or
      // its commits could not be read before they are forwarded.
      return _forward(
        request,
        _upstream(
          ForgeHost.github,
          owner,
          name,
          rest,
          service: 'git-receive-pack',
        ),
        token,
        rewriteAdvertisement: true,
      );
    }

    // The push: read the ref updates, decide, then forward or reject.
    final encoding = request.headers.value(HttpHeaders.contentEncodingHeader);
    if (encoding != null && encoding != 'identity' && encoding != 'gzip') {
      return _plain(
        request,
        HttpStatus.unsupportedMediaType,
        'Control Center cannot inspect this push encoding.',
      );
    }
    final compressed = encoding == 'gzip';
    final iterator = StreamIterator<List<int>>(
      compressed ? gzip.decoder.bind(request) : request,
    );
    final preamble = BytesBuilder(copy: false);
    _PushCommands? commands;
    try {
      while (commands == null &&
          preamble.length < _maxPreambleBytes &&
          await iterator.moveNext()) {
        preamble.add(iterator.current);
        commands = _PushCommands.parse(preamble.toBytes());
      }
      if (commands == null ||
          (commands.refs.isEmpty &&
              (preamble.length != 4 || await iterator.moveNext()))) {
        throw const FormatException('Uninspectable push preamble.');
      }
    } on FormatException {
      // Cancelling unread request bytes can reset the connection before git
      // receives the rejection. Drain them just as for a policy denial.
      while (await iterator.moveNext()) {}
      return _plain(
        request,
        HttpStatus.badRequest,
        'Control Center could not inspect the pushed refs; push blocked.',
      );
    }

    if (commands.refs.isNotEmpty) {
      final refs = [for (final r in commands.refs) _shortRef(r)];
      final summary = 'git push to $owner/$name: ${refs.join(', ')}';
      final pushRequest = ActionRequest(
        classes: const {ActionClass.gitPush},
        refs: refs,
        hosts: [ForgeHost.github.gitHost],
      );
      final verdict =
          await _answeredAtShell(grant, secret, refs, pushRequest, summary)
          ? const GuardVerdict.allow(prompted: true)
          : await _pushVerdict(grant, secret, request, pushRequest, summary);
      if (!verdict.allowed) {
        // Drain what git is still sending before answering, so it reads the
        // rejection instead of a reset connection.
        while (await iterator.moveNext()) {}
        return _rejectPush(
          request,
          commands,
          'Control Center policy: ${verdict.reason ?? 'push denied'}',
        );
      }
    }
    // Only a complete, flush-only request is a ref-free probe. Compressed,
    // malformed or incomplete updates must never become an unchecked probe.

    const write = ForgeTokenScope.write;
    final token = await _token(grant, secret, owner, name, write);
    if (token == null) {
      while (await iterator.moveNext()) {}
      return _rejectPush(
        request,
        commands,
        _tokenRefusal(secret, owner, name, write) ??
            'Control Center has no GitHub credential that can push here.',
      );
    }

    // Every commit and tag the push adds must carry the run's identity: read
    // them all before a byte reaches GitHub.
    final spool = await Directory.systemTemp.createTemp('cc-push-');
    try {
      final spooled = File('${spool.path}/rest');
      // The chunk that completed the commands usually carries the start of
      // the pack too: it is spooled (and inspected) with the rest.
      final head = preamble.takeBytes();
      final commandBytes = head.sublist(0, commands.end);
      final carried = <String>{};
      final builtOn = <String, String>{};
      final problem =
          await _spoolAndInspect(
            head.sublist(commands.end),
            iterator,
            spooled,
            commands,
            grant.identity,
            carried,
            builtOn,
          ) ??
          await _uninspected(commands, carried, builtOn, owner, name, token);
      if (problem != null) {
        return await _rejectPush(request, commands, 'Control Center: $problem');
      }
      _recordPushedBranches(secret, owner, name, commands.newIds);
      return await _forward(
        request,
        _upstream(ForgeHost.github, owner, name, rest),
        token,
        body: _replayFile(commandBytes, spooled),
        decodedBody: compressed,
      );
    } finally {
      try {
        await spool.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
  }

  /// Remembers the branches (and the commits they were set to) a run is
  /// pushing to [owner]/[name], once policy allowed the push and its commits
  /// passed inspection.
  void _recordPushedBranches(
    String secret,
    String owner,
    String name,
    Map<String, String> updates,
  ) {
    if (_grants.containsKey(secret)) {
      _pushedBranches
          .putIfAbsent(secret, () => {})
          .addAll(AgentRunPushedBranch.ofUpdates(owner, name, updates));
    }
  }

  /// Cap on a spooled push body (GitHub refuses pushes over 2 GiB).
  static const int _maxPushBytes = 2 * 1024 * 1024 * 1024;

  /// Writes the rest of the push (push options, then the pack) to [rest] —
  /// [leading], the bytes already read past the commands, first — and checks
  /// every commit and tag in the pack against [identity], adding their ids
  /// to [carried] and what they stand on to [builtOn] (object id → the
  /// carried object naming it). Returns why the push is refused, or null.
  Future<String?> _spoolAndInspect(
    List<int> leading,
    StreamIterator<List<int>> iterator,
    File rest,
    _PushCommands commands,
    AgentCommitIdentity? identity,
    Set<String> carried,
    Map<String, String> builtOn,
  ) async {
    final sink = rest.openWrite();
    var written = leading.length;
    var tooLarge = false;
    sink.add(leading);
    try {
      while (await iterator.moveNext()) {
        written += iterator.current.length;
        if (written > _maxPushBytes) {
          tooLarge = true;
          continue;
        }
        sink.add(iterator.current);
      }
    } finally {
      await sink.close();
    }
    if (tooLarge) {
      return 'this push is too large to inspect.';
    }
    // Push options are a few pkt-lines; the pack signature follows them.
    final handle = await rest.open();
    final List<int> head;
    try {
      head = await handle.read(1 << 20);
    } finally {
      await handle.close();
    }
    final packStart = _packOffset(
      head,
      pushOptions: commands.capabilities.contains('push-options'),
    );
    if (packStart == null) {
      return 'the pushed pack could not be read.';
    }
    if (packStart >= written) {
      return null;
    }
    final pack = File('${rest.path}.pack');
    final source = rest.openRead(packStart);
    await source.pipe(pack.openWrite());
    final List<PushedGitObject> objects;
    try {
      objects = await _inspectPack(pack);
    } on FormatException catch (e) {
      return 'the pushed commits could not be inspected (${e.message}).';
    }
    carried.addAll([for (final o in objects) o.oid.toLowerCase()]);
    for (final o in objects) {
      for (final below in o.buildsOn) {
        builtOn.putIfAbsent(
          below.toLowerCase(),
          () => PushedCommitInspector.at(o),
        );
      }
    }
    if (objects.isEmpty) {
      return null;
    }
    if (identity == null) {
      return 'this run has no commit identity, so it cannot push commits.';
    }
    return PushedCommitInspector.violation(objects, identity);
  }

  /// Where the pack starts in the body that follows the ref updates: right
  /// away, or after a flush-terminated block of push options. Null when the
  /// bytes are neither.
  static int? _packOffset(List<int> head, {required bool pushOptions}) {
    var offset = 0;
    if (pushOptions) {
      while (true) {
        if (offset + 4 > head.length) {
          return head.isEmpty ? 0 : null;
        }
        final length = int.tryParse(
          ascii.decode(head.sublist(offset, offset + 4), allowInvalid: true),
          radix: 16,
        );
        if (length == null || (length > 0 && length < 4)) {
          return null;
        }
        offset += length == 0 ? 4 : length;
        if (length == 0) {
          break;
        }
      }
    }
    if (offset == head.length) {
      return offset;
    }
    if (offset + 4 <= head.length &&
        ascii.decode(head.sublist(offset, offset + 4), allowInvalid: true) ==
            'PACK') {
      return offset;
    }
    return null;
  }

  /// Whether the operator already answered this push's `ask` at the shell
  /// prompt for the command running it, so it is not asked twice.
  ///
  /// Only an ask is answered: a deny still denies. An approval that named its
  /// branches covers pushes to exactly those. One that could not name them
  /// ("destination branch not specified") covers only the general push ask:
  /// a rule on a branch (`main`) still asks, as the operator never saw it.
  Future<bool> _answeredAtShell(
    AgentRunGrant grant,
    String secret,
    List<String> refs,
    ActionRequest request,
    String summary,
  ) async {
    final approval = _shellPushApprovals[secret];
    if (approval == null || !DateTime.now().isBefore(approval.until)) {
      return false;
    }
    final resolution = await _guard.resolve(
      workspaceId: grant.workspaceId,
      classes: const {ActionClass.gitPush},
      spaceId: grant.spaceId,
      agentId: grant.agentId,
      mode: grant.mode,
      request: request,
    );
    if (resolution.decision != ActionDecision.prompt) {
      return false;
    }
    final named = approval.refs;
    final covered = named != null
        ? refs.every(named.contains)
        : resolution.prompting.every((r) => r.rule?.constraint == null);
    if (!covered) {
      return false;
    }
    _guard.recordOutcome(
      workspaceId: grant.workspaceId,
      resolution: resolution,
      applied: ActionDecision.allow,
      classes: const {ActionClass.gitPush},
      agentId: grant.agentId,
      spaceId: grant.spaceId,
      actionSummary: '$summary (approved at the shell prompt)',
      prompted: true,
      onBehalfOfUserId: grant.actingUserId,
      runId: grant.runLogId,
      command: summary,
    );
    return true;
  }

  Future<bool> _mayTouchRepo(
    AgentRunGrant grant,
    String owner,
    String name,
  ) async {
    final check = _repoAllowed;
    if (check != null) {
      return check(grant.workspaceId, owner, name, grant.actingUserId);
    }
    return grant.repoOn(ForgeHost.github, owner, name) != null;
  }

  /// Forwards a push request to GitHub on the write [token] and relays the
  /// answer. [body] replaces the request's own (already read and inspected);
  /// [decodedBody] says it is no longer gzip-encoded.
  Future<void> _forward(
    HttpRequest request,
    Uri upstream,
    String token, {
    Stream<List<int>>? body,
    bool decodedBody = false,
    bool rewriteAdvertisement = false,
  }) async {
    final client = _httpClient();
    try {
      final out = await _openUpstream(
        client,
        request,
        upstream,
        forgeGitBasicAuthorization(ForgeHost.github, token),
        dropContentEncoding: decodedBody,
      );
      if (body != null) {
        out.headers.chunkedTransferEncoding = true;
        await out.addStream(body);
      }
      final response = await out.close();
      if (rewriteAdvertisement && response.statusCode == HttpStatus.ok) {
        final advertised = await response.fold<BytesBuilder>(
          BytesBuilder(copy: false),
          (b, chunk) => b..add(chunk),
        );
        final rewritten = withNoThin(advertised.takeBytes());
        if (rewritten == null) {
          return await _plain(
            request,
            HttpStatus.badGateway,
            'Control Center could not read GitHub\'s ref advertisement.',
          );
        }
        request.response.statusCode = response.statusCode;
        for (final header in const [
          HttpHeaders.contentTypeHeader,
          HttpHeaders.cacheControlHeader,
        ]) {
          final value = response.headers.value(header);
          if (value != null) {
            request.response.headers.set(header, value);
          }
        }
        request.response.add(rewritten);
        await request.response.close();
        return;
      }
      await _relay(request, response, ForgeHost.github);
    } finally {
      client.close();
    }
  }

  /// The upstream URL for [rest] (`info/refs`, `git-upload-pack`,
  /// `git-receive-pack`) of [owner]/[name] on [forge]: the forge's own
  /// constant host, the validated path, always with `.git`, and nothing the
  /// request chose besides.
  Uri _upstream(
    ForgeHost forge,
    String owner,
    String name,
    String rest, {
    String? service,
  }) => (_forgeBases[forge] ?? Uri.parse('https://${forge.gitHost}')).replace(
    path: '/$owner/$name.git/$rest',
    query: service == null ? null : 'service=$service',
  );

  /// Opens [upstream] for [request]'s method with the git headers that
  /// matter copied over, never following a redirect. [authorization] is the
  /// only credential sent, and only when given.
  static Future<HttpClientRequest> _openUpstream(
    HttpClient client,
    HttpRequest request,
    Uri upstream,
    String? authorization, {
    bool dropContentEncoding = false,
  }) async {
    final out = await client.openUrl(request.method, upstream);
    out.followRedirects = false;
    for (final header in const [
      HttpHeaders.contentTypeHeader,
      HttpHeaders.acceptHeader,
      HttpHeaders.contentEncodingHeader,
      HttpHeaders.userAgentHeader,
      'git-protocol',
    ]) {
      if (dropContentEncoding && header == HttpHeaders.contentEncodingHeader) {
        continue;
      }
      final value = request.headers.value(header);
      if (value != null) {
        out.headers.set(header, value);
      }
    }
    if (authorization != null) {
      out.headers.set(HttpHeaders.authorizationHeader, authorization);
    }
    return out;
  }

  /// Streams the forge's [response] back to git: its status, `Content-Type`,
  /// `Cache-Control`, and `Content-Encoding` only while the body is still
  /// encoded (`dart:io` decodes gzip itself and leaves the header in place).
  ///
  /// A redirect is not relayed (git would follow it somewhere this gateway
  /// never checked), and neither is a 401: git would answer it by asking for
  /// a password and sending it here.
  static Future<void> _relay(
    HttpRequest request,
    HttpClientResponse response,
    ForgeHost forge,
  ) async {
    final status = response.statusCode;
    if (status == HttpStatus.unauthorized || (status >= 300 && status < 400)) {
      await response.drain<void>();
      return _plain(
        request,
        status == HttpStatus.unauthorized
            ? HttpStatus.forbidden
            : HttpStatus.badGateway,
        status == HttpStatus.unauthorized
            ? 'Control Center: ${forge.displayName} refused this request '
                  '(HTTP 401).'
            : 'Control Center: ${forge.displayName} answered with a redirect '
                  '(HTTP $status), which Control Center does not follow. If '
                  'the repository moved, link it under its new name.',
      );
    }
    request.response.statusCode = status;
    for (final header in const [
      HttpHeaders.contentTypeHeader,
      HttpHeaders.cacheControlHeader,
    ]) {
      final value = response.headers.value(header);
      if (value != null) {
        request.response.headers.set(header, value);
      }
    }
    final encoding = response.headers.value(HttpHeaders.contentEncodingHeader);
    if (encoding != null &&
        response.compressionState ==
            HttpClientResponseCompressionState.compressed) {
      request.response.headers.set(HttpHeaders.contentEncodingHeader, encoding);
    }
    await request.response.addStream(response);
    await request.response.close();
  }

  /// Answers a push git will understand as a rejection: `report-status` with
  /// every ref `ng`, wrapped in side-band when git asked for it, plus a
  /// progress line so the reason is printed even by a client that does not
  /// show per-ref reasons.
  Future<void> _rejectPush(
    HttpRequest request,
    _PushCommands commands,
    String reason,
  ) async {
    final oneLine = reason.replaceAll('\n', ' ');
    final report = BytesBuilder(copy: false)..add(_pkt('unpack ok\n'));
    for (final ref in commands.refs) {
      report.add(_pkt('ng $ref $oneLine\n'));
    }
    report.add(utf8.encode('0000'));
    final reportBytes = report.takeBytes();

    final out = BytesBuilder(copy: false);
    final sideband = commands.capabilities.contains('side-band-64k')
        ? 65515
        : commands.capabilities.contains('side-band')
        ? 995
        : null;
    if (sideband != null) {
      out.add(_pktBytes([2, ...utf8.encode('$oneLine\n')]));
      for (var i = 0; i < reportBytes.length; i += sideband) {
        final end = min(i + sideband, reportBytes.length);
        out.add(_pktBytes([1, ...reportBytes.sublist(i, end)]));
      }
      out.add(utf8.encode('0000'));
    } else {
      out.add(reportBytes);
    }
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-git-receive-pack-result',
      )
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..add(out.takeBytes());
    await request.response.close();
  }

  // ---------------------------------------------------------------------------
  // Helpers

  static String _shortRef(String ref) =>
      ref.startsWith('refs/heads/') ? ref.substring('refs/heads/'.length) : ref;

  static Stream<List<int>> _replayFile(List<int> head, File rest) async* {
    if (head.isNotEmpty) {
      yield head;
    }
    yield* rest.openRead();
  }

  /// [advertisement] (a receive-pack ref advertisement) with `no-thin` added
  /// to the capabilities on its first ref line, or null when it is not one.
  ///
  /// A client must not send a thin pack to a server advertising `no-thin`, so
  /// every object a push names arrives in its own pack and can be read.
  /// Public for tests.
  static List<int>? withNoThin(List<int> advertisement) {
    final out = BytesBuilder(copy: false);
    var offset = 0;
    var rewritten = false;
    while (offset + 4 <= advertisement.length) {
      final length = int.tryParse(
        ascii.decode(
          advertisement.sublist(offset, offset + 4),
          allowInvalid: true,
        ),
        radix: 16,
      );
      if (length == null || (length > 0 && length < 4)) {
        return null;
      }
      if (length == 0) {
        out.add(advertisement.sublist(offset, offset + 4));
        offset += 4;
        continue;
      }
      if (offset + length > advertisement.length) {
        return null;
      }
      final payload = advertisement.sublist(offset + 4, offset + length);
      final nul = payload.indexOf(0);
      if (!rewritten && nul >= 0) {
        final tail = payload.sublist(nul + 1);
        final newline = tail.isNotEmpty && tail.last == 0x0a;
        final caps = utf8
            .decode(newline ? tail.sublist(0, tail.length - 1) : tail)
            .split(' ')
            .where((c) => c.isNotEmpty)
            .toList();
        if (!caps.contains('no-thin')) {
          caps.add('no-thin');
        }
        out.add(
          _pktBytes([
            ...payload.sublist(0, nul + 1),
            ...utf8.encode(caps.join(' ')),
            if (newline) 0x0a,
          ]),
        );
        rewritten = true;
      } else {
        out.add(advertisement.sublist(offset, offset + length));
      }
      offset += length;
    }
    if (offset != advertisement.length || !rewritten) {
      return null;
    }
    return out.takeBytes();
  }

  static List<int> _pkt(String line) => _pktBytes(utf8.encode(line));

  static List<int> _pktBytes(List<int> payload) => [
    ...ascii.encode((payload.length + 4).toRadixString(16).padLeft(4, '0')),
    ...payload,
  ];

  static Object? _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static Future<List<int>?> _readCapped(HttpRequest request, int max) async {
    if (request.contentLength > max) {
      return null;
    }
    final out = BytesBuilder(copy: false);
    await for (final chunk in request) {
      out.add(chunk);
      if (out.length > max) {
        return null;
      }
    }
    return out.takeBytes();
  }

  static Future<void> _plain(
    HttpRequest request,
    int status,
    String message,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..write('$message\n');
    await request.response.close();
  }
}
