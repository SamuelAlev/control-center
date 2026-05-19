/// A parsed pull-request search query: a set of author logins plus free text.
///
/// This is our own, deliberately small search vocabulary. An
/// `author:@<login>` (or `author:<login>`) qualifier — repeatable — narrows the
/// queue to those authors, and everything else is free text. A search adapter
/// (`PrSearchPort`) maps this backend-neutral query onto a concrete provider
/// (GitHub's `/search/issues` today, any other forge tomorrow); the app itself
/// never speaks a provider's query language.
class PrSearchQuery {
  /// Creates a [PrSearchQuery].
  const PrSearchQuery({this.authors = const {}, this.text = ''});

  /// Parses a raw search string into a [PrSearchQuery]. Author qualifiers are
  /// extracted (and removed) wherever they appear; the remainder, with
  /// collapsed whitespace, becomes [text]. Empty author tokens are dropped.
  factory PrSearchQuery.parse(String raw) {
    final authors = <String>{};
    final stripped = raw.replaceAllMapped(_authorToken, (match) {
      final login = match.group(1)!.toLowerCase();
      if (login.isNotEmpty) {
        authors.add(login);
      }
      return ' ';
    });
    final text = stripped.replaceAll(_whitespace, ' ').trim();
    return PrSearchQuery(authors: authors, text: text);
  }

  /// An empty query — the queue falls back to its unfiltered population.
  static const empty = PrSearchQuery();

  /// Author logins to filter by, lowercased and without a leading `@`. When
  /// more than one is present they OR together.
  final Set<String> authors;

  /// Free-text terms (title/body), with the `author:` qualifiers stripped out
  /// and whitespace collapsed.
  final String text;

  // `author:`, an optional `@`, then an (optionally empty) login. Matching a
  // bare `author:`/`author:@` with no login lets [parse] strip dangling tokens
  // (mid-typing) instead of leaking them into the free text.
  static final _authorToken = RegExp(
    r'author:@?([A-Za-z0-9-]*)',
    caseSensitive: false,
  );

  static final _whitespace = RegExp(r'\s+');

  /// Whether the query carries no constraint at all.
  bool get isEmpty => authors.isEmpty && text.isEmpty;

  /// Whether the query narrows the queue.
  bool get isActive => !isEmpty;

  /// Renders the backend-neutral qualifier fragment a search adapter appends to
  /// its provider-specific scope. Produces `author:a author:b free text`.
  String toQualifiers() {
    final parts = <String>[
      for (final author in authors) 'author:$author',
      if (text.isNotEmpty) text,
    ];
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrSearchQuery &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          _setEquals(authors, other.authors);

  @override
  int get hashCode => Object.hash(text, Object.hashAllUnordered(authors));

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final value in a) {
      if (!b.contains(value)) {
        return false;
      }
    }
    return true;
  }
}
