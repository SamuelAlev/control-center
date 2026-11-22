import 'dart:math' as math;

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:meta/meta.dart';

/// Tokeniser for tool text. Mirrors the upstream behaviour: lightweight accent
/// stripping, acronym + camelCase + digit→letter boundary splitting, non-
/// alphanumeric → space, lowercase, split on whitespace. No stemming, no
/// stopword removal.
List<String> tokenizeToolText(String value) {
  if (value.isEmpty) {
    return const [];
  }
  var s = _stripDiacritics(value);
  // MCPTool → MCP Tool (acronym boundary).
  s = s.replaceAllMapped(
    RegExp('([A-Z]+)([A-Z][a-z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  // fooBar → foo Bar (camelCase).
  s = s.replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  // 2Beta → 2 Beta (digit→letter).
  s = s.replaceAllMapped(RegExp('([0-9])([A-Za-z])'), (m) => '${m[1]} ${m[2]}');
  s = s.replaceAll(RegExp('[^A-Za-z0-9]+'), ' ').toLowerCase();
  return s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
}

/// One indexed tool document with its weighted term frequencies.
class _ToolDocument {
  _ToolDocument({
    required this.name,
    required this.label,
    required this.description,
    required this.schemaKeys,
    required this.termFrequencies,
    required this.length,
  });

  final String name;
  final String label;
  final String description;
  final List<String> schemaKeys;
  final Map<String, double> termFrequencies;
  final double length;
}

/// A ranked search hit.
class ToolSearchHit {
  /// Creates a [ToolSearchHit].
  const ToolSearchHit({
    required this.name,
    required this.label,
    required this.description,
    required this.schemaKeys,
    required this.score,
  });

  /// The tool name (the activation key).
  final String name;

  /// A humanised label.
  final String label;

  /// The tool description.
  final String description;

  /// The tool's top-level argument keys.
  final List<String> schemaKeys;

  /// The BM25 relevance score.
  final double score;

  /// The result map sent back to the agent.
  Map<String, dynamic> toJson() => {
    'name': name,
    'label': label,
    'description': description,
    'schema_keys': schemaKeys,
    'score': double.parse(score.toStringAsFixed(4)),
  };
}

/// A BM25 index over tool definitions (PRD 01 phase 1.4).
///
/// When CC ships ~110 tools plus any bridged external ones, serialising every
/// schema into each request bloats context and churns the prompt-cache prefix.
/// The scoring is the standard BM25+ with `k1 = 1.2`, `b = 0.75`, `delta = 1.0`
/// and field weights `name = 6`, `mcpToolName = 4`, `label = 4`,
/// `serverName = 2`, `summary = 2`, `schemaKey = 1`.
///
/// Lives in the shared kernel because two very different callers index the same
/// documents: the MCP-facing `search_tool_bm25` (which only DESCRIBES tools to
/// an external client) and the harness's own `search_tools` (which describes
/// them AND loads their schemas into the run). Two copies of the ranking would
/// mean an agent's search and the same agent's MCP search disagreeing about
/// what the best match is.
class ToolIndex {
  ToolIndex._(this._documents, this._averageLength);

  /// The index of [tools], shared: built once per distinct indexed content
  /// and handed to every caller with the same content (each script of a run,
  /// its subagents, other runs with the same admitted surface), instead of
  /// once per caller.
  ///
  /// The key is what the index holds of each tool, in order: its name, and
  /// its argument names and description as far as its share reads them
  /// ([shareFor]). Two tool sets share an index only when those are equal,
  /// compared in full (never by a hash alone), so an index answers only
  /// from the content it was built from, and two sets that differ only
  /// beyond their shares share one. At most [maxSharedIndexes] are kept,
  /// the least recently used dropped first, so a server that keeps changing
  /// its tool list cannot grow it.
  ///
  /// [whole] are documents of a known, constant size that the caller adds
  /// after [tools] (the script's own functions): each is indexed up to the
  /// per-tool bounds ([maxToolUnits]) whatever the share, outside
  /// [maxIndexedUnits], like names, so a large catalog never cuts them.
  factory ToolIndex.shared(
    List<ToolDef> tools, {
    List<ToolDef> whole = const [],
  }) {
    final indexed = [
      ..._indexedContent(tools, maxIndexedUnits),
      for (final tool in whole) _IndexedTool.within(tool, maxToolUnits),
    ];
    final key = _IndexKey.of(indexed);
    final cached = _shared.remove(key);
    if (cached != null) {
      _shared[key] = cached;
      return cached;
    }
    final index = ToolIndex._of(indexed);
    _shared[key] = index;
    while (_shared.length > maxSharedIndexes) {
      _shared.remove(_shared.keys.first);
    }
    return index;
  }

  /// Builds an index over [tools], holding at most [totalUnits] of their
  /// descriptions and argument names ([maxIndexedUnits] unless a test says
  /// otherwise).
  factory ToolIndex.build(
    List<ToolDef> tools, {
    @visibleForTesting int totalUnits = maxIndexedUnits,
  }) => ToolIndex._of(_indexedContent(tools, totalUnits));

  factory ToolIndex._of(List<_IndexedTool> tools) {
    _builds++;
    final docs = <_ToolDocument>[];
    var totalLength = 0.0;
    for (final tool in tools) {
      final doc = _buildDocument(tool);
      docs.add(doc);
      totalLength += doc.length;
    }
    final avg = docs.isEmpty ? 0.0 : totalLength / docs.length;
    return ToolIndex._(docs, avg);
  }

  /// The most UTF-16 units of descriptions and argument names one index
  /// holds, whatever the number of tools: what bounds the time and memory
  /// of one build. Names are outside it ([maxIndexedNameChars] each), so a
  /// tool is found by its name in a catalog of any size.
  static const int maxIndexedUnits = 1048576;

  /// The most of its description and argument names one tool has indexed:
  /// [maxIndexedDescriptionChars] plus [maxSchemaKeys] names of at most
  /// [maxTermChars].
  static const int maxToolUnits =
      maxIndexedDescriptionChars + maxSchemaKeys * maxTermChars;

  /// What each of [toolCount] tools may have indexed of its argument names
  /// and description: an equal share of [totalUnits], never more than
  /// [maxToolUnits]. Every tool gets the same share, whatever its position.
  static int shareFor(int toolCount, {int totalUnits = maxIndexedUnits}) =>
      toolCount == 0
      ? maxToolUnits
      : math.min(maxToolUnits, totalUnits ~/ toolCount);

  /// The most indexes [ToolIndex.shared] keeps.
  static const int maxSharedIndexes = 8;

  static final Map<_IndexKey, ToolIndex> _shared = {};

  static int _builds = 0;

  /// How many indexes this process has built ([ToolIndex.build], shared or
  /// not): what a test counts to show that a shared index is built once.
  static int get builds => _builds;

  static const double _k1 = 1.2;
  static const double _b = 0.75;
  static const double _delta = 1.0;

  static const Map<String, int> _fieldWeights = {
    'name': 6,
    'mcpToolName': 4,
    'label': 4,
    'serverName': 2,
    'summary': 2,
    'schemaKey': 1,
  };

  /// Default tool-count threshold above which discovery activates.
  static const int autoThreshold = 40;

  /// The most characters of a query that are read; the rest is ignored.
  ///
  /// A query is often a script's or a model's input, so its cost is bounded
  /// here, for every caller: at most [maxQueryTerms] distinct terms of at
  /// most [maxTermChars] characters, each scored against every document.
  static const int maxQueryChars = 4096;

  /// The most distinct terms a query contributes; later ones are ignored.
  static const int maxQueryTerms = 64;

  /// The longest term indexed or searched; a longer one is dropped.
  static const int maxTermChars = 64;

  /// The most characters of a tool's name that are indexed.
  static const int maxIndexedNameChars = 256;

  /// The most characters of a tool's description that are indexed: what one
  /// tool (an external server's above all) contributes to the index, and to
  /// the time and memory the index takes to build.
  static const int maxIndexedDescriptionChars = 4096;

  /// The most top-level argument names indexed (and returned) per tool.
  static const int maxSchemaKeys = 64;

  final List<_ToolDocument> _documents;
  final double _averageLength;

  /// Number of indexed tools.
  int get length => _documents.length;

  /// The units of descriptions and argument names this index holds: never
  /// more than [maxIndexedUnits], plus the documents a caller asked to be
  /// indexed whole ([ToolIndex.shared]'s `whole`).
  int get indexedUnits {
    var units = 0;
    for (final doc in _documents) {
      units += doc.description.length;
      for (final key in doc.schemaKeys) {
        units += key.length;
      }
    }
    return units;
  }

  /// Searches for [query], returning up to [limit] hits ranked by BM25 score.
  ///
  /// Reads at most [maxQueryChars] of [query] and its first [maxQueryTerms]
  /// distinct terms of at most [maxTermChars] characters.
  List<ToolSearchHit> search(String query, {int limit = 8}) {
    final terms = tokenizeToolText(boundQuery(query));
    if (terms.isEmpty || _documents.isEmpty) {
      return const [];
    }
    // Per-term document frequency.
    final queryTermCounts = <String, int>{};
    for (final t in terms) {
      if (t.length > maxTermChars) {
        continue;
      }
      final count = queryTermCounts[t];
      if (count == null && queryTermCounts.length >= maxQueryTerms) {
        continue;
      }
      queryTermCounts[t] = (count ?? 0) + 1;
    }
    if (queryTermCounts.isEmpty) {
      return const [];
    }
    final documentFrequency = <String, int>{};
    for (final term in queryTermCounts.keys) {
      var df = 0;
      for (final doc in _documents) {
        if (doc.termFrequencies.containsKey(term)) {
          df++;
        }
      }
      documentFrequency[term] = df;
    }

    final n = _documents.length;
    final scored = <ToolSearchHit>[];
    for (final doc in _documents) {
      var score = 0.0;
      for (final entry in queryTermCounts.entries) {
        final term = entry.key;
        final tf = doc.termFrequencies[term];
        if (tf == null) {
          continue;
        }
        final df = documentFrequency[term]!;
        final idf = math.log(1 + (n - df + 0.5) / (df + 0.5));
        final norm =
            _k1 *
            (1 -
                _b +
                _b * (doc.length / (_averageLength == 0 ? 1 : _averageLength)));
        score += entry.value * idf * ((tf * (_k1 + 1)) / (tf + norm) + _delta);
      }
      if (score > 0) {
        scored.add(
          ToolSearchHit(
            name: doc.name,
            label: doc.label,
            description: doc.description,
            schemaKeys: doc.schemaKeys,
            score: score,
          ),
        );
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.length > limit ? scored.sublist(0, limit) : scored;
  }

  /// What the index holds of each of [tools] within its share of
  /// [totalUnits]: its name head, then, inside the share, its argument
  /// names in order while they fit, then the head of its description that
  /// fits in what is left.
  static List<_IndexedTool> _indexedContent(
    List<ToolDef> tools,
    int totalUnits,
  ) {
    final share = shareFor(tools.length, totalUnits: totalUnits);
    return [for (final tool in tools) _IndexedTool.within(tool, share)];
  }

  static _ToolDocument _buildDocument(_IndexedTool tool) {
    final termFrequencies = <String, double>{};
    var length = 0.0;

    void addField(String text, int weight) {
      for (final token in tokenizeToolText(text)) {
        if (token.length > maxTermChars) {
          continue;
        }
        termFrequencies[token] = (termFrequencies[token] ?? 0) + weight;
        length += weight;
      }
    }

    // Parse a bridged `mcp__server__tool` name into its parts.
    String? serverName;
    String? mcpToolName;
    final name = tool.indexedName;
    if (name.startsWith('mcp__')) {
      final parts = name.substring('mcp__'.length).split('__');
      if (parts.length >= 2) {
        serverName = parts.first;
        mcpToolName = parts.sublist(1).join('__');
      }
    }

    final schemaKeys = tool.schemaKeys;
    addField(name, _fieldWeights['name']!);
    addField(_humanize(name), _fieldWeights['label']!);
    final description = tool.description;
    addField(description, _fieldWeights['summary']!);
    if (serverName != null) {
      addField(serverName, _fieldWeights['serverName']!);
    }
    if (mcpToolName != null) {
      addField(mcpToolName, _fieldWeights['mcpToolName']!);
    }
    for (final key in schemaKeys) {
      addField(key, _fieldWeights['schemaKey']!);
    }

    return _ToolDocument(
      name: tool.name,
      label: _humanize(name),
      // The indexed head only: the index never keeps more of a tool than it
      // searches, whatever the definitions it was built from hold.
      description: description,
      schemaKeys: schemaKeys,
      termFrequencies: termFrequencies,
      length: length,
    );
  }

  /// Extracts the top-level property keys from a JSON schema, sorted: the
  /// first [maxSchemaKeys] of them, each at most [maxTermChars] characters
  /// (a longer key is left out).
  static List<String> _schemaKeys(Map<String, dynamic> schema) {
    final properties = schema['properties'];
    if (properties is! Map) {
      return const [];
    }
    final keys = <String>[];
    for (final k in properties.keys) {
      final key = k.toString();
      if (key.length <= maxTermChars) {
        keys.add(key);
      }
    }
    keys.sort();
    return keys.length > maxSchemaKeys ? keys.sublist(0, maxSchemaKeys) : keys;
  }

  /// What [search] reads of [query]: its first [maxQueryChars] characters. A
  /// caller that works on a query before searching (stopwords, say) cuts it
  /// with this first, so its own work is bounded too.
  static String boundQuery(String query) => _head(query, maxQueryChars);

  /// The first [max] UTF-16 units of [text].
  static String _head(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;

  static String _humanize(String name) =>
      name.replaceAll('mcp__', '').replaceAll('__', ' ').replaceAll('_', ' ');
}

final Map<int, String> _diacritics = _buildDiacritics();

Map<int, String> _buildDiacritics() {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY';
  final map = <int, String>{};
  for (var i = 0; i < from.length; i++) {
    map[from.codeUnitAt(i)] = to[i];
  }
  return map;
}

/// Strips common Latin diacritics so `café` indexes as `cafe`. A pragmatic
/// stand-in for full Unicode NFD decomposition (which Dart's core lacks).
String _stripDiacritics(String input) {
  final units = input.codeUnits;
  var first = 0;
  while (first < units.length && !_diacritics.containsKey(units[first])) {
    first++;
  }
  if (first == units.length) {
    // Nothing to strip: the common case, and no copy.
    return input;
  }
  final out = List<int>.of(units);
  for (var i = first; i < out.length; i++) {
    final replacement = _diacritics[out[i]];
    if (replacement != null) {
      out[i] = replacement.codeUnitAt(0);
    }
  }
  return String.fromCharCodes(out);
}

/// What the index holds of one tool, within its share.
final class _IndexedTool {
  _IndexedTool(this.name, this.description, this.schemaKeys);

  /// [tool] as indexed within [share] units: its argument names first, in
  /// order while each fits, then the head of its description that fits in
  /// what is left. Its name is outside the share.
  factory _IndexedTool.within(ToolDef tool, int share) {
    final keys = <String>[];
    var spent = 0;
    for (final key in ToolIndex._schemaKeys(tool.inputSchema)) {
      if (spent + key.length > share) {
        break;
      }
      keys.add(key);
      spent += key.length;
    }
    return _IndexedTool(
      tool.name,
      ToolIndex._head(
        tool.description,
        math.min(ToolIndex.maxIndexedDescriptionChars, share - spent),
      ),
      keys,
    );
  }

  /// The tool's full name: what a hit returns, so what the key compares.
  final String name;
  final String description;
  final List<String> schemaKeys;

  /// The part of [name] that is searched.
  String get indexedName =>
      ToolIndex._head(name, ToolIndex.maxIndexedNameChars);
}

/// What [ToolIndex.shared] keys an index on: each tool's name, and its
/// argument names and description as indexed, in order. Equal only when
/// every part is.
final class _IndexKey {
  _IndexKey(this._parts) : _hash = Object.hashAll(_parts);

  factory _IndexKey.of(List<_IndexedTool> tools) => _IndexKey([
    for (final tool in tools) ...[
      tool.name,
      tool.description,
      tool.schemaKeys.join('\u0000'),
    ],
  ]);

  final List<String> _parts;
  final int _hash;

  @override
  int get hashCode => _hash;

  @override
  bool operator ==(Object other) {
    if (other is! _IndexKey ||
        other._hash != _hash ||
        other._parts.length != _parts.length) {
      return false;
    }
    for (var i = 0; i < _parts.length; i++) {
      if (other._parts[i] != _parts[i]) {
        return false;
      }
    }
    return true;
  }
}
