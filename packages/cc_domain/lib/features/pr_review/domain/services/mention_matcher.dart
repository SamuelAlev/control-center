/// Matching `@mentions` in forge comment bodies.
///
/// Extracted from the GitHub bot bridge so the same matcher serves both lanes:
/// the bot deciding whether a comment addresses it, and the viewer lane
/// deciding whether a comment addresses the operator. Two regexes for one
/// question is how "the bot heard you but your notification didn't" happens.
library;

/// The human GitHub account addressed in PR conversations.
const githubPrConversationMentionLogin = 'usectrl';

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

/// What [neutralizeMentions] puts between `@` and a name: a zero-width space,
/// invisible when rendered, which no forge reads as part of a mention.
const String mentionBreak = '\u200B';

final RegExp _mentionAt = RegExp(r'(?<![A-Za-z0-9_])@(?=[A-Za-z0-9_{])');
final RegExp _encodedAt = RegExp(
  r'&(?:#0*64|#x0*40|commat);',
  caseSensitive: false,
);
final RegExp _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})');
final RegExp _url = RegExp(r'https?://[^\s<>()\[\]]+', caseSensitive: false);

/// [body] with every @-mention outside code made inert, for text the Control
/// Center bot posts on a forge: an agent's words (or a pull request's,
/// steering an agent) must not page a user or a whole team (`@org/team`,
/// GitLab's `@all`) through the bot's account.
///
/// A zero-width space goes after the `@` ([mentionBreak]) so the text still
/// reads the same. Entity-encoded `@` (`&#64;`, `&#x40;`, `&commat;`) counts
/// too: forges decode it before they look for mentions. Fenced code blocks and
/// inline code spans are left as they are (no forge mentions inside code, and
/// `@Annotation` in a snippet must stay copyable), and so are URLs; an e-mail
/// address is not a mention. Idempotent.
String neutralizeMentions(String body) {
  if (!body.contains('@') && !body.contains('&')) {
    return body;
  }
  final out = StringBuffer();
  String? openFence;
  final lines = body.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final fence = _fence.firstMatch(line)?.group(1);
    if (openFence != null) {
      out.write(line);
      if (fence != null &&
          fence[0] == openFence[0] &&
          fence.length >= openFence.length &&
          line.trim() == fence) {
        openFence = null;
      }
    } else if (fence != null) {
      openFence = fence;
      out.write(line);
    } else {
      out.write(_neutralizeOutsideCodeSpans(line));
    }
    if (i < lines.length - 1) {
      out.write('\n');
    }
  }
  return out.toString();
}

/// [line] with mentions neutralized everywhere but inside inline code spans
/// (a run of N backticks up to the next run of exactly N).
String _neutralizeOutsideCodeSpans(String line) {
  // A URL keeps its `@` (`https://host/@user`): it links, it does not page.
  String plain(String text) => text.splitMapJoin(
    _url,
    onNonMatch: (t) => t
        .replaceAll(_encodedAt, '@$mentionBreak')
        .replaceAll(_mentionAt, '@$mentionBreak'),
  );
  final out = StringBuffer();
  var cursor = 0;
  var scan = 0;
  while (scan < line.length) {
    final open = line.indexOf('`', scan);
    if (open < 0) {
      break;
    }
    var slashes = 0;
    while (open - slashes > 0 && line[open - slashes - 1] == r'\') {
      slashes++;
    }
    if (slashes.isOdd) {
      // `\`` is a literal backtick, not the start of code.
      scan = open + 1;
      continue;
    }
    var openEnd = open;
    while (openEnd < line.length && line[openEnd] == '`') {
      openEnd++;
    }
    final run = openEnd - open;
    var close = -1;
    var search = openEnd;
    while (search < line.length) {
      final next = line.indexOf('`', search);
      if (next < 0) {
        break;
      }
      var nextEnd = next;
      while (nextEnd < line.length && line[nextEnd] == '`') {
        nextEnd++;
      }
      if (nextEnd - next == run) {
        close = nextEnd;
        break;
      }
      search = nextEnd;
    }
    if (close < 0) {
      // An unclosed run is literal text, not code.
      scan = openEnd;
      continue;
    }
    out
      ..write(plain(line.substring(cursor, open)))
      ..write(line.substring(open, close));
    cursor = close;
    scan = close;
  }
  out.write(plain(line.substring(cursor)));
  return out.toString();
}
