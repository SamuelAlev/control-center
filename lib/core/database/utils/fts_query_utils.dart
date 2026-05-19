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
