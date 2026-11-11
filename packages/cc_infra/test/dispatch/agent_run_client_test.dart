import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/agent_run_client.dart';
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/process/agent_run_client_launcher.dart';
import 'package:test/test.dart';

/// The run's secret in these tests. It must never be printed.
const _secret = 'run-secret-for-tests';

/// What the fake gateway saw of one request.
typedef _Seen = ({
  String method,
  String path,
  Map<String, String> query,
  String? token,
  String? contentType,
  String? tool,
  List<int> body,
});

/// A gateway that records what it is sent and answers with [answer].
class _Gateway {
  _Gateway(this.server) {
    server.listen((request) async {
      final body = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      seen.add((
        method: request.method,
        path: request.uri.path,
        query: request.uri.queryParameters,
        token: request.headers.value(agentRunTokenHeader),
        contentType: request.headers.value(HttpHeaders.contentTypeHeader),
        tool: request.headers.value('X-CC-Env-Tool'),
        body: body,
      ));
      await answer(request.response);
      await request.response.close();
    });
  }

  final HttpServer server;
  final List<_Seen> seen = [];

  /// Answers every request. By default: 200, empty.
  Future<void> Function(HttpResponse response) answer = (_) async {};

  String get base => 'http://127.0.0.1:${server.port}';

  Map<String, String> get env => {
    agentRunTokenEnvKey: _secret,
    agentRunGatewayEnvKey: base,
  };
}

/// Collects what is written to an [IOSink].
class _Collect implements StreamConsumer<List<int>> {
  final List<int> bytes = [];

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(bytes.addAll);

  @override
  Future<void> close() async {}

  String get text => utf8.decode(bytes);
}

typedef _Result = ({int code, String out, String err, List<int> outBytes});

Future<_Result> _client(
  List<String> args,
  Map<String, String> env, {
  List<int> input = const [],
}) async {
  final out = _Collect();
  final err = _Collect();
  final code = await runAgentRunClient(
    args,
    environment: env,
    input: Stream.value(input),
    output: IOSink(out),
    errors: IOSink(err),
  );
  return (code: code, out: out.text, err: err.text, outBytes: out.bytes);
}

/// Every output of [results], for checks that hold across all of them.
String _said(Iterable<_Result> results) =>
    [for (final r in results) '${r.out}\n${r.err}'].join('\n');

void main() {
  late _Gateway gateway;
  late Directory dir;
  final results = <_Result>[];

  Future<_Result> client(
    List<String> args, {
    Map<String, String>? env,
    List<int> input = const [],
  }) async {
    final r = await _client(args, env ?? gateway.env, input: input);
    results.add(r);
    return r;
  }

  setUp(() async {
    gateway = _Gateway(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    dir = Directory.systemTemp.createTempSync('cc_run_client_');
    results.clear();
  });

  tearDown(() async {
    expect(
      _said(results),
      isNot(contains(_secret)),
      reason: 'the run\'s secret is never printed',
    );
    await gateway.server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  test('speaks the gateway\'s names and deadlines', () {
    expect(agentRunTokenEnvKey, AgentRunLease.tokenEnvKey);
    expect(agentRunGatewayEnvKey, AgentRunLease.gatewayEnvKey);
    expect(agentRunTokenHeader, AgentRunLease.tokenHeader);
    expect(agentRunHookDeadline, AgentRunGateway.hookTransportDeadline);
    expect(
      agentRunHookDeadline,
      allOf(
        greaterThan(AgentRunGateway.hookDecisionDeadline),
        lessThan(AgentRunGateway.hookTimeout),
      ),
    );
  });

  group('hook', () {
    final input = utf8.encode('{"tool_name":"Bash"}');

    test('passes only on the gateway\'s explicit allow', () async {
      for (final reply in ['allow', 'allow\n']) {
        gateway.answer = (r) async => r.write(reply);
        final r = await client(const ['hook'], input: input);
        expect(r.code, 0);
        expect(r.err, isEmpty);
      }
      final seen = gateway.seen.first;
      expect(seen.method, 'POST');
      expect(seen.path, '/agent/hooks/pre-tool-use');
      expect(seen.token, _secret);
      expect(seen.contentType, startsWith('application/json'));
      expect(seen.body, input);
    });

    test('anything else blocks with exit 2', () async {
      for (final (status, reply, said) in const [
        (
          200,
          'Control Center policy: no pushes.',
          'Control Center policy: '
              'no pushes.\n',
        ),
        (403, 'allow', 'allow\n'),
        (500, '', 'Control Center permission check failed; command blocked.\n'),
        (200, '', 'Control Center permission check failed; command blocked.\n'),
        (200, 'allowed', 'allowed\n'),
      ]) {
        gateway.answer = (r) async => r
          ..statusCode = status
          ..write(reply);
        final r = await client(const ['hook'], input: input);
        expect(r.code, 2, reason: '$status $reply');
        expect(r.err, said);
      }
    });

    test('no gateway, or one that does not answer, blocks', () async {
      for (final env in [
        <String, String>{},
        {agentRunTokenEnvKey: _secret},
        {agentRunGatewayEnvKey: gateway.base},
        // Nothing listens on the discard port.
        {
          agentRunTokenEnvKey: _secret,
          agentRunGatewayEnvKey: 'http://127.0.0.1:9',
        },
      ]) {
        final r = await client(const ['hook'], env: env, input: input);
        expect(r.code, 2);
        expect(
          r.err,
          'Control Center permission check failed; command blocked.\n',
        );
      }
      expect(gateway.seen, isEmpty);
    });

    test('a gateway that hangs up blocks', () async {
      gateway.answer = (r) async {
        await r.detachSocket().then((s) => s.destroy());
      };
      final r = await client(const ['hook'], input: input);
      expect(r.code, 2);
    });
  });

  group('git-sign', () {
    late File object;

    setUp(() {
      object = File('${dir.path}/commit')..writeAsStringSync('tree abc\n');
    });

    test('writes the gateway\'s signature beside the object', () async {
      gateway.answer = (r) async => r.write('-----BEGIN SSH SIGNATURE-----');

      final r = await client([
        'git-sign',
        '-Y',
        'sign',
        '-n',
        'git',
        '-f',
        '/dev/null',
        object.path,
      ]);

      expect(r.code, 0, reason: r.err);
      expect(
        File('${object.path}.sig').readAsStringSync(),
        '-----BEGIN SSH SIGNATURE-----',
      );
      final seen = gateway.seen.single;
      expect(seen.path, '/agent/git-sign');
      expect(seen.method, 'POST');
      expect(seen.contentType, 'application/octet-stream');
      expect(utf8.decode(seen.body), 'tree abc\n');
    });

    test('a refusal leaves no signature and says why', () async {
      File('${object.path}.sig').writeAsStringSync('stale');
      gateway.answer = (r) async => r
        ..statusCode = 403
        ..write('Control Center: this run signs no commits.\n');

      final r = await client(['git-sign', '-Y', 'sign', object.path]);

      expect(r.code, 1);
      expect(r.err, 'Control Center: this run signs no commits.\n');
      expect(File('${object.path}.sig').existsSync(), isFalse);
    });

    test('signs nothing else, and nothing without a run', () async {
      final verify = await client(['git-sign', '-Y', 'verify', object.path]);
      expect(verify.code, 1);
      expect(verify.err, 'Control Center: this signer only signs commits.\n');

      final none = await client([
        'git-sign',
        '-Y',
        'sign',
        object.path,
      ], env: const {});
      expect(none.code, 1);
      expect(
        none.err,
        'Control Center: this session cannot sign commits (no agent run).\n',
      );
      expect(gateway.seen, isEmpty);
    });

    test('a gateway that does not answer says so', () async {
      final r = await client(
        ['git-sign', '-Y', 'sign', object.path],
        env: {
          agentRunTokenEnvKey: _secret,
          agentRunGatewayEnvKey: 'http://127.0.0.1:9',
        },
      );
      expect(r.code, 1);
      expect(r.err, 'Control Center: the agent run gateway did not answer.\n');
      expect(File('${object.path}.sig').existsSync(), isFalse);
    });
  });

  group('forge-token', () {
    test('prints the token for the repository asked about', () async {
      gateway.answer = (r) async => r.write('review-test-token');

      final named = await client(const ['forge-token', 'acme/widgets']);
      final unnamed = await client(const ['forge-token']);

      expect(named.code, 0);
      expect(named.out, 'review-test-token');
      expect(unnamed.out, 'review-test-token');
      expect(gateway.seen.map((s) => (s.method, s.path)), [
        ('GET', '/agent/forge-token'),
        ('GET', '/agent/forge-token'),
      ]);
      expect(gateway.seen.map((s) => s.query), [
        {'repo': 'acme/widgets'},
        isEmpty,
      ]);
    });

    test('a refusal goes to stderr, never stdout', () async {
      gateway.answer = (r) async => r
        ..statusCode = 403
        ..write('Control Center: this run has no GitHub token for o/r.\n');

      final r = await client(const ['forge-token', 'o/r']);

      expect(r.code, 1);
      expect(r.out, isEmpty);
      expect(r.err, 'Control Center: this run has no GitHub token for o/r.\n');
    });

    test('an empty answer is no token', () async {
      final r = await client(const ['forge-token']);
      expect(r.code, 1);
      expect(r.out, isEmpty);
      expect(r.err, 'Control Center: the agent run gateway did not answer.\n');
    });
  });

  group('env', () {
    test('sends the tool and its arguments, and relays the answer', () async {
      gateway.answer = (r) async {
        r.headers
          ..set('X-CC-Exit-Code', '3')
          ..set('X-CC-Stderr', base64.encode(utf8.encode('warned\n')));
        r.write('output\n');
      };

      final r = await client(const ['env', 'cc-env', 'up', 'a b', '']);

      expect(r.code, 3);
      expect(r.out, 'output\n');
      expect(r.err, 'warned\n');
      final seen = gateway.seen.single;
      expect(seen.path, '/agent/env');
      expect(seen.tool, 'cc-env');
      expect(seen.body, utf8.encode('up\u0000a b\u0000\u0000'));
    });

    test('a refusal exits 1 with the reason on stderr', () async {
      gateway.answer = (r) async => r
        ..statusCode = 403
        ..write('Control Center: no environment here.\n');

      final r = await client(const ['env', 'docker', 'ps']);

      expect(r.code, 1);
      expect(r.out, isEmpty);
      expect(r.err, 'Control Center: no environment here.\n');
    });

    test('no gateway is exit 5, as environment commands report it', () async {
      for (final (args, env) in [
        (const ['env'], gateway.env),
        (const ['env', 'cc-env'], <String, String>{}),
        (
          const ['env', 'cc-env'],
          {
            agentRunTokenEnvKey: _secret,
            agentRunGatewayEnvKey: 'http://127.0.0.1:9',
          },
        ),
      ]) {
        final r = await client(args, env: env);
        expect(r.code, 5);
        expect(r.err, 'Control Center gateway is unavailable.\n');
      }
      expect(gateway.seen, isEmpty);
    });
  });

  test('sends the token to nothing but plain HTTP on a loopback IP', () async {
    final port = gateway.server.port;
    for (final base in [
      'http://example.com:$port',
      'https://127.0.0.1:$port',
      'http://localhost:$port',
      'http://user:pass@127.0.0.1:$port',
      'http://10.0.0.1:$port',
      'http://127.0.0.1:$port/agent',
      'http://127.0.0.1:$port/?x=1',
      'http://127.0.0.1:$port/#x',
      'ftp://127.0.0.1:$port',
      '127.0.0.1:$port',
      '',
    ]) {
      final env = {agentRunTokenEnvKey: _secret, agentRunGatewayEnvKey: base};
      final token = await client(const ['forge-token'], env: env);
      final hook = await client(const ['hook'], env: env);
      expect(token.code, 1, reason: base);
      expect(hook.code, 2, reason: base);
    }
    expect(gateway.seen, isEmpty);

    // The same gateway, named properly, is reached.
    gateway.answer = (r) async => r.write('allow');
    final ok = await client(
      const ['hook'],
      env: {
        agentRunTokenEnvKey: _secret,
        agentRunGatewayEnvKey: 'http://127.0.0.1:$port/',
      },
    );
    expect(ok.code, 0);
  });

  test('an unknown verb prints its usage', () async {
    for (final args in const [
      <String>[],
      ['curl'],
      ['Hook'],
    ]) {
      final r = await client(args);
      expect(r.code, 64, reason: '$args');
      expect(r.err, startsWith('usage: agent-run '));
    }
    expect(gateway.seen, isEmpty);
  });

  group('shims, through the real client', () {
    final launcher = AgentRunClientLauncher.current;

    Future<String> write(String name, String script) async {
      final file = File('${dir.path}/bin/$name')
        ..createSync(recursive: true)
        ..writeAsStringSync(script);
      await Process.run('/bin/chmod', ['755', file.path]);
      return file.path;
    }

    test('the launcher runs from files that exist, by absolute path', () {
      expect(launcher.command.first, startsWith('/'));
      expect(launcher.files.first, launcher.command.first);
      for (final file in launcher.files) {
        expect(File(file).existsSync(), isTrue, reason: file);
      }
    });

    test('an environment shim relays a command\'s output and exit', () async {
      gateway.answer = (r) async {
        r.headers.set('X-CC-Exit-Code', '4');
        r.write('ran\n');
      };
      final shim = await write(
        'cc-env',
        agentShimScript(clientCommand: launcher.shellCommand),
      );

      final r = await Process.run(shim, const [
        'status',
        '--all',
      ], environment: gateway.env);

      expect(r.exitCode, 4, reason: '${r.stderr}');
      expect(r.stdout, 'ran\n');
      expect(gateway.seen.single.tool, 'cc-env');
      expect(gateway.seen.single.body, utf8.encode('status\u0000--all\u0000'));
    });

    test('the signer is git\'s ssh program', () async {
      gateway.answer = (r) async => r.write('signature');
      final shim = await write(
        AgentRunSigning.shimName,
        AgentRunSigning.shim(launcher),
      );
      final object = File('${dir.path}/commit')..writeAsStringSync('tree x\n');

      final r = await Process.run(shim, [
        '-Y',
        'sign',
        '-n',
        'git',
        '-f',
        '/dev/null',
        object.path,
      ], environment: gateway.env);

      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect(File('${object.path}.sig').readAsStringSync(), 'signature');
    });

    test('a path with a space or a quote is one word', () async {
      const odd = AgentRunClientLauncher(
        command: ["/opt/it's here/cc server", 'agent-run'],
        files: [],
      );
      final r = await Process.run('sh', [
        '-c',
        'for a in ${odd.shellCommand}; do printf "%s|" "\$a"; done',
      ]);
      expect(r.stdout, "/opt/it's here/cc server|agent-run|");
    });
  }, skip: Platform.isWindows ? 'The shims are POSIX shell.' : false);
}
