import 'dart:math' as math;

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

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
  s = s.replaceAllMapped(
    RegExp('([a-z0-9])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  // 2Beta → 2 Beta (digit→letter).
  s = s.replaceAllMapped(
    RegExp('([0-9])([A-Za-z])'),
    (m) => '${m[1]} ${m[2]}',
  );
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
/// When CC ships ~55 tools plus any bridged external ones, serialising every
/// schema into each `tools/list` bloats context and churns the prompt-cache
/// prefix. Above [autoThreshold] tools, the host exposes only the search tool
/// (+ essentials) and the agent retrieves the rest by query. The scoring is the
/// standard BM25+ with `k1 = 1.2`, `b = 0.75`, `delta = 1.0` and field weights
/// `name = 6`, `mcpToolName = 4`, `label = 4`, `serverName = 2`, `summary = 2`,
/// `schemaKey = 1`.
class ToolIndex {
  ToolIndex._(this._documents, this._averageLength);

  /// Builds an index over [tools].
  factory ToolIndex.build(List<ToolDef> tools) {
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

  final List<_ToolDocument> _documents;
  final double _averageLength;

  /// Number of indexed tools.
  int get length => _documents.length;

  /// Searches for [query], returning up to [limit] hits ranked by BM25 score.
  List<ToolSearchHit> search(String query, {int limit = 8}) {
    final terms = tokenizeToolText(query);
    if (terms.isEmpty || _documents.isEmpty) {
      return const [];
    }
    // Per-term document frequency.
    final queryTermCounts = <String, int>{};
    for (final t in terms) {
      queryTermCounts[t] = (queryTermCounts[t] ?? 0) + 1;
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
        final norm = _k1 *
            (1 - _b + _b * (doc.length / (_averageLength == 0 ? 1 : _averageLength)));
        score +=
            entry.value * idf * ((tf * (_k1 + 1)) / (tf + norm) + _delta);
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

  static _ToolDocument _buildDocument(ToolDef tool) {
    final termFrequencies = <String, double>{};
    var length = 0.0;

    void addField(String text, int weight) {
      for (final token in tokenizeToolText(text)) {
        termFrequencies[token] = (termFrequencies[token] ?? 0) + weight;
        length += weight;
      }
    }

    // Parse a bridged `mcp__server__tool` name into its parts.
    String? serverName;
    String? mcpToolName;
    if (tool.name.startsWith('mcp__')) {
      final parts = tool.name.substring('mcp__'.length).split('__');
      if (parts.length >= 2) {
        serverName = parts.first;
        mcpToolName = parts.sublist(1).join('__');
      }
    }

    final schemaKeys = _schemaKeys(tool.inputSchema);
    addField(tool.name, _fieldWeights['name']!);
    addField(_humanize(tool.name), _fieldWeights['label']!);
    addField(tool.description, _fieldWeights['summary']!);
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
      label: _humanize(tool.name),
      description: tool.description,
      schemaKeys: schemaKeys,
      termFrequencies: termFrequencies,
      length: length,
    );
  }

  /// Extracts the top-level property keys from a JSON schema, sorted.
  static List<String> _schemaKeys(Map<String, dynamic> schema) {
    final properties = schema['properties'];
    if (properties is! Map) {
      return const [];
    }
    final keys = properties.keys.map((k) => k.toString()).toList()..sort();
    return keys;
  }

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
  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    buffer.write(_diacritics[unit] ?? String.fromCharCode(unit));
  }
  return buffer.toString();
}
