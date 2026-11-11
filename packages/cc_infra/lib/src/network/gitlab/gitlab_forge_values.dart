/// Pure value helpers behind `GitLabForgePrClient`: note ids, merge-commit
/// messages and handle sets.
library;

import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart'
    show ForgeReactionTarget;

/// The numeric note id behind [commentId]; GitLab note ids are integers, so
/// anything else is a caller bug and throws.
int gitLabNoteId(String commentId) {
  final noteId = int.tryParse(commentId.trim());
  if (noteId == null || noteId <= 0) {
    throw ArgumentError.value(
      commentId,
      'commentId',
      'GitLab note ids are integers',
    );
  }
  return noteId;
}

/// The note id behind a comment reaction target.
int gitLabReactionNoteId(String targetId, ForgeReactionTarget target) {
  final noteId = int.tryParse(targetId.trim());
  if (noteId == null || noteId <= 0) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'a ${target.name} reaction on GitLab needs a numeric note id',
    );
  }
  return noteId;
}

/// Joins a merge-commit title and body the way git writes them.
String? gitLabCommitMessage(String? title, String? message) {
  final head = title?.trim() ?? '';
  final tail = message?.trim() ?? '';
  if (head.isEmpty && tail.isEmpty) {
    return null;
  }
  if (head.isEmpty) {
    return tail;
  }
  if (tail.isEmpty) {
    return head;
  }
  return '$head\n\n$tail';
}

/// [values] trimmed and lower-cased, blanks dropped.
Set<String> lowercasedHandles(Iterable<String> values) => <String>{
  for (final value in values)
    if (value.trim().isNotEmpty) value.trim().toLowerCase(),
};
