import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// One end of a multi-line diff position (`position[line_range][start]` /
/// `[end]`).
class GitLabLineRangeEnd {
  /// Creates a [GitLabLineRangeEnd].
  const GitLabLineRangeEnd({
    this.lineCode = '',
    this.type = '',
    this.oldLine,
    this.newLine,
  });

  /// Reads a [GitLabLineRangeEnd] off a decoded JSON object.
  factory GitLabLineRangeEnd.fromJson(Map<String, dynamic> json) =>
      GitLabLineRangeEnd(
        lineCode: json['line_code'] as String? ?? '',
        type: json['type'] as String? ?? '',
        oldLine: (json['old_line'] as num?)?.toInt(),
        newLine: (json['new_line'] as num?)?.toInt(),
      );

  /// Reads a [GitLabLineRangeEnd] from [raw] when it is an object, else null.
  static GitLabLineRangeEnd? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabLineRangeEnd.fromJson(raw) : null;

  /// GitLab's `<sha1(path)>_<old_line>_<new_line>` line identifier.
  final String lineCode;

  /// `new` (right side) or `old` (left side).
  final String type;

  /// Line number in the pre-image, when this end sits on the old side.
  final int? oldLine;

  /// Line number in the post-image, when this end sits on the new side.
  final int? newLine;

  /// Serializes back to the shape GitLab accepts on a discussion POST.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (lineCode.isNotEmpty) 'line_code': lineCode,
    if (type.isNotEmpty) 'type': type,
    'old_line': oldLine,
    'new_line': newLine,
  };
}

/// The multi-line span of a diff note.
class GitLabLineRange {
  /// Creates a [GitLabLineRange].
  const GitLabLineRange({this.start, this.end});

  /// Reads a [GitLabLineRange] off a decoded JSON object.
  factory GitLabLineRange.fromJson(Map<String, dynamic> json) =>
      GitLabLineRange(
        start: GitLabLineRangeEnd.maybeFromJson(json['start']),
        end: GitLabLineRangeEnd.maybeFromJson(json['end']),
      );

  /// Reads a [GitLabLineRange] from [raw] when it is an object, else null.
  static GitLabLineRange? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabLineRange.fromJson(raw) : null;

  /// First line of the span.
  final GitLabLineRangeEnd? start;

  /// Last line of the span — where the comment is anchored.
  final GitLabLineRangeEnd? end;

  /// Serializes back to the shape GitLab accepts on a discussion POST.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (start != null) 'start': start!.toJson(),
    if (end != null) 'end': end!.toJson(),
  };
}

/// Where in a diff a note is anchored.
///
/// A note carrying one of these is an inline review comment; a note without
/// one is a top-level conversation comment. That presence test is the only
/// thing separating the two on GitLab.
class GitLabNotePosition {
  /// Creates a [GitLabNotePosition].
  const GitLabNotePosition({
    this.baseSha = '',
    this.startSha = '',
    this.headSha = '',
    this.oldPath = '',
    this.newPath = '',
    this.positionType = 'text',
    this.oldLine,
    this.newLine,
    this.lineRange,
  });

  /// Reads a [GitLabNotePosition] off a decoded JSON object.
  factory GitLabNotePosition.fromJson(Map<String, dynamic> json) =>
      GitLabNotePosition(
        baseSha: json['base_sha'] as String? ?? '',
        startSha: json['start_sha'] as String? ?? '',
        headSha: json['head_sha'] as String? ?? '',
        oldPath: json['old_path'] as String? ?? '',
        newPath: json['new_path'] as String? ?? '',
        positionType: json['position_type'] as String? ?? 'text',
        oldLine: (json['old_line'] as num?)?.toInt(),
        newLine: (json['new_line'] as num?)?.toInt(),
        lineRange: GitLabLineRange.maybeFromJson(json['line_range']),
      );

  /// Reads a [GitLabNotePosition] from [raw] when it is an object, else null.
  static GitLabNotePosition? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabNotePosition.fromJson(raw) : null;

  /// Tip of the target branch the diff was computed against.
  final String baseSha;

  /// Merge-base of source and target.
  final String startSha;

  /// Tip of the source branch.
  final String headSha;

  /// Path before the change.
  final String oldPath;

  /// Path after the change.
  final String newPath;

  /// `text` for a line comment, `image` for an image comment.
  final String positionType;

  /// Anchored line in the pre-image. Set for a left-side comment.
  final int? oldLine;

  /// Anchored line in the post-image. Set for a right-side comment.
  final int? newLine;

  /// The multi-line span, when the comment covers more than one line.
  final GitLabLineRange? lineRange;

  /// The path this position refers to, preferring the post-image path.
  String get path => newPath.isNotEmpty ? newPath : oldPath;

  /// Serializes back to the shape GitLab accepts as `position` on a
  /// discussion POST.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'base_sha': baseSha,
    'start_sha': startSha,
    'head_sha': headSha,
    'position_type': positionType,
    if (oldPath.isNotEmpty) 'old_path': oldPath,
    if (newPath.isNotEmpty) 'new_path': newPath,
    if (oldLine != null) 'old_line': oldLine,
    if (newLine != null) 'new_line': newLine,
    if (lineRange != null) 'line_range': lineRange!.toJson(),
  };
}

/// A GitLab note — the single primitive behind every comment on a merge
/// request, inline or not.
class GitLabNote {
  /// Creates a [GitLabNote].
  const GitLabNote({
    required this.id,
    required this.body,
    this.author,
    this.createdAt,
    this.updatedAt,
    this.system = false,
    this.type = '',
    this.resolvable = false,
    this.resolved = false,
    this.noteableIid = 0,
    this.position,
  });

  /// Reads a [GitLabNote] off a decoded JSON object.
  factory GitLabNote.fromJson(Map<String, dynamic> json) => GitLabNote(
    id: (json['id'] as num?)?.toInt() ?? 0,
    body: json['body'] as String? ?? '',
    author: GitLabUser.maybeFromJson(json['author']),
    createdAt: parseDate(json['created_at']),
    updatedAt: parseDate(json['updated_at']),
    system: json['system'] as bool? ?? false,
    type: json['type'] as String? ?? '',
    resolvable: json['resolvable'] as bool? ?? false,
    resolved: json['resolved'] as bool? ?? false,
    noteableIid: (json['noteable_iid'] as num?)?.toInt() ?? 0,
    position: GitLabNotePosition.maybeFromJson(json['position']),
  );

  /// Reads an array of notes.
  static List<GitLabNote> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <GitLabNote>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GitLabNote.fromJson)
        .toList(growable: false);
  }

  /// Instance-wide note id. This is the `targetId` the reaction endpoints
  /// take, and the id a caller edits or deletes by.
  final int id;

  /// Markdown body.
  final String body;

  /// Author, when supplied.
  final GitLabUser? author;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last-edit timestamp.
  final DateTime? updatedAt;

  /// Whether GitLab generated this note itself ("changed the description",
  /// "assigned to @x"). System notes are activity, never comments.
  final bool system;

  /// `DiffNote` for an inline comment, `DiscussionNote` for a reply in a
  /// non-diff thread, empty for a plain individual note.
  final String type;

  /// Whether the note can be marked resolved.
  final bool resolvable;

  /// Whether the thread was resolved.
  final bool resolved;

  /// The `iid` of the merge request the note hangs off.
  final int noteableIid;

  /// The diff anchor. Non-null exactly when this is an inline comment.
  final GitLabNotePosition? position;
}

/// A GitLab discussion — an ordered thread of [GitLabNote]s.
///
/// This is the unit inline review comments are created and replied to in:
/// `POST .../discussions` opens a thread, `POST .../discussions/:id/notes`
/// appends to one. The discussion id is a hex string, not a number.
class GitLabDiscussion {
  /// Creates a [GitLabDiscussion].
  const GitLabDiscussion({
    required this.id,
    this.individualNote = false,
    this.notes = const <GitLabNote>[],
  });

  /// Reads a [GitLabDiscussion] off a decoded JSON object.
  factory GitLabDiscussion.fromJson(Map<String, dynamic> json) =>
      GitLabDiscussion(
        id: json['id']?.toString() ?? '',
        individualNote: json['individual_note'] as bool? ?? false,
        notes: GitLabNote.listFromJson(json['notes']),
      );

  /// Opaque discussion id — the `parentCommentId` a reply is addressed to.
  final String id;

  /// True when this "discussion" is really a standalone comment that GitLab
  /// wrapped in a single-note discussion.
  final bool individualNote;

  /// The thread's notes, oldest first.
  final List<GitLabNote> notes;

  /// The notes that are anchored to a diff line.
  Iterable<GitLabNote> get diffNotes => notes.where((n) => n.position != null);
}
