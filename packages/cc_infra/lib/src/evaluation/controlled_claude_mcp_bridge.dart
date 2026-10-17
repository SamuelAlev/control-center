import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
import 'package:path/path.dart' as p;

/// Private, per-attempt MCP endpoint. Claude owns no native tool authority;
/// each call crosses the same OS enclosure used by the builtin evaluator.
class ControlledClaudeMcpBridge {
  /// Opens a per-attempt bridge over tools restricted to the guest workspace.
  ControlledClaudeMcpBridge({
    required this.root,
    required this.cancellation,
    required this.visibleSkillHashes,
    this.visibleSkillFiles = const {},
    this.commandGuard,
  });

  /// Isolated attempt workspace containing the admitted skill packages.
  final String root;

  /// Cancellation shared with guest tool execution.
  final CancellationToken cancellation;

  /// Package digests for skills visible to this attempt.
  final Map<String, String> visibleSkillHashes;

  /// Paths admitted for each visible skill when recording exposure events.
  final Map<String, Set<String>> visibleSkillFiles;

  /// Optional server decision applied to controlled shell commands.
  final Future<String?> Function(String command)? commandGuard;

  /// Tool calls recorded for the attempt report.
  final toolEvents = <EvaluationToolEvent>[];

  /// Observed skill file loads and script executions.
  final skillEvents = <EvaluationSkillEvent>[];
  final _random = Random.secure();
  HttpServer? _server;
  int _activeCalls = 0;
  Completer<void>? _idle;
  late final String _secret = base64Url.encode(
    List.generate(32, (_) => _random.nextInt(256)),
  );
  late final ControlledEvaluationProcess _process = ControlledEvaluationProcess(
    root: root,
    home: '$root-home',
    readOnlyRoots: visibleSkillHashes.isEmpty
        ? const []
        : [p.join(root, '.agents')],
    cancellation: cancellation,
    commandGuard: commandGuard,
  );
  late final List<HarnessTool> _tools = [
    ...controlledFileTools(_process),
    ControlledEvaluationBashTool(_process),
  ];

  /// Authenticated loopback MCP endpoint after [start] completes.
  String get url => 'http://127.0.0.1:${_server!.port}/mcp';

  /// Per-attempt bearer token required by the endpoint.
  String get token => _secret;

  /// Advertised tool names and schema digests for surface verification.
  List<List<String>> get toolCatalog => [
    for (final tool in _tools)
      [
        'mcp__cc_controlled__${tool.name}',
        canonicalHash({
          'name': tool.name,
          'description': tool.description,
          'inputSchema': tool.inputSchema,
        }),
      ],
  ]..sort((a, b) => a.first.compareTo(b.first));

  /// Binds the authenticated MCP endpoint to a fresh loopback port.
  Future<void> start() async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    _server!.listen(_handle);
  }

  /// Closes the endpoint and waits for active tool calls to finish.
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    if (_activeCalls > 0) {
      await _idle!.future;
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.headers.set('Cache-Control', 'no-store');
    final origin = request.headers.value('Origin');
    if (request.uri.path != '/mcp' ||
        request.headers.value(HttpHeaders.authorizationHeader) !=
            'Bearer $_secret' ||
        (origin != null &&
            origin != 'http://127.0.0.1:${_server?.port}' &&
            origin != 'http://localhost:${_server?.port}')) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }
    if (request.method == 'GET' || request.method == 'DELETE') {
      response.statusCode = request.method == 'GET'
          ? HttpStatus.methodNotAllowed
          : HttpStatus.ok;
      await response.close();
      return;
    }
    if (request.method != 'POST' ||
        cancellation.isCancelled ||
        (request.contentLength > 64 * 1024)) {
      response.statusCode = HttpStatus.badRequest;
      await response.close();
      return;
    }
    try {
      final bytes = <int>[];
      await for (final part in request) {
        bytes.addAll(part);
        if (bytes.length > 64 * 1024) {
          throw const FormatException('MCP request too large');
        }
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> || value['jsonrpc'] != '2.0') {
        throw const FormatException('Invalid MCP request');
      }
      final id = value['id'];
      if (id == null) {
        response.statusCode = HttpStatus.accepted;
        await response.close();
        return;
      }
      Object result;
      switch (value['method']) {
        case 'initialize':
          result = {
            'protocolVersion': '2025-03-26',
            'capabilities': {
              'tools': {'listChanged': false},
            },
            'serverInfo': {
              'name': 'cc-controlled-evaluation',
              'version': '1.0.0',
            },
          };
        case 'ping':
          result = <String, dynamic>{};
        case 'tools/list':
          result = {
            'tools': [
              for (final tool in _tools)
                {
                  'name': tool.name,
                  'description': tool.description,
                  'inputSchema': tool.inputSchema,
                },
            ],
          };
        case 'tools/call':
          final params = value['params'];
          if (params is! Map ||
              params['name'] is! String ||
              params['arguments'] is! Map) {
            throw const FormatException('Invalid tool arguments');
          }
          final tool = _tools
              .where((tool) => tool.name == params['name'])
              .firstOrNull;
          if (tool == null) {
            throw const FormatException('Unknown tool');
          }
          final args = Map<String, dynamic>.from(params['arguments'] as Map);
          final answer = await _call(tool, args);
          result = {
            'content': [
              {'type': 'text', 'text': answer.content},
            ],
            'isError': answer.isError,
          };
        default:
          response.write(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': id,
              'error': {'code': -32601, 'message': 'Unsupported MCP method'},
            }),
          );
          await response.close();
          return;
      }
      response.write(
        jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
      );
    } on Object catch (error) {
      response.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': null,
          'error': {'code': -32600, 'message': '$error'},
        }),
      );
    }
    await response.close();
  }

  Future<HarnessToolResult> _call(
    HarnessTool tool,
    Map<String, dynamic> args,
  ) async {
    _activeCalls++;
    _idle ??= Completer<void>();
    try {
      return await _executeCall(tool, args);
    } finally {
      _activeCalls--;
      if (_activeCalls == 0) {
        _idle!.complete();
        _idle = null;
      }
    }
  }

  Future<HarnessToolResult> _executeCall(
    HarnessTool tool,
    Map<String, dynamic> args,
  ) async {
    if (cancellation.isCancelled || toolEvents.length >= 100) {
      return HarnessToolResult.error(
        'Evaluation stopped or tool limit reached',
      );
    }
    final name = tool.name;
    if (name == 'write' || name == 'edit') {
      final paths = <String>[
        if (args['path'] is String) args['path'] as String,
        for (final e in args['edits'] as List? ?? const [])
          if (e is Map && e['path'] is String) e['path'] as String,
      ];
      for (final path in paths) {
        final normalized = p.normalize(
          p.isAbsolute(path) ? p.relative(path, from: root) : path,
        );
        if (normalized == '..' ||
            normalized.startsWith('../') ||
            p.isAbsolute(normalized) ||
            normalized == '.agents' ||
            normalized.startsWith('.agents/')) {
          return HarnessToolResult.error(
            'Immutable skills or outside workspace',
          );
        }
      }
    }
    final context = HarnessToolContext(
      workingDirectory: root,
      workspaceId: 'cc-eval',
      conversationId: 'cc-eval',
      agentId: 'cc-eval',
      cancel: cancellation,
    );
    final answer = await tool.execute(args, context);
    toolEvents.add(
      EvaluationToolEvent(
        name: name,
        isError: answer.isError,
        target: args['path'] is String ? args['path'] as String : null,
      ),
    );
    if (!answer.isError) {
      _observe(name, args, answer);
    }
    return answer;
  }

  void _observe(
    String name,
    Map<String, dynamic> args,
    HarnessToolResult answer,
  ) {
    String? path;
    String? kind;
    if (name == 'read' &&
        args['path'] is String &&
        answer.content.startsWith('[file ${args['path']} lines=')) {
      path = args['path'] as String;
      kind = 'body_load';
    } else if (name == 'bash' && args['command'] is String) {
      final match = RegExp(
        r'^\s*(?:bash|python3)\s+(?:\./)?(\.agents/skills/[^\s;&|]+)\s*$',
      ).firstMatch(args['command'] as String);
      path = match?.group(1);
      kind = 'script_execution';
    }
    if (path == null) {
      return;
    }
    final normalized = p
        .normalize(p.isAbsolute(path) ? p.relative(path, from: root) : path)
        .replaceAll(p.separator, '/');
    for (final entry in visibleSkillHashes.entries) {
      final prefix = '.agents/skills/${entry.key}/';
      if (!normalized.startsWith(prefix)) {
        continue;
      }
      final relative = normalized.substring(prefix.length);
      if (relative.isEmpty ||
          relative == '.' ||
          relative.startsWith('../') ||
          !(visibleSkillFiles[entry.key]?.contains(relative) ?? false)) {
        return;
      }
      skillEvents.add(
        EvaluationSkillEvent(
          kind: kind == 'body_load' && relative != 'SKILL.md'
              ? 'reference_load'
              : kind!,
          skillHash: entry.value,
          atEpochMs: DateTime.now().millisecondsSinceEpoch,
          origin: name == 'read' ? 'tool_read' : 'shell',
          path: normalized,
        ),
      );
      return;
    }
  }
}
