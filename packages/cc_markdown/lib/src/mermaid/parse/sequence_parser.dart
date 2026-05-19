/// The `sequenceDiagram` parser.
///
/// Lifelines are declared (or inferred from first use, in message order, which
/// is what mermaid does) and the body is read as a recursive step list so
/// framed constructs — `loop`, `alt`/`else`, `opt`, `par`/`and`,
/// `critical`/`option`, `break`, `rect` — nest correctly.
///
/// `box … end` participant grouping is parsed TRANSPARENTLY: the participants
/// inside are declared, the frame is not drawn.
library;

import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:cc_markdown/src/mermaid/parse/source.dart';

/// Arrow tokens, longest first so `-->>` never lexes as `-->`.
const List<(String, CcMermaidEdgeStroke, CcMermaidEdgeMarker)> _arrows = [
  ('<<-->>', CcMermaidEdgeStroke.dotted, CcMermaidEdgeMarker.arrow),
  ('<<->>', CcMermaidEdgeStroke.solid, CcMermaidEdgeMarker.arrow),
  ('-->>', CcMermaidEdgeStroke.dotted, CcMermaidEdgeMarker.arrow),
  ('->>', CcMermaidEdgeStroke.solid, CcMermaidEdgeMarker.arrow),
  ('--x', CcMermaidEdgeStroke.dotted, CcMermaidEdgeMarker.cross),
  ('-x', CcMermaidEdgeStroke.solid, CcMermaidEdgeMarker.cross),
  ('--)', CcMermaidEdgeStroke.dotted, CcMermaidEdgeMarker.openArrow),
  ('-)', CcMermaidEdgeStroke.solid, CcMermaidEdgeMarker.openArrow),
  ('-->', CcMermaidEdgeStroke.dotted, CcMermaidEdgeMarker.none),
  ('->', CcMermaidEdgeStroke.solid, CcMermaidEdgeMarker.none),
];

final RegExp _participantStatement = RegExp(
  r'''^(participant|actor)\s+([^\s:]+?)(?:\s+as\s+(.+?))?\s*$''',
  caseSensitive: false,
);
final RegExp _noteStatement = RegExp(
  r'^note\s+(right\s+of|left\s+of|over)\s+([^:]+?)\s*:\s*(.*)$',
  caseSensitive: false,
);
final RegExp _activationStatement = RegExp(
  r'^(activate|deactivate)\s+(\S+)\s*$',
  caseSensitive: false,
);
final RegExp _dividerStatement = RegExp(r'^==+\s*(.*?)\s*==+$');
final RegExp _titleStatement = RegExp(
  r'^title(?:\s+|\s*:\s*)(.*)$',
  caseSensitive: false,
);
final RegExp _blockOpen = RegExp(
  r'^(loop|alt|opt|par|critical|break|rect|box)\b\s*(.*)$',
  caseSensitive: false,
);
final RegExp _sectionKeyword = RegExp(
  r'^(else|and|option)\b\s*(.*)$',
  caseSensitive: false,
);
final RegExp _ignored = RegExp(
  r'^(autonumber\s+\S+|links?|properties|accTitle|accDescr|create|destroy|sequenceDiagram)\b',
  caseSensitive: false,
);

const Map<String, CcMermaidBlockKind> _blockKinds = {
  'loop': CcMermaidBlockKind.loop,
  'alt': CcMermaidBlockKind.alt,
  'opt': CcMermaidBlockKind.opt,
  'par': CcMermaidBlockKind.par,
  'critical': CcMermaidBlockKind.critical,
  'break': CcMermaidBlockKind.breakBlock,
  'rect': CcMermaidBlockKind.rect,
};

/// Parses a `sequenceDiagram` source.
CcMermaidSequence parseMermaidSequence(CcMermaidSource source) {
  final builder = _SequenceBuilder(source.statements);
  final steps = builder.parseSteps(depth: 0);
  return CcMermaidSequence(
    participants: builder.participants,
    steps: steps,
    autonumber: builder.autonumber,
    title: builder.title ?? source.title,
  );
}

class _SequenceBuilder {
  _SequenceBuilder(this.statements);

  final List<String> statements;
  final List<CcMermaidParticipant> participants = [];
  final Set<String> _declared = {};
  bool autonumber = false;
  String? title;
  int _index = 0;

  /// Reads steps until `end` (or the next section keyword) at this [depth].
  List<CcMermaidSequenceStep> parseSteps({required int depth}) {
    final steps = <CcMermaidSequenceStep>[];
    while (_index < statements.length) {
      final statement = statements[_index].trim();
      if (statement.isEmpty) {
        _index++;
        continue;
      }
      final lower = statement.toLowerCase();
      if (lower == 'end' || _sectionKeyword.hasMatch(statement)) {
        if (depth > 0) {
          // Left for the enclosing block to consume.
          return steps;
        }
        // A stray `end`/`else` at top level: skip it rather than stop parsing.
        _index++;
        continue;
      }
      _index++;
      final step = _statement(statement, depth: depth);
      if (step != null) {
        steps.add(step);
      }
    }
    return steps;
  }

  CcMermaidSequenceStep? _statement(String statement, {required int depth}) {
    final lower = statement.toLowerCase();
    if (lower == 'autonumber') {
      autonumber = true;
      return null;
    }

    final block = _blockOpen.firstMatch(statement);
    if (block != null) {
      final keyword = block.group(1)!.toLowerCase();
      final label = block.group(2)!.trim();
      if (keyword == 'box') {
        // Transparent grouping: its participants are declared, no frame drawn.
        final inner = parseSteps(depth: depth + 1);
        _consumeEnd();
        return inner.isEmpty
            ? null
            : CcMermaidBlock(
                kind: CcMermaidBlockKind.box,
                label: label,
                sections: [CcMermaidBlockSection(label: label, steps: inner)],
              );
      }
      return _parseBlock(_blockKinds[keyword]!, label, depth: depth);
    }

    final participant = _participantStatement.firstMatch(statement);
    if (participant != null) {
      _declare(
        participant.group(2)!,
        label: participant.group(3),
        isActor: participant.group(1)!.toLowerCase() == 'actor',
      );
      return null;
    }

    final note = _noteStatement.firstMatch(statement);
    if (note != null) {
      final placement = switch (note
          .group(1)!
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .first) {
        'right' => CcMermaidNotePlacement.right,
        'left' => CcMermaidNotePlacement.left,
        _ => CcMermaidNotePlacement.over,
      };
      final anchors = [
        for (final id in note.group(2)!.split(',')) _declare(id.trim()),
      ];
      return CcMermaidNote(
        placement: placement,
        participantIds: anchors,
        lines: splitMermaidLabel(note.group(3)),
      );
    }

    final activation = _activationStatement.firstMatch(statement);
    if (activation != null) {
      return CcMermaidActivation(
        participantId: _declare(activation.group(2)!),
        active: activation.group(1)!.toLowerCase() == 'activate',
      );
    }

    final divider = _dividerStatement.firstMatch(statement);
    if (divider != null) {
      return CcMermaidDivider(divider.group(1)!.trim());
    }

    final titleMatch = _titleStatement.firstMatch(statement);
    if (titleMatch != null) {
      title = titleMatch.group(1)!.trim();
      return null;
    }

    if (_ignored.hasMatch(statement)) {
      // `autonumber 10 10` still turns numbering on.
      if (lower.startsWith('autonumber')) {
        autonumber = true;
      }
      return null;
    }

    return _parseMessage(statement);
  }

  CcMermaidBlock _parseBlock(
    CcMermaidBlockKind kind,
    String label, {
    required int depth,
  }) {
    final sections = <CcMermaidBlockSection>[];
    var sectionLabel = label;
    while (true) {
      final steps = parseSteps(depth: depth + 1);
      sections.add(CcMermaidBlockSection(label: sectionLabel, steps: steps));
      if (_index >= statements.length) {
        break;
      }
      final next = statements[_index].trim();
      final section = _sectionKeyword.firstMatch(next);
      if (section != null) {
        _index++;
        sectionLabel = section.group(2)!.trim();
        continue;
      }
      _consumeEnd();
      break;
    }
    return CcMermaidBlock(kind: kind, label: label, sections: sections);
  }

  void _consumeEnd() {
    if (_index < statements.length &&
        statements[_index].trim().toLowerCase() == 'end') {
      _index++;
    }
  }

  CcMermaidSequenceStep? _parseMessage(String statement) {
    final arrow = _findArrow(statement);
    if (arrow == null) {
      return null;
    }
    final (token, stroke, marker, start) = arrow;
    final fromRaw = statement.substring(0, start).trim();
    var rest = statement.substring(start + token.length);
    var activates = false;
    var deactivates = false;
    rest = rest.trimLeft();
    if (rest.startsWith('+')) {
      activates = true;
      rest = rest.substring(1);
    } else if (rest.startsWith('-')) {
      deactivates = true;
      rest = rest.substring(1);
    }
    final colon = rest.indexOf(':');
    final toRaw = (colon < 0 ? rest : rest.substring(0, colon)).trim();
    final text = colon < 0 ? '' : rest.substring(colon + 1).trim();
    if (fromRaw.isEmpty || toRaw.isEmpty) {
      return null;
    }
    return CcMermaidMessage(
      fromId: _declare(fromRaw),
      toId: _declare(toRaw),
      lines: splitMermaidLabel(text),
      stroke: stroke,
      marker: marker,
      activates: activates,
      deactivates: deactivates,
    );
  }

  /// Finds the earliest arrow token, preferring the longest match there.
  (String, CcMermaidEdgeStroke, CcMermaidEdgeMarker, int)? _findArrow(
    String statement,
  ) {
    var bestIndex = -1;
    (String, CcMermaidEdgeStroke, CcMermaidEdgeMarker)? best;
    for (final arrow in _arrows) {
      final index = statement.indexOf(arrow.$1);
      if (index < 0) {
        continue;
      }
      if (bestIndex < 0 ||
          index < bestIndex ||
          (index == bestIndex && arrow.$1.length > best!.$1.length)) {
        bestIndex = index;
        best = arrow;
      }
    }
    if (best == null) {
      return null;
    }
    return (best.$1, best.$2, best.$3, bestIndex);
  }

  /// Declares (or interns) a participant, returning its id. First mention wins
  /// the left-to-right lane order — mermaid's rule.
  String _declare(String raw, {String? label, bool isActor = false}) {
    final id = stripMermaidQuotes(raw).trim();
    if (id.isEmpty) {
      return id;
    }
    if (_declared.add(id)) {
      participants.add(
        CcMermaidParticipant(
          id: id,
          lines: splitMermaidLabel(label ?? id),
          isActor: isActor,
        ),
      );
      return id;
    }
    if (label != null || isActor) {
      for (var i = 0; i < participants.length; i++) {
        if (participants[i].id == id) {
          participants[i] = CcMermaidParticipant(
            id: id,
            lines: label == null
                ? participants[i].lines
                : splitMermaidLabel(label),
            isActor: isActor || participants[i].isActor,
          );
          break;
        }
      }
    }
    return id;
  }
}
