import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/jsonrpc_process/jsonrpc_process_client.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_server_registry.dart';
import 'package:path/path.dart' as p;

/// One connected language server: handshake, document sync, and the requests
/// the `lsp` tool exposes.
///
/// Owns no policy — which server to start, when to start it and how long to
/// keep it are the supervisor's job. This is the protocol.
class LspClient {
  LspClient._(this.config, this.rootPath, this._rpc);

  /// Starts [config] against [rootPath] and completes the LSP handshake.
  ///
  /// Returns null when the server cannot be spawned or does not answer
  /// `initialize` in time. A null is a normal outcome, not an error: a machine
  /// without that toolchain installed simply has no server for it, and the
  /// tool reports "no server" rather than failing the run.
  static Future<LspClient?> start({
    required LspServerConfig config,
    required String rootPath,
    Duration warmupTimeout = const Duration(seconds: 20),
  }) async {
    final binary = resolveServerBinary(config.command, rootPath);
    if (binary == null) {
      return null;
    }
    final JsonRpcProcessClient rpc;
    try {
      rpc = await JsonRpcProcessClient.start(
        command: binary,
        args: config.args,
        workingDirectory: rootPath,
        name: config.name,
      );
    } on Object catch (e) {
      CcInfraLog.warning('lsp: could not spawn ${config.name}: $e');
      return null;
    }

    final client = LspClient._(config, rootPath, rpc);
    try {
      await client._initialize(warmupTimeout);
      return client;
    } on Object catch (e) {
      CcInfraLog.warning(
        'lsp: ${config.name} failed to initialize: $e'
        '${rpc.stderrLog.isEmpty ? '' : ' — ${rpc.stderrLog.last}'}',
      );
      await rpc.close();
      return null;
    }
  }

  /// The server's definition.
  final LspServerConfig config;

  /// The workspace root the server was started against.
  final String rootPath;

  final JsonRpcProcessClient _rpc;
  final Map<String, List<LspDiagnostic>> _diagnostics = {};
  final Map<String, int> _versions = {};
  final Set<String> _open = {};
  final Map<String, List<Completer<void>>> _diagnosticWaiters = {};
  Map<String, dynamic> _capabilities = const {};
  StreamSubscription<JsonRpcInbound>? _inboundSub;

  /// Whether the underlying process is gone.
  bool get isDead => _rpc.isDead;

  /// The server's advertised capabilities.
  Map<String, dynamic> get capabilities => _capabilities;

  Future<void> _initialize(Duration timeout) async {
    _inboundSub = _rpc.inbound.listen(_onInbound);
    final result = await _rpc.request('initialize', {
      'processId': pid,
      'clientInfo': {'name': 'control-center'},
      'rootUri': _uriOf(rootPath),
      'workspaceFolders': [
        {'uri': _uriOf(rootPath), 'name': p.basename(rootPath)},
      ],
      'capabilities': {
        'textDocument': {
          'synchronization': {'didSave': true, 'dynamicRegistration': false},
          'publishDiagnostics': {'relatedInformation': false},
          'hover': {'contentFormat': ['plaintext', 'markdown']},
          'definition': {'linkSupport': false},
          'references': <String, dynamic>{},
          'documentSymbol': {'hierarchicalDocumentSymbolSupport': true},
          'rename': {'prepareSupport': false},
          'codeAction': <String, dynamic>{},
        },
        'workspace': {
          'workspaceFolders': true,
          'symbol': <String, dynamic>{},
          'applyEdit': true,
          'configuration': true,
        },
      },
      'initializationOptions': ?config.initOptions,
    }, timeout: timeout);
    if (result is Map) {
      _capabilities =
          (result['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {};
    }
    _rpc.notify('initialized', <String, dynamic>{});
    final settings = config.settings;
    if (settings != null) {
      _rpc.notify('workspace/didChangeConfiguration', {'settings': settings});
    }
  }

  void _onInbound(JsonRpcInbound message) {
    switch (message.method) {
      case 'textDocument/publishDiagnostics':
        final uri = message.params['uri'];
        if (uri is! String) {
          return;
        }
        final path = _pathOf(uri);
        final raw = message.params['diagnostics'];
        _diagnostics[path] = [
          for (final d in (raw as List?) ?? const [])
            if (d is Map) _toDiagnostic(path, d.cast<String, dynamic>()),
        ];
        // Wake anyone waiting on this file's diagnostics. Settling on the
        // publish rather than on a fixed sleep is what makes the wait both
        // fast for a healthy server and bounded for a slow one.
        final waiters = _diagnosticWaiters.remove(path);
        if (waiters != null) {
          for (final waiter in waiters) {
            if (!waiter.isCompleted) {
              waiter.complete();
            }
          }
        }
      case 'window/showMessage':
      case 'window/logMessage':
        break;
      case 'workspace/configuration':
        // Answer with per-item settings so a server that blocks on this (rust
        // -analyzer does) can finish starting.
        final id = message.id;
        if (id != null) {
          final items = (message.params['items'] as List?) ?? const [];
          _rpc.respond(id, [
            for (var i = 0; i < items.length; i++)
              config.settings ?? <String, dynamic>{},
          ]);
        }
      default:
        // Any other server request gets a null result rather than silence: an
        // unanswered request leaves some servers waiting forever.
        final id = message.id;
        if (id != null) {
          _rpc.respond(id, null);
        }
    }
  }

  LspDiagnostic _toDiagnostic(String path, Map<String, dynamic> json) {
    final range = (json['range'] as Map?)?.cast<String, dynamic>();
    final start = (range?['start'] as Map?)?.cast<String, dynamic>();
    final severity = switch ((json['severity'] as num?)?.toInt()) {
      1 => 'error',
      2 => 'warning',
      3 => 'info',
      _ => 'hint',
    };
    final code = json['code'];
    return LspDiagnostic(
      path: path,
      // LSP positions are 0-indexed; everything a human or a model reads is
      // 1-indexed, and mixing the two is the classic off-by-one here.
      line: ((start?['line'] as num?)?.toInt() ?? 0) + 1,
      column: ((start?['character'] as num?)?.toInt() ?? 0) + 1,
      severity: severity,
      message: (json['message'] as String? ?? '').trim(),
      source: json['source'] as String?,
      code: code == null ? null : '$code',
    );
  }

  /// Opens or re-syncs [path] with the server, using [content] as its text.
  Future<void> syncFile(String path, String content) async {
    final uri = _uriOf(path);
    final version = (_versions[path] ?? 0) + 1;
    _versions[path] = version;
    if (_open.add(path)) {
      _rpc.notify('textDocument/didOpen', {
        'textDocument': {
          'uri': uri,
          'languageId': _languageIdOf(path),
          'version': version,
          'text': content,
        },
      });
    } else {
      _rpc.notify('textDocument/didChange', {
        'textDocument': {'uri': uri, 'version': version},
        // Full sync: incremental sync buys nothing here because the agent
        // rewrote the file on disk and we have the whole new text anyway.
        'contentChanges': [
          {'text': content},
        ],
      });
    }
    _rpc.notify('textDocument/didSave', {
      'textDocument': {'uri': uri},
      'text': content,
    });
  }

  /// Closes [path] on the server.
  void closeFile(String path) {
    if (_open.remove(path)) {
      _rpc.notify('textDocument/didClose', {
        'textDocument': {'uri': _uriOf(path)},
      });
    }
  }

  /// Waits until the server publishes diagnostics for [path], or [timeout]
  /// elapses. Returns whatever is currently known either way.
  ///
  /// A timeout is NOT an error: a server that is still indexing legitimately
  /// has nothing to say yet, and the caller's fallback (report late, or report
  /// nothing) is better than failing an edit that succeeded.
  Future<List<LspDiagnostic>> waitForDiagnostics(
    String path, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();
    (_diagnosticWaiters[path] ??= []).add(completer);
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      _diagnosticWaiters[path]?.remove(completer);
    }
    return _diagnostics[path] ?? const [];
  }

  /// The diagnostics currently known for [path], without waiting.
  List<LspDiagnostic> diagnosticsFor(String path) =>
      _diagnostics[path] ?? const [];

  /// Every diagnostic the server has published, across all files.
  List<LspDiagnostic> allDiagnostics() => [
    for (final entry in _diagnostics.entries) ...entry.value,
  ];

  /// Sends a raw request. Used by the higher-level operations.
  Future<Object?> request(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 20),
  }) => _rpc.request(method, params, timeout: timeout);

  /// Builds the `textDocument`/`position` pair every navigation request needs.
  Map<String, dynamic> positionParams(String path, int line, int column) => {
    'textDocument': {'uri': _uriOf(path)},
    'position': {'line': line - 1, 'character': column - 1},
  };

  /// Shuts the server down politely, then kills it.
  Future<void> close() async {
    await _inboundSub?.cancel();
    try {
      await _rpc.request(
        'shutdown',
        null,
        timeout: const Duration(seconds: 2),
      );
      _rpc.notify('exit');
    } on Object {
      // A server that will not shut down gets killed below; the polite path is
      // an optimization, not a requirement.
    }
    await _rpc.close();
  }

  /// Converts an absolute path to a `file://` URI.
  static String _uriOf(String path) => Uri.file(path).toString();

  /// Converts a `file://` URI back to a path.
  static String _pathOf(String uri) {
    try {
      return Uri.parse(uri).toFilePath();
    } on Object {
      return uri;
    }
  }

  static String _languageIdOf(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.dart':
        return 'dart';
      case '.ts':
        return 'typescript';
      case '.tsx':
        return 'typescriptreact';
      case '.js':
      case '.mjs':
      case '.cjs':
        return 'javascript';
      case '.jsx':
        return 'javascriptreact';
      case '.rs':
        return 'rust';
      case '.go':
        return 'go';
      case '.py':
      case '.pyi':
        return 'python';
      case '.c':
        return 'c';
      case '.cc':
      case '.cpp':
      case '.h':
      case '.hpp':
        return 'cpp';
      case '.lua':
        return 'lua';
      case '.sh':
      case '.bash':
        return 'shellscript';
      default:
        return 'plaintext';
    }
  }
}
