import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_client.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/lsp/lsp_symbol_position.dart';
import 'package:path/path.dart' as p;

/// Gives the agent everything the IDE knows: diagnostics, navigation, symbol
/// search and code actions.
///
/// **The gap this closes.** Control Center's code graph gives the agent
/// structure — symbols, call edges, an impact radius — from tree-sitter. What
/// it cannot give is TYPES: whether the call actually compiles, whether that
/// field exists, whether the rename missed a re-export. Without a language
/// server an agent finds out at `dart analyze` time, or never.
///
/// **Addressing is by symbol, not by column.** A model asked for a column
/// number guesses, and a wrong guess silently resolves to a different symbol
/// on the same line — the answer looks plausible and is about the wrong thing.
/// Here it supplies `line` plus a `symbol` substring (with an optional
/// `name#2` occurrence selector) and the tool resolves the column. Omitting
/// `symbol` on a navigation action is a hard error rather than a first-column
/// guess.
class LspTool extends HarnessTool {
  /// Creates an [LspTool].
  LspTool({
    required LspSupervisor supervisor,
    required DiagnosticsLedger ledger,
    required String workingDirectory,
  }) : _supervisor = supervisor,
       _ledger = ledger,
       _workingDirectory = workingDirectory;

  final LspSupervisor _supervisor;
  final DiagnosticsLedger _ledger;
  final String _workingDirectory;

  @override
  String get name => 'lsp';

  @override
  String get description =>
      'Query the language server: diagnostics, go-to-definition, references, '
      'hover, symbol search and code actions. Use `diagnostics` after editing '
      'to check your work compiles, and `references` before changing a '
      'signature. Address a position with `line` plus a `symbol` substring — '
      'never a column.';

  /// Read tier, and that is what SPLITS this tool from `LspRenameTool`.
  ///
  /// The tier is a property of the tool, not of the call — it decides which
  /// surfaces even SEE the tool (plan mode and read-only subagents are capped
  /// at `read`). Folding a project-wide rename into this tool would either
  /// hand a read-only explorer the ability to rewrite the repo, or gate every
  /// hover behind an approval prompt. Splitting gets both right with no new
  /// mechanism.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': [
          'diagnostics',
          'definition',
          'type_definition',
          'implementation',
          'references',
          'hover',
          'symbols',
          'code_actions',
          'status',
          'reload',
        ],
        'description':
            'diagnostics: errors/warnings for a file (or "*" for the whole '
            'project). definition/type_definition/implementation/references/'
            'hover: navigation at a position. symbols: document symbols for a '
            'file, or a workspace-wide search with `query`. code_actions: '
            'list available fixes. status: which servers are running. '
            'reload: restart them.',
      },
      'file': {
        'type': 'string',
        'description':
            'Path to the file. For `diagnostics`, "*" reports every file the '
            'servers currently know about.',
      },
      'line': {
        'type': 'integer',
        'description': '1-indexed line for a position-based action.',
      },
      'symbol': {
        'type': 'string',
        'description':
            'Substring identifying the symbol ON that line; the tool resolves '
            'the column. Use `name#2` for the second occurrence. REQUIRED '
            'with `line` for definition/references.',
      },
      'query': {
        'type': 'string',
        'description': 'Workspace symbol search term (with action=symbols).',
      },
    },
    'required': ['action'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final action = args['action'] as String?;
    if (action == null || action.isEmpty) {
      return HarnessToolResult.error('lsp requires an action.');
    }
    final root = findProjectRoot(_workingDirectory);

    if (action == 'status') {
      return HarnessToolResult.success(_renderStatus(root));
    }
    if (action == 'reload') {
      await _supervisor.reload(root);
      _ledger.clear();
      return HarnessToolResult.success(
        'Language servers restarted. ${_renderStatus(root)}',
      );
    }

    if (action == 'symbols' && args['file'] == null) {
      return _workspaceSymbols(root, args['query'] as String?);
    }

    final rawFile = args['file'] as String?;
    if (rawFile == null || rawFile.isEmpty) {
      return HarnessToolResult.error('lsp $action requires `file`.');
    }
    if (action == 'diagnostics' && rawFile == '*') {
      return _projectDiagnostics(root);
    }

    final path = p.isAbsolute(rawFile)
        ? rawFile
        : p.normalize(p.join(_workingDirectory, rawFile));
    final file = File(path);
    if (!file.existsSync()) {
      return HarnessToolResult.error('No such file: $rawFile');
    }

    if (action == 'diagnostics') {
      return _fileDiagnostics(root, path);
    }

    // Everything below is position-based and must not be answered by a linter.
    final client = await _supervisor.clientForFile(
      root,
      path,
      typeIntelligenceOnly: true,
    );
    if (client == null) {
      return HarnessToolResult.error(
        'No language server available for ${p.basename(path)}. '
        '${_renderStatus(root)}',
      );
    }

    final content = await file.readAsString();
    await client.syncFile(path, content);

    final line = (args['line'] as num?)?.toInt();
    if (line == null) {
      return HarnessToolResult.error('lsp $action requires `line`.');
    }
    final column = resolveSymbolColumn(content, line, args['symbol'] as String?);
    if (column is String) {
      return HarnessToolResult.error(column);
    }

    switch (action) {
      case 'definition':
        return _locations(client, path, line, column as int, 'definition');
      case 'type_definition':
        return _locations(client, path, line, column as int, 'typeDefinition');
      case 'implementation':
        return _locations(client, path, line, column as int, 'implementation');
      case 'references':
        return _references(client, path, line, column as int);
      case 'hover':
        return _hover(client, path, line, column as int);
      case 'symbols':
        return _documentSymbols(client, path);
      case 'code_actions':
        return _codeActions(client, path, line, column as int);
      default:
        return HarnessToolResult.error('Unknown lsp action: $action');
    }
  }

  String _renderStatus(String root) {
    final servers = _supervisor.statusFor(root);
    if (servers.isEmpty) {
      return 'No language servers detected for $root (no matching project '
          'markers, or the binaries are not installed).';
    }
    return 'Language servers in $root: '
        '${servers.map((s) => '${s.name} (${s.status}'
            '${s.isLinter ? ', linter' : ''})').join(', ')}';
  }

  Future<HarnessToolResult> _fileDiagnostics(String root, String path) async {
    final clients = await _supervisor.clientsForFile(root, path);
    if (clients.isEmpty) {
      return HarnessToolResult.error(
        'No language server available for ${p.basename(path)}.',
      );
    }
    final content = await File(path).readAsString();
    final all = <LspDiagnostic>[];
    for (final client in clients) {
      await client.syncFile(path, content);
      all.addAll(await client.waitForDiagnostics(path));
    }
    // An explicit query wants the CURRENT state, not the delta — the ledger's
    // job is to keep automatic post-edit reports quiet, not to hide what the
    // agent directly asked for. Recording it keeps the next automatic report
    // consistent with what the agent has already been told.
    _ledger.fresh(path, all);
    if (all.isEmpty) {
      return HarnessToolResult.success('No diagnostics in ${p.basename(path)}.');
    }
    return HarnessToolResult.success(
      renderDiagnostics(all, limit: 50, includePath: false),
    );
  }

  /// Project-wide diagnostics WITHOUT asking every server to index everything.
  ///
  /// A workspace-wide LSP pull is slow and, on several servers, unsupported.
  /// The project's own checker answers the same question far faster and is
  /// what a human would run — so `file: "*"` shells out to it.
  Future<HarnessToolResult> _projectDiagnostics(String root) async {
    final checks = <({List<String> argv, String marker})>[
      (argv: ['dart', 'analyze', '--fatal-infos=false'], marker: 'pubspec.yaml'),
      (argv: ['cargo', 'check', '--message-format=short'], marker: 'Cargo.toml'),
      (argv: ['go', 'build', './...'], marker: 'go.mod'),
      (argv: ['npx', 'tsc', '--noEmit'], marker: 'tsconfig.json'),
    ];
    for (final check in checks) {
      if (!File(p.join(root, check.marker)).existsSync()) {
        continue;
      }
      try {
        final result = await Process.run(
          check.argv.first,
          check.argv.sublist(1),
          workingDirectory: root,
          runInShell: true,
        ).timeout(const Duration(minutes: 3));
        final output = '${result.stdout}\n${result.stderr}'.trim();
        if (output.isEmpty) {
          return HarnessToolResult.success('No project diagnostics.');
        }
        final lines = output.split('\n');
        final shown = lines.take(50).join('\n');
        return HarnessToolResult.success(
          lines.length > 50
              ? '$shown\n… and ${lines.length - 50} more lines'
              : shown,
        );
      } on Object catch (e) {
        return HarnessToolResult.error('Project check failed: $e');
      }
    }
    // No project checker: fall back to whatever the running servers know.
    final all = <LspDiagnostic>[];
    for (final config in _supervisor.serversFor(root)) {
      final client = await _supervisor.clientFor(config, root);
      if (client != null) {
        all.addAll(client.allDiagnostics());
      }
    }
    return HarnessToolResult.success(
      all.isEmpty
          ? 'No diagnostics reported.'
          : renderDiagnostics(all, limit: 50),
    );
  }

  Future<HarnessToolResult> _locations(
    LspClient client,
    String path,
    int line,
    int column,
    String kind,
  ) async {
    final result = await client.request(
      'textDocument/$kind',
      client.positionParams(path, line, column),
    );
    final locations = _flattenLocations(result);
    if (locations.isEmpty) {
      return HarnessToolResult.success('No $kind found.');
    }
    return HarnessToolResult.success(locations.join('\n'));
  }

  Future<HarnessToolResult> _references(
    LspClient client,
    String path,
    int line,
    int column,
  ) async {
    final params = {
      ...client.positionParams(path, line, column),
      'context': {'includeDeclaration': true},
    };
    var result = await client.request('textDocument/references', params);
    var locations = _flattenLocations(result);
    // Anti-flake retry: a server that is still indexing answers with only the
    // declaration itself. That is indistinguishable from "genuinely unused",
    // which is a dangerous thing to tell an agent about to delete something.
    if (locations.length <= 1) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      result = await client.request('textDocument/references', params);
      locations = _flattenLocations(result);
    }
    if (locations.isEmpty) {
      return HarnessToolResult.success('No references found.');
    }
    final shown = locations.take(50).toList();
    return HarnessToolResult.success(
      locations.length > shown.length
          ? '${shown.join('\n')}\n… and ${locations.length - shown.length} more'
          : shown.join('\n'),
    );
  }

  Future<HarnessToolResult> _hover(
    LspClient client,
    String path,
    int line,
    int column,
  ) async {
    final result = await client.request(
      'textDocument/hover',
      client.positionParams(path, line, column),
    );
    if (result is! Map) {
      return HarnessToolResult.success('No hover information.');
    }
    final contents = result['contents'];
    final text = switch (contents) {
      String() => contents,
      Map() => '${contents['value'] ?? ''}',
      List() => contents
          .map((c) => c is Map ? '${c['value'] ?? ''}' : '$c')
          .join('\n'),
      _ => '',
    };
    return HarnessToolResult.success(
      text.trim().isEmpty ? 'No hover information.' : text.trim(),
    );
  }

  Future<HarnessToolResult> _documentSymbols(
    LspClient client,
    String path,
  ) async {
    final result = await client.request('textDocument/documentSymbol', {
      'textDocument': {'uri': Uri.file(path).toString()},
    });
    final out = <String>[];
    void walk(Object? node, int depth) {
      if (node is List) {
        for (final child in node) {
          walk(child, depth);
        }
        return;
      }
      if (node is! Map) {
        return;
      }
      final name = node['name'];
      // Servers answer with either `DocumentSymbol` (a `range`) or the older
      // `SymbolInformation` (a nested `location.range`); accept both.
      final location = node['location'];
      final range =
          (node['range'] ?? (location is Map ? location['range'] : null))
              as Map?;
      final startLine =
          ((range?['start'] as Map?)?['line'] as num?)?.toInt() ?? 0;
      out.add('${'  ' * depth}$name  (line ${startLine + 1})');
      walk(node['children'], depth + 1);
    }

    walk(result, 0);
    if (out.isEmpty) {
      return HarnessToolResult.success('No symbols found.');
    }
    final shown = out.take(200).toList();
    return HarnessToolResult.success(
      out.length > shown.length
          ? '${shown.join('\n')}\n… and ${out.length - shown.length} more'
          : shown.join('\n'),
    );
  }

  Future<HarnessToolResult> _workspaceSymbols(
    String root,
    String? query,
  ) async {
    if (query == null || query.isEmpty) {
      return HarnessToolResult.error(
        'symbols needs either `file` (document symbols) or `query` '
        '(workspace search).',
      );
    }
    final out = <String>[];
    for (final config in _supervisor.serversFor(root)) {
      if (config.isLinter) {
        continue;
      }
      final client = await _supervisor.clientFor(config, root);
      if (client == null) {
        continue;
      }
      final result = await client.request('workspace/symbol', {
        'query': query,
      });
      for (final item in (result as List?) ?? const []) {
        if (item is! Map) {
          continue;
        }
        final location = item['location'];
        final uri = location is Map ? location['uri'] : null;
        final startLine = location is Map
            ? (((location['range'] as Map?)?['start'] as Map?)?['line'] as num?)
                  ?.toInt()
            : null;
        final path = uri is String
            ? p.relative(Uri.parse(uri).toFilePath(), from: root)
            : '?';
        out.add('${item['name']}  $path:${(startLine ?? 0) + 1}');
      }
    }
    if (out.isEmpty) {
      return HarnessToolResult.success('No symbols matching "$query".');
    }
    final shown = out.take(100).toList();
    return HarnessToolResult.success(
      out.length > shown.length
          ? '${shown.join('\n')}\n… and ${out.length - shown.length} more'
          : shown.join('\n'),
    );
  }

  Future<HarnessToolResult> _codeActions(
    LspClient client,
    String path,
    int line,
    int column,
  ) async {
    final result = await client.request('textDocument/codeAction', {
      'textDocument': {'uri': Uri.file(path).toString()},
      'range': {
        'start': {'line': line - 1, 'character': column - 1},
        'end': {'line': line - 1, 'character': column - 1},
      },
      'context': {'diagnostics': <Object>[]},
    });
    final titles = [
      for (final item in (result as List?) ?? const [])
        if (item is Map && item['title'] != null) '${item['title']}',
    ];
    return HarnessToolResult.success(
      titles.isEmpty
          ? 'No code actions available here.'
          : titles.map((t) => '- $t').join('\n'),
    );
  }

  List<String> _flattenLocations(Object? result) {
    final out = <String>[];
    void visit(Object? node) {
      if (node is List) {
        for (final child in node) {
          visit(child);
        }
        return;
      }
      if (node is! Map) {
        return;
      }
      final uri = node['uri'] ?? node['targetUri'];
      final range = node['range'] ?? node['targetSelectionRange'];
      if (uri is! String) {
        return;
      }
      final start = ((range as Map?)?['start'] as Map?)?.cast<String, dynamic>();
      final line = ((start?['line'] as num?)?.toInt() ?? 0) + 1;
      final column = ((start?['character'] as num?)?.toInt() ?? 0) + 1;
      final path = p.relative(
        Uri.parse(uri).toFilePath(),
        from: _workingDirectory,
      );
      out.add('$path:$line:$column');
    }

    visit(result);
    return out;
  }
}
