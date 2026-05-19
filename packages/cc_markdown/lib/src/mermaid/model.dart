/// The mermaid diagram model: what a mermaid source MEANS, with nothing about
/// how it looks or where it sits.
///
/// Pure Dart by construction (no `dart:ui`, no Flutter) so the grammar can be
/// parsed and unit-tested without a Flutter binding, and so a future offload of
/// mermaid parsing to a Web Worker stays possible.
///
/// Four diagram families cover the mermaid dialects the app actually receives:
///
///  * [CcMermaidGraph] — the box-and-arrow family. `flowchart`/`graph`,
///    `stateDiagram`, `classDiagram`, and `erDiagram` all LOWER into it: they
///    differ in node shapes, node content (a label vs. compartments), and edge
///    end markers, not in topology, so one layered layout serves all four.
///  * [CcMermaidSequence] — lifelines and messages (a time axis, not a graph).
///  * [CcMermaidPie] — one circle of weighted slices.
///  * [CcMermaidTimeline] — a chronological axis of grouped events.
library;

/// Which mermaid dialect produced a [CcMermaidGraph]. Drives shape defaults,
/// edge decorations, and the label a host UI shows for the diagram.
enum CcMermaidGraphKind {
  /// `flowchart` / `graph`.
  flowchart,

  /// `stateDiagram` / `stateDiagram-v2`.
  state,

  /// `classDiagram`.
  classDiagram,

  /// `erDiagram`.
  er,
}

/// Layout direction of a [CcMermaidGraph].
enum CcMermaidDirection {
  /// Top to bottom (`TD` / `TB`).
  topDown,

  /// Bottom to top (`BT`).
  bottomUp,

  /// Left to right (`LR`).
  leftRight,

  /// Right to left (`RL`).
  rightLeft;

  /// Whether ranks advance horizontally (`LR`/`RL`).
  bool get isHorizontal =>
      this == CcMermaidDirection.leftRight ||
      this == CcMermaidDirection.rightLeft;

  /// Whether ranks advance in the negative direction (`BT`/`RL`).
  bool get isReversed =>
      this == CcMermaidDirection.bottomUp ||
      this == CcMermaidDirection.rightLeft;

  /// Parses a mermaid direction token (`TD`, `TB`, `BT`, `LR`, `RL`); null when
  /// [token] is not a direction.
  static CcMermaidDirection? tryParse(String token) =>
      switch (token.toUpperCase()) {
        'TD' || 'TB' || 'V' => CcMermaidDirection.topDown,
        'BT' || '^' => CcMermaidDirection.bottomUp,
        'LR' || '>' => CcMermaidDirection.leftRight,
        'RL' || '<' => CcMermaidDirection.rightLeft,
        _ => null,
      };
}

/// The outline a graph node is drawn with.
enum CcMermaidNodeShape {
  /// `[text]` — a plain rectangle.
  rect,

  /// `(text)` — a rounded rectangle.
  roundRect,

  /// `([text])` — a pill.
  stadium,

  /// `[[text]]` — a rectangle with doubled side walls.
  subroutine,

  /// `[(text)]` — a database cylinder.
  cylinder,

  /// `((text))` — a circle.
  circle,

  /// `(((text)))` — a double circle.
  doubleCircle,

  /// `{text}` — a decision rhombus.
  diamond,

  /// `{{text}}` — a hexagon.
  hexagon,

  /// `[/text/]` — a parallelogram leaning right.
  parallelogram,

  /// `[\text\]` — a parallelogram leaning left.
  parallelogramAlt,

  /// `[/text\]` — a trapezoid.
  trapezoid,

  /// `[\text/]` — an inverted trapezoid.
  trapezoidAlt,

  /// `>text]` — an asymmetric flag.
  asymmetric,

  /// A compartment box: name header plus attribute/method rows
  /// (`classDiagram` / `erDiagram`).
  compartments,

  /// A state-diagram start marker (`[*]` as a source) — a filled dot.
  startPoint,

  /// A state-diagram terminal marker (`[*]` as a target) — a ringed dot.
  endPoint,

  /// A `<<choice>>` state — a small rhombus.
  choice,

  /// A `<<fork>>` / `<<join>>` state — a thick bar.
  bar,

  /// A note box (dog-eared, always dashed-linked to its subject).
  note,
}

/// Stroke pattern of an edge.
enum CcMermaidEdgeStroke {
  /// `-->` / `---`.
  solid,

  /// `-.->` / `-.-`.
  dotted,

  /// `==>` / `===`.
  thick,

  /// `~~~` — reserves layout space but paints nothing.
  invisible,
}

/// A decoration at one end of an edge.
enum CcMermaidEdgeMarker {
  /// Nothing (a bare line end).
  none,

  /// A filled triangular arrowhead (`-->`).
  arrow,

  /// A thin open arrowhead (`->>` in class/state dialects).
  openArrow,

  /// A cross (`--x`).
  cross,

  /// A hollow circle (`--o`).
  circle,

  /// A hollow triangle — inheritance (`<|--`).
  triangleHollow,

  /// A filled diamond — composition (`*--`).
  diamondFilled,

  /// A hollow diamond — aggregation (`o--`).
  diamondHollow,

  /// ER cardinality: exactly one (`||`).
  erOne,

  /// ER cardinality: zero or one (`|o`).
  erZeroOrOne,

  /// ER cardinality: one or many (`}|`).
  erOneOrMany,

  /// ER cardinality: zero or many (`}o`).
  erZeroOrMany,
}

/// One node of a [CcMermaidGraph].
class CcMermaidNode {
  /// Creates a [CcMermaidNode].
  const CcMermaidNode({
    required this.id,
    required this.lines,
    this.shape = CcMermaidNodeShape.rect,
    this.compartments = const [],
    this.stereotype,
    this.clusterId,
    this.styleClasses = const [],
    this.href,
    this.tooltip,
  });

  /// Graph-unique id as written in the source.
  final String id;

  /// Label lines (already `<br>`-split; empty means "render the id").
  final List<String> lines;

  /// The outline to draw.
  final CcMermaidNodeShape shape;

  /// Compartment rows below the header, for [CcMermaidNodeShape.compartments]
  /// (class members grouped attributes/methods, ER attributes).
  final List<List<String>> compartments;

  /// `<<interface>>`-style annotation shown above the name, or null.
  final String? stereotype;

  /// Innermost cluster (`subgraph` / composite state) containing this node.
  final String? clusterId;

  /// `classDef`/`:::`-assigned style class names, in application order.
  final List<String> styleClasses;

  /// `click`-bound link target, or null.
  final String? href;

  /// `click`-bound tooltip, or null.
  final String? tooltip;

  /// The label lines to draw, falling back to the id for a bare `A --> B`.
  List<String> get displayLines => lines.isEmpty ? [id] : lines;

  /// A copy with the given fields replaced.
  CcMermaidNode copyWith({
    List<String>? lines,
    CcMermaidNodeShape? shape,
    List<List<String>>? compartments,
    String? stereotype,
    String? clusterId,
    List<String>? styleClasses,
    String? href,
    String? tooltip,
  }) => CcMermaidNode(
    id: id,
    lines: lines ?? this.lines,
    shape: shape ?? this.shape,
    compartments: compartments ?? this.compartments,
    stereotype: stereotype ?? this.stereotype,
    clusterId: clusterId ?? this.clusterId,
    styleClasses: styleClasses ?? this.styleClasses,
    href: href ?? this.href,
    tooltip: tooltip ?? this.tooltip,
  );

  @override
  String toString() => 'CcMermaidNode($id, ${displayLines.join(' ')}, $shape)';
}

/// One edge of a [CcMermaidGraph].
///
/// Ranking always runs [fromId] → [toId]; the DECORATIONS say what the arrow
/// means. A class-diagram `Animal <|-- Duck` therefore becomes
/// `from: Animal, to: Duck, startMarker: triangleHollow` — the parent stays
/// above the child in the layout while the hollow triangle lands on the parent.
class CcMermaidEdge {
  /// Creates a [CcMermaidEdge].
  const CcMermaidEdge({
    required this.fromId,
    required this.toId,
    this.label = '',
    this.labelLines = const [],
    this.stroke = CcMermaidEdgeStroke.solid,
    this.startMarker = CcMermaidEdgeMarker.none,
    this.endMarker = CcMermaidEdgeMarker.arrow,
    this.startCardinality,
    this.endCardinality,
    this.minRankSpan = 1,
  });

  /// Source node id.
  final String fromId;

  /// Target node id.
  final String toId;

  /// Flattened label (empty when unlabeled).
  final String label;

  /// Label split on `<br>`; empty when unlabeled.
  final List<String> labelLines;

  /// Stroke pattern.
  final CcMermaidEdgeStroke stroke;

  /// Decoration at the [fromId] end.
  final CcMermaidEdgeMarker startMarker;

  /// Decoration at the [toId] end.
  final CcMermaidEdgeMarker endMarker;

  /// Class-diagram cardinality label near the [fromId] end (`"1"`, `"0..*"`).
  final String? startCardinality;

  /// Class-diagram cardinality label near the [toId] end.
  final String? endCardinality;

  /// Minimum number of ranks the edge must span (mermaid's `---` length).
  final int minRankSpan;

  /// Whether the edge carries a label to reserve layout space for.
  bool get hasLabel => labelLines.isNotEmpty;

  /// A copy with the given fields replaced.
  CcMermaidEdge copyWith({
    String? fromId,
    String? toId,
    CcMermaidEdgeMarker? startMarker,
    CcMermaidEdgeMarker? endMarker,
  }) => CcMermaidEdge(
    fromId: fromId ?? this.fromId,
    toId: toId ?? this.toId,
    label: label,
    labelLines: labelLines,
    stroke: stroke,
    startMarker: startMarker ?? this.startMarker,
    endMarker: endMarker ?? this.endMarker,
    startCardinality: startCardinality,
    endCardinality: endCardinality,
    minRankSpan: minRankSpan,
  );

  @override
  String toString() =>
      'CcMermaidEdge($fromId ${stroke.name}→ $toId${label.isEmpty ? '' : ' "$label"'})';
}

/// A `subgraph` (flowchart) or composite state (state diagram): a labeled box
/// drawn around a set of member nodes.
class CcMermaidCluster {
  /// Creates a [CcMermaidCluster].
  const CcMermaidCluster({
    required this.id,
    required this.lines,
    this.parentId,
    this.direction,
  });

  /// Cluster-unique id.
  final String id;

  /// Title lines (empty renders an untitled box).
  final List<String> lines;

  /// Enclosing cluster id for nested subgraphs, or null.
  final String? parentId;

  /// A cluster-local `direction` override, or null to inherit.
  final CcMermaidDirection? direction;

  @override
  String toString() => 'CcMermaidCluster($id, ${lines.join(' ')})';
}

/// Base type of every parsed diagram.
sealed class CcMermaidDiagram {
  /// Creates a [CcMermaidDiagram].
  const CcMermaidDiagram({this.title});

  /// Front-matter / `title` directive text, or null.
  final String? title;

  /// A short human label for the diagram family (host UIs show it in chrome).
  String get kindLabel;
}

/// The box-and-arrow family: flowchart, state, class, and ER diagrams.
class CcMermaidGraph extends CcMermaidDiagram {
  /// Creates a [CcMermaidGraph].
  const CcMermaidGraph({
    required this.kind,
    required this.direction,
    required this.nodes,
    required this.edges,
    this.clusters = const [],
    super.title,
  });

  /// Which dialect this graph came from.
  final CcMermaidGraphKind kind;

  /// Layout direction.
  final CcMermaidDirection direction;

  /// Nodes in declaration order (the layout's tie-breaker).
  final List<CcMermaidNode> nodes;

  /// Edges in declaration order.
  final List<CcMermaidEdge> edges;

  /// Clusters (subgraphs / composite states), outermost first.
  final List<CcMermaidCluster> clusters;

  @override
  String get kindLabel => switch (kind) {
    CcMermaidGraphKind.flowchart => 'flowchart',
    CcMermaidGraphKind.state => 'state diagram',
    CcMermaidGraphKind.classDiagram => 'class diagram',
    CcMermaidGraphKind.er => 'ER diagram',
  };

  /// The node with [id], or null.
  CcMermaidNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'CcMermaidGraph(${kind.name}, ${direction.name}, ${nodes.length} nodes, '
      '${edges.length} edges, ${clusters.length} clusters)';
}

// ─── Sequence ──────────────────────────────────────────────────────────────

/// A sequence-diagram lifeline.
class CcMermaidParticipant {
  /// Creates a [CcMermaidParticipant].
  const CcMermaidParticipant({
    required this.id,
    required this.lines,
    this.isActor = false,
  });

  /// Participant id as written.
  final String id;

  /// Display label lines.
  final List<String> lines;

  /// True for `actor Alice` (drawn as a stick figure head + shoulders).
  final bool isActor;

  /// Label lines to draw, falling back to the id.
  List<String> get displayLines => lines.isEmpty ? [id] : lines;

  @override
  String toString() => 'CcMermaidParticipant($id${isActor ? ', actor' : ''})';
}

/// Where a sequence note sits relative to its participants.
enum CcMermaidNotePlacement {
  /// `Note left of A`.
  left,

  /// `Note right of A`.
  right,

  /// `Note over A,B`.
  over,
}

/// The framed group constructs of a sequence diagram.
enum CcMermaidBlockKind {
  /// `loop`.
  loop,

  /// `alt` (sections separated by `else`).
  alt,

  /// `opt`.
  opt,

  /// `par` (sections separated by `and`).
  par,

  /// `critical` (sections separated by `option`).
  critical,

  /// `break`.
  breakBlock,

  /// `rect` (a plain tinted frame).
  rect,

  /// `box` (a participant grouping frame).
  box,
}

/// Base type of one step on a sequence diagram's time axis.
sealed class CcMermaidSequenceStep {
  /// Creates a [CcMermaidSequenceStep].
  const CcMermaidSequenceStep();
}

/// A message arrow between two lifelines (or a self-message when
/// [fromId] == [toId]).
class CcMermaidMessage extends CcMermaidSequenceStep {
  /// Creates a [CcMermaidMessage].
  const CcMermaidMessage({
    required this.fromId,
    required this.toId,
    required this.lines,
    this.stroke = CcMermaidEdgeStroke.solid,
    this.marker = CcMermaidEdgeMarker.arrow,
    this.activates = false,
    this.deactivates = false,
  });

  /// Sender lifeline id.
  final String fromId;

  /// Receiver lifeline id.
  final String toId;

  /// Message label lines.
  final List<String> lines;

  /// Solid (`->>`) or dotted (`-->>`) line.
  final CcMermaidEdgeStroke stroke;

  /// Arrowhead style at the receiver.
  final CcMermaidEdgeMarker marker;

  /// `+` suffix: activates the receiver.
  final bool activates;

  /// `-` suffix: deactivates the sender.
  final bool deactivates;

  @override
  String toString() => 'CcMermaidMessage($fromId → $toId, ${lines.join(' ')})';
}

/// A note box attached to one or two lifelines.
class CcMermaidNote extends CcMermaidSequenceStep {
  /// Creates a [CcMermaidNote].
  const CcMermaidNote({
    required this.placement,
    required this.participantIds,
    required this.lines,
  });

  /// Where the box sits.
  final CcMermaidNotePlacement placement;

  /// Anchor lifelines (one, or two for `over A,B`).
  final List<String> participantIds;

  /// Note text lines.
  final List<String> lines;

  @override
  String toString() => 'CcMermaidNote(${placement.name}, ${lines.join(' ')})';
}

/// One section of a framed block: the header label plus its steps. `alt`/`par`/
/// `critical` carry more than one section (`else` / `and` / `option`).
class CcMermaidBlockSection {
  /// Creates a [CcMermaidBlockSection].
  const CcMermaidBlockSection({required this.label, required this.steps});

  /// Section label (may be empty).
  final String label;

  /// Steps inside the section.
  final List<CcMermaidSequenceStep> steps;
}

/// A framed group of steps (`loop`, `alt`/`else`, `opt`, `par`, …).
class CcMermaidBlock extends CcMermaidSequenceStep {
  /// Creates a [CcMermaidBlock].
  const CcMermaidBlock({
    required this.kind,
    required this.sections,
    this.label = '',
  });

  /// Which construct this is.
  final CcMermaidBlockKind kind;

  /// The block's sections, in source order (at least one).
  final List<CcMermaidBlockSection> sections;

  /// The label on the opening line.
  final String label;

  /// The keyword drawn in the frame's corner tab.
  String get keyword => switch (kind) {
    CcMermaidBlockKind.loop => 'loop',
    CcMermaidBlockKind.alt => 'alt',
    CcMermaidBlockKind.opt => 'opt',
    CcMermaidBlockKind.par => 'par',
    CcMermaidBlockKind.critical => 'critical',
    CcMermaidBlockKind.breakBlock => 'break',
    CcMermaidBlockKind.rect => 'rect',
    CcMermaidBlockKind.box => 'box',
  };

  @override
  String toString() =>
      'CcMermaidBlock(${kind.name}, ${sections.length} sections)';
}

/// An explicit `activate A` / `deactivate A` statement.
class CcMermaidActivation extends CcMermaidSequenceStep {
  /// Creates a [CcMermaidActivation].
  const CcMermaidActivation({
    required this.participantId,
    required this.active,
  });

  /// The lifeline whose activation changes.
  final String participantId;

  /// True for `activate`, false for `deactivate`.
  final bool active;

  @override
  String toString() =>
      'CcMermaidActivation($participantId, ${active ? 'activate' : 'deactivate'})';
}

/// A `== section ==` divider across all lifelines.
class CcMermaidDivider extends CcMermaidSequenceStep {
  /// Creates a [CcMermaidDivider].
  const CcMermaidDivider(this.label);

  /// The divider label.
  final String label;

  @override
  String toString() => 'CcMermaidDivider($label)';
}

/// A sequence diagram: ordered lifelines plus a time-ordered step list.
class CcMermaidSequence extends CcMermaidDiagram {
  /// Creates a [CcMermaidSequence].
  const CcMermaidSequence({
    required this.participants,
    required this.steps,
    this.autonumber = false,
    super.title,
  });

  /// Lifelines, left to right.
  final List<CcMermaidParticipant> participants;

  /// Steps, top to bottom.
  final List<CcMermaidSequenceStep> steps;

  /// Whether `autonumber` is on (messages get `1)`-style prefixes).
  final bool autonumber;

  @override
  String get kindLabel => 'sequence diagram';

  @override
  String toString() =>
      'CcMermaidSequence(${participants.length} participants, ${steps.length} steps)';
}

// ─── Pie ───────────────────────────────────────────────────────────────────

/// One slice of a [CcMermaidPie].
class CcMermaidSlice {
  /// Creates a [CcMermaidSlice].
  const CcMermaidSlice({required this.label, required this.value});

  /// Slice label.
  final String label;

  /// Slice weight (non-negative).
  final double value;

  @override
  String toString() => 'CcMermaidSlice($label, $value)';
}

/// A pie chart.
class CcMermaidPie extends CcMermaidDiagram {
  /// Creates a [CcMermaidPie].
  const CcMermaidPie({
    required this.slices,
    this.showData = false,
    super.title,
  });

  /// Slices in declaration order.
  final List<CcMermaidSlice> slices;

  /// Whether `pie showData` asked for raw values beside the labels.
  final bool showData;

  /// The sum of all slice values (0 when empty).
  double get total {
    var sum = 0.0;
    for (final slice in slices) {
      sum += slice.value;
    }
    return sum;
  }

  @override
  String get kindLabel => 'pie chart';

  @override
  String toString() => 'CcMermaidPie(${slices.length} slices)';
}

// ─── Timeline ──────────────────────────────────────────────────────────────

/// One time period of a [CcMermaidTimeline] with the events recorded at it.
class CcMermaidTimelineEntry {
  /// Creates a [CcMermaidTimelineEntry].
  const CcMermaidTimelineEntry({
    required this.period,
    required this.events,
    this.section,
  });

  /// The period label (the left side of `2021 : event`).
  final String period;

  /// Events at this period.
  final List<String> events;

  /// The enclosing `section` title, or null.
  final String? section;

  @override
  String toString() =>
      'CcMermaidTimelineEntry($period, ${events.length} events)';
}

/// A timeline diagram: an axis of periods, each with events, optionally grouped
/// into sections.
class CcMermaidTimeline extends CcMermaidDiagram {
  /// Creates a [CcMermaidTimeline].
  const CcMermaidTimeline({required this.entries, super.title});

  /// Entries in source order.
  final List<CcMermaidTimelineEntry> entries;

  @override
  String get kindLabel => 'timeline';

  @override
  String toString() => 'CcMermaidTimeline(${entries.length} entries)';
}

// ─── Parse result ──────────────────────────────────────────────────────────

/// The outcome of parsing a mermaid source.
sealed class CcMermaidParseResult {
  /// Creates a [CcMermaidParseResult].
  const CcMermaidParseResult();
}

/// A successfully parsed diagram.
class CcMermaidParsed extends CcMermaidParseResult {
  /// Creates a [CcMermaidParsed].
  const CcMermaidParsed(this.diagram);

  /// The diagram.
  final CcMermaidDiagram diagram;
}

/// Parsing failed, or the dialect is not supported — the host renders the
/// source as a code block and shows [message].
///
/// The engine NEVER throws on bad input; every failure arrives here.
class CcMermaidUnsupported extends CcMermaidParseResult {
  /// Creates a [CcMermaidUnsupported].
  const CcMermaidUnsupported(this.message, {this.dialect});

  /// A short, user-facing reason ("unsupported diagram type: gantt").
  final String message;

  /// The dialect keyword that was recognized but not supported, or null.
  final String? dialect;

  @override
  String toString() => 'CcMermaidUnsupported($message)';
}
