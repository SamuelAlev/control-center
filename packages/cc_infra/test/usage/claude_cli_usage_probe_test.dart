import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/usage/claude_cli_usage_probe.dart';
import 'package:test/test.dart';

/// A `claude` stand-in answering control requests from a script, the way the
/// real CLI does on stdin/stdout.
class _FakeClaude implements Process {
  _FakeClaude(this.answer) {
    _stdin.stream.transform(utf8.decoder).transform(const LineSplitter()).listen((
      line,
    ) {
      final frame = jsonDecode(line) as Map<String, dynamic>;
      final request = frame['request'] as Map<String, dynamic>;
      requests.add(request);
      final body = answer(request);
      if (body == null) {
        return;
      }
      _stdout.add(
        utf8.encode(
          '${jsonEncode({
            'type': 'control_response',
            'response': {'subtype': 'success', 'request_id': frame['request_id'], 'response': body},
          })}\n',
        ),
      );
    });
  }

  final Map<String, dynamic>? Function(Map<String, dynamic> request) answer;
  final requests = <Map<String, dynamic>>[];
  // ignore: close_sinks, closed by kill() or left with the test.
  final _stdin = StreamController<List<int>>();
  // ignore: close_sinks, closed by kill().
  final _stdout = StreamController<List<int>>();
  bool killed = false;

  @override
  // ignore: close_sinks, the probe owns this for the life of the process.
  late final IOSink stdin = IOSink(_stdin.sink);

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Future<int> get exitCode async => 0;

  @override
  int get pid => 1;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    unawaited(_stdout.close());
    return true;
  }
}

void main() {
  const signedIn = {
    'account': {'apiProvider': 'firstParty', 'subscriptionType': 'max'},
  };
  const usage = {
    'rate_limits_available': true,
    'rate_limits': {
      'five_hour': {'utilization': 12},
    },
  };

  Map<String, dynamic>? answering(Map<String, dynamic> request) =>
      switch (request['subtype']) {
        'initialize' => signedIn,
        'get_usage' => usage,
        _ => null,
      };

  ClaudeCliUsageProbe probe(
    _FakeClaude fake, {
    Map<String, String> environment = const {'PATH': '/usr/bin'},
    String? standIn,
    void Function(Map<String, String> env, List<String> args)? onStart,
  }) => ClaudeCliUsageProbe(
    resolveBinary: (_) async => '/bin/claude',
    environment: environment,
    keychainStandInDir: () => standIn,
    requestTimeout: const Duration(milliseconds: 200),
    start:
        (
          executable,
          arguments, {
          required workingDirectory,
          required environment,
        }) async {
          onStart?.call(environment, arguments);
          return fake;
        },
  );

  test('reads usage without sending a message, then ends the CLI', () async {
    final fake = _FakeClaude(answering);

    final reading = await probe(fake).read();

    expect(reading?.available, isTrue);
    expect(reading?.signedOut, isFalse);
    expect(reading?.rateLimits['five_hour'], {'utilization': 12});
    expect(fake.requests.map((r) => r['subtype']), ['initialize', 'get_usage']);
    expect(fake.requests.last['skip_behaviors'], isTrue);
    expect(fake.killed, isTrue);
  });

  test('never spends a model turn or leaves a session behind', () async {
    late List<String> args;
    await probe(_FakeClaude(answering), onStart: (_, a) => args = a).read();

    expect(args, contains('--no-session-persistence'));
    expect(args, contains('--strict-mcp-config'));
  });

  test('reports a signed-out CLI', () async {
    final fake = _FakeClaude(
      (request) => switch (request['subtype']) {
        'initialize' => {
          'account': {'tokenSource': 'none', 'apiProvider': 'firstParty'},
        },
        'get_usage' => {'rate_limits_available': false, 'rate_limits': null},
        _ => null,
      },
    );

    final reading = await probe(fake).read();

    expect(reading?.signedOut, isTrue);
    expect(reading?.available, isFalse);
  });

  test('is null when Claude Code is not installed', () async {
    final reading = await ClaudeCliUsageProbe(
      resolveBinary: (_) async => null,
      start:
          (
            executable,
            arguments, {
            required workingDirectory,
            required environment,
          }) => fail('nothing to spawn'),
    ).read();

    expect(reading, isNull);
  });

  test('a silent CLI times out and is still ended', () async {
    final fake = _FakeClaude((_) => null);

    await expectLater(probe(fake).read(), throwsA(isA<TimeoutException>()));
    expect(fake.killed, isTrue);
  });

  group('environment', () {
    test('a metered key cannot replace the plan being read', () {
      final env = probe(
        _FakeClaude(answering),
        environment: const {
          'PATH': '/usr/bin',
          'ANTHROPIC_API_KEY': 'k',
          'ANTHROPIC_AUTH_TOKEN': 't',
        },
      ).environmentFor(null);

      expect(env.containsKey('ANTHROPIC_API_KEY'), isFalse);
      expect(env.containsKey('ANTHROPIC_AUTH_TOKEN'), isFalse);
    });

    test('the operator login keeps the real keychain', () {
      final env = probe(
        _FakeClaude(answering),
        standIn: '/stand-in',
      ).environmentFor(null);

      expect(env['PATH'], '/usr/bin');
      expect(env.containsKey('CLAUDE_CONFIG_DIR'), isFalse);
    });

    test('a managed account reads the same file its runs renew', () {
      final env = probe(
        _FakeClaude(answering),
        standIn: '/stand-in',
      ).environmentFor('/accounts/work');

      expect(env['CLAUDE_CONFIG_DIR'], '/accounts/work');
      expect(env['PATH'], '/stand-in:/usr/bin');
    });

    test('hosts without a stand-in leave PATH alone', () {
      final env = probe(_FakeClaude(answering)).environmentFor('/accounts/w');

      expect(env['PATH'], '/usr/bin');
    });
  });
}
