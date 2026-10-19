import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/log/cc_infra_log.dart';

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
}

/// A registered run's handle on the gateway: what to put in its environment
/// and how to point Claude Code's hooks at it.
class AgentRunLease {
  AgentRunLease._(this.secret, this.base);

  /// Env var carrying [secret] to the agent process.
  static const String tokenEnvKey = 'CC_AGENT_RUN_TOKEN';

  /// Header the gateway authenticates a run by.
  static const String tokenHeader = 'X-CC-Agent-Run';

  /// The per-run secret. Knowing it lets a process ASK the gateway on the
  /// run's behalf — every answer still comes from the action policy.
  final String secret;

  /// Loopback base the run reaches the gateway at (`http://127.0.0.1:<port>`).
  final Uri base;

  String get _gitBase => '$base/agent/git/';

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
  ];

  /// Environment for the agent process: the secret plus [gitConfig] appended
  /// to whatever `GIT_CONFIG_*` entries [env] already carries.
  Map<String, String> environment(Map<String, String> env) {
    final out = <String, String>{tokenEnvKey: secret};
    var count = int.tryParse(env['GIT_CONFIG_COUNT'] ?? '') ?? 0;
    for (final (key, value) in gitConfig) {
      out['GIT_CONFIG_KEY_$count'] = key;
      out['GIT_CONFIG_VALUE_$count'] = value;
      count++;
    }
    out['GIT_CONFIG_COUNT'] = '$count';
    return out;
  }

  /// Claude's command hook blocks with exit 2 unless the gateway explicitly
  /// allows the call. HTTP hooks fail open on transport errors; curl has its
  /// own deadline inside the hook timeout so those errors instead deny.
  ///
  /// A missing lease installs a blocking hook, never an unguarded Bash tool.
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
            'matcher': 'Bash',
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
/// server-held write credential. A GitHub App read token cannot push directly;
/// an unnarrowable fallback PAT can, so shell preflight must gate pushes too.
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
  }) : _httpClient = httpClient ?? HttpClient.new,
       _githubBase = githubBase ?? Uri.parse('https://github.com');

  /// How long Claude Code waits on the hook. Generous, because "ask first"
  /// waits on a human.
  static const Duration hookTimeout = Duration(hours: 1);

  /// When the gateway stops waiting for a human and denies. This expires
  /// before curl's deadline, which itself expires before Claude's hook timeout.
  static const Duration hookDecisionDeadline = Duration(minutes: 55);

  /// The hook's HTTP client must exit with a blocking result before Claude
  /// times out the command hook (a timeout is not an authorization decision).
  static const Duration hookTransportDeadline = Duration(minutes: 56);

  /// Cap on the ref-update preamble read before a push is decided. The
  /// commands are a few hundred bytes; anything this large is not a push.
  static const int _maxPreambleBytes = 1024 * 1024;

  /// Cap on a hook request body.
  static const int _maxHookBodyBytes = 1024 * 1024;

  final ActionGuardService _guard;
  final CredentialBrokerPort _broker;
  final Future<Uri?> Function() _loopbackBase;
  final Future<bool> Function(String workspaceId, String owner, String name)?
  _repoAllowed;
  final HttpClient Function() _httpClient;
  final Uri _githubBase;

  final Map<String, AgentRunGrant> _grants = {};

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
    return AgentRunLease._(secret, base);
  }

  /// Forgets a run and revokes every write token minted for it.
  Future<void> close(AgentRunLease? lease) async {
    if (lease == null) {
      return;
    }
    _grants.remove(lease.secret);
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
        return await _preToolUse(request, grant);
      }
      if (path.startsWith('/agent/git/github.com/')) {
        return await _git(request, grant, secret);
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
  // Claude Code PreToolUse hook

  Future<void> _preToolUse(HttpRequest request, AgentRunGrant grant) async {
    final body = await _readCapped(request, _maxHookBodyBytes);
    final decoded = body == null ? null : _tryJson(utf8.decode(body));
    final input = decoded is Map ? decoded['tool_input'] : null;
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
          request: ActionRequest(classes: classes, command: command),
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
      return _forward(request, owner, repoSegment, rest, token);
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
      final verdict = await _guard.check(
        workspaceId: grant.workspaceId,
        classes: const {ActionClass.gitPush},
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: 'git push to $owner/$name: ${refs.join(', ')}',
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runId,
        request: ActionRequest(
          classes: const {ActionClass.gitPush},
          refs: refs,
          hosts: [_githubBase.host],
        ),
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
    return _forward(
      request,
      owner,
      repoSegment,
      rest,
      token,
      body: _replay(preamble.takeBytes(), iterator),
      decodedBody: compressed,
    );
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

  static Stream<List<int>> _replay(
    List<int> head,
    StreamIterator<List<int>> rest,
  ) async* {
    if (head.isNotEmpty) {
      yield head;
    }
    while (await rest.moveNext()) {
      yield rest.current;
    }
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

/// The ref updates at the front of a `git-receive-pack` request.
class _PushCommands {
  const _PushCommands(this.refs, this.capabilities);

  /// Full ref names being updated (`refs/heads/main`).
  final List<String> refs;

  /// Capabilities the client sent on its first command.
  final Set<String> capabilities;

  /// Parses pkt-lines up to the first flush. Null while incomplete.
  static _PushCommands? parse(Uint8List bytes) {
    final refs = <String>[];
    final caps = <String>{};
    var offset = 0;
    while (offset + 4 <= bytes.length) {
      final length = int.tryParse(
        ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true),
        radix: 16,
      );
      if (length == null || (length > 0 && length < 4)) {
        throw const FormatException('Invalid push packet length.');
      }
      if (length == 0) {
        return _PushCommands(refs, caps);
      }
      if (offset + length > bytes.length) {
        return null;
      }
      var line = utf8.decode(
        bytes.sublist(offset + 4, offset + length),
        allowMalformed: true,
      );
      offset += length;
      final nul = line.indexOf('\u0000');
      if (nul >= 0) {
        caps.addAll(line.substring(nul + 1).trim().split(' '));
        line = line.substring(0, nul);
      }
      // `<old-oid> <new-oid> <ref>`; a signed push's certificate lines and
      // shallow lines carry no ref update.
      final parts = line.trim().split(' ');
      if (parts.length == 3 && parts[2].startsWith('refs/')) {
        refs.add(parts[2]);
      }
    }
    return null;
  }
}
