/// The `erDiagram` parser.
///
/// Entities become compartment boxes (name header + attribute rows) and
/// relationships become edges carrying a crow's-foot cardinality marker at each
/// end. As in the class dialect, ranking follows DECLARATION ORDER: the
/// left-hand entity sits above the right-hand one.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/relation_token.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

/// Cardinality tokens, both orientations.
const List<String> _cardinalityMarkers = [
  '||',
  '|o',
  'o|',
  '}|',
  '|{',
  '}o',
  'o{',
];

const Map<String, CcMermaidEdgeMarker> _markerByToken = {
  '||': CcMermaidEdgeMarker.erOne,
  '|o': CcMermaidEdgeMarker.erZeroOrOne,
  'o|': CcMermaidEdgeMarker.erZeroOrOne,
  '}|': CcMermaidEdgeMarker.erOneOrMany,
  '|{': CcMermaidEdgeMarker.erOneOrMany,
  '}o': CcMermaidEdgeMarker.erZeroOrMany,
  'o{': CcMermaidEdgeMarker.erZeroOrMany,
};

final RegExp _directionStatement = RegExp(
  r'^direction\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _entityOpen = RegExp(
  r'''^"?([^"\s{]+)"?(?:\s*\[[^\]]*\])?\s*\{\s*$''',
);
final RegExp _relationLabel = RegExp(
  r'''^"?([^"\s:]+)"?\s*(?::\s*"?(.*?)"?)?\s*$''',
);
final RegExp _ignored = RegExp(
  r'^(erDiagram|accTitle|accDescr|classDef|class|style)\b',
  caseSensitive: false,
);

/// Parses an `erDiagram` source into a graph.
CcMermaidGraph parseMermaidEr(CcMermaidSource source) {
  final builder = _ErBuilder();
  for (final statement in source.statements) {
    builder.statement(statement);
  }
  return builder.build(title: source.title);
}

class _ErBuilder {
  CcMermaidDirection direction = CcMermaidDirection.topDown;

  final Map<String, List<String>> _attributes = {};
  final List<String> _order = [];
  final List<CcMermaidEdge> _edges = [];
  String? _openEntity;

  void statement(String raw) {
    final statement = raw.trim();
    if (statement.isEmpty) {
      return;
    }

    if (_openEntity != null) {
      if (statement == '}') {
        _openEntity = null;
        return;
      }
      _attributes[_openEntity!]!.add(_formatAttribute(statement));
      return;
    }

    if (statement == '}') {
      return;
    }

    final directionMatch = _directionStatement.firstMatch(statement);
    if (directionMatch != null) {
      final parsed = CcMermaidDirection.tryParse(directionMatch.group(1)!);
      if (parsed != null) {
        direction = parsed;
      }
      return;
    }

    if (_ignored.hasMatch(statement)) {
      return;
    }

    final relation = findRelationToken(statement, markers: _cardinalityMarkers);
    if (relation != null) {
      final left = _relationLabel.firstMatch(
        statement.substring(0, relation.start).trim(),
      );
      final right = _relationLabel.firstMatch(
        statement.substring(relation.end).trim(),
      );
      if (left != null && right != null) {
        final fromId = _entity(left.group(1)!);
        final toId = _entity(right.group(1)!);
        final labelLines = splitMermaidLabel(right.group(2));
        _edges.add(
          CcMermaidEdge(
            fromId: fromId,
            toId: toId,
            label: labelLines.join(' '),
            labelLines: labelLines,
            stroke: relation.dashed
                ? CcMermaidEdgeStroke.dotted
                : CcMermaidEdgeStroke.solid,
            startMarker:
                _markerByToken[relation.leftMarker] ?? CcMermaidEdgeMarker.none,
            endMarker:
                _markerByToken[relation.rightMarker] ??
                CcMermaidEdgeMarker.none,
          ),
        );
        return;
      }
    }

    final open = _entityOpen.firstMatch(statement);
    if (open != null) {
      _openEntity = _entity(open.group(1)!);
      return;
    }

    // A lone entity declaration.
    final bare = stripMermaidQuotes(statement);
    if (!bare.contains(' ')) {
      _entity(bare);
    }
  }

  String _entity(String rawId) {
    final id = stripMermaidQuotes(rawId);
    if (!_attributes.containsKey(id)) {
      _attributes[id] = [];
      _order.add(id);
    }
    return id;
  }

  /// Formats an attribute row: `string custNumber PK "the number"` renders as
  /// `string custNumber PK` with the comment dropped (comments would double the
  /// box width for prose the diagram cannot lay out).
  String _formatAttribute(String raw) {
    final withoutComment = raw.replaceAll(RegExp(r'"[^"]*"\s*$'), '').trim();
    return decodeMermaidEntities(
      withoutComment.replaceAll(RegExp(r'\s+'), ' '),
    );
  }

  CcMermaidGraph build({String? title}) {
    return CcMermaidGraph(
      kind: CcMermaidGraphKind.er,
      direction: direction,
      nodes: [
        for (final id in _order)
          CcMermaidNode(
            id: id,
            lines: [id],
            shape: CcMermaidNodeShape.compartments,
            compartments: [
              if (_attributes[id]!.isNotEmpty)
                List.unmodifiable(_attributes[id]!),
            ],
          ),
      ],
      edges: List.unmodifiable(_edges),
      title: title,
    );
  }
}
