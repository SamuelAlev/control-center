/// The `flowchart` / `graph` parser.
///
/// Reads the box-and-arrow dialect into a [CcMermaidGraph]: shaped vertices,
/// every mermaid link form (solid/dotted/thick/invisible, both end markers,
/// pipe and inline labels, extra-dash lengths), `&` fan-out groups, chained
/// links, and nested `subgraph` clusters.
///
/// Author styling (`style`, `classDef`, `linkStyle`) is PARSED BUT NOT APPLIED:
/// class names land on [CcMermaidNode.styleClasses] for inspection, while the
/// colors are dropped on purpose — the host app themes diagrams from its own
/// design tokens, so honoring hardcoded hex would break dark mode and the
/// design system's contrast guarantees.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

/// A scanned vertex: id plus an optional shape/label.
class _Vertex {
  _Vertex(this.id, this.shape, this.label, this.styleClass);
  final String id;
  final CcMermaidNodeShape? shape;
  final String? label;
  final String? styleClass;
}

/// A scanned link between two vertex groups.
class _Link {
  _Link({
    required this.stroke,
    required this.startMarker,
    required this.endMarker,
    required this.span,
    this.label,
  });
  final CcMermaidEdgeStroke stroke;
  final CcMermaidEdgeMarker startMarker;
  final CcMermaidEdgeMarker endMarker;
  final int span;
  final String? label;
}

/// Opening delimiter → (closing delimiter, shape). Longest openers first; the
/// scanner tries them in order, so `(((` wins over `((` wins over `(`.
const List<(String, String, CcMermaidNodeShape)> _shapeDelimiters = [
  ('(((', ')))', CcMermaidNodeShape.doubleCircle),
  ('([', '])', CcMermaidNodeShape.stadium),
  ('((', '))', CcMermaidNodeShape.circle),
  ('[[', ']]', CcMermaidNodeShape.subroutine),
  ('[(', ')]', CcMermaidNodeShape.cylinder),
  ('[/', '/]', CcMermaidNodeShape.parallelogram),
  (r'[\', r'\]', CcMermaidNodeShape.parallelogramAlt),
  ('{{', '}}', CcMermaidNodeShape.hexagon),
  ('[', ']', CcMermaidNodeShape.rect),
  ('(', ')', CcMermaidNodeShape.roundRect),
  ('{', '}', CcMermaidNodeShape.diamond),
  ('>', ']', CcMermaidNodeShape.asymmetric),
];

/// The two openers whose closing delimiter decides between a parallelogram and
/// a trapezoid (`[/…/]` vs `[/…\]`).
const Map<String, (String, CcMermaidNodeShape, String, CcMermaidNodeShape)>
_ambiguousDelimiters = {
  '[/': (
    '/]',
    CcMermaidNodeShape.parallelogram,
    r'\]',
    CcMermaidNodeShape.trapezoid,
  ),
  r'[\': (
    r'\]',
    CcMermaidNodeShape.parallelogramAlt,
    '/]',
    CcMermaidNodeShape.trapezoidAlt,
  ),
};

final RegExp _subgraphStart = RegExp(
  r'^subgraph\b\s*(.*)$',
  caseSensitive: false,
);
final RegExp _subgraphTitled = RegExp(r'^(\S+)\s*\[(.*)\]\s*$');
final RegExp _directionStatement = RegExp(
  r'^direction\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _classStatement = RegExp(
  r'^class\s+(\S+)\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _clickStatement = RegExp(
  r'''^click\s+(\S+)\s+(?:(?:href|call)\s+)?"?([^"]*)"?(?:\s+"([^"]*)")?''',
  caseSensitive: false,
);
final RegExp _ignoredStatement = RegExp(
  r'^(classDef|style|linkStyle|accTitle|accDescr|graph|flowchart)\b',
  caseSensitive: false,
);

/// Parses the statements of a `flowchart` / `graph` source.
///
/// [header] is the already-consumed first line, whose direction token seeds the
/// graph direction.
CcMermaidGraph parseMermaidFlowchart(
  CcMermaidSource source, {
  CcMermaidGraphKind kind = CcMermaidGraphKind.flowchart,
}) {
  final builder = _FlowchartBuilder(kind: kind);
  builder.direction =
      _headerDirection(source.header) ?? CcMermaidDirection.topDown;
  for (final statement in source.statements) {
    builder.statement(statement);
  }
  return builder.build(title: source.title);
}

CcMermaidDirection? _headerDirection(String header) {
  final (_, rest) = splitFirstWord(header);
  if (rest.isEmpty) {
    return null;
  }
  return CcMermaidDirection.tryParse(rest.split(RegExp(r'\s+')).first);
}

class _FlowchartBuilder {
  _FlowchartBuilder({required this.kind});

  final CcMermaidGraphKind kind;
  CcMermaidDirection direction = CcMermaidDirection.topDown;

  final Map<String, CcMermaidNode> _nodes = {};
  final List<CcMermaidEdge> _edges = [];
  final List<CcMermaidCluster> _clusters = [];
  final List<String> _clusterStack = [];
  var _anonymousClusters = 0;

  String? get _currentCluster =>
      _clusterStack.isEmpty ? null : _clusterStack.last;

  void statement(String raw) {
    final statement = raw.trim();
    if (statement.isEmpty) {
      return;
    }

    if (statement.toLowerCase() == 'end') {
      if (_clusterStack.isNotEmpty) {
        _clusterStack.removeLast();
      }
      return;
    }

    final subgraph = _subgraphStart.firstMatch(statement);
    if (subgraph != null) {
      _openCluster(subgraph.group(1)!.trim());
      return;
    }

    final directionMatch = _directionStatement.firstMatch(statement);
    if (directionMatch != null) {
      final parsed = CcMermaidDirection.tryParse(directionMatch.group(1)!);
      if (parsed != null) {
        if (_clusterStack.isEmpty) {
          direction = parsed;
        } else {
          _setClusterDirection(_clusterStack.last, parsed);
        }
      }
      return;
    }

    final classMatch = _classStatement.firstMatch(statement);
    if (classMatch != null) {
      for (final id in classMatch.group(1)!.split(',')) {
        _addStyleClass(id.trim(), classMatch.group(2)!.trim());
      }
      return;
    }

    final click = _clickStatement.firstMatch(statement);
    if (click != null) {
      final node = _nodes[click.group(1)!];
      if (node != null) {
        _nodes[node.id] = node.copyWith(
          href: click.group(2)?.trim(),
          tooltip: click.group(3)?.trim(),
        );
      }
      return;
    }

    if (_ignoredStatement.hasMatch(statement)) {
      return;
    }

    _parseChain(statement);
  }

  void _openCluster(String spec) {
    String id;
    List<String> lines;
    final titled = _subgraphTitled.firstMatch(spec);
    if (titled != null) {
      id = titled.group(1)!;
      lines = splitMermaidLabel(stripMermaidQuotes(titled.group(2)!));
    } else if (spec.isEmpty) {
      id = '__subgraph_${_anonymousClusters++}';
      lines = const [];
    } else {
      id = stripMermaidQuotes(spec);
      lines = splitMermaidLabel(id);
    }
    // A duplicate id would silently merge two boxes; suffix instead.
    var uniqueId = id;
    var suffix = 1;
    while (_clusters.any((c) => c.id == uniqueId)) {
      uniqueId = '$id~${suffix++}';
    }
    _clusters.add(
      CcMermaidCluster(id: uniqueId, lines: lines, parentId: _currentCluster),
    );
    _clusterStack.add(uniqueId);
  }

  void _setClusterDirection(String id, CcMermaidDirection value) {
    for (var i = 0; i < _clusters.length; i++) {
      if (_clusters[i].id == id) {
        _clusters[i] = CcMermaidCluster(
          id: _clusters[i].id,
          lines: _clusters[i].lines,
          parentId: _clusters[i].parentId,
          direction: value,
        );
        return;
      }
    }
  }

  void _addStyleClass(String id, String className) {
    final node = _nodes[id];
    if (node == null) {
      return;
    }
    _nodes[id] = node.copyWith(styleClasses: [...node.styleClasses, className]);
  }

  /// Parses one statement as a chain of vertex groups joined by links:
  /// `A & B --> C -.->|label| D`.
  void _parseChain(String statement) {
    var i = skipMermaidSpaces(statement, 0);
    final first = _scanGroup(statement, i);
    if (first == null) {
      return;
    }
    var previous = first.ids;
    i = first.end;

    while (i < statement.length) {
      i = skipMermaidSpaces(statement, i);
      final link = _scanLink(statement, i);
      if (link == null) {
        break;
      }
      i = skipMermaidSpaces(statement, link.$2);
      final next = _scanGroup(statement, i);
      if (next == null) {
        break;
      }
      i = next.end;
      for (final from in previous) {
        for (final to in next.ids) {
          _addEdge(from, to, link.$1);
        }
      }
      previous = next.ids;
    }
  }

  void _addEdge(String from, String to, _Link link) {
    final labelLines = splitMermaidLabel(link.label);
    _edges.add(
      CcMermaidEdge(
        fromId: from,
        toId: to,
        label: labelLines.join(' '),
        labelLines: labelLines,
        stroke: link.stroke,
        startMarker: link.startMarker,
        endMarker: link.endMarker,
        minRankSpan: link.span,
      ),
    );
  }

  /// Scans one `&`-joined vertex group, registering every vertex it declares.
  ({List<String> ids, int end})? _scanGroup(String text, int start) {
    final ids = <String>[];
    var i = start;
    while (true) {
      i = skipMermaidSpaces(text, i);
      final vertex = _scanVertex(text, i);
      if (vertex == null) {
        break;
      }
      _register(vertex.$1);
      ids.add(vertex.$1.id);
      i = vertex.$2;
      final after = skipMermaidSpaces(text, i);
      if (after < text.length && text[after] == '&') {
        i = after + 1;
        continue;
      }
      break;
    }
    if (ids.isEmpty) {
      return null;
    }
    return (ids: ids, end: i);
  }

  void _register(_Vertex vertex) {
    final existing = _nodes[vertex.id];
    final lines = vertex.label == null
        ? (existing?.lines ?? const <String>[])
        : splitMermaidLabel(vertex.label);
    final shape = vertex.shape ?? existing?.shape ?? CcMermaidNodeShape.rect;
    final classes = <String>[
      ...?existing?.styleClasses,
      if (vertex.styleClass != null) vertex.styleClass!,
    ];
    _nodes[vertex.id] = CcMermaidNode(
      id: vertex.id,
      lines: lines,
      shape: shape,
      // First mention wins the cluster: a node re-referenced outside its
      // subgraph must not jump out of the box it was declared in.
      clusterId: existing?.clusterId ?? _currentCluster,
      styleClasses: classes,
      href: existing?.href,
      tooltip: existing?.tooltip,
    );
  }

  /// Scans `id`, `id[Label]`, `id{Label}`, … plus a trailing `:::class`.
  (_Vertex, int)? _scanVertex(String text, int start) {
    final id = readMermaidId(text, start);
    if (id.isEmpty) {
      return null;
    }
    var i = start + id.length;
    CcMermaidNodeShape? shape;
    String? label;

    for (final (open, close, delimiterShape) in _shapeDelimiters) {
      if (!text.startsWith(open, i)) {
        continue;
      }
      final ambiguous = _ambiguousDelimiters[open];
      if (ambiguous != null) {
        final (closeA, shapeA, closeB, shapeB) = ambiguous;
        final bodyA = _readDelimited(text, i + open.length, closeA);
        final bodyB = _readDelimited(text, i + open.length, closeB);
        // Whichever terminator appears FIRST is the real one.
        if (bodyA != null && (bodyB == null || bodyA.$2 <= bodyB.$2)) {
          label = bodyA.$1;
          shape = shapeA;
          i = bodyA.$2;
        } else if (bodyB != null) {
          label = bodyB.$1;
          shape = shapeB;
          i = bodyB.$2;
        }
        if (shape != null) {
          break;
        }
        continue;
      }
      final body = _readDelimited(text, i + open.length, close);
      if (body == null) {
        continue;
      }
      label = body.$1;
      shape = delimiterShape;
      i = body.$2;
      break;
    }

    String? styleClass;
    if (text.startsWith(':::', i)) {
      final className = readMermaidId(text, i + 3);
      if (className.isNotEmpty) {
        styleClass = className;
        i += 3 + className.length;
      }
    }

    return (_Vertex(id, shape, label, styleClass), i);
  }

  /// Reads a delimited label body starting at [start], returning
  /// (label, indexAfterCloser). A quoted body may contain the closer.
  (String, int)? _readDelimited(String text, int start, String closer) {
    if (start < text.length && (text[start] == '"' || text[start] == "'")) {
      final quote = text[start];
      final end = text.indexOf(quote, start + 1);
      if (end > 0) {
        final afterQuote = end + 1;
        if (text.startsWith(closer, afterQuote)) {
          return (text.substring(start + 1, end), afterQuote + closer.length);
        }
      }
    }
    final end = text.indexOf(closer, start);
    if (end < 0) {
      return null;
    }
    return (
      stripMermaidQuotes(text.substring(start, end)),
      end + closer.length,
    );
  }

  // --- Links ---------------------------------------------------------------

  /// Scans a link token (with either label form) at [start].
  (_Link, int)? _scanLink(String text, int start) {
    final inline = _scanInlineLabeledLink(text, start);
    if (inline != null) {
      return inline;
    }
    final plain = _scanPlainLink(text, start);
    if (plain == null) {
      return null;
    }
    var (link, end) = plain;
    // Pipe label: `-->|yes|`.
    if (end < text.length && text[end] == '|') {
      final close = text.indexOf('|', end + 1);
      if (close > 0) {
        link = _Link(
          stroke: link.stroke,
          startMarker: link.startMarker,
          endMarker: link.endMarker,
          span: link.span,
          label: stripMermaidQuotes(text.substring(end + 1, close)),
        );
        end = close + 1;
      }
    }
    return (link, end);
  }

  static const Map<String, CcMermaidEdgeMarker> _startMarkers = {
    '<': CcMermaidEdgeMarker.arrow,
    'x': CcMermaidEdgeMarker.cross,
    'o': CcMermaidEdgeMarker.circle,
  };
  static const Map<String, CcMermaidEdgeMarker> _endMarkers = {
    '>': CcMermaidEdgeMarker.arrow,
    'x': CcMermaidEdgeMarker.cross,
    'o': CcMermaidEdgeMarker.circle,
  };

  /// `A -- text --> B`, `A -. text .-> B`, `A == text ==> B`.
  (_Link, int)? _scanInlineLabeledLink(String text, int start) {
    var i = start;
    if (i < text.length && _startMarkers.containsKey(text[i])) {
      // A leading `<`/`x`/`o` only counts as a start marker when a link body
      // actually follows it (`<-- no --> B`); otherwise fall through.
      final marker = _startMarkers[text[i]]!;
      final probe = _scanInlineLabeledLink(text, i + 1);
      if (probe != null) {
        final (link, end) = probe;
        return (
          _Link(
            stroke: link.stroke,
            startMarker: marker,
            endMarker: link.endMarker,
            span: link.span,
            label: link.label,
          ),
          end,
        );
      }
      return null;
    }

    final (opener, stroke) = switch (true) {
      _ when text.startsWith('-.', i) => ('-.', CcMermaidEdgeStroke.dotted),
      _ when text.startsWith('==', i) => ('==', CcMermaidEdgeStroke.thick),
      _ when text.startsWith('--', i) => ('--', CcMermaidEdgeStroke.solid),
      _ => ('', CcMermaidEdgeStroke.solid),
    };
    if (opener.isEmpty) {
      return null;
    }
    i += opener.length;
    // The label must be separated from the dashes; `-->` is not a label.
    if (i >= text.length || (text[i] != ' ' && text[i] != '\t')) {
      return null;
    }
    final closerPattern = switch (stroke) {
      CcMermaidEdgeStroke.dotted => RegExp(r'\.-+([>xo])?'),
      CcMermaidEdgeStroke.thick => RegExp(r'=={1,}([>xo])?'),
      _ => RegExp(r'--+([>xo])?'),
    };
    final match = closerPattern.firstMatch(text.substring(i));
    if (match == null) {
      return null;
    }
    final label = text.substring(i, i + match.start).trim();
    if (label.isEmpty) {
      return null;
    }
    final endMarker =
        _endMarkers[match.group(1) ?? ''] ?? CcMermaidEdgeMarker.none;
    return (
      _Link(
        stroke: stroke,
        startMarker: CcMermaidEdgeMarker.none,
        endMarker: endMarker,
        span: 1,
        label: stripMermaidQuotes(label),
      ),
      i + match.end,
    );
  }

  static final RegExp _plainLinkPattern = RegExp(
    r'^(?<start>[<xo])?(?:(?<dotted>-\.+-)|(?<thick>={2,})|(?<invisible>~{2,})|(?<solid>-{2,}))(?<end>[>xo])?',
  );

  /// `-->`, `---`, `-.->`, `==>`, `<-->`, `--x`, `~~~`, with dash-count length.
  (_Link, int)? _scanPlainLink(String text, int start) {
    final match = _plainLinkPattern.firstMatch(text.substring(start));
    if (match == null) {
      return null;
    }
    final endToken = match.namedGroup('end');
    final endMarker = _endMarkers[endToken ?? ''] ?? CcMermaidEdgeMarker.none;
    final startToken = match.namedGroup('start');
    final startMarker =
        _startMarkers[startToken ?? ''] ?? CcMermaidEdgeMarker.none;

    final dotted = match.namedGroup('dotted');
    final thick = match.namedGroup('thick');
    final invisible = match.namedGroup('invisible');
    final solid = match.namedGroup('solid');

    final CcMermaidEdgeStroke stroke;
    final int span;
    if (dotted != null) {
      stroke = CcMermaidEdgeStroke.dotted;
      // `-.->` is length 1, `-..->` 2, … — the DOTS carry the length, so strip
      // the two framing dashes.
      span = dotted.length - 2;
    } else if (thick != null) {
      stroke = CcMermaidEdgeStroke.thick;
      span = thick.length + (endToken == null ? 0 : 1) - 2;
    } else if (invisible != null) {
      stroke = CcMermaidEdgeStroke.invisible;
      span = 1;
    } else {
      stroke = CcMermaidEdgeStroke.solid;
      span = solid!.length + (endToken == null ? 0 : 1) - 2;
    }

    // An open link (`A --- B`) has no arrowhead; a bare `-` is not a link.
    return (
      _Link(
        stroke: stroke,
        startMarker: startMarker,
        endMarker: endMarker,
        span: span < 1 ? 1 : span,
      ),
      start + match.end,
    );
  }

  CcMermaidGraph build({String? title}) {
    // Drop clusters that never captured a node: an author's stray `subgraph`
    // would otherwise paint an empty box.
    final used = <String>{
      for (final node in _nodes.values)
        if (node.clusterId != null) node.clusterId!,
    };
    final live = <CcMermaidCluster>[];
    for (final cluster in _clusters) {
      if (used.contains(cluster.id) ||
          _clusters.any(
            (c) => c.parentId == cluster.id && used.contains(c.id),
          )) {
        live.add(cluster);
      }
    }
    return CcMermaidGraph(
      kind: kind,
      direction: direction,
      nodes: List.unmodifiable(_nodes.values),
      edges: List.unmodifiable(_edges),
      clusters: List.unmodifiable(live),
      title: title,
    );
  }
}
