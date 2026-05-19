// Deterministic, computed-once insights attached to a cohort: which SYMBOLS
// the diff actually touched (not just which files), and which test files cover
// them. Stored as one JSON blob on `review_cohorts.insights_json` so later
// deterministic signals can join the same row without another migration.
//
// Null-on-malformed throughout, the same discipline as `ReviewNodePayload`: a
// blob written by an older/newer server degrades to "no insights", never to a
// half-parsed lie.
//
// ignore_for_file: sort_constructors_first

/// Where a cohort's symbol spans were read from — load-bearing for honesty.
///
/// A PR worktree indexes asynchronously, so the head partition may hold
/// nothing yet. Falling back to the base partition is useful (the spans are
/// usually still right) but it is NOT head-accurate, and the UI says so rather
/// than presenting stale line ranges as current.
enum SymbolSource {
  /// Spans came from the PR's own head partition — accurate for this diff.
  head,

  /// Spans came from the repo's base partition — approximate; the head
  /// worktree was not indexed yet.
  base,

  /// No symbols were available at all (repo not indexed).
  none;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored name, defaulting to [none] (the honest fallback).
  static SymbolSource fromName(String? name) => SymbolSource.values.firstWhere(
    (s) => s.name == name,
    orElse: () => SymbolSource.none,
  );
}

/// A symbol's line span within a file.
class SymbolSpan {
  /// Creates a [SymbolSpan].
  const SymbolSpan({
    required this.name,
    required this.qualifiedName,
    required this.kind,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    this.symbolId = '',
  });

  /// Short symbol name.
  final String name;

  /// Fully-qualified name (container-scoped).
  final String qualifiedName;

  /// Symbol kind wire name (`function`, `class`, `method`, …).
  final String kind;

  /// Repository-relative file.
  final String filePath;

  /// First line of the symbol (inclusive, 1-based).
  final int startLine;

  /// Last line of the symbol (inclusive, 1-based).
  final int endLine;

  /// Code-graph symbol id, when known (empty for synthesized spans).
  final String symbolId;

  /// Number of lines the symbol spans.
  int get lineCount => (endLine - startLine).abs() + 1;

  /// Whether [line] falls inside this span.
  bool contains(int line) => line >= startLine && line <= endLine;

  /// Builds from JSON, or null when the shape is unusable.
  static SymbolSpan? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final filePath = json['filePath'];
    final start = (json['startLine'] as num?)?.toInt();
    final end = (json['endLine'] as num?)?.toInt();
    if (name is! String ||
        filePath is! String ||
        start == null ||
        end == null) {
      return null;
    }
    return SymbolSpan(
      name: name,
      qualifiedName: json['qualifiedName'] as String? ?? name,
      kind: json['kind'] as String? ?? '',
      filePath: filePath,
      startLine: start,
      endLine: end,
      symbolId: json['symbolId'] as String? ?? '',
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'kind': kind,
    'filePath': filePath,
    'startLine': startLine,
    'endLine': endLine,
    if (symbolId.isNotEmpty) 'symbolId': symbolId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolSpan &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          qualifiedName == other.qualifiedName &&
          kind == other.kind &&
          filePath == other.filePath &&
          startLine == other.startLine &&
          endLine == other.endLine &&
          symbolId == other.symbolId;

  @override
  int get hashCode => Object.hash(
    name,
    qualifiedName,
    kind,
    filePath,
    startLine,
    endLine,
    symbolId,
  );
}

/// A symbol the diff touched, with how many of its lines changed.
class ChangedSymbol {
  /// Creates a [ChangedSymbol].
  const ChangedSymbol({
    required this.symbol,
    this.addedLines = 0,
    this.removedLines = 0,
  });

  /// The touched symbol.
  final SymbolSpan symbol;

  /// Added lines landing inside the symbol's span.
  final int addedLines;

  /// Removed lines landing inside the symbol's span.
  final int removedLines;

  /// Total lines the diff changed inside this symbol.
  int get changedLines => addedLines + removedLines;

  /// Builds from JSON, or null when the shape is unusable.
  static ChangedSymbol? fromJson(Map<String, dynamic> json) {
    final raw = json['symbol'];
    if (raw is! Map) {
      return null;
    }
    final symbol = SymbolSpan.fromJson(raw.cast<String, dynamic>());
    if (symbol == null) {
      return null;
    }
    return ChangedSymbol(
      symbol: symbol,
      addedLines: (json['addedLines'] as num?)?.toInt() ?? 0,
      removedLines: (json['removedLines'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'symbol': symbol.toJson(),
    if (addedLines != 0) 'addedLines': addedLines,
    if (removedLines != 0) 'removedLines': removedLines,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangedSymbol &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          addedLines == other.addedLines &&
          removedLines == other.removedLines;

  @override
  int get hashCode => Object.hash(symbol, addedLines, removedLines);
}

/// The deterministic insight bundle stored on a cohort.
class CohortInsights {
  /// Creates a [CohortInsights].
  const CohortInsights({
    this.changedSymbols = const [],
    this.coveringTests = const [],
    this.symbolSource = SymbolSource.none,
    this.testCoverageKnown = false,
  });

  /// Symbols the diff touched, most-changed first.
  final List<ChangedSymbol> changedSymbols;

  /// Repository-relative test files that reach this cohort's symbols.
  final List<String> coveringTests;

  /// Where [changedSymbols] spans were read from.
  final SymbolSource symbolSource;

  /// Whether test coverage could be computed at all.
  ///
  /// The distinction matters: an empty [coveringTests] with
  /// [testCoverageKnown] false means "we could not tell", which must never be
  /// reported as "this code has no tests".
  final bool testCoverageKnown;

  /// An empty bundle.
  static const empty = CohortInsights();

  /// Whether nothing was computed.
  bool get isEmpty =>
      changedSymbols.isEmpty &&
      coveringTests.isEmpty &&
      symbolSource == SymbolSource.none &&
      !testCoverageKnown;

  /// The number of covering tests, or null when coverage is unknown.
  int? get coveringTestCount => testCoverageKnown ? coveringTests.length : null;

  /// Builds from a stored JSON map. Returns [empty] for a missing or malformed
  /// blob — insights are an enrichment, never a reason to fail a read.
  factory CohortInsights.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return empty;
    }
    final symbols = <ChangedSymbol>[];
    for (final raw in (json['changedSymbols'] as List? ?? const [])) {
      if (raw is! Map) {
        continue;
      }
      final parsed = ChangedSymbol.fromJson(raw.cast<String, dynamic>());
      if (parsed != null) {
        symbols.add(parsed);
      }
    }
    return CohortInsights(
      changedSymbols: symbols,
      coveringTests:
          (json['coveringTests'] as List?)?.whereType<String>().toList() ??
          const [],
      symbolSource: SymbolSource.fromName(json['symbolSource'] as String?),
      testCoverageKnown: json['testCoverageKnown'] as bool? ?? false,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (changedSymbols.isNotEmpty)
      'changedSymbols': changedSymbols.map((c) => c.toJson()).toList(),
    if (coveringTests.isNotEmpty) 'coveringTests': coveringTests,
    'symbolSource': symbolSource.wireName,
    if (testCoverageKnown) 'testCoverageKnown': true,
  };

  /// Returns an edited copy.
  CohortInsights copyWith({
    List<ChangedSymbol>? changedSymbols,
    List<String>? coveringTests,
    SymbolSource? symbolSource,
    bool? testCoverageKnown,
  }) => CohortInsights(
    changedSymbols: changedSymbols ?? this.changedSymbols,
    coveringTests: coveringTests ?? this.coveringTests,
    symbolSource: symbolSource ?? this.symbolSource,
    testCoverageKnown: testCoverageKnown ?? this.testCoverageKnown,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortInsights &&
          runtimeType == other.runtimeType &&
          _listEquals(changedSymbols, other.changedSymbols) &&
          _listEquals(coveringTests, other.coveringTests) &&
          symbolSource == other.symbolSource &&
          testCoverageKnown == other.testCoverageKnown;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(changedSymbols),
    Object.hashAll(coveringTests),
    symbolSource,
    testCoverageKnown,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
