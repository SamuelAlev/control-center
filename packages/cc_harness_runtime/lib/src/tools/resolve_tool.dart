import 'dart:io';

import 'package:cc_harness/tools.dart';

/// Commits or discards a staged change as its own tool (visible approval +
/// transcript line). Refuses the whole change if any file drifted since staging
/// — never partially applied.
class ResolveTool extends HarnessTool {
  /// Creates a [ResolveTool] over [store].
  ResolveTool(this.store);

  /// Where staged changes live. Shared with whatever staged them.
  final StagedEditStore store;

  @override
  String get name => 'resolve';

  @override
  String get description =>
      'Apply or discard a change a tool staged instead of writing. Pass the '
      'edit_id from the (proposed) result. action "accept" writes every file '
      'at once; "discard" drops it. A file that changed since it was staged '
      'refuses the whole change.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'edit_id': {
        'type': 'string',
        'description': 'The id from the staged (proposed) result.',
      },
      'action': {
        'type': 'string',
        'enum': ['accept', 'discard'],
        'description': 'Whether to write the change or drop it.',
      },
    },
    'required': ['edit_id', 'action'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final id = args['edit_id'];
    if (id is! String || id.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: edit_id');
    }
    final action = args['action'];
    if (action != 'accept' && action != 'discard') {
      return HarnessToolResult.error(
        'action must be "accept" or "discard", got: $action',
      );
    }

    final staged = store.peek(id);
    if (staged == null) {
      final pending = store.pending;
      return HarnessToolResult.error(
        pending.isEmpty
            ? 'No staged change "$id". It was already resolved, or the tool '
                  'that staged it wrote directly.'
            : 'No staged change "$id". Pending: '
                  '${pending.map((s) => s.id).join(', ')}.',
      );
    }

    if (action == 'discard') {
      store.discard(id);
      return HarnessToolResult.success(
        'Discarded $id (${staged.summary}). Nothing was written.',
      );
    }

    final rejection = store.validate(id, (path) {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      try {
        return file.readAsStringSync();
      } on FileSystemException {
        return null;
      }
    });
    if (rejection == StagedEditRejection.stale) {
      store.discard(id);
      return HarnessToolResult.error(
        'Refused: a file changed since $id was staged, so applying it would '
        'discard that change. The staged edit has been dropped — re-run the '
        'tool against the current files.',
      );
    }

    // Validated as a set, so the write is a set too.
    final written = <String>[];
    for (final file in staged.files) {
      if (file.isNoop) {
        continue;
      }
      try {
        File(file.path).writeAsStringSync(file.after);
        written.add(file.path);
      } on FileSystemException catch (e) {
        // A mid-write failure is the one case that cannot be atomic — report
        // exactly what landed rather than implying nothing did.
        store.discard(id);
        return HarnessToolResult.error(
          'Wrote ${written.length} of ${staged.files.length} files, then '
          'failed on ${file.path}: ${e.message}. Written: '
          '${written.join(', ')}.',
        );
      }
    }
    store.take(id);
    return HarnessToolResult.success(
      'Applied $id: ${staged.summary}. ${staged.replacements} '
      'replacement${staged.replacements == 1 ? '' : 's'} across '
      '${written.length} file${written.length == 1 ? '' : 's'}.',
    );
  }
}
