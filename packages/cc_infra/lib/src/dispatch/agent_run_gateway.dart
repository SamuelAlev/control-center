import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/host_commit_signer.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

part 'agent_run_git_objects.dart';
part 'agent_run_native_tools.dart';

/// Who a registered agent run is, as the action policy needs to know it.
class AgentRunGrant {
  /// Creates an [AgentRunGrant].
  const AgentRunGrant({
    required this.workspaceId,
    required this.conversationId,
    this.agentId,
    this.spaceId,
    this.mode = Mode.chat,
    this.actingUserId,
    this.runId,
    this.repoOwner,
    this.repoName,
    this.identity,
    this.worktreeRoot,
    this.runnerStateDirs = const [],
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

  /// The member the run acts for; bounds the forge credential to their reach.
  final String? actingUserId;

  /// The dispatch id, threaded into the audit trail.
  final String? runId;

  /// The worktree's own GitHub repo, when it has one. A push there needs no
  /// further repo check.
  final String? repoOwner;

  /// See [repoOwner].
  final String? repoName;

  /// Who the run's commits name and whether the host key may sign them.
  /// Every pushed commit must match it and the host signs only objects
  /// committed as it; null pushes no commits and signs nothing.
  final AgentCommitIdentity? identity;

  /// The run's working tree. A native write inside it is the agent's own work.
  final String? worktreeRoot;

  /// Directories the runner keeps its own state in, such as a Claude account's
  /// config dir. Plan mode writes its plan file there.
  final List<String> runnerStateDirs;
}

/// A registered run's handle on the gateway: what to put in its environment
/// and how to point Claude Code's hooks at it.
class AgentRunLease {
  AgentRunLease._(
    this.secret,
    this.base, {
    this.repoOwner,
    this.repoName,
    this.mayHostSign = false,
  });

  /// Env var carrying [secret] to the agent process.
  static const String tokenEnvKey = 'CC_AGENT_RUN_TOKEN';

  /// Header the gateway authenticates a run by.
  static const String tokenHeader = McpCallScope.runGrantHeader;

  /// Env var carrying [base] to the agent process, for the sandbox's signing
  /// shim (`MacosSandbox.sshSignShim`).
  static const String gatewayEnvKey = 'CC_AGENT_GATEWAY';

  /// Path a run posts a git object to for the host to sign.
  static const String signPath = '/agent/git-sign';

  /// Env var carrying the run's forge token, which fetches authenticate with.
  static const String forgeTokenEnvKey = 'GH_TOKEN';

  /// Answers git's `get` from [forgeTokenEnvKey], so the token stays out of
  /// URLs, argv and config. Does nothing for `store` and `erase`.
  static const String _fetchCredentialHelper =
      '!f() { if test "\$1" = get && test -n "\$$forgeTokenEnvKey"; then '
      'echo username=x-access-token; '
      "printf 'password=%s\\n' \"\$$forgeTokenEnvKey\"; fi; }; f";

  /// What an owner or repo name may contain before it enters a git config key.
  static final RegExp _repoPathPart = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.-]*$');

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

  /// The worktree's own GitHub repo, when it has one: the only repo the run's
  /// token fetches.
  final String? repoOwner;

  /// See [repoOwner].
  final String? repoName;

  /// Whether the run's commits may be signed with the host key. When not,
  /// [gitConfig] turns signing off and points every signer at `false`.
  final bool mayHostSign;

  String get _gitBase => '$base/agent/git/';

  /// `git -c` pairs that keep a run that may not use the host key from
  /// signing at all. The user's global `commit.gpgsign` would otherwise make
  /// every commit fail, and an explicit `-S` still reaches nothing that signs.
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
    ('http.$_gitBase.extraHeader', '$tokenHeader: $secret'),
    if (!mayHostSign) ...unsignedGitConfig,
  ];

  /// `git -c` pairs that let the run fetch its own repo with its forge token.
  ///
  /// A sandbox never reaches the user's SSH agent or `~/.ssh`, so an SSH origin
  /// cannot fetch. These move the run's own repo to HTTPS, where GitHub enforces
  /// the token's scope and the sandbox's egress rules still apply. Pushes are
  /// unaffected: [gitConfig]'s `pushInsteadOf` matches the original URL first.
  ///
  /// The rewrites name the repo so they outrank a user's global
  /// `https://github.com/` rewrite to SSH: git takes the longest match. They
  /// are prefix matches, so a sibling (`widgets-extra`) moves to HTTPS too. The
  /// helper is what stays exact: its config matches on path segments, so the
  /// token is offered for this repo and paths under it, which on GitHub are
  /// the same repo. The empty entry clears the user's helpers, which keeps the
  /// token out of their keychain.
  List<(String, String)> get fetchGitConfig {
    final owner = repoOwner;
    final name = repoName;
    if (owner == null ||
        name == null ||
        !_repoPathPart.hasMatch(owner) ||
        !_repoPathPart.hasMatch(name)) {
      return const [];
    }
    final repo = 'https://github.com/$owner/$name';
    return [
      for (final origin in [
        'git@github.com:$owner/$name',
        'ssh://git@github.com/$owner/$name',
        repo,
      ])
        ('url.$repo.insteadOf', origin),
      for (final url in [repo, '$repo.git']) ...[
        ('credential.$url.helper', ''),
        ('credential.$url.helper', _fetchCredentialHelper),
      ],
    ];
  }

  /// Environment for the agent process: the secret plus [gitConfig] appended
  /// to whatever `GIT_CONFIG_*` entries [env] already carries, and
  /// [fetchGitConfig] when [env] holds a forge token to fetch with. Without
  /// one, the run's origin is left as it is.
  Map<String, String> environment(Map<String, String> env) {
    final out = <String, String>{tokenEnvKey: secret, gatewayEnvKey: '$base'};
    var count = int.tryParse(env['GIT_CONFIG_COUNT'] ?? '') ?? 0;
    final hasForgeToken = env[forgeTokenEnvKey]?.isNotEmpty ?? false;
    for (final (key, value) in [
      ...gitConfig,
      if (hasForgeToken) ...fetchGitConfig,
    ]) {
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

  /// Claude's command hook blocks with exit 2 unless the gateway explicitly
  /// allows the call. HTTP hooks fail open on transport errors; curl has its
  /// own deadline inside the hook timeout so those errors instead deny.
  ///
  /// A missing lease installs a blocking hook, never an unguarded Bash tool.
  /// Only Bash: the file and web tools stay usable, because the OS sandbox
  /// bounds them without help from the gateway and Bash it cannot.
  static String claudeHookSettings(AgentRunLease? lease) {
    final command = lease == null
        ? "printf '%s\\n' 'Control Center permission gateway is unavailable.' >&2; exit 2"
        : '''
if verdict=\$(curl --disable --silent --show-error --fail --noproxy '*' \\
  --connect-timeout 5 --max-time ${AgentRunGateway.hookTransportDeadline.inSeconds} \\
  --header "$tokenHeader: \$$tokenEnvKey" \\
  --header 'Content-Type: application/json' --data-binary @- \\
  '${lease.base}/agent/hooks/pre-tool-use'); then
  if [ "\$verdict" = allow ]; then exit 0; fi
  printf '%s\\n' "\$verdict" >&2
else
  printf '%s\\n' 'Control Center permission check failed; command blocked.' >&2
fi
exit 2
''';
    return jsonEncode({
      'disableAllHooks': false,
      'hooks': {
        'PreToolUse': [
          {
            'matcher': lease == null ? 'Bash' : guardedClaudeTools,
            'hooks': [
              {
                'type': 'command',
                'command': command,
                'timeout': AgentRunGateway.hookTimeout.inSeconds,
              },
            ],
          },
        ],
      },
    });
  }
}

/// The host side of the action policy for code running inside an agent's
/// sandbox: a push proxy and a Claude Code hook endpoint, served on the same
/// loopback listener agents already dial for MCP.
///
/// **Push proxy.** Conventional push URLs route here. The gateway reads the
/// ref updates, asks policy with the actual refs, then forwards using a
/// server-held write credential: the run's own token is read-only.
///
/// **Commit signing.** The sandbox cannot reach the user's SSH agent, so its
/// signing shim posts the commit or tag object here and the host signs it
/// with the user's own signer ([CommitSigner]). Only the object crosses: the
/// key, the program and the `git` namespace are the host's choice. The key is
/// the machine owner's, so only runs acting for the owner may use it, and only
/// for objects whose committer (or tagger) is the run's own identity.
///
/// **Shell commands (soft).** Claude Code runs its own `Bash` tool; the
/// PreToolUse hook posts each command here, the [ShellActionClassifier] names
/// the rules it falls under (`gh pr create` → "Open a pull request"), and the
/// answer comes back as the hook's allow/deny.
///
/// Every request is authenticated by a per-run secret ([AgentRunLease]) and
/// every scope comes from the registered [AgentRunGrant] — never from the
/// request — so one run cannot ask with another's identity.
class AgentRunGateway {
  /// Creates an [AgentRunGateway].
  ///
  /// The loopback-base resolver says where runs reach this gateway (the MCP
  /// loopback listener); null means it is not being served, and runs then get
  /// no lease. The repo check decides whether a run may push to a repo other
  /// than its own worktree's — normally "is it linked to the workspace".
  AgentRunGateway({
    required this._guard,
    required this._broker,
    required this._loopbackBase,
    this._repoAllowed,
    HttpClient Function()? httpClient,
    Uri? githubBase,
    this._mayUseHostSigner,
    CommitSigner? signer,
    Future<List<PushedGitObject>> Function(File pack)? inspectPack,
  }) : _httpClient = httpClient ?? HttpClient.new,
       _githubBase = githubBase ?? Uri.parse('https://github.com'),
       _signer = signer ?? HostCommitSigner(),
       _inspectPack = inspectPack ?? PushedCommitInspector.inspect;

  /// How long Claude Code waits on the hook. Generous, because "ask first"
  /// waits on a human.
  static const Duration hookTimeout = Duration(hours: 1);

  /// When the gateway stops waiting for a human and denies. This expires
  /// before curl's deadline, which itself expires before Claude's hook timeout.
  static const Duration hookDecisionDeadline = Duration(minutes: 55);

  /// The hook's HTTP client must exit with a blocking result before Claude
  /// times out the command hook (a timeout is not an authorization decision).
  static const Duration hookTransportDeadline = Duration(minutes: 56);

  /// How long an operator's "yes" to a pushing shell command also answers the
  /// push gateway's own ask for that run, so one push is one prompt. Long
  /// enough for a command that builds or tests before it pushes.
  static const Duration shellPushApprovalWindow = Duration(minutes: 15);

  /// Cap on the ref-update preamble read before a push is decided. The
  /// commands are a few hundred bytes; anything this large is not a push.
  static const int _maxPreambleBytes = 1024 * 1024;

  /// Cap on a hook request body. Generous because a `Write` carries the whole
  /// file: refusing a large one here would block work no rule objected to.
  static const int _maxHookBodyBytes = 32 * 1024 * 1024;

  /// Cap on a git object posted for signing.
  static const int _maxSignBodyBytes = 8 * 1024 * 1024;

  /// The signing shim's HTTP deadline: past the signer's own, so a slow
  /// approval comes back as the signer's reason rather than a cut connection.
  static const Duration signTransportDeadline = Duration(minutes: 6);

  final ActionGuardService _guard;
  final CredentialBrokerPort _broker;
  final Future<Uri?> Function() _loopbackBase;
  final Future<bool> Function(String workspaceId, String owner, String name)?
  _repoAllowed;
  final HttpClient Function() _httpClient;
  final Uri _githubBase;
  final CommitSigner _signer;

  /// Reads the commits and tags out of a pushed pack.
  final Future<List<PushedGitObject>> Function(File pack) _inspectPack;

  /// Whether a run acting for this member (null: programmatic dispatch) may
  /// sign with the host's key. Null refuses every run.
  final Future<bool> Function(String? actingUserId)? _mayUseHostSigner;

  /// Signatures run one at a time: each may wait on a human at the SSH agent,
  /// and parallel prompts from one machine invite approving the wrong one.
  Future<void> _signing = Future.value();

  final Map<String, AgentRunGrant> _grants = {};

  /// secret → the pushing shell command the operator last approved.
  final Map<String, _ShellPushApproval> _shellPushApprovals = {};

  /// secret → minted write credentials per `owner/name`, revoked on [close].
  final Map<String, Map<String, ScopedCredentials>> _writeTokens = {};

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
    _grants[secret] = grant;
    return AgentRunLease._(
      secret,
      base,
      repoOwner: grant.repoOwner,
      repoName: grant.repoName,
      mayHostSign: grant.identity?.mayHostSign ?? false,
    );
  }

  /// The MCP scope [secret] proves, or null when it names no open run.
  McpCallScope? mcpScopeFor(String secret) {
    final grant = _grants[secret];
    return grant == null
        ? null
        : McpCallScope(
            workspaceId: grant.workspaceId,
            agentId: grant.agentId,
            conversationId: grant.conversationId,
            spaceId: grant.spaceId,
            attested: true,
          );
  }

  /// Forgets a run and revokes every write token minted for it.
  Future<void> close(AgentRunLease? lease) async {
    if (lease == null) {
      return;
    }
    _grants.remove(lease.secret);
    _shellPushApprovals.remove(lease.secret);
    final minted = _writeTokens.remove(lease.secret);
    for (final credentials in minted?.values ?? const <ScopedCredentials>[]) {
      try {
        await _broker.revoke(credentials.handle);
      } on Object catch (e) {
        CcInfraLog.warning('agent gateway: revoke failed: $e');
      }
    }
  }

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
      if (path == '/agent/hooks/pre-tool-use' && request.method == 'POST') {
        return await _preToolUse(request, grant, secret);
      }
      if (path == AgentRunLease.signPath && request.method == 'POST') {
        return await _sign(request, grant);
      }
      if (path.startsWith('/agent/git/github.com/')) {
        return await _git(request, grant, secret);
      }
      if (path == envPath && request.method == 'POST') {
        return await _environmentCommand(request, grant);
      }
      return await _plain(request, HttpStatus.notFound, 'Not found.');
    } on Object catch (e, st) {
      CcInfraLog.warning('agent gateway: $path failed: $e\n$st');
      try {
        return await _plain(
          request,
          HttpStatus.internalServerError,
          'The Control Center gateway failed: $e',
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

  Future<void> _environmentCommand(
    HttpRequest request,
    AgentRunGrant grant,
  ) async {
    final environments = this.environments;
    final spaceId = grant.spaceId;
    final tool = request.headers.value('X-CC-Env-Tool');
    if (environments == null || spaceId == null || tool == null) {
      return _plain(
        request,
        HttpStatus.notFound,
        'This run has no environment.',
      );
    }
    final body = await _readCapped(request, _maxEnvBodyBytes);
    if (body == null) {
      return _plain(
        request,
        HttpStatus.requestEntityTooLarge,
        'Command too long.',
      );
    }
    final text = utf8.decode(body, allowMalformed: true);
    final arguments = text.isEmpty
        ? const <String>[]
        : (text.split('\u0000')..removeLast());
    final result = await environments.handle(
      AgentEnvironmentCaller(
        workspaceId: grant.workspaceId,
        spaceId: spaceId,
        conversationId: grant.conversationId,
        runId: grant.runId,
        agentId: grant.agentId,
        mode: grant.mode,
        actingUserId: grant.actingUserId,
      ),
      tool,
      arguments,
    );
    final stderr = utf8.encode(result.stderr);
    // Headers are bounded, and stderr's tail is the useful part.
    final tail = stderr.length > _maxEnvStderrBytes
        ? stderr.sublist(stderr.length - _maxEnvStderrBytes)
        : stderr;
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.set('X-CC-Exit-Code', '${result.exitCode}')
      ..headers.set('X-CC-Stderr', base64.encode(tail))
      ..headers.contentType = ContentType.text
      ..write(result.stdout);
    await request.response.close();
  }

  static const int _maxEnvBodyBytes = 1024 * 1024;
  static const int _maxEnvStderrBytes = 6 * 1024;

  // ---------------------------------------------------------------------------
  // Claude Code PreToolUse hook

  Future<void> _preToolUse(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final body = await _readCapped(request, _maxHookBodyBytes);
    final decoded = body == null ? null : _tryJson(utf8.decode(body));
    final input = decoded is Map ? decoded['tool_input'] : null;
    if (decoded is Map && input is Map && decoded['tool_name'] != 'Bash') {
      return _nativeToolDecision(
        request,
        grant,
        _NativeToolAction.of(decoded['tool_name'], input, grant),
      );
    }
    final command = input is Map ? input['command'] : null;
    if (decoded is! Map ||
        decoded['tool_name'] != 'Bash' ||
        command is! String ||
        command.trim().isEmpty) {
      return _hookDecision(
        request,
        allowed: false,
        reason: 'Control Center: invalid Bash permission request.',
      );
    }

    // The transcript labels a Bash row with its `description`; Claude Code
    // leaves it optional. Refused before the policy check so a call that will
    // be retried never raises an approval. See
    // `ClaudeCliBackend.bashDescriptionInstruction`.
    final description = input is Map ? input['description'] : null;
    if (description is! String || description.trim().isEmpty) {
      return _hookDecision(
        request,
        allowed: false,
        reason:
            'Missing argument: description. Retry with a clear, concise '
            '5-10 word description of what this command does.',
      );
    }

    final classes = const ShellActionClassifier().classify(command);
    // Named branches let branch rules (and branch-scoped standing approvals)
    // decide here instead of asking about an unknown destination.
    final pushRefs = classes.contains(ActionClass.gitPush)
        ? ShellActionClassifier.pushRefs(command)
        : null;
    // `processSpawn` is deliberately NOT declared: Claude Code's plan mode is
    // read-only by its own rules and still runs `git diff`, and the read-only
    // mode profiles deny `processSpawn` wholesale. What the command DOES is
    // what the operator's rules are about.
    final verdict = await _guard
        .check(
          workspaceId: grant.workspaceId,
          classes: classes,
          command: command,
          spaceId: grant.spaceId,
          conversationId: grant.conversationId,
          agentId: grant.agentId,
          mode: grant.mode,
          actionSummary: 'bash: $command',
          approvalRationale: description,
          onBehalfOfUserId: grant.actingUserId,
          runId: grant.runId,
          request: ActionRequest(
            classes: classes,
            command: command,
            refs: pushRefs ?? const [],
          ),
        )
        .timeout(
          hookDecisionDeadline,
          onTimeout: () =>
              const GuardVerdict.deny('Nobody answered the approval in time.'),
        );
    if (verdict.allowed &&
        verdict.prompted &&
        classes.contains(ActionClass.gitPush)) {
      _shellPushApprovals[secret] = _ShellPushApproval(
        refs: pushRefs,
        until: DateTime.now().add(shellPushApprovalWindow),
      );
    }
    return _hookDecision(
      request,
      allowed: verdict.allowed,
      reason: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  /// The policy's answer for one of Claude Code's own file or web tools. Null
  /// [action] is a request this hook cannot read, which is refused.
  Future<void> _nativeToolDecision(
    HttpRequest request,
    AgentRunGrant grant,
    _NativeToolAction? action,
  ) async {
    if (action == null) {
      return _hookDecision(
        request,
        allowed: false,
        reason: 'Control Center: invalid tool permission request.',
      );
    }
    final verdict = await _guard
        .check(
          workspaceId: grant.workspaceId,
          classes: action.request.classes,
          spaceId: grant.spaceId,
          conversationId: grant.conversationId,
          agentId: grant.agentId,
          mode: grant.mode,
          actionSummary: action.summary,
          onBehalfOfUserId: grant.actingUserId,
          runId: grant.runId,
          request: action.request,
        )
        .timeout(
          hookDecisionDeadline,
          onTimeout: () =>
              const GuardVerdict.deny('Nobody answered the approval in time.'),
        );
    return _hookDecision(
      request,
      allowed: verdict.allowed,
      reason: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  /// Only the exact `allow` response lets the command hook exit successfully.
  Future<void> _hookDecision(
    HttpRequest request, {
    required bool allowed,
    required String reason,
  }) async {
    return _plain(request, HttpStatus.ok, allowed ? 'allow' : reason);
  }

  // ---------------------------------------------------------------------------
  // Commit signing

  /// Signs a commit or tag object with the host user's signer.
  ///
  /// Refused unless every check passes, before the signer is ever started:
  /// the body is a well-formed, unsigned commit or tag; the run acts for the
  /// machine owner; the object is committed (tagged) as the run's own
  /// identity; and the "Create a commit" rule does not deny (read-only modes
  /// included). Creating the commit was already governed by the shell hook or
  /// harness gate, so an "ask" rule is not asked a second time here.
  Future<void> _sign(HttpRequest request, AgentRunGrant grant) async {
    final payload = await _readCapped(request, _maxSignBodyBytes);
    if (payload == null) {
      return _plain(
        request,
        HttpStatus.requestEntityTooLarge,
        'Control Center: this object is too large to sign.',
      );
    }
    final object = SignableGitObject.parse(payload);
    if (object == null) {
      return _plain(
        request,
        HttpStatus.badRequest,
        'Control Center only signs well-formed, unsigned git commits and tags.',
      );
    }
    final identity = grant.identity;
    final mayUse = _mayUseHostSigner;
    if (identity == null ||
        !identity.mayHostSign ||
        mayUse == null ||
        !await mayUse(grant.actingUserId)) {
      return _plain(
        request,
        HttpStatus.forbidden,
        "Control Center signs only runs the machine's owner asked for, and "
        'this one is not. Commit unsigned (git commit --no-gpg-sign).',
      );
    }
    final expected = identity.committerEmail.trim().toLowerCase();
    if (object.signerEmail.toLowerCase() != expected) {
      return _plain(
        request,
        HttpStatus.forbidden,
        'Control Center signs only as this run '
        '(${identity.committerEmail}); this ${object.kind} '
        'names ${object.signerEmail}.',
      );
    }
    final classes = {ActionClass.gitCommit};
    final resolution = await _guard.resolve(
      workspaceId: grant.workspaceId,
      classes: classes,
      spaceId: grant.spaceId,
      agentId: grant.agentId,
      mode: grant.mode,
    );
    final denied = resolution.decision == ActionDecision.deny;
    _guard.recordOutcome(
      workspaceId: grant.workspaceId,
      resolution: resolution,
      applied: denied ? ActionDecision.deny : ActionDecision.allow,
      classes: classes,
      agentId: grant.agentId,
      spaceId: grant.spaceId,
      actionSummary: 'sign git ${object.kind}',
      onBehalfOfUserId: grant.actingUserId,
      runId: grant.runId,
    );
    if (denied) {
      return _plain(
        request,
        HttpStatus.forbidden,
        'Control Center policy: ${resolution.driving.reason}',
      );
    }
    final done = Completer<void>();
    final previous = _signing;
    _signing = done.future;
    try {
      await previous;
      final signature = await _signer.sign(payload);
      return await _plain(request, HttpStatus.ok, signature.trimRight());
    } on CommitSigningException catch (e) {
      return _plain(request, HttpStatus.badGateway, e.message);
    } finally {
      done.complete();
    }
  }

  // ---------------------------------------------------------------------------
  // Push proxy

  Future<void> _git(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    // /agent/git/github.com/<owner>/<repo>[.git]/<rest>
    final segments = request.uri.pathSegments;
    if (segments.length < 6) {
      return _plain(request, HttpStatus.notFound, 'Not a repository path.');
    }
    final owner = segments[3];
    final repoSegment = segments[4];
    final name = repoSegment.endsWith('.git')
        ? repoSegment.substring(0, repoSegment.length - 4)
        : repoSegment;
    final rest = segments.sublist(5).join('/');
    final service = request.uri.queryParameters['service'];

    final isAdvertisement =
        request.method == 'GET' &&
        rest == 'info/refs' &&
        service == 'git-receive-pack';
    final isPush = request.method == 'POST' && rest == 'git-receive-pack';
    if (!isAdvertisement && !isPush) {
      // Only pushes are rewritten here; anything else did not come from git's
      // push path and is not something this gateway forwards.
      return _plain(
        request,
        HttpStatus.forbidden,
        'Control Center only proxies pushes.',
      );
    }

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
          runId: grant.runId,
        );
        return _plain(
          request,
          HttpStatus.forbidden,
          'Control Center policy: ${resolution.driving.reason}',
        );
      }
      final token = await _writeToken(grant, secret, owner, name);
      if (token == null) {
        return _plain(
          request,
          HttpStatus.serviceUnavailable,
          'Control Center has no GitHub credential that can push to '
          '$owner/$name. Install the GitHub App on it or connect GitHub.',
        );
      }
      // `no-thin`: the push that follows must carry every object it names, or
      // its commits could not be read before they are forwarded.
      return _forward(
        request,
        owner,
        repoSegment,
        rest,
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
        hosts: [_githubBase.host],
      );
      final verdict =
          await _answeredAtShell(grant, secret, refs, pushRequest, summary)
          ? const GuardVerdict.allow(prompted: true)
          : await _guard.check(
              workspaceId: grant.workspaceId,
              classes: const {ActionClass.gitPush},
              spaceId: grant.spaceId,
              conversationId: grant.conversationId,
              agentId: grant.agentId,
              mode: grant.mode,
              actionSummary: summary,
              onBehalfOfUserId: grant.actingUserId,
              runId: grant.runId,
              request: pushRequest,
            );
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

    final token = await _writeToken(grant, secret, owner, name);
    if (token == null) {
      while (await iterator.moveNext()) {}
      return _rejectPush(
        request,
        commands,
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
      final problem = await _spoolAndInspect(
        head.sublist(commands.end),
        iterator,
        spooled,
        commands,
        grant.identity,
      );
      if (problem != null) {
        return await _rejectPush(request, commands, 'Control Center: $problem');
      }
      return await _forward(
        request,
        owner,
        repoSegment,
        rest,
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

  /// Cap on a spooled push body (GitHub refuses pushes over 2 GiB).
  static const int _maxPushBytes = 2 * 1024 * 1024 * 1024;

  /// Writes the rest of the push (push options, then the pack) to [rest] —
  /// [leading], the bytes already read past the commands, first — and checks
  /// every commit and tag in the pack against [identity]. Returns why the
  /// push is refused, or null.
  Future<String?> _spoolAndInspect(
    List<int> leading,
    StreamIterator<List<int>> iterator,
    File rest,
    _PushCommands commands,
    AgentCommitIdentity? identity,
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
  /// ("destination branch not specified") covers only the general push ask —
  /// a branch-specific rule (e.g. "ask before pushing to `main`") still asks,
  /// because the operator never saw that branch.
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
      runId: grant.runId,
    );
    return true;
  }

  Future<bool> _mayTouchRepo(
    AgentRunGrant grant,
    String owner,
    String name,
  ) async {
    final own = grant.repoOwner;
    if (own != null &&
        own.toLowerCase() == owner.toLowerCase() &&
        grant.repoName?.toLowerCase() == name.toLowerCase()) {
      return true;
    }
    final check = _repoAllowed;
    return check != null && await check(grant.workspaceId, owner, name);
  }

  Future<String?> _writeToken(
    AgentRunGrant grant,
    String secret,
    String owner,
    String name,
  ) async {
    final key = '${owner.toLowerCase()}/${name.toLowerCase()}';
    final cache = _writeTokens.putIfAbsent(secret, () => {});
    final cached = cache[key];
    final expiresAt = cached?.expiresAt;
    if (cached != null &&
        (expiresAt == null ||
            expiresAt.isAfter(
              DateTime.now().add(const Duration(minutes: 5)),
            ))) {
      return cached.environment['GH_TOKEN'];
    }
    final minted = await _broker.mint(
      conversationId: grant.conversationId,
      scope: ForgeTokenScope.write,
      repoOwner: owner,
      repoName: name,
      actingUserId: grant.actingUserId,
      workspaceId: grant.workspaceId,
    );
    final token = minted.environment['GH_TOKEN'];
    if (token == null || token.isEmpty) {
      await _broker.revoke(minted.handle);
      return null;
    }
    if (cached != null) {
      unawaited(_broker.revoke(cached.handle));
    }
    cache[key] = minted;
    return token;
  }

  Future<void> _forward(
    HttpRequest request,
    String owner,
    String repoSegment,
    String rest,
    String token, {
    Stream<List<int>>? body,
    bool decodedBody = false,
    bool rewriteAdvertisement = false,
  }) async {
    final upstream = _githubBase.replace(
      path: '/$owner/$repoSegment/$rest',
      query: request.uri.query.isEmpty ? null : request.uri.query,
    );
    final client = _httpClient();
    try {
      final out = await client.openUrl(request.method, upstream);
      out.followRedirects = false;
      for (final header in const [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.acceptHeader,
        HttpHeaders.contentEncodingHeader,
        HttpHeaders.userAgentHeader,
        'git-protocol',
      ]) {
        if (decodedBody && header == HttpHeaders.contentEncodingHeader) {
          continue;
        }
        final value = request.headers.value(header);
        if (value != null) {
          out.headers.set(header, value);
        }
      }
      out.headers.set(
        HttpHeaders.authorizationHeader,
        'Basic ${base64.encode(utf8.encode('x-access-token:$token'))}',
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
      request.response.statusCode = response.statusCode;
      for (final header in const [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.cacheControlHeader,
        HttpHeaders.contentEncodingHeader,
      ]) {
        final value = response.headers.value(header);
        if (value != null) {
          request.response.headers.set(header, value);
        }
      }
      await request.response.addStream(response);
      await request.response.close();
    } finally {
      client.close();
    }
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
