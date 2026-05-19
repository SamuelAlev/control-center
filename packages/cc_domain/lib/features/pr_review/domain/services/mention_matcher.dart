/// Matching `@mentions` in forge comment bodies.
///
/// Extracted from the GitHub bot bridge so the same matcher serves both lanes:
/// the bot deciding whether a comment addresses it, and the viewer lane
/// deciding whether a comment addresses the operator. Two regexes for one
/// question is how "the bot heard you but your notification didn't" happens.
library;

/// The logins a comment may @mention to address [login].
///
/// For a GitHub App bot (`<slug>[bot]`) that is the full login AND the bare
/// slug — the full form is punishing to type and absent from GitHub's @
/// autocomplete, so accepting the short form is OUR matcher's decision, made
/// wherever comment text is matched rather than by the forge.
///
/// The collision this invites is stated rather than smoothed: a HUMAN whose
/// login equals an app's slug would be addressed by the same short form. Slug
/// and user logins are visible to whoever registered the app, so the operator
/// picks a distinctive slug or lives with the ambiguity.
///
/// For a plain human login the short form equals the login, so this returns a
/// single entry and the bracket handling is inert.
List<String> acceptedMentionLogins(String login) {
  if (login.isEmpty) {
    return const [];
  }
  final short = login.toLowerCase().endsWith('[bot]')
      ? login.substring(0, login.length - '[bot]'.length)
      : login;
  return short.isEmpty || short == login ? [login] : [login, short];
}

/// Whether [body] @mentions [login] (or its bare slug, for a bot).
///
/// Case-insensitive (forge logins are) and boundary-aware: the lookahead
/// rejects a longer login continuing at the same spot — including an opening
/// `[`, so a bare slug does not match inside another bracketed account like
/// `@app[bots]` — while allowing any other punctuation: `@app[bot]:` matches,
/// `@app[bot]x` does not, `@app!` matches. `\b` cannot express this because
/// the bracketed `[bot]` suffix ends in a non-word character.
bool bodyMentions(String body, String login) {
  if (login.isEmpty || body.isEmpty) {
    return false;
  }
  return acceptedMentionLogins(
    login,
  ).any((l) => mentionPattern(l).hasMatch(body));
}

/// Whether [body] @mentions any of [logins].
bool bodyMentionsAny(String body, Iterable<String> logins) =>
    logins.any((l) => bodyMentions(body, l));

/// Strips the first @mention of [login] from [body].
///
/// The full login is tried first so `@app[bot] question` strips to `question`,
/// not `[bot] question`.
String stripMention(String body, String login) {
  if (login.isEmpty) {
    return body;
  }
  for (final l in acceptedMentionLogins(login)) {
    final stripped = body.replaceFirst(mentionPattern(l), '').trim();
    if (stripped != body) {
      return stripped;
    }
  }
  return body.trim();
}

/// The boundary-aware mention pattern for one login.
RegExp mentionPattern(String login) =>
    RegExp('@${RegExp.escape(login)}(?![a-zA-Z0-9-\\[])', caseSensitive: false);

/// One comment reduced to what thread-membership needs.
typedef MentionThreadComment = ({
  int id,
  int? inReplyToId,
  String? authorLogin,
});

/// The ids of comments belonging to a thread [isAuthor] participates in.
///
/// A comment qualifies when any comment in its reply chain (itself included)
/// satisfies [isAuthor]. The predicate rather than a login is what lets the bot
/// lane keep its broader test (ours specifically, OR any `[bot]` account, which
/// is its loop guard against other bots) while the viewer lane uses an exact
/// login match.
///
/// A parent the list does not carry (deleted, or page-truncated) ends the walk:
/// the thread cannot be proven to be theirs, so it is not.
Set<int> threadCommentIdsAuthoredBy(
  Iterable<MentionThreadComment> comments,
  bool Function(String? login) isAuthor,
) {
  final all = comments.toList();
  final byId = {for (final c in all) c.id: c};
  final matched = <int>{};
  for (final comment in all) {
    var current = comment;
    var guard = 0;
    while (guard++ < 100) {
      if (isAuthor(current.authorLogin)) {
        matched.add(comment.id);
        break;
      }
      final parentId = current.inReplyToId;
      if (parentId == null) {
        break;
      }
      final parent = byId[parentId];
      if (parent == null) {
        break;
      }
      current = parent;
    }
  }
  return matched;
}
