/// Converts raw user text into an FTS5 query expression that uses OR
/// between tokens (default AND would force every word to appear). Drops
/// punctuation and FTS5 operator characters, one-letter Latin tokens and
/// common English stopwords, so "what's my name?" becomes `"name"*` instead
/// of an empty / malformed expression that silently returns zero rows.
///
/// Tokens are runs of Unicode letters, digits and combining marks: the same
/// characters the FTS tables' `unicode61` tokenizer keeps, so Japanese, Arabic
/// or Hindi text is searched as written rather than stripped to nothing. Each
/// token is quoted, so no FTS5 syntax can leak from it. A single non-Latin
/// character is a whole word in some scripts (`猫`), so only ASCII tokens need
/// two characters.
String toFtsOrQuery(String raw) {
  const stopwords = {
    'a',
    'an',
    'the',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'i',
    'me',
    'my',
    'mine',
    'we',
    'us',
    'our',
    'you',
    'your',
    'he',
    'she',
    'it',
    'they',
    'them',
    'their',
    'and',
    'or',
    'but',
    'if',
    'in',
    'on',
    'at',
    'to',
    'of',
    'for',
    'with',
    'by',
    'as',
    'from',
    'this',
    'that',
    'these',
    'those',
    'what',
    'who',
    'whom',
    'whose',
    'where',
    'when',
    'why',
    'how',
    'do',
    'does',
    'did',
    'have',
    'has',
    'had',
    's',
    't',
    'm',
    're',
    've',
    'll',
    'd',
  };
  final tokens = _token
      .allMatches(raw.toLowerCase())
      .map((m) => m[0]!)
      .where(
        (t) => (t.length >= 2 || !_ascii.hasMatch(t)) && !stopwords.contains(t),
      )
      .toSet();
  if (tokens.isEmpty) {
    return '';
  }
  // Tokens hold only letters, digits and marks, so a quote cannot occur in
  // one; the quotes keep words like `NEAR` from being read as operators.
  return tokens.map((t) => '"$t"*').join(' OR ');
}

/// One query token: a run of Unicode letters, digits and combining marks.
final _token = RegExp(r'[\p{L}\p{N}\p{M}]+', unicode: true);

/// Only ASCII characters.
final _ascii = RegExp(r'^[\x00-\x7f]*$');

/// Builds a **workspace-scoped** FTS5 MATCH expression.
///
/// The user query (from [raw]) is matched only against [textColumns] and the whole match is
/// constrained to rows whose `workspace_id` FTS column equals [workspaceId].
/// This scopes the FTS scan to a single workspace *at the index level* — the virtual table
/// itself never yields another workspace's docs — rather than leaning solely on a post-join
/// `WHERE workspace_id = ?` filter.
String toWorkspaceScopedFtsMatch(
  String raw,
  String workspaceId, {
  required List<String> textColumns,
}) {
  final orQuery = toFtsOrQuery(raw);
  if (orQuery.isEmpty) {
    return '';
  }
  final cols = '{${textColumns.join(' ')}}';
  final textExpr = '$cols : ($orQuery)';
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(workspaceId)) {
    return textExpr;
  }
  // Strip embedded double-quotes so the value stays a single FTS5 phrase.
  final phrase = '"${workspaceId.replaceAll('"', '')}"';
  return '($textExpr) AND (workspace_id : $phrase)';
}
