import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/detection/claude_code_model_probe.dart';
import 'package:test/test.dart';

/// A stand-in `claude` that answers the stream-json control protocol the way
/// 2.1.316 does: `initialize` with its model rows, `set_model` switching the
/// current model, `get_context_usage` reporting that model's window.
class _FakeClaude implements Process {
  _FakeClaude({
    required this.rows,
    required this.windows,
    this.defaultModel = 'claude-opus-5-5',
    this.refuse = const {},
    this.racy = false,
  }) : _current = defaultModel {
    stdin = IOSink(_Consumer(_onStdin));
  }

  final List<Map<String, Object?>> rows;

  /// Window per resolved model id.
  final Map<String, int> windows;
  final String defaultModel;

  /// Ids `set_model` rejects.
  final Set<String> refuse;

  /// Applies and answers `set_model` only after a delay, the way a real CLI's
  /// reply can trail — a probe that does not wait would read the old model.
  final bool racy;

  String _current;
  final _stdout = StreamController<List<int>>();
  final requests = <Map<String, dynamic>>[];
  bool killed = false;

  @override
  late final IOSink stdin;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Future<int> get exitCode => Completer<int>().future;

  @override
  int get pid => 1;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    unawaited(_stdout.close());
    unawaited(stdin.close());
    return true;
  }

  String _resolve(String id) => switch (id) {
    'opus' => 'claude-opus-5-5',
    'sonnet' => 'claude-sonnet-5-5',
    'opusplan' => 'claude-sonnet-5-5',
    _ => id,
  };

  void _send(String id, Map<String, Object?> response, {String? error}) {
    _stdout.add(
      utf8.encode(
        '${jsonEncode({
          'type': 'control_response',
          'response': {'subtype': error == null ? 'success' : 'error', 'request_id': id, 'response': response, 'error': ?error},
        })}\n',
      ),
    );
  }

  void _onStdin(String line) {
    final msg = jsonDecode(line) as Map<String, dynamic>;
    requests.add(msg);
    final id = msg['request_id'] as String;
    final req = msg['request'] as Map<String, dynamic>;
    switch (req['subtype']) {
      case 'initialize':
        _send(id, {'models': rows});
      case 'set_model':
        final model = req['model'] as String;
        if (refuse.contains(model)) {
          _send(id, {}, error: 'unknown model');
          break;
        }
        void apply() {
          _current = _resolve(model);
          _send(id, {'model': _current});
        }
        if (racy) {
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 50), apply),
          );
        } else {
          apply();
        }
      case 'get_context_usage':
        expect(req['detail'], 'summary', reason: 'never the token-count API');
        _send(id, {'model': _current, 'rawMaxTokens': windows[_current]});
    }
  }
}

class _Consumer implements StreamConsumer<List<int>> {
  _Consumer(this.onLine);
  final void Function(String line) onLine;
  final _buffer = StringBuffer();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach((chunk) {
    _buffer.write(utf8.decode(chunk));
    final text = _buffer.toString();
    final parts = text.split('\n');
    _buffer
      ..clear()
      ..write(parts.removeLast());
    parts.where((l) => l.isNotEmpty).forEach(onLine);
  });

  @override
  Future<void> close() async {}
}

const _rows = [
  {'value': 'default', 'resolvedModel': 'claude-opus-5-5'},
  {
    'value': 'opus',
    'resolvedModel': 'claude-opus-5-5',
    'displayName': 'Opus 5.5',
    'supportsEffort': true,
    'supportedEffortLevels': ['low', 'medium', 'high', 'xhigh', 'max'],
  },
  {
    'value': 'claude-opus-4-6',
    'resolvedModel': 'claude-opus-4-6',
    'displayName': 'Opus 4.6',
    'supportsEffort': true,
    'supportedEffortLevels': ['low', 'medium', 'high', 'max'],
  },
  {
    'value': 'claude-haiku-4-5-20251001',
    'displayName': 'Haiku 4.5',
    'supportsThinkingOff': true,
  },
  {'value': '', 'displayName': 'no value: skipped'},
];

const _windows = {
  'claude-opus-5-5': 1000000,
  'claude-sonnet-5-5': 1000000,
  'claude-opus-4-6': 200000,
  'claude-haiku-4-5-20251001': 200000,
};

void main() {
  late _FakeClaude fake;
  late List<String> args;
  late Map<String, String> env;
  late String cwd;

  ClaudeCodeModelProbe probeFor(_FakeClaude claude) {
    fake = claude;
    return ClaudeCodeModelProbe(
      start:
          (
            exe,
            arguments, {
            required workingDirectory,
            required environment,
          }) async {
            args = arguments;
            env = environment;
            cwd = workingDirectory;
            return claude;
          },
      requestTimeout: const Duration(seconds: 2),
    );
  }

  test('reads the CLI list and each row\'s window, without a prompt', () async {
    final result = await probeFor(
      _FakeClaude(rows: _rows, windows: _windows),
    ).probe(binaryPath: '/bin/claude', configDir: '/accounts/a');

    expect(
      [for (final m in result.models) m.value],
      ['default', 'opus', 'claude-opus-4-6', 'claude-haiku-4-5-20251001'],
    );
    final byId = {for (final m in result.models) m.value: m};
    expect(byId['opus']!.contextWindow, 1000000);
    expect(byId['opus']!.resolvedModel, 'claude-opus-5-5');
    expect(byId['opus']!.effortLevels, hasLength(5));
    expect(byId['claude-opus-4-6']!.contextWindow, 200000);
    expect(byId['claude-haiku-4-5-20251001']!.contextWindow, 200000);
    expect(byId['claude-haiku-4-5-20251001']!.effortLevels, isNull);
    expect(result.defaultWindow, 1000000);

    // Only control requests: nothing that would reach a model.
    expect(fake.requests.map((r) => r['type']).toSet(), {'control_request'});
    expect(fake.killed, isTrue);
  });

  test('runs isolated, as the given account', () async {
    await probeFor(
      _FakeClaude(rows: _rows, windows: _windows),
    ).probe(binaryPath: '/bin/claude', configDir: '/accounts/a');

    expect(
      args,
      containsAll([
        '--strict-mcp-config',
        '--no-session-persistence',
        '{"disableAllHooks":true}',
      ]),
    );
    expect(env['CLAUDE_CONFIG_DIR'], '/accounts/a');
    expect(Directory(cwd).existsSync(), isFalse, reason: 'temp cwd removed');
  });

  test('waits for each set_model before reading the window', () async {
    final result =
        await probeFor(
          _FakeClaude(rows: _rows, windows: _windows, racy: true),
        ).probe(
          binaryPath: '/bin/claude',
          configDir: null,
          listCatalog: false,
          extraIds: ['claude-opus-4-6'],
        );

    expect(result.extras['claude-opus-4-6']!.contextWindow, 200000);
  });

  test('an id the CLI refuses is left out, not guessed', () async {
    final result =
        await probeFor(
          _FakeClaude(rows: _rows, windows: _windows, refuse: {'best'}),
        ).probe(
          binaryPath: '/bin/claude',
          listCatalog: false,
          extraIds: ['opusplan', 'best'],
        );

    expect(result.extras.keys, ['opusplan']);
    expect(result.extras['opusplan']!.resolvedModel, 'claude-sonnet-5-5');
    expect(result.extras['opusplan']!.contextWindow, 1000000);
  });

  test('an empty list is returned as is', () async {
    // An answer, not a failure: the catalog decides it is unusable.
    final result = await probeFor(
      _FakeClaude(rows: const [], windows: _windows),
    ).probe(binaryPath: '/bin/claude');
    expect(result.models, isEmpty);
  });
}
