/// The agent run client: what a run's shims run to talk to the agent run
/// gateway (`AgentRunGateway`) from inside the run's sandbox.
///
/// It ships inside the server binary (`cc_server agent-run <verb> …`), so a
/// run needs no HTTP tool of its own. It holds no secret and decides
/// nothing: it reads the run's token and the gateway's address from the
/// environment, sends one request and reports the gateway's answer.
///
/// This file imports only `dart:` libraries, so it starts fast and can be
/// read in one sitting.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Env var carrying the run's secret (`AgentRunLease.tokenEnvKey`).
const String agentRunTokenEnvKey = 'CC_AGENT_RUN_TOKEN';

/// Env var carrying the gateway's base URL (`AgentRunLease.gatewayEnvKey`).
const String agentRunGatewayEnvKey = 'CC_AGENT_GATEWAY';

/// Header the gateway authenticates a run by (`AgentRunLease.tokenHeader`).
const String agentRunTokenHeader = 'X-CC-Agent-Run';

/// Env var naming the harness command this process runs under
/// (`AgentRunLease.callTokenEnvKey`).
const String agentRunCallEnvKey = 'CC_AGENT_CALL_TOKEN';

/// Header carrying [agentRunCallEnvKey] to the gateway
/// (`AgentRunLease.callTokenHeader`). It authenticates nothing; the gateway
/// uses it only to tell that command's tool call when it asks a person.
const String agentRunCallHeader = 'X-CC-Agent-Call';

/// What a call token looks like: the gateway mints base64url text. Anything
/// else is not sent, so a garbled variable can never fail a request.
final RegExp _callTokenShape = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

/// How long the hook waits for the gateway. Shorter than Claude Code's own
/// hook timeout, so a hook that gets no answer still blocks instead of timing
/// out (`AgentRunGateway.hookTransportDeadline`).
const Duration agentRunHookDeadline = Duration(minutes: 56);

/// How long the `stop` and `pre-compact` verbs wait for the gateway: inside
/// Claude Code's timeout for those hooks (`AgentRunGateway.turnHookTimeout`),
/// and longer than the owner's script may run.
const Duration agentRunTurnHookDeadline = Duration(seconds: 75);

const Duration _connectTimeout = Duration(seconds: 5);
const Duration _shortDeadline = Duration(seconds: 60);
const Duration _envDeadline = Duration(hours: 1);

const String _hookPath = '/agent/hooks/pre-tool-use';
const String _stopPath = '/agent/hooks/stop';
const String _preCompactPath = '/agent/hooks/pre-compact';
const String _signPath = '/agent/git-sign';
const String _tokenPath = '/agent/forge-token';
const String _envPath = '/agent/env';

const String _hookFailed =
    'Control Center permission check failed; command blocked.';
const String _noAnswer =
    'Control Center: the agent run gateway did not answer.';
const String _envUnavailable = 'Control Center gateway is unavailable.';

/// Runs one verb of the agent run client and returns the process exit code.
///
/// Verbs:
/// * `hook`: Claude Code's PreToolUse check. Exits 0 only on the gateway's
///   explicit `allow`, else 2 with the reason on stderr.
/// * `stop`: Claude Code's Stop hook. Exits 2 with the owner's text on
///   stderr when the gateway answers `block`, which keeps the turn going;
///   every other outcome exits 0 and lets the turn end.
/// * `pre-compact`: Claude Code's PreCompact hook. Prints the owner's text on
///   stdout for the compaction's instructions and always exits 0 (exit 2
///   would block the compaction).
/// * `git-sign -Y sign … <file>`: git's SSH signer. Writes `<file>.sig`.
/// * `forge-token [<repo>]`: prints the run's read token for a repository.
/// * `env <tool> [args…]`: an environment command (`cc-env`, `docker`, …).
///
/// [environment], [input], [output] and [errors] default to this process's.
Future<int> runAgentRunClient(
  List<String> args, {
  Map<String, String>? environment,
  Stream<List<int>>? input,
  IOSink? output,
  IOSink? errors,
}) async {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  final verb = args.isEmpty ? '' : args.first;
  int code;
  try {
    code = await _run(
      verb,
      args.skip(1).toList(),
      environment ?? Platform.environment,
      input ?? stdin,
      out,
      err,
    );
  } on Object {
    // Never the error itself: it could name the gateway's address or worse.
    // The turn hooks fail open: a broken client lets the turn end and the
    // compaction run.
    code = switch (verb) {
      'hook' => 2,
      'stop' || 'pre-compact' => 0,
      _ => 1,
    };
    if (code != 0) {
      err.writeln(verb == 'hook' ? _hookFailed : _noAnswer);
    }
  }
  try {
    await out.flush();
    await err.flush();
  } on Object {
    // A reader that went away cannot change the answer.
  }
  return code;
}

Future<int> _run(
  String verb,
  List<String> rest,
  Map<String, String> env,
  Stream<List<int>> input,
  IOSink out,
  IOSink err,
) async {
  switch (verb) {
    case 'hook':
      return _hook(env, input, err);
    case 'stop':
      return _stop(env, input, err);
    case 'pre-compact':
      return _preCompact(env, input, out);
    case 'git-sign':
      return _sign(rest, env, err);
    case 'forge-token':
      return _forgeToken(rest, env, out, err);
    case 'env':
      return _env(rest, env, out, err);
  }
  err.writeln(
    'usage: agent-run hook | stop | pre-compact | '
    'git-sign -Y sign … <file> | '
    'forge-token [<repo>] | env <tool> [args…]',
  );
  return verb == 'hook' ? 2 : 64;
}

/// The gateway the run may talk to, or null when the environment names none
/// or names one that is not plain HTTP on a loopback address. Nothing is
/// sent anywhere else: the run's token must never leave the host. `call` is
/// the command's call token, when the environment carries a well-formed one.
({Uri base, String token, String? call})? _gateway(Map<String, String> env) {
  final token = env[agentRunTokenEnvKey] ?? '';
  final base = Uri.tryParse(env[agentRunGatewayEnvKey] ?? '');
  if (token.isEmpty || base == null || base.scheme != 'http') {
    return null;
  }
  final address = InternetAddress.tryParse(base.host);
  if (address == null ||
      !address.isLoopback ||
      base.userInfo.isNotEmpty ||
      base.hasQuery ||
      base.hasFragment ||
      (base.path.isNotEmpty && base.path != '/')) {
    return null;
  }
  final call = env[agentRunCallEnvKey] ?? '';
  return (
    base: base.replace(path: ''),
    token: token,
    call: _callTokenShape.hasMatch(call) ? call : null,
  );
}

/// One answer from the gateway: its status, headers and body.
typedef _Answer = ({int status, HttpHeaders headers, List<int> body});

/// Sends one request and reads the whole answer, or null when there was no
/// answer within [deadline] (refused, unreachable, cut off, too slow).
Future<_Answer?> _send(
  ({Uri base, String token, String? call}) gateway,
  String method,
  String path, {
  required Duration deadline,
  Map<String, String> query = const {},
  Map<String, String> headers = const {},
  Stream<List<int>>? body,
}) async {
  final client = HttpClient()
    ..connectionTimeout = _connectTimeout
    ..findProxy = ((_) => 'DIRECT');
  try {
    return await () async {
      final request = await client.openUrl(
        method,
        gateway.base.replace(
          path: path,
          queryParameters: query.isEmpty ? null : query,
        ),
      );
      request.followRedirects = false;
      request.headers.set(agentRunTokenHeader, gateway.token);
      if (gateway.call case final call?) {
        request.headers.set(agentRunCallHeader, call);
      }
      headers.forEach(request.headers.set);
      if (body != null) {
        await request.addStream(body);
      }
      final response = await request.close();
      final bytes = await response.fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (b, chunk) => b..add(chunk),
      );
      return (
        status: response.statusCode,
        headers: response.headers,
        body: bytes.takeBytes(),
      );
    }().timeout(deadline);
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

bool _ok(int status) => status >= 200 && status < 300;

/// [body] as text, without the trailing newlines the gateway ends it with.
String _text(List<int> body) =>
    utf8.decode(body, allowMalformed: true).replaceFirst(RegExp(r'\n+$'), '');

Future<int> _hook(
  Map<String, String> env,
  Stream<List<int>> input,
  IOSink err,
) async {
  final gateway = _gateway(env);
  if (gateway == null) {
    err.writeln(_hookFailed);
    return 2;
  }
  final answer = await _send(
    gateway,
    'POST',
    _hookPath,
    deadline: agentRunHookDeadline,
    headers: const {'Content-Type': 'application/json'},
    body: input,
  );
  if (answer == null) {
    err.writeln(_hookFailed);
    return 2;
  }
  final verdict = _text(answer.body);
  if (_ok(answer.status) && verdict == 'allow') {
    return 0;
  }
  err.writeln(verdict.isEmpty ? _hookFailed : verdict);
  return 2;
}

Future<int> _stop(
  Map<String, String> env,
  Stream<List<int>> input,
  IOSink err,
) async {
  final gateway = _gateway(env);
  if (gateway == null) {
    return 0;
  }
  final answer = await _send(
    gateway,
    'POST',
    _stopPath,
    deadline: agentRunTurnHookDeadline,
    headers: const {'Content-Type': 'application/json'},
    body: input,
  );
  if (answer == null || !_ok(answer.status)) {
    return 0;
  }
  final verdict = _text(answer.body);
  const block = 'block\n';
  if (!verdict.startsWith(block)) {
    return 0;
  }
  final text = verdict.substring(block.length).trim();
  if (text.isEmpty) {
    return 0;
  }
  err.writeln(text);
  return 2;
}

Future<int> _preCompact(
  Map<String, String> env,
  Stream<List<int>> input,
  IOSink out,
) async {
  final gateway = _gateway(env);
  if (gateway == null) {
    return 0;
  }
  final answer = await _send(
    gateway,
    'POST',
    _preCompactPath,
    deadline: agentRunTurnHookDeadline,
    headers: const {'Content-Type': 'application/json'},
    body: input,
  );
  if (answer != null && _ok(answer.status)) {
    final text = _text(answer.body).trim();
    if (text.isNotEmpty) {
      out.writeln(text);
    }
  }
  return 0;
}

Future<int> _sign(
  List<String> args,
  Map<String, String> env,
  IOSink err,
) async {
  if (args.length < 3 || args[0] != '-Y' || args[1] != 'sign') {
    err.writeln('Control Center: this signer only signs commits.');
    return 1;
  }
  final gateway = _gateway(env);
  if (gateway == null) {
    err.writeln(
      'Control Center: this session cannot sign commits (no agent run).',
    );
    return 1;
  }
  // Git names the object to sign last, and expects the signature beside it.
  final object = File(args.last);
  final signature = File('${object.path}.sig');
  final answer = await _send(
    gateway,
    'POST',
    _signPath,
    deadline: _shortDeadline,
    headers: const {'Content-Type': 'application/octet-stream'},
    body: object.openRead(),
  );
  if (answer != null && _ok(answer.status)) {
    await signature.writeAsBytes(answer.body, flush: true);
    return 0;
  }
  if (signature.existsSync()) {
    signature.deleteSync();
  }
  final reason = answer == null ? '' : _text(answer.body);
  err.writeln(reason.isEmpty ? _noAnswer : reason);
  return 1;
}

Future<int> _forgeToken(
  List<String> args,
  Map<String, String> env,
  IOSink out,
  IOSink err,
) async {
  final gateway = _gateway(env);
  if (gateway == null) {
    err.writeln(_noAnswer);
    return 1;
  }
  final repo = args.isEmpty ? '' : args.first.trim();
  final answer = await _send(
    gateway,
    'GET',
    _tokenPath,
    deadline: _shortDeadline,
    query: {if (repo.isNotEmpty) 'repo': repo},
  );
  final text = answer == null ? '' : _text(answer.body);
  if (answer != null && _ok(answer.status) && text.isNotEmpty) {
    out.write(text);
    return 0;
  }
  // A refusal is the gateway's own words, which never carry a token.
  err.writeln(text.isEmpty ? _noAnswer : text);
  return 1;
}

Future<int> _env(
  List<String> args,
  Map<String, String> env,
  IOSink out,
  IOSink err,
) async {
  final gateway = _gateway(env);
  if (args.isEmpty || gateway == null) {
    err.writeln(_envUnavailable);
    return 5;
  }
  final arguments = BytesBuilder(copy: false);
  for (final argument in args.skip(1)) {
    arguments
      ..add(utf8.encode(argument))
      ..addByte(0);
  }
  final answer = await _send(
    gateway,
    'POST',
    _envPath,
    deadline: _envDeadline,
    headers: {
      'Content-Type': 'application/octet-stream',
      'X-CC-Env-Tool': args.first,
    },
    body: Stream.value(arguments.takeBytes()),
  );
  if (answer == null) {
    err.writeln(_envUnavailable);
    return 5;
  }
  if (!_ok(answer.status)) {
    err.writeln(_text(answer.body));
    return 1;
  }
  out.add(answer.body);
  final stderrTail = answer.headers.value('X-CC-Stderr') ?? '';
  if (stderrTail.isNotEmpty) {
    try {
      err.add(base64.decode(stderrTail));
    } on FormatException {
      // A garbled tail is dropped; the exit code still says what happened.
    }
  }
  return int.tryParse(answer.headers.value('X-CC-Exit-Code') ?? '') ?? 1;
}
