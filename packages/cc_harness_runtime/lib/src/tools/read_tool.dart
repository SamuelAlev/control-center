import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_file_search.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';

/// Reads a file from the workspace and returns line-numbered content.
///
/// Supports `offset`/`limit` paging and a `sel` line-range selector
/// (`"50"`, `"50-200"`, `"50+150"`). Binary files are rejected with a clear
/// message rather than dumping bytes into the model context.
class ReadTool extends HarnessTool {
  /// Creates a [ReadTool].
  ///
  /// [onRead] (when set) is called with the full file content on every read so
  /// a shared edit service can snapshot it for later drift-tolerant patching.
  /// [hashOf] (when set) computes the content hash prepended as a header so the
  /// model can anchor `apply_patch` edits to the version it read.
  /// [fileSearch] (when set) powers did-you-mean recovery: a read of a path
  /// that does not exist fuzzy-searches the workspace (fff-backed in Control
  /// Center) and returns the closest matches instead of a bare not-found.
  ReadTool({this.onRead, this.hashOf, this.fileSearch});

  /// Records the read content (path, content) for drift recovery.
  final void Function(String path, String content)? onRead;

  /// Computes the content hash shown in the read header.
  final String Function(String content)? hashOf;

  /// Fuzzy file search used to suggest paths when the requested one is absent.
  final FileSearchPort? fileSearch;

  @override
  String get name => 'read';

  @override
  String get description =>
      'Read a file from the workspace and return its content with line '
      'numbers. Use offset/limit to page through large files, or sel for a '
      'line range (e.g. "50-200").';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Absolute or workspace-relative path to the file.',
      },
      'offset': {
        'type': 'integer',
        'description': 'Line to start reading from (1-indexed).',
        'default': 1,
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of lines to read.',
        'default': 2000,
      },
      'sel': {
        'type': 'string',
        'description':
            'Line selector: "50", "50-200", or "50+150" (50 lines '
            'from line 50). Overrides offset/limit.',
      },
    },
    'required': ['path'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final path = args['path'];
    if (path is! String || path.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: path');
    }
    final resolved = resolveInsideWorkspace(
      context.workingDirectory,
      path,
      sharedRoots: context.sharedRoots,
    );
    if (resolved == null) {
      return HarnessToolResult.error(
        outsideWorkspaceMessage(
          'read',
          path,
          workspaceRoot: context.workingDirectory,
          sharedRoots: context.sharedRoots,
        ),
      );
    }
    final file = File(resolved);
    if (!file.existsSync()) {
      final suggestions = await _suggestPaths(
        path,
        root: context.workingDirectory,
        sharedRoots: context.sharedRoots,
      );
      if (suggestions.isEmpty) {
        return HarnessToolResult.error('File not found: $path');
      }
      return HarnessToolResult.error(
        'File not found: $path\n'
        'Did you mean one of these?\n'
        '${suggestions.map((s) => '  $s').join('\n')}',
      );
    }

    final String content;
    String? fileHash;
    try {
      // Async, not `readAsStringSync`: this tool runs inside cc_server, where
      // a synchronous read of a large file blocks every concurrent RPC.
      content = await file.readAsString();
      if (_looksBinary(content)) {
        return HarnessToolResult.error('Cannot read binary file: $path');
      }
      onRead?.call(resolved, content);
      fileHash = hashOf?.call(content);
    } on FileSystemException catch (e) {
      return HarnessToolResult.error('Failed to read $path: ${e.message}');
    } on FormatException {
      return HarnessToolResult.error('Cannot read binary file: $path');
    }

    var start = ((args['offset'] as num?)?.toInt() ?? 1) - 1;
    var count = (args['limit'] as num?)?.toInt() ?? 2000;
    final sel = args['sel'];
    if (sel is String && sel.isNotEmpty) {
      final range = _parseSel(sel);
      if (range != null) {
        start = range.$1 - 1;
        count = range.$2;
      }
    }
    if (start < 0) {
      start = 0;
    }
    // Only the requested window is materialized. `content.split('\n')` on a
    // 50k-line file allocates 50k strings to hand back 20 of them.
    final window = _lineWindow(content, start, count);
    if (start >= window.totalLines) {
      return HarnessToolResult.success(
        '(file has ${window.totalLines} lines; offset $start is past the end)',
      );
    }
    final buffer = StringBuffer();
    if (fileHash != null) {
      // Anchor header for apply_patch: pass this file_hash back with edits.
      buffer.writeln('[file $path hash=$fileHash lines=${window.totalLines}]');
    }
    for (var i = 0; i < window.lines.length; i++) {
      buffer.writeln('${start + i + 1}\t${window.lines[i]}');
    }
    return HarnessToolResult.success(buffer.toString().trimRight());
  }

  /// Counts the file's lines in one scan and slices out only `[start, start +
  /// count)`, matching `content.split('\n')` semantics (a trailing newline
  /// yields a final empty line).
  static ({List<String> lines, int totalLines}) _lineWindow(
    String content,
    int start,
    int count,
  ) {
    final selected = <String>[];
    var line = 0;
    var lineStart = 0;
    final end = start + count;
    for (var i = 0; i <= content.length; i++) {
      final atEnd = i == content.length;
      if (!atEnd && content.codeUnitAt(i) != 0x0A) {
        continue;
      }
      if (line >= start && line < end) {
        selected.add(content.substring(lineStart, i));
      }
      line++;
      lineStart = i + 1;
      if (atEnd) {
        break;
      }
    }
    return (lines: selected, totalLines: line);
  }

  /// Fuzzy-searches the workspace for paths resembling the missing [path]
  /// (basename first — the query fff scores best on — falling back to the
  /// full relative path). Returns workspace-relative candidates, best first.
  ///
  /// Covers [sharedRoots] as well as [root]: a stale path from the code index
  /// or an agent's memory almost always points into a repo worktree, which
  /// lives in a shared root — suggesting nothing there is what turns one
  /// not-found into a long guess-and-retry loop.
  Future<List<String>> _suggestPaths(
    String path, {
    required String root,
    List<String> sharedRoots = const [],
  }) async {
    final search = fileSearch;
    if (search == null) {
      return const [];
    }
    final basename = path.split('/').last;
    try {
      var matches = await searchWorkspaceFiles(
        search,
        basename,
        workspaceRoot: root,
        sharedRoots: sharedRoots,
        limit: 5,
      );
      if (matches.isEmpty && basename != path) {
        matches = await searchWorkspaceFiles(
          search,
          path,
          workspaceRoot: root,
          sharedRoots: sharedRoots,
          limit: 5,
        );
      }
      return [
        for (final m in matches)
          if (!m.isDirectory) m.path,
      ];
    } catch (_) {
      // Suggestions are best-effort; a search failure must not mask the
      // original not-found error.
      return const [];
    }
  }

  /// Parses a selector into a (1-indexed start, count) pair.
  (int, int)? _parseSel(String sel) {
    final plus = sel.indexOf('+');
    if (plus != -1) {
      final start = int.tryParse(sel.substring(0, plus).trim());
      final len = int.tryParse(sel.substring(plus + 1).trim());
      if (start != null && len != null) {
        return (start, len);
      }
      return null;
    }
    final dash = sel.indexOf('-');
    if (dash != -1) {
      final start = int.tryParse(sel.substring(0, dash).trim());
      final endLine = int.tryParse(sel.substring(dash + 1).trim());
      if (start != null && endLine != null && endLine >= start) {
        return (start, endLine - start + 1);
      }
      return null;
    }
    final single = int.tryParse(sel.trim());
    if (single != null) {
      return (single, 1);
    }
    return null;
  }

  static bool _looksBinary(String content) {
    final limit = content.length > 8000 ? 8000 : content.length;
    for (var i = 0; i < limit; i++) {
      if (content.codeUnitAt(i) == 0) {
        return true;
      }
    }
    return false;
  }
}
