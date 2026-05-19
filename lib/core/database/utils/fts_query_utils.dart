/// Converts raw user text into an FTS5 query expression that uses OR
/// between tokens (default AND would force every word to appear). Drops
/// FTS5 operator characters, very short tokens, and common stopwords so
/// "what's my name?" becomes `name*` instead of an empty / malformed
/// expression that silently returns zero rows.
String toFtsOrQuery(String raw) {
  const stopwords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been',
    'i', 'me', 'my', 'mine', 'we', 'us', 'our', 'you', 'your',
    'he', 'she', 'it', 'they', 'them', 'their',
    'and', 'or', 'but', 'if', 'in', 'on', 'at', 'to', 'of', 'for',
    'with', 'by', 'as', 'from', 'this', 'that', 'these', 'those',
    'what', 'who', 'whom', 'whose', 'where', 'when', 'why', 'how',
    'do', 'does', 'did', 'have', 'has', 'had',
    's', 't', 'm', 're', 've', 'll', 'd',
  };
  final tokens = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 2 && !stopwords.contains(t))
      .toSet();
  if (tokens.isEmpty) {
    return '';
  }
  return tokens.map((t) => '$t*').join(' OR ');
}

/// Builds a **workspace-scoped** FTS5 MATCH expression.
///
/// The user query (from [raw]) is matched only against [textColumns], and the
/// whole match is constrained to rows whose `workspace_id` FTS column equals
/// [workspaceId]. This scopes the FTS scan to a single workspace *at the index
/// level* — the virtual table itself never yields another workspace's docs —
/// rather than leaning solely on a post-join `WHERE workspace_id = ?` filter.
///
/// Callers MUST still apply that exact `workspace_id = ?` filter on the joined
/// content table: this expression is the index-level narrowing (and the
/// authoritative isolation boundary remains the SQL filter, which also handles
/// the degenerate case below). Returns '' when [raw] yields no usable tokens,
/// so callers can short-circuit to an empty result.
///
/// The FTS table stores the raw workspace id; FTS5 tokenizes it identically on
/// both sides, so a UUID matches as a contiguous phrase against exactly its own
/// rows. If [workspaceId] contains no alphanumeric character (so it would
/// tokenize to nothing), the workspace clause is omitted and isolation falls
/// back entirely to the caller's exact SQL filter.
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
