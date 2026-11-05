import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// One model as the Claude Code CLI itself advertises it.
class ClaudeCodeProbedModel {
  /// Creates a [ClaudeCodeProbedModel].
  const ClaudeCodeProbedModel({
    required this.value,
    this.resolvedModel,
    this.displayName,
    this.effortLevels,
    this.contextWindow,
    this.disabled = false,
  });

  /// Reads one row of the `initialize` response's `models` array, or null
  /// when the row has no usable `value`.
  static ClaudeCodeProbedModel? fromInitRow(Object? row) {
    if (row is! Map) {
      return null;
    }
    final value = row['value'];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    final levels = row['supportedEffortLevels'];
    return ClaudeCodeProbedModel(
      value: value.trim(),
      resolvedModel: _nonEmpty(row['resolvedModel']),
      displayName: _nonEmpty(row['displayName']),
      effortLevels: row['supportsEffort'] == true && levels is List
          ? [
              for (final l in levels)
                if (l is String && l.isNotEmpty) l,
            ]
          : null,
      disabled: row['disabled'] == true,
    );
  }

  /// What `--model` takes: an alias (`opus`), a model id, or `default`.
  final String value;

  /// The wire model id [value] resolves to (`opus` → `claude-opus-5-5`).
  final String? resolvedModel;

  /// The CLI's own label (`Opus 5.5`).
  final String? displayName;

  /// The `--effort` levels the model accepts; null when it takes none.
  final List<String>? effortLevels;

  /// The window, in tokens, the CLI runs [value] with; null when the probe
  /// could not read it.
  final int? contextWindow;

  /// Listed but not selectable for this account (e.g. excluded by the org's
  /// zero-data-retention setting).
  final bool disabled;

  /// A copy with [contextWindow] and, when given, [resolvedModel] replaced.
  ClaudeCodeProbedModel withWindow(int? window, {String? resolvedModel}) =>
      ClaudeCodeProbedModel(
        value: value,
        resolvedModel: resolvedModel ?? this.resolvedModel,
        displayName: displayName,
        effortLevels: effortLevels,
        contextWindow: window,
        disabled: disabled,
      );

  static String? _nonEmpty(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;
}

/// What one probe learned.
class ClaudeCodeProbeResult {
  /// Creates a [ClaudeCodeProbeResult].
  const ClaudeCodeProbeResult({
    required this.models,
    required this.defaultWindow,
    required this.extras,
  });

  /// The CLI's own model list, in its order, each with its window.
  final List<ClaudeCodeProbedModel> models;

  /// The window of the model the CLI runs when given no `--model`.
  final int? defaultWindow;

  /// The ids asked about beyond the list, keyed by id: what each resolves
  /// to and its window. An id the CLI refused is absent.
  final Map<String, ClaudeCodeProbedModel> extras;
}

/// Starts the CLI process. A seam so tests drive the protocol without a
/// binary.
typedef ClaudeProbeProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required Map<String, String> environment,
    });

/// Asks the installed Claude Code CLI which models it offers, and the window
/// each one runs with, without spending a token.
///
/// `claude` has no listing subcommand, but its stream-json control protocol
/// (the one the Agent SDK speaks) does: `initialize` answers with the CLI's
/// own picker rows, filtered for the signed-in account and provider. Each row
/// then gets its window from `set_model` + `get_context_usage` with
/// `detail: summary`, which answers from local estimates (no token-count API
/// call). No user message is ever sent, so nothing reaches a model.
///
/// The process is isolated from anything that could act: an empty temporary
/// working directory (no project settings, `.mcp.json` or CLAUDE.md), no MCP
/// servers, hooks disabled and no session persisted. User settings still load,
/// because they are what decides the provider and the model list a real run
/// gets.
class ClaudeCodeModelProbe {
  /// Creates a [ClaudeCodeModelProbe].
  ClaudeCodeModelProbe({
    ClaudeProbeProcessStarter? start,
    this.timeout = const Duration(seconds: 45),
    this.requestTimeout = const Duration(seconds: 15),
  }) : _start = start ?? _defaultStart;

  final ClaudeProbeProcessStarter _start;

  /// The bound on one whole probe.
  final Duration timeout;

  /// The bound on one control request.
  final Duration requestTimeout;

  /// The flags every probe runs with. See the class doc for why each is
  /// there.
  static const List<String> args = [
    '-p',
    '--input-format',
    'stream-json',
    '--output-format',
    'stream-json',
    '--verbose',
    '--strict-mcp-config',
    '--no-session-persistence',
    '--settings',
    '{"disableAllHooks":true}',
  ];

  static Future<Process> _defaultStart(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: false,
  );

  /// Probes [binaryPath] as the account in [configDir] (the operator's own
  /// Claude home when null).
  ///
  /// With [listCatalog] the CLI's own list is read and every row gets its
  /// window; [extraIds] are ids to resolve beyond it (vocabulary the list
  /// omits, or an id an agent was configured with). Throws when the CLI
  /// cannot be driven at all; a single row the CLI refuses is skipped.
  Future<ClaudeCodeProbeResult> probe({
    required String binaryPath,
    String? configDir,
    bool listCatalog = true,
    List<String> extraIds = const [],
  }) async {
    final cwd = await Directory.systemTemp.createTemp('cc-claude-models-');
    Process? process;
    try {
      process = await _start(
        binaryPath,
        args,
        workingDirectory: cwd.path,
        environment: {
          ...Platform.environment,
          if (configDir != null && configDir.isNotEmpty)
            'CLAUDE_CONFIG_DIR': configDir,
        },
      );
      final session = _ControlSession(process, requestTimeout);
      return await _run(
        session,
        listCatalog: listCatalog,
        extraIds: extraIds,
      ).timeout(timeout);
    } finally {
      process?.kill();
      try {
        await cwd.delete(recursive: true);
      } on Object {
        // A leftover empty temp dir is harmless.
      }
    }
  }

  Future<ClaudeCodeProbeResult> _run(
    _ControlSession session, {
    required bool listCatalog,
    required List<String> extraIds,
  }) async {
    final init = await session.request({'subtype': 'initialize'});
    // Before any `set_model`, the window is the default model's.
    final defaultWindow = (await session.contextUsage())?.window;

    final models = <ClaudeCodeProbedModel>[];
    if (listCatalog) {
      final rows = init['models'];
      if (rows is! List) {
        throw const FormatException(
          'claude initialize answered without a models list',
        );
      }
      for (final row in rows) {
        final model = ClaudeCodeProbedModel.fromInitRow(row);
        if (model == null) {
          continue;
        }
        final usage = model.value == 'default'
            ? (window: defaultWindow, model: model.resolvedModel)
            : await session.usageFor(model.value);
        models.add(model.withWindow(usage?.window));
      }
    }

    final extras = <String, ClaudeCodeProbedModel>{};
    for (final id in extraIds) {
      final usage = await session.usageFor(id);
      if (usage == null) {
        continue;
      }
      extras[id] = ClaudeCodeProbedModel(
        value: id,
        resolvedModel: usage.model,
        contextWindow: usage.window,
      );
    }
    return ClaudeCodeProbeResult(
      models: models,
      defaultWindow: defaultWindow,
      extras: extras,
    );
  }
}

/// A request/response lane over one CLI process's stdin/stdout.
class _ControlSession {
  _ControlSession(this._process, this._requestTimeout) {
    _sub = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onDone, onError: (_) => _onDone());
    // Drained so a chatty stderr can never fill its pipe and stall the CLI.
    _process.stderr.listen((_) {});
  }

  final Process _process;
  final Duration _requestTimeout;
  late final StreamSubscription<String> _sub;
  final _pending = <String, Completer<Map<String, dynamic>>>{};
  var _next = 0;
  var _closed = false;

  void _onLine(String line) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (decoded is! Map || decoded['type'] != 'control_response') {
      return;
    }
    final response = decoded['response'];
    if (response is! Map) {
      return;
    }
    final completer = _pending.remove(response['request_id']);
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (response['subtype'] == 'success') {
      final body = response['response'];
      completer.complete(
        body is Map ? Map<String, dynamic>.from(body) : const {},
      );
    } else {
      completer.completeError(
        StateError('${response['error'] ?? 'control request failed'}'),
      );
    }
  }

  void _onDone() {
    _closed = true;
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('claude exited mid-probe'));
      }
    }
    _pending.clear();
    unawaited(_sub.cancel());
  }

  Future<Map<String, dynamic>> request(Map<String, Object?> body) {
    if (_closed) {
      return Future.error(StateError('claude exited mid-probe'));
    }
    final id = 'cc-models-${_next++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _process.stdin.writeln(
      jsonEncode({
        'type': 'control_request',
        'request_id': id,
        'request': body,
      }),
    );
    return completer.future.timeout(
      _requestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('claude control request timed out');
      },
    );
  }

  /// The current model's window, or null when the CLI could not say.
  Future<({int? window, String? model})?> contextUsage() async {
    try {
      final usage = await request({
        'subtype': 'get_context_usage',
        'detail': 'summary',
      });
      final raw = usage['rawMaxTokens'] ?? usage['maxTokens'];
      final model = usage['model'];
      return (
        window: raw is num && raw > 0 ? raw.toInt() : null,
        model: model is String ? model : null,
      );
    } on TimeoutException {
      rethrow;
    } on Object {
      return null;
    }
  }

  /// Switches to [id] and reads its window; null when the CLI refused [id].
  ///
  /// Strictly sequential: a usage read sent before `set_model` is answered
  /// measures the previous model.
  Future<({int? window, String? model})?> usageFor(String id) async {
    try {
      await request({'subtype': 'set_model', 'model': id});
    } on TimeoutException {
      rethrow;
    } on Object {
      return null;
    }
    return contextUsage();
  }
}
