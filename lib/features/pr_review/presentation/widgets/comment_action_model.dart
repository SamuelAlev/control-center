/// Whether [viewerLogin] wrote [authorLogin].
///
/// GitHub logins compare case-insensitively. A mismatched case would hide
/// Delete from the one person who can always remove their own comment.
bool commentIsAuthor(String? authorLogin, String? viewerLogin) {
  final author = authorLogin?.trim().toLowerCase() ?? '';
  final viewer = viewerLogin?.trim().toLowerCase() ?? '';
  if (author.isEmpty || viewer.isEmpty) {
    return false;
  }
  return author == viewer;
}

/// Whether the viewer may delete this comment.
///
/// An unpublished draft never reached the forge, so discarding it is local.
/// A published comment can be removed by its author, or by anyone whose repo
/// permission is `write` or `admin`. Anything else — read, none, or a
/// permission that has not loaded — cannot.
bool canDeleteComment({
  required bool isAuthor,
  required bool published,
  String? permission,
}) {
  if (!published || isAuthor) {
    return true;
  }
  return permission == 'write' || permission == 'admin';
}

/// Whether the viewer may rewrite this comment.
///
/// Editing replaces the author's words. Only the author of a comment that is
/// already on the forge gets that action; a draft is edited in the composer
/// that still holds it.
bool canEditComment({required bool isAuthor, required bool published}) =>
    isAuthor && published;

/// A forge permalink for [commentId], or empty when [htmlUrl] is missing.
///
/// GitHub, GitLab and Bitbucket each anchor a comment with a different
/// fragment. The host of [htmlUrl] picks the fragment; an unknown host uses
/// GitHub's, which is what a github.com pull request carries.
String commentPermalink({
  required String htmlUrl,
  required int commentId,
  required bool reviewComment,
}) {
  final trimmed = htmlUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final base = trimmed.split('#').first;
  final host = Uri.tryParse(base)?.host.toLowerCase() ?? '';
  final String fragment;
  if (host.contains('gitlab')) {
    fragment = 'note_$commentId';
  } else if (host.contains('bitbucket')) {
    fragment = 'comment-$commentId';
  } else if (reviewComment) {
    fragment = 'discussion_r$commentId';
  } else {
    fragment = 'issuecomment-$commentId';
  }
  return '$base#$fragment';
}

/// One comment in a thread, in reading order.
typedef CommentExcerpt = ({String author, String body});

/// The message handed to an agent: where the comment sits, then the words
/// themselves quoted so they read as the task and not as the agent's own.
String commentAgentPrompt({
  required String body,
  String? author,
  String? path,
  int? startLine,
  int? endLine,
  List<CommentExcerpt>? thread,
}) {
  final entries = (thread == null || thread.isEmpty)
      ? <CommentExcerpt>[(author: author ?? '', body: body)]
      : thread;
  final buf = StringBuffer()..writeln('Address this comment.');
  final where = commentLocation(path, startLine, endLine);
  if (where != null) {
    buf
      ..writeln()
      ..writeln(where);
  }
  buf.writeln();
  for (final entry in entries) {
    final who = entry.author.trim();
    if (who.isNotEmpty) {
      buf.writeln(who);
    }
    final text = entry.body.trim();
    if (text.isEmpty) {
      buf.writeln('>');
    } else {
      for (final line in text.split('\n')) {
        buf.writeln('> $line');
      }
    }
    buf.writeln();
  }
  return buf.toString().trimRight();
}

/// Markdown for the clipboard: the location, then each author and body.
String commentAsMarkdown({
  required String body,
  String? author,
  String? path,
  int? startLine,
  int? endLine,
  List<CommentExcerpt>? thread,
}) {
  final entries = (thread == null || thread.isEmpty)
      ? <CommentExcerpt>[(author: author ?? '', body: body)]
      : thread;
  final buf = StringBuffer();
  final where = commentLocation(path, startLine, endLine);
  if (where != null) {
    buf
      ..writeln('`$where`')
      ..writeln();
  }
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final who = entry.author.trim();
    if (who.isNotEmpty) {
      buf.writeln('**$who**');
    }
    final text = entry.body.trim();
    if (text.isNotEmpty) {
      buf.writeln(text);
    }
    if (i != entries.length - 1) {
      buf.writeln();
    }
  }
  return buf.toString().trimRight();
}

/// `path`, `path:line`, or `path:start-end`. Null when there is no path.
String? commentLocation(String? path, int? startLine, int? endLine) {
  final file = path?.trim() ?? '';
  if (file.isEmpty) {
    return null;
  }
  if (startLine == null && endLine == null) {
    return file;
  }
  final end = endLine ?? startLine!;
  final start = startLine ?? end;
  if (start != end) {
    return '$file:$start-$end';
  }
  return '$file:$end';
}
