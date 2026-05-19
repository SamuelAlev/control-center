/// The `classDiagram` parser.
///
/// Classes become compartment boxes (name header, attribute rows, method rows)
/// and relations become decorated edges. Mermaid ranks by DECLARATION ORDER —
/// the left-hand class of `Animal <|-- Duck` sits above the right-hand one, with
/// the hollow triangle drawn at the left end — so edges keep the written
/// direction and carry a marker per end.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/relation_token.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

/// Every marker the class dialect accepts at either end of a relation.
const List<String> _relationMarkers = ['<|', '|>', '*', 'o', '<', '>'];

final RegExp _directionStatement = RegExp(
  r'^direction\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _classOpen = RegExp(
  r'''^class\s+([^\s{\[:]+)(?:\[\s*"?([^"\]]*)"?\s*\])?(?::::(\S+))?\s*\{\s*$''',
  caseSensitive: false,
);
final RegExp _classDeclaration = RegExp(
  r'''^class\s+([^\s{\[:]+)(?:\[\s*"?([^"\]]*)"?\s*\])?(?::::(\S+))?\s*$''',
  caseSensitive: false,
);
final RegExp _memberStatement = RegExp(r'^([^\s:]+)\s*:\s*(.+)$');
final RegExp _stereotypeMember = RegExp(r'^<<\s*(.+?)\s*>>$');
final RegExp _annotationStatement = RegExp(
  r'^<<\s*(.+?)\s*>>\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _noteFor = RegExp(
  r'''^note\s+for\s+(\S+)\s+"?(.*?)"?\s*$''',
  caseSensitive: false,
);
final RegExp _standaloneNote = RegExp(
  r'''^note\s+"?(.*?)"?\s*$''',
  caseSensitive: false,
);
final RegExp _cssClassStatement = RegExp(
  r'^cssClass\s+"([^"]*)"\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _ignored = RegExp(
  r'^(classDef|style|click|callback|link|accTitle|accDescr|classDiagram(-v2)?|namespace)\b',
  caseSensitive: false,
);

/// A quoted cardinality plus the identifier beside it, on either side of the
/// relation token: `Customer "1" --> "*" Ticket`.
final RegExp _leftSide = RegExp(r'''^(\S+?)\s*(?:"([^"]*)"\s*)?$''');
final RegExp _rightSide = RegExp(
  r'''^(?:"([^"]*)"\s*)?(\S+?)\s*(?::\s*(.*))?$''',
);

/// Parses a `classDiagram` source into a graph.
CcMermaidGraph parseMermaidClass(CcMermaidSource source) {
  final builder = _ClassBuilder();
  for (final statement in source.statements) {
    builder.statement(statement);
  }
  return builder.build(title: source.title);
}

class _ClassBuilder {
  CcMermaidDirection direction = CcMermaidDirection.topDown;

  final Map<String, _ClassBox> _boxes = {};
  final List<CcMermaidEdge> _edges = [];
  var _notes = 0;
  String? _openClass;

  void statement(String raw) {
    final statement = raw.trim();
    if (statement.isEmpty) {
      return;
    }

    if (_openClass != null) {
      if (statement == '}') {
        _openClass = null;
        return;
      }
      _addMember(_openClass!, statement);
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

    final open = _classOpen.firstMatch(statement);
    if (open != null) {
      final box = _box(open.group(1)!);
      final label = open.group(2);
      if (label != null && label.trim().isNotEmpty) {
        box.label = stripMermaidQuotes(label);
      }
      final styleClass = open.group(3);
      if (styleClass != null) {
        box.styleClasses.add(styleClass);
      }
      _openClass = box.id;
      return;
    }

    final declaration = _classDeclaration.firstMatch(statement);
    if (declaration != null) {
      final box = _box(declaration.group(1)!);
      final label = declaration.group(2);
      if (label != null && label.trim().isNotEmpty) {
        box.label = stripMermaidQuotes(label);
      }
      final styleClass = declaration.group(3);
      if (styleClass != null) {
        box.styleClasses.add(styleClass);
      }
      return;
    }

    final annotation = _annotationStatement.firstMatch(statement);
    if (annotation != null) {
      _box(annotation.group(2)!).stereotype = annotation.group(1);
      return;
    }

    final noteFor = _noteFor.firstMatch(statement);
    if (noteFor != null) {
      _addNote(noteFor.group(2)!, subject: noteFor.group(1));
      return;
    }

    final cssClass = _cssClassStatement.firstMatch(statement);
    if (cssClass != null) {
      for (final id in cssClass.group(1)!.split(',')) {
        _box(id.trim()).styleClasses.add(cssClass.group(2)!);
      }
      return;
    }

    if (_ignored.hasMatch(statement)) {
      return;
    }

    final relation = findRelationToken(statement, markers: _relationMarkers);
    if (relation != null && _addRelation(statement, relation)) {
      return;
    }

    final note = _standaloneNote.firstMatch(statement);
    if (note != null) {
      _addNote(note.group(1)!);
      return;
    }

    // `Animal : +int age` — the inline member form.
    final member = _memberStatement.firstMatch(statement);
    if (member != null) {
      _addMember(member.group(1)!, member.group(2)!);
      return;
    }

    if (!statement.contains(' ')) {
      _box(statement);
    }
  }

  /// Interns a class box. A generic id (`List~int~`) is keyed without its type
  /// parameter but LABELED with it, rendered in `<>` form.
  _ClassBox _box(String rawId) {
    final id = rawId.replaceAll(RegExp('~.*~?'), '');
    return _boxes.putIfAbsent(
      id.isEmpty ? rawId : id,
      () => _ClassBox(id: id.isEmpty ? rawId : id, label: _formatMember(rawId)),
    );
  }

  void _addMember(String classId, String raw) {
    final box = _box(classId);
    var member = raw.trim();
    final stereotype = _stereotypeMember.firstMatch(member);
    if (stereotype != null) {
      box.stereotype = stereotype.group(1);
      return;
    }
    // Static (`$`) and abstract (`*`) markers are dropped: the renderer draws
    // plain runs, and a stray sigil reads as part of the name.
    member = member.replaceAll(RegExp(r'[\$\*]\s*$'), '').trim();
    if (member.isEmpty) {
      return;
    }
    if (member.contains('(')) {
      box.methods.add(_formatMember(member));
    } else {
      box.attributes.add(_formatMember(member));
    }
  }

  /// Normalizes generics (`List~int~` → `List<int>`) and decodes entities.
  String _formatMember(String member) {
    var text = decodeMermaidEntities(member);
    var open = true;
    final buf = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit == 0x7E /* ~ */ ) {
        buf.write(open ? '<' : '>');
        open = !open;
        continue;
      }
      buf.writeCharCode(unit);
    }
    text = buf.toString();
    return text;
  }

  static const Map<String, CcMermaidEdgeMarker> _markers = {
    '<|': CcMermaidEdgeMarker.triangleHollow,
    '|>': CcMermaidEdgeMarker.triangleHollow,
    '*': CcMermaidEdgeMarker.diamondFilled,
    'o': CcMermaidEdgeMarker.diamondHollow,
    '<': CcMermaidEdgeMarker.openArrow,
    '>': CcMermaidEdgeMarker.openArrow,
  };

  /// Adds the relation described by [token]; false when the statement's sides
  /// don't read as class names after all (the caller then tries other forms).
  bool _addRelation(String statement, MermaidRelationToken token) {
    final left = _leftSide.firstMatch(
      statement.substring(0, token.start).trim(),
    );
    final right = _rightSide.firstMatch(statement.substring(token.end).trim());
    if (left == null || right == null) {
      return false;
    }
    final fromId = _box(left.group(1)!).id;
    final toId = _box(right.group(2)!).id;
    final labelLines = splitMermaidLabel(right.group(3));
    _edges.add(
      CcMermaidEdge(
        fromId: fromId,
        toId: toId,
        label: labelLines.join(' '),
        labelLines: labelLines,
        stroke: token.dashed
            ? CcMermaidEdgeStroke.dotted
            : CcMermaidEdgeStroke.solid,
        startMarker: _markers[token.leftMarker] ?? CcMermaidEdgeMarker.none,
        endMarker: _markers[token.rightMarker] ?? CcMermaidEdgeMarker.none,
        startCardinality: _cardinality(left.group(2)),
        endCardinality: _cardinality(right.group(1)),
      ),
    );
    return true;
  }

  String? _cardinality(String? raw) {
    final text = raw?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _addNote(String text, {String? subject}) {
    final id = '__class_note_${_notes++}';
    _boxes[id] = _ClassBox(id: id, label: '')
      ..shape = CcMermaidNodeShape.note
      ..noteLines = splitMermaidLabel(text);
    if (subject != null) {
      _edges.add(
        CcMermaidEdge(
          fromId: subject,
          toId: id,
          stroke: CcMermaidEdgeStroke.dotted,
          endMarker: CcMermaidEdgeMarker.none,
        ),
      );
    }
  }

  CcMermaidGraph build({String? title}) {
    final nodes = <CcMermaidNode>[
      for (final box in _boxes.values)
        if (box.shape == CcMermaidNodeShape.note)
          CcMermaidNode(
            id: box.id,
            lines: box.noteLines,
            shape: CcMermaidNodeShape.note,
          )
        else
          CcMermaidNode(
            id: box.id,
            lines: splitMermaidLabel(box.label.isEmpty ? box.id : box.label),
            shape: CcMermaidNodeShape.compartments,
            compartments: [
              if (box.attributes.isNotEmpty) List.unmodifiable(box.attributes),
              if (box.methods.isNotEmpty) List.unmodifiable(box.methods),
            ],
            stereotype: box.stereotype,
            styleClasses: List.unmodifiable(box.styleClasses),
          ),
    ];
    return CcMermaidGraph(
      kind: CcMermaidGraphKind.classDiagram,
      direction: direction,
      nodes: List.unmodifiable(nodes),
      edges: List.unmodifiable(_edges),
      title: title,
    );
  }
}

class _ClassBox {
  _ClassBox({required this.id, required this.label});

  final String id;
  String label;
  String? stereotype;
  CcMermaidNodeShape shape = CcMermaidNodeShape.compartments;
  List<String> noteLines = const [];
  final List<String> attributes = [];
  final List<String> methods = [];
  final List<String> styleClasses = [];
}
