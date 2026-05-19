/// One file a staged change would rewrite.
class StagedFileEdit {
  /// Creates a [StagedFileEdit].
  const StagedFileEdit({
    required this.path,
    required this.before,
    required this.after,
    required this.replacements,
  });

  /// Absolute path of the file.
  final String path;

  /// The file's content when the change was staged.
  ///
  /// Kept so the commit can verify nothing moved underneath it. Without this,
  /// a staged multi-file rewrite committed after the agent edited one of those
  /// files by hand would silently discard the hand edit.
  final String before;

  /// The content the commit would write.
  final String after;

  /// How many sites changed in this file.
  final int replacements;

  /// Whether this file would actually change.
  bool get isNoop => before == after;
}

/// A change that has been computed but not written.
class StagedEdit {
  /// Creates a [StagedEdit].
  const StagedEdit({
    required this.id,
    required this.tool,
    required this.summary,
    required this.files,
  });

  /// The handle the model passes to `resolve`.
  final String id;

  /// The tool that staged it, for the transcript card.
  final String tool;

  /// One line describing what it would do.
  final String summary;

  /// The files it would rewrite, in a stable order.
  final List<StagedFileEdit> files;

  /// Total sites changed.
  int get replacements => files.fold(0, (sum, f) => sum + f.replacements);
}

/// Why a commit was refused.
enum StagedEditRejection {
  /// No staged change with that id — usually already committed or discarded.
  unknown,

  /// A file changed on disk after the change was staged.
  stale,
}

/// Holds changes that were computed but not written, until something commits
/// or discards them.
///
/// **Why staging is worth a mechanism of its own.** A wide mechanical edit — a
/// codemod, a bulk rename, a structural rewrite across forty files — is the
/// one shape of change nobody reviews line by line, either the model or the
/// human. Applying it and reporting "done" means the first honest look at it
/// is a `git diff` after the fact. Staging turns it into two steps with a real
/// decision in between: the tool reports what it WOULD do and what it matched,
/// and the change lands only when something commits it.
///
/// **All or nothing, and that is the point.** A multi-file rewrite that writes
/// nineteen files and fails on the twentieth leaves a tree that compiles under
/// neither the old shape nor the new one. The store hands back every file at
/// once so the committer can write them as a unit and refuse the whole thing
/// if any one of them moved.
///
/// **It is not an approval mechanism.** Whether a human is asked is
/// `ConfirmationPort`'s and the guardrail policy's job; this only makes the
/// question askable, by giving the change a name and a body while it is still
/// hypothetical.
class StagedEditStore {
  /// Creates a [StagedEditStore].
  StagedEditStore({this.capacity = 8});

  /// How many staged changes are kept.
  ///
  /// Small on purpose: these hold whole file bodies twice over, and a staged
  /// change nobody committed within the next few tool calls is one the model
  /// abandoned. The oldest is evicted rather than refusing the new one — the
  /// change in front of the model is the one it is working on.
  final int capacity;

  final Map<String, StagedEdit> _staged = {};
  int _counter = 0;

  /// Everything currently staged, oldest first.
  List<StagedEdit> get pending => _staged.values.toList();

  /// Stages [files] under a fresh id and returns the record.
  StagedEdit stage({
    required String tool,
    required String summary,
    required List<StagedFileEdit> files,
  }) {
    // Deterministic and monotonic, not random: it goes in a tool result the
    // model reads back, and a replayed session has to produce the same one.
    final id = 'edit_${++_counter}';
    final staged = StagedEdit(
      id: id,
      tool: tool,
      summary: summary,
      files: files,
    );
    _staged[id] = staged;
    while (_staged.length > capacity) {
      _staged.remove(_staged.keys.first);
    }
    return staged;
  }

  /// The staged change with [id], or null.
  StagedEdit? peek(String id) => _staged[id];

  /// Removes and returns the staged change with [id].
  StagedEdit? take(String id) => _staged.remove(id);

  /// Drops [id] without committing it.
  bool discard(String id) => _staged.remove(id) != null;

  /// Drops everything.
  void clear() => _staged.clear();

  /// Checks a staged change against the current content of its files.
  ///
  /// [currentContent] returns what is on disk now, or null when the file is
  /// gone. Returns null when the change is still safe to apply.
  StagedEditRejection? validate(
    String id,
    String? Function(String path) currentContent,
  ) {
    final staged = _staged[id];
    if (staged == null) {
      return StagedEditRejection.unknown;
    }
    for (final file in staged.files) {
      if (currentContent(file.path) != file.before) {
        return StagedEditRejection.stale;
      }
    }
    return null;
  }
}

/// Renders a staged change the way the model should read it back.
///
/// Counts and paths, not a diff: the model already knows what it asked for, and
/// echoing forty file bodies back at it is how a preview costs more context
/// than the edit saved. The human's diff is the transcript card's job.
String describeStagedEdit(StagedEdit staged, {int maxFiles = 20}) {
  final buffer = StringBuffer()
    ..writeln('(proposed) ${staged.summary}')
    ..writeln(
      '${staged.replacements} replacement'
      '${staged.replacements == 1 ? '' : 's'} in '
      '${staged.files.length} file${staged.files.length == 1 ? '' : 's'}:',
    );
  for (final file in staged.files.take(maxFiles)) {
    buffer.writeln('  ${file.path} (${file.replacements})');
  }
  if (staged.files.length > maxFiles) {
    buffer.writeln('  … ${staged.files.length - maxFiles} more');
  }
  buffer.write(
    'Nothing has been written. Call resolve with edit_id "${staged.id}" and '
    'action "accept" to apply it, or "discard" to drop it.',
  );
  return buffer.toString();
}
