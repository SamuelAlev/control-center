/// The `stateDiagram` / `stateDiagram-v2` parser.
///
/// State diagrams lower into the same [CcMermaidGraph] the flowchart uses —
/// states are rounded boxes, composite states are clusters and `[*]` becomes a
/// start dot (as a source) or a terminal ring (as a target). Every `[*]`
/// OCCURRENCE gets its own marker node, which is what mermaid draws: one shared
/// hub would pull unrelated branches together.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

final RegExp _directionStatement = RegExp(
  r'^direction\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _stateAlias = RegExp(
  r'''^state\s+(?:"([^"]*)"|'([^']*)')\s+as\s+(\S+)\s*$''',
  caseSensitive: false,
);
final RegExp _stateComposite = RegExp(
  r'^state\s+([^\s{]+)(?:\s+as\s+(\S+))?\s*\{\s*$',
  caseSensitive: false,
);
final RegExp _stateStereotype = RegExp(
  r'^(?:state\s+)?(\S+)\s*<<\s*(choice|fork|join|end|start)\s*>>\s*$',
  caseSensitive: false,
);
final RegExp _stateDeclaration = RegExp(
  r'^state\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _noteStatement = RegExp(
  r'^note\s+(right|left)\s+of\s+([^:]+?)\s*(?::\s*(.*))?$',
  caseSensitive: false,
);
final RegExp _noteOver = RegExp(
  r'^note\s+over\s+([^:]+?)\s*(?::\s*(.*))?$',
  caseSensitive: false,
);
final RegExp _transition = RegExp(r'^(.+?)\s*(-->|->)\s*(.+)$');
final RegExp _descriptionStatement = RegExp(r'^([^:]+?)\s*:\s*(.*)$');
final RegExp _ignored = RegExp(
  r'^(classDef|class|style|accTitle|accDescr|stateDiagram(-v2)?|hide empty description)\b',
  caseSensitive: false,
);

/// Parses a `stateDiagram` source into a graph.
CcMermaidGraph parseMermaidState(CcMermaidSource source) {
  final builder = _StateBuilder();
  final headerDirection = _headerDirection(source.header);
  if (headerDirection != null) {
    builder.direction = headerDirection;
  }
  var i = 0;
  while (i < source.statements.length) {
    i = builder.statement(source.statements, i);
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

class _StateBuilder {
  CcMermaidDirection direction = CcMermaidDirection.topDown;

  final Map<String, CcMermaidNode> _nodes = {};
  final List<CcMermaidEdge> _edges = [];
  final List<CcMermaidCluster> _clusters = [];
  final List<String> _clusterStack = [];
  var _markers = 0;
  var _notes = 0;

  String? get _cluster => _clusterStack.isEmpty ? null : _clusterStack.last;

  /// Handles the statement at [index]; returns the next index to read (notes
  /// with an `end note` body consume several lines).
  int statement(List<String> statements, int index) {
    final statement = statements[index].trim();
    var next = index + 1;
    if (statement.isEmpty) {
      return next;
    }

    if (statement == '}') {
      if (_clusterStack.isNotEmpty) {
        _clusterStack.removeLast();
      }
      return next;
    }
    // A concurrency divider inside a composite state — no visual of its own.
    if (statement == '--') {
      return next;
    }

    final directionMatch = _directionStatement.firstMatch(statement);
    if (directionMatch != null) {
      final parsed = CcMermaidDirection.tryParse(directionMatch.group(1)!);
      if (parsed != null && _clusterStack.isEmpty) {
        direction = parsed;
      }
      return next;
    }

    final composite = _stateComposite.firstMatch(statement);
    if (composite != null) {
      final label = stripMermaidQuotes(composite.group(1)!);
      final id = composite.group(2) ?? label;
      _clusters.add(
        CcMermaidCluster(
          id: id,
          lines: splitMermaidLabel(label),
          parentId: _cluster,
        ),
      );
      _clusterStack.add(id);
      return next;
    }

    final alias = _stateAlias.firstMatch(statement);
    if (alias != null) {
      final label = alias.group(1) ?? alias.group(2) ?? '';
      _touch(alias.group(3)!, label: label);
      return next;
    }

    final stereotype = _stateStereotype.firstMatch(statement);
    if (stereotype != null) {
      final kind = stereotype.group(2)!.toLowerCase();
      _touch(
        stereotype.group(1)!,
        shape: switch (kind) {
          'choice' => CcMermaidNodeShape.choice,
          'fork' || 'join' => CcMermaidNodeShape.bar,
          'start' => CcMermaidNodeShape.startPoint,
          _ => CcMermaidNodeShape.endPoint,
        },
        // A choice rhombus and a fork bar carry no text in mermaid.
        label: '',
      );
      return next;
    }

    final declaration = _stateDeclaration.firstMatch(statement);
    if (declaration != null) {
      _touch(stripMermaidQuotes(declaration.group(1)!));
      return next;
    }

    final note =
        _noteStatement.firstMatch(statement) ?? _noteOver.firstMatch(statement);
    if (note != null) {
      final isOver = _noteStatement.firstMatch(statement) == null;
      final subject = (isOver ? note.group(1) : note.group(2))!.trim();
      var text = (isOver ? note.group(2) : note.group(3))?.trim() ?? '';
      if (text.isEmpty) {
        // Block form: `note right of A` … `end note`.
        final body = <String>[];
        while (next < statements.length &&
            statements[next].trim().toLowerCase() != 'end note') {
          body.add(statements[next].trim());
          next++;
        }
        if (next < statements.length) {
          next++; // the `end note` line
        }
        text = body.join('\n');
      }
      _addNote(subject.split(',').first.trim(), text);
      return next;
    }

    final transition = _transition.firstMatch(statement);
    if (transition != null) {
      var target = transition.group(3)!.trim();
      String? label;
      final labelSplit = _descriptionStatement.firstMatch(target);
      if (labelSplit != null) {
        target = labelSplit.group(1)!.trim();
        label = labelSplit.group(2)!.trim();
      }
      final fromId = _resolveEndpoint(
        transition.group(1)!.trim(),
        isSource: true,
      );
      final toId = _resolveEndpoint(target, isSource: false);
      final labelLines = splitMermaidLabel(label);
      _edges.add(
        CcMermaidEdge(
          fromId: fromId,
          toId: toId,
          label: labelLines.join(' '),
          labelLines: labelLines,
        ),
      );
      return next;
    }

    if (_ignored.hasMatch(statement)) {
      return next;
    }

    // `id : description`.
    final description = _descriptionStatement.firstMatch(statement);
    if (description != null) {
      _touch(description.group(1)!.trim(), label: description.group(2)!.trim());
      return next;
    }

    // A bare state name on its own line.
    if (!statement.contains(' ')) {
      _touch(statement);
    }
    return next;
  }

  /// Resolves a transition endpoint, minting a fresh marker node for `[*]`.
  String _resolveEndpoint(String token, {required bool isSource}) {
    final name = stripMermaidQuotes(token);
    if (name == '[*]') {
      final id = '__state_marker_${_markers++}';
      _nodes[id] = CcMermaidNode(
        id: id,
        lines: const [],
        shape: isSource
            ? CcMermaidNodeShape.startPoint
            : CcMermaidNodeShape.endPoint,
        clusterId: _cluster,
      );
      return id;
    }
    // A transition may name a composite state; keep it as a node id only when
    // it is not a cluster (an edge to a cluster is rendered to its box).
    _touch(name);
    return name;
  }

  void _addNote(String subject, String text) {
    final id = '__state_note_${_notes++}';
    _nodes[id] = CcMermaidNode(
      id: id,
      lines: splitMermaidLabel(text),
      shape: CcMermaidNodeShape.note,
      clusterId: _nodes[subject]?.clusterId,
    );
    _edges.add(
      CcMermaidEdge(
        fromId: subject,
        toId: id,
        stroke: CcMermaidEdgeStroke.dotted,
        endMarker: CcMermaidEdgeMarker.none,
      ),
    );
  }

  void _touch(String id, {String? label, CcMermaidNodeShape? shape}) {
    if (id.isEmpty || _clusters.any((c) => c.id == id)) {
      return;
    }
    final existing = _nodes[id];
    _nodes[id] = CcMermaidNode(
      id: id,
      lines: label == null
          ? (existing?.lines ?? const <String>[])
          : splitMermaidLabel(label),
      shape: shape ?? existing?.shape ?? CcMermaidNodeShape.roundRect,
      clusterId: existing?.clusterId ?? _cluster,
    );
  }

  CcMermaidGraph build({String? title}) {
    return CcMermaidGraph(
      kind: CcMermaidGraphKind.state,
      direction: direction,
      nodes: List.unmodifiable(_nodes.values),
      edges: List.unmodifiable(_edges),
      clusters: List.unmodifiable(_clusters),
      title: title,
    );
  }
}
