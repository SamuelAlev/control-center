import 'dart:io';

import 'package:cc_harness/tools.dart';

/// Commits or discards a change a tool staged instead of writing.
///
/// **Why an explicit tool rather than a magic write.** Committing a staged
/// change by writing to a pseudo-path keeps the schema small at the
/// cost of making the commit invisible: nothing in the transcript says a
/// forty-file rewrite just landed, because it looks like an ordinary write. Our
/// approval surface is a GUI, and a card that says "accept these 40 files"
/// needs a call it can be attached to. So the commit is its own tool, its own
/// approval, and its own line in the transcript.
///
/// **The staleness check is the whole safety property.** Between staging and
/// committing, the agent may have edited one of those files by hand, a
/// diagnostics pass may have rewritten it, or a watcher may have reformatted
/// it. Committing anyway would silently discard that work, and the diff would
/// look intentional. So every file is compared against the content captured at
/// staging time and the whole change is refused on any mismatch — never
/// partially applied, because a partly-applied structural rewrite leaves a tree
/// that compiles under neither shape.
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
