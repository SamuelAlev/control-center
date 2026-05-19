import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_client.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/lsp/lsp_symbol_position.dart';
import 'package:path/path.dart' as p;

/// Renames a symbol across the project through the language server.
///
/// Split from `LspTool` because it WRITES, and `approvalTier` is what decides
/// which surfaces see a tool at all. A rename living on the read tool would
/// hand plan mode and every read-only explorer the ability to rewrite the
/// repo; gating the whole read tool at `write` would instead put an approval
/// prompt in front of every hover. Two tools gets both right with no new
/// mechanism.
///
/// Worth having as a distinct verb rather than find-and-replace: the server
/// follows re-exports, imports and aliases, so the edit reaches files a
/// textual search would never have found — and it will NOT rewrite an
/// unrelated identifier that merely shares the name.
class LspRenameTool extends HarnessTool {
  /// Creates an [LspRenameTool].
  LspRenameTool({
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
  String get name => 'lsp_rename';

  @override
  String get description =>
      'Rename a symbol across the whole project using the language server. '
      'Prefer this over find-and-replace: it follows re-exports, imports and '
      'aliases, and will not rename an unrelated identifier that happens to '
      'share the name. Address the symbol with `file` + `line` + `symbol`.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.fileWriteOutsideWorktree,
  };

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'file': {'type': 'string', 'description': 'File holding the symbol.'},
      'line': {
        'type': 'integer',
        'description': '1-indexed line the symbol appears on.',
      },
      'symbol': {
        'type': 'string',
        'description':
            'The current name, as a substring of that line. Use `name#2` for '
            'the second occurrence.',
      },
      'new_name': {'type': 'string', 'description': 'The new name.'},
    },
    'required': ['file', 'line', 'symbol', 'new_name'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final rawFile = args['file'] as String?;
    final line = (args['line'] as num?)?.toInt();
    if (rawFile == null || rawFile.isEmpty || line == null) {
      return HarnessToolResult.error('lsp_rename requires `file` and `line`.');
    }
    final path = p.isAbsolute(rawFile)
        ? rawFile
        : p.normalize(p.join(_workingDirectory, rawFile));
    final file = File(path);
    if (!file.existsSync()) {
      return HarnessToolResult.error('No such file: $rawFile');
    }
    final root = findProjectRoot(_workingDirectory);
    final client = await _supervisor.clientForFile(
      root,
      path,
      typeIntelligenceOnly: true,
    );
    if (client == null) {
      return HarnessToolResult.error(
        'No language server available for ${p.basename(path)}.',
      );
    }
    final content = await file.readAsString();
    await client.syncFile(path, content);
    final column = resolveSymbolColumn(content, line, args['symbol'] as String?);
    if (column is String) {
      return HarnessToolResult.error(column);
    }
    return _rename(client, path, line, column as int, args['new_name'] as String?);
  }

  Future<HarnessToolResult> _rename(
    LspClient client,
    String path,
    int line,
    int column,
    String? newName,
  ) async {
    if (newName == null || newName.isEmpty) {
      return HarnessToolResult.error('rename requires `new_name`.');
    }
    final result = await client.request('textDocument/rename', {
      ...client.positionParams(path, line, column),
      'newName': newName,
    });
    if (result is! Map) {
      return HarnessToolResult.error(
        'The server declined the rename (the symbol may not be renameable '
        'here).',
      );
    }
    final edits = _collectEdits(result);
    if (edits.isEmpty) {
      return HarnessToolResult.error('The rename produced no edits.');
    }
    // Apply from a single snapshot, and apply each file's edits from the END
    // backwards so earlier offsets stay valid as later ones are rewritten.
    final touched = <String>[];
    for (final entry in edits.entries) {
      final file = File(entry.key);
      if (!file.existsSync()) {
        continue;
      }
      final lines = (await file.readAsString()).split('\n');
      final sorted = [...entry.value]..sort((a, b) {
        final byLine = b.line.compareTo(a.line);
        return byLine != 0 ? byLine : b.column.compareTo(a.column);
      });
      for (final edit in sorted) {
        if (edit.line < 0 || edit.line >= lines.length) {
          continue;
        }
        final text = lines[edit.line];
        if (edit.column > text.length || edit.endColumn > text.length) {
          continue;
        }
        lines[edit.line] =
            text.substring(0, edit.column) +
            edit.newText +
            text.substring(edit.endColumn);
      }
      await file.writeAsString(lines.join('\n'));
      touched.add(p.relative(entry.key, from: _workingDirectory));
      // The file changed underneath every ledger entry for it; a stale entry
      // would suppress a diagnostic the rename just introduced.
      _ledger.forget(entry.key);
    }
    final count = edits.values.fold<int>(0, (sum, e) => sum + e.length);
    return HarnessToolResult.success(
      'Renamed to "$newName": $count edit(s) across ${touched.length} file(s).'
      '\n${touched.map((t) => '- $t').join('\n')}',
    );
  }

  Map<String, List<_TextEdit>> _collectEdits(Map<Object?, Object?> workspace) {
    final out = <String, List<_TextEdit>>{};
    void add(String uri, Object? rawEdits) {
      final path = Uri.parse(uri).toFilePath();
      for (final raw in (rawEdits as List?) ?? const []) {
        if (raw is! Map) {
          continue;
        }
        final range = (raw['range'] as Map?)?.cast<String, dynamic>();
        final start = (range?['start'] as Map?)?.cast<String, dynamic>();
        final end = (range?['end'] as Map?)?.cast<String, dynamic>();
        if (start == null || end == null) {
          continue;
        }
        (out[path] ??= []).add(
          _TextEdit(
            line: (start['line'] as num?)?.toInt() ?? 0,
            column: (start['character'] as num?)?.toInt() ?? 0,
            endColumn: (end['character'] as num?)?.toInt() ?? 0,
            newText: raw['newText'] as String? ?? '',
          ),
        );
      }
    }

    final changes = workspace['changes'];
    if (changes is Map) {
      for (final entry in changes.entries) {
        add('${entry.key}', entry.value);
      }
    }
    final documentChanges = workspace['documentChanges'];
    if (documentChanges is List) {
      for (final change in documentChanges) {
        if (change is! Map) {
          continue;
        }
        final uri = (change['textDocument'] as Map?)?['uri'];
        if (uri is String) {
          add(uri, change['edits']);
        }
      }
    }
    return out;
  }
}

class _TextEdit {
  const _TextEdit({
    required this.line,
    required this.column,
    required this.endColumn,
    required this.newText,
  });
  final int line;
  final int column;
  final int endColumn;
  final String newText;
}
