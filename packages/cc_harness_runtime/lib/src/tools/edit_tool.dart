import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';

/// Applies one or more find/replace edits across one or more files, atomically.
///
/// Accepts either a single edit (top-level `path`/`old_text`/`new_text`) or a
/// batch via `edits`. Every edit is validated first — each `old_text` must be
/// present and unique unless `replace_all` is set — and the whole batch is
/// computed in memory before anything is written, so a failure leaves the tree
/// untouched (no partial edits). Edits to the same file apply in order against
/// its evolving content. Write-tier — gated by the approval callback.
class EditTool extends HarnessTool {
  /// Creates an [EditTool].
  EditTool();

  @override
  String get name => 'edit';

  @override
  String get description =>
      'Apply find/replace edits to files. Pass a single edit '
      '(path, old_text, new_text) or a batch via `edits`. Each old_text must '
      'appear exactly once unless replace_all is true. All edits apply '
      'atomically — if any fails to match, nothing is written.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'Single-edit target file.'},
      'old_text': {
        'type': 'string',
        'description': 'Single-edit text to find.',
      },
      'new_text': {
        'type': 'string',
        'description': 'Single-edit replacement text.',
      },
      'replace_all': {
        'type': 'boolean',
        'description': 'Replace every occurrence instead of requiring one.',
      },
      'edits': {
        'type': 'array',
        'description':
            'Batch of edits, applied atomically across files. Each item: '
            '{path, old_text, new_text, replace_all?}.',
        'items': {
          'type': 'object',
          'properties': {
            'path': {'type': 'string'},
            'old_text': {'type': 'string'},
            'new_text': {'type': 'string'},
            'replace_all': {'type': 'boolean'},
          },
          'required': ['path', 'old_text', 'new_text'],
        },
      },
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final List<_Edit> edits;
    try {
      edits = _parseEdits(args);
    } on _EditError catch (e) {
      return HarnessToolResult.error(e.message);
    }
    if (edits.isEmpty) {
      return HarnessToolResult.error(
        'No edits provided. Pass path/old_text/new_text or an `edits` array.',
      );
    }

    // Resolve + load each distinct file once, then apply its edits in order to
    // an in-memory buffer. Nothing is written until every edit validates.
    final buffers = <String, String>{}; // resolved path → working content
    final displayName = <String, String>{}; // resolved path → arg path
    final perFileCount = <String, int>{};
    for (final edit in edits) {
      final resolved = resolveInsideWorkspace(
        context.workingDirectory,
        edit.path,
        sharedRoots: context.sharedRoots,
      );
      if (resolved == null) {
        return HarnessToolResult.error(
          outsideWorkspaceMessage(
            'edit',
            edit.path,
            workspaceRoot: context.workingDirectory,
            sharedRoots: context.sharedRoots,
          ),
        );
      }
      if (!buffers.containsKey(resolved)) {
        final file = File(resolved);
        if (!file.existsSync()) {
          return HarnessToolResult.error('File not found: ${edit.path}');
        }
        try {
          buffers[resolved] = file.readAsStringSync();
        } on FileSystemException catch (e) {
          return HarnessToolResult.error(
            'Failed to read ${edit.path}: ${e.message}',
          );
        }
        displayName[resolved] = edit.path;
        perFileCount[resolved] = 0;
      }

      final content = buffers[resolved]!;
      final occurrences = edit.oldText.allMatches(content).length;
      if (occurrences == 0) {
        return HarnessToolResult.error(
          'old_text not found in ${edit.path}. The file may have changed; '
          'read it again before editing.',
        );
      }
      if (occurrences > 1 && !edit.replaceAll) {
        return HarnessToolResult.error(
          'old_text appears $occurrences times in ${edit.path}; it must be '
          'unique (or set replace_all). Add surrounding context to '
          'disambiguate.',
        );
      }
      buffers[resolved] = edit.replaceAll
          ? content.replaceAll(edit.oldText, edit.newText)
          : content.replaceFirst(edit.oldText, edit.newText);
      perFileCount[resolved] = perFileCount[resolved]! + 1;
    }

    // All edits validated — commit.
    for (final entry in buffers.entries) {
      try {
        File(entry.key).writeAsStringSync(entry.value);
      } on FileSystemException catch (e) {
        return HarnessToolResult.error(
          'Failed to write ${displayName[entry.key]}: ${e.message}',
        );
      }
    }

    if (buffers.length == 1) {
      final only = buffers.keys.first;
      return HarnessToolResult.success(
        'Edited ${displayName[only]} (${perFileCount[only]} '
        'change${perFileCount[only] == 1 ? '' : 's'}).',
      );
    }
    final summary = buffers.keys
        .map((k) => '${displayName[k]} (${perFileCount[k]})')
        .join(', ');
    return HarnessToolResult.success(
      'Edited ${buffers.length} files: $summary.',
    );
  }

  List<_Edit> _parseEdits(Map<String, dynamic> args) {
    final raw = args['edits'];
    if (raw is List) {
      return [
        for (final item in raw)
          if (item is Map) _editFrom(Map<String, dynamic>.from(item)),
      ];
    }
    return [_editFrom(args)];
  }

  _Edit _editFrom(Map<String, dynamic> m) {
    final path = m['path'];
    final oldText = m['old_text'];
    final newText = m['new_text'];
    if (path is! String || path.isEmpty) {
      throw const _EditError('Missing or invalid argument: path');
    }
    if (oldText is! String || oldText.isEmpty) {
      throw const _EditError('Missing or invalid argument: old_text');
    }
    if (newText is! String) {
      throw const _EditError('Missing or invalid argument: new_text');
    }
    return _Edit(
      path: path,
      oldText: oldText,
      newText: newText,
      replaceAll: m['replace_all'] == true,
    );
  }
}

class _Edit {
  const _Edit({
    required this.path,
    required this.oldText,
    required this.newText,
    required this.replaceAll,
  });

  final String path;
  final String oldText;
  final String newText;
  final bool replaceAll;
}

class _EditError implements Exception {
  const _EditError(this.message);
  final String message;
}
