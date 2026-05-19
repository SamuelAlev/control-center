import 'package:collection/collection.dart';

/// The canonical list of artifact block kinds — the ONE declaration everything
/// else derives from.
///
/// The tool schema's `type` enum, [ArtifactBlock.fromJson]'s dispatch, and the
/// codec's validator are all projections of this list, and a round-trip test
/// asserts they agree. That is deliberate: the failure mode this prevents is an
/// "invisible kind" — a block type the schema advertises to the model but the
/// decoder (or the renderer registry) silently drops, so the agent publishes an
/// artifact and the operator sees a hole where their chart should be.
///
/// Order is the presentation order in the tool description; it is not
/// semantically meaningful.
const List<String> artifactBlockKinds = <String>[
  'markdown',
  'table',
  'chart',
  'mermaid',
  'code',
  'data',
];

/// Horizontal alignment of an artifact table column.
enum ArtifactColumnAlign {
  /// Align cell content to the leading edge (the default).
  left,

  /// Center cell content.
  center,

  /// Align cell content to the trailing edge — numeric columns.
  right;

  /// Parses a persisted/wire alignment, or null when absent or unrecognized.
  ///
  /// Unrecognized is deliberately null rather than [left]: an alignment the
  /// model invented ("justify") should fall back to the renderer's per-type
  /// default, not silently claim to be left-aligned.
  static ArtifactColumnAlign? fromWire(Object? value) => switch (value) {
    'left' => ArtifactColumnAlign.left,
    'center' || 'centre' => ArtifactColumnAlign.center,
    'right' => ArtifactColumnAlign.right,
    _ => null,
  };
}

/// Which chart form an [ArtifactChartBlock] draws.
///
/// Deliberately tiny (PRD Part 2 §2.1: "keep the spec small"). A richer chart
/// grammar is a renderer problem, and every kind added here is a kind the
/// native renderer must draw on desktop, web, AND phone.
enum ArtifactChartKind {
  /// Categorical bars, one group per x value.
  bar,

  /// Connected points, ordered by their position in the series.
  line,

  /// Proportions of a whole — the first series only.
  pie;

  /// Parses a persisted/wire chart kind, or null when absent/unrecognized.
  static ArtifactChartKind? fromWire(Object? value) => switch (value) {
    'bar' => ArtifactChartKind.bar,
    'line' => ArtifactChartKind.line,
    'pie' => ArtifactChartKind.pie,
    _ => null,
  };
}

/// One column of an [ArtifactTableBlock].
class ArtifactColumn {
  /// Creates an [ArtifactColumn].
  const ArtifactColumn({required this.key, required this.label, this.align});

  /// Decodes a column, coercing scalars to text and deriving a missing
  /// [key]/[label] from whichever of the two was supplied.
  factory ArtifactColumn.fromJson(Map<String, dynamic> json) {
    final key = coerceArtifactText(json['key']);
    final label = coerceArtifactText(json['label']);
    return ArtifactColumn(
      key: key.isEmpty ? label : key,
      label: label.isEmpty ? key : label,
      align: ArtifactColumnAlign.fromWire(json['align']),
    );
  }

  /// Stable identifier for the column (also the row-cell order key).
  final String key;

  /// Header text shown to the operator.
  final String label;

  /// Cell alignment, or null to let the renderer decide.
  final ArtifactColumnAlign? align;

  /// Encodes the column to JSON.
  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    if (align != null) 'align': align!.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactColumn &&
          key == other.key &&
          label == other.label &&
          align == other.align;

  @override
  int get hashCode => Object.hash(key, label, align);
}

/// One (x, y) sample in an [ArtifactSeries].
///
/// [x] is text on purpose: artifact charts plot labelled categories and time
/// buckets ("Mon", "2026-W31", "gpt-5"), never a continuous numeric domain.
class ArtifactPoint {
  /// Creates an [ArtifactPoint].
  const ArtifactPoint({required this.x, required this.y});

  /// Decodes a point. An unparseable [y] becomes [double.nan], which the
  /// codec's semantic pass rejects — the structural parse never throws on a
  /// numeric field so one bad point reports as one precise error path instead
  /// of collapsing the whole chart into "malformed".
  factory ArtifactPoint.fromJson(Map<String, dynamic> json) => ArtifactPoint(
    x: coerceArtifactText(json['x']),
    y: coerceArtifactDouble(json['y']),
  );

  /// The category / bucket label.
  final String x;

  /// The measured value. Non-finite means "the source was unparseable"; the
  /// codec rejects such a chart rather than drawing a gap.
  final double y;

  /// Encodes the point to JSON.
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// One labelled data series of an [ArtifactChartBlock].
class ArtifactSeries {
  /// Creates an [ArtifactSeries].
  const ArtifactSeries({required this.label, required this.points});

  /// Decodes a series, skipping non-map point entries.
  factory ArtifactSeries.fromJson(Map<String, dynamic> json) => ArtifactSeries(
    label: coerceArtifactText(json['label']),
    points: [
      for (final p in json['points'] as List? ?? const [])
        if (p is Map) ArtifactPoint.fromJson(p.cast<String, dynamic>()),
    ],
  );

  /// Legend label. Required so a multi-series chart is never colour-only
  /// (DESIGN.md: never status-by-colour-alone).
  final String label;

  /// The samples, in draw order.
  final List<ArtifactPoint> points;

  /// Encodes the series to JSON.
  Map<String, dynamic> toJson() => {
    'label': label,
    'points': [for (final p in points) p.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactSeries &&
          label == other.label &&
          const ListEquality<ArtifactPoint>().equals(points, other.points);

  @override
  int get hashCode =>
      Object.hash(label, const ListEquality<ArtifactPoint>().hash(points));
}

/// One ordered, typed block of an artifact document.
///
/// Artifacts are **block lists, never HTML** — that is the design constraint,
/// not a limitation: every kind here maps to a native Flutter renderer the app
/// already owns (cc_markdown for prose and mermaid, the shared code block, a
/// tokenized table, a JSON tree, the chart widget), so an agent-authored
/// document inherits the app's theme, accessibility floor, reduced-motion
/// behaviour, and selection model for free.
///
/// Persisted inside a `WorkProductRevision.content` JSON envelope (see
/// `ArtifactDocument`), which is why the codecs here are defensive: a revision
/// written by an older build must still decode.
sealed class ArtifactBlock {
  /// Creates an [ArtifactBlock].
  const ArtifactBlock({this.id});

  /// Decodes a block, dispatching on the `type` discriminator.
  ///
  /// Throws a [FormatException] ONLY for a discriminator that cannot be
  /// rendered at all (an unknown block `type`, an unknown chart kind) — there
  /// is no honest coercion for those. Every other field is read defensively
  /// (missing/junk scalars coerce, non-map list entries are skipped), and
  /// emptiness is left for the codec's semantic pass to judge so a caller gets
  /// a precise error path instead of an exception.
  static ArtifactBlock fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final type = json['type'];
    switch (type) {
      case 'markdown':
        return ArtifactMarkdownBlock(
          text: coerceArtifactText(json['text']),
          id: id,
        );
      case 'table':
        return ArtifactTableBlock(
          columns: [
            for (final c in json['columns'] as List? ?? const [])
              if (c is Map) ArtifactColumn.fromJson(c.cast<String, dynamic>()),
          ],
          rows: [
            for (final r in json['rows'] as List? ?? const [])
              if (r is List) [for (final cell in r) coerceArtifactText(cell)],
          ],
          id: id,
        );
      case 'chart':
        final kind = ArtifactChartKind.fromWire(json['chartKind']);
        if (kind == null) {
          throw FormatException(
            'chartKind must be one of '
            '${ArtifactChartKind.values.map((k) => k.name).join(', ')}',
            json['chartKind'],
          );
        }
        return ArtifactChartBlock(
          chartKind: kind,
          series: [
            for (final s in json['series'] as List? ?? const [])
              if (s is Map) ArtifactSeries.fromJson(s.cast<String, dynamic>()),
          ],
          title: _optionalText(json['title']),
          xLabel: _optionalText(json['xLabel']),
          yLabel: _optionalText(json['yLabel']),
          id: id,
        );
      case 'mermaid':
        return ArtifactMermaidBlock(
          source: coerceArtifactText(json['source']),
          id: id,
        );
      case 'code':
        return ArtifactCodeBlock(
          code: coerceArtifactText(json['code']),
          language: _optionalText(json['language']),
          title: _optionalText(json['title']),
          lineStart: (json['lineStart'] as num?)?.toInt(),
          id: id,
        );
      case 'data':
        return ArtifactDataBlock(json: json['json'], id: id);
      default:
        throw FormatException(
          'unknown block type — must be one of '
              '${artifactBlockKinds.join(', ')}',
          '$type',
        );
    }
  }

  /// Server-assigned short identifier, stable across revisions, or null before
  /// the server has stamped it (an agent never supplies these itself).
  final String? id;

  /// The `type` discriminator; always a member of [artifactBlockKinds].
  String get type;

  /// Encodes the block to JSON (discriminated by [type]).
  Map<String, dynamic> toJson();

  /// Returns this block with [id] applied. Used by the publish path to stamp
  /// stable ids without the caller having to switch on the kind.
  ArtifactBlock withId(String? id);
}

/// Prose, headings, lists — rendered by the in-repo cc_markdown engine.
class ArtifactMarkdownBlock extends ArtifactBlock {
  /// Creates an [ArtifactMarkdownBlock].
  const ArtifactMarkdownBlock({required this.text, super.id});

  /// The markdown source.
  final String text;

  @override
  String get type => 'markdown';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'text': text,
  };

  @override
  ArtifactMarkdownBlock withId(String? id) =>
      ArtifactMarkdownBlock(text: text, id: id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactMarkdownBlock && text == other.text && id == other.id;

  @override
  int get hashCode => Object.hash(type, text, id);
}

/// A typed data table: named columns plus text cells.
class ArtifactTableBlock extends ArtifactBlock {
  /// Creates an [ArtifactTableBlock].
  const ArtifactTableBlock({
    required this.columns,
    required this.rows,
    super.id,
  });

  /// Column definitions, in display order.
  final List<ArtifactColumn> columns;

  /// Row cells, each row in [columns] order. Cells are text: an artifact table
  /// reports already-formatted values (a currency, a duration, a percentage),
  /// so the renderer never has to guess a number's presentation.
  final List<List<String>> rows;

  @override
  String get type => 'table';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'columns': [for (final c in columns) c.toJson()],
    'rows': rows,
  };

  @override
  ArtifactTableBlock withId(String? id) =>
      ArtifactTableBlock(columns: columns, rows: rows, id: id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactTableBlock &&
          id == other.id &&
          const ListEquality<ArtifactColumn>().equals(columns, other.columns) &&
          const DeepCollectionEquality().equals(rows, other.rows);

  @override
  int get hashCode => Object.hash(
    type,
    id,
    const ListEquality<ArtifactColumn>().hash(columns),
    const DeepCollectionEquality().hash(rows),
  );
}

/// A small chart: one or more labelled series over text categories.
class ArtifactChartBlock extends ArtifactBlock {
  /// Creates an [ArtifactChartBlock].
  const ArtifactChartBlock({
    required this.chartKind,
    required this.series,
    this.title,
    this.xLabel,
    this.yLabel,
    super.id,
  });

  /// Which chart form to draw.
  final ArtifactChartKind chartKind;

  /// The data. A [ArtifactChartKind.pie] chart draws the first series only.
  final List<ArtifactSeries> series;

  /// Optional chart title.
  final String? title;

  /// Optional x-axis label.
  final String? xLabel;

  /// Optional y-axis label.
  final String? yLabel;

  @override
  String get type => 'chart';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'chartKind': chartKind.name,
    if (title != null) 'title': title,
    'series': [for (final s in series) s.toJson()],
    if (xLabel != null) 'xLabel': xLabel,
    if (yLabel != null) 'yLabel': yLabel,
  };

  @override
  ArtifactChartBlock withId(String? id) => ArtifactChartBlock(
    chartKind: chartKind,
    series: series,
    title: title,
    xLabel: xLabel,
    yLabel: yLabel,
    id: id,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactChartBlock &&
          id == other.id &&
          chartKind == other.chartKind &&
          title == other.title &&
          xLabel == other.xLabel &&
          yLabel == other.yLabel &&
          const ListEquality<ArtifactSeries>().equals(series, other.series);

  @override
  int get hashCode => Object.hash(
    type,
    id,
    chartKind,
    title,
    xLabel,
    yLabel,
    const ListEquality<ArtifactSeries>().hash(series),
  );
}

/// A mermaid diagram, drawn natively by cc_markdown's diagram engine.
class ArtifactMermaidBlock extends ArtifactBlock {
  /// Creates an [ArtifactMermaidBlock].
  const ArtifactMermaidBlock({required this.source, super.id});

  /// The mermaid source (the body of what would be a ```` ```mermaid ````
  /// fence).
  final String source;

  @override
  String get type => 'mermaid';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'source': source,
  };

  @override
  ArtifactMermaidBlock withId(String? id) =>
      ArtifactMermaidBlock(source: source, id: id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactMermaidBlock && source == other.source && id == other.id;

  @override
  int get hashCode => Object.hash(type, source, id);
}

/// A source-code excerpt, rendered with the app's shared syntax highlighter.
class ArtifactCodeBlock extends ArtifactBlock {
  /// Creates an [ArtifactCodeBlock].
  const ArtifactCodeBlock({
    required this.code,
    this.language,
    this.title,
    this.lineStart,
    super.id,
  });

  /// The code text.
  final String code;

  /// Highlighter language hint (`dart`, `sql`, …), or null for plain text.
  final String? language;

  /// Optional caption — conventionally the file path.
  final String? title;

  /// First line number to display, so an excerpt can carry the line numbers it
  /// has in the real file instead of restarting at 1.
  final int? lineStart;

  @override
  String get type => 'code';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'code': code,
    if (language != null) 'language': language,
    if (title != null) 'title': title,
    if (lineStart != null) 'lineStart': lineStart,
  };

  @override
  ArtifactCodeBlock withId(String? id) => ArtifactCodeBlock(
    code: code,
    language: language,
    title: title,
    lineStart: lineStart,
    id: id,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactCodeBlock &&
          id == other.id &&
          code == other.code &&
          language == other.language &&
          title == other.title &&
          lineStart == other.lineStart;

  @override
  int get hashCode => Object.hash(type, id, code, language, title, lineStart);
}

/// Arbitrary JSON, rendered as a collapsible tree.
///
/// The escape hatch for structured output that has no better block: an API
/// response, a config diff, a raw tool result. It stays a first-class kind
/// rather than "stringify it into a code block" so the renderer can collapse,
/// search, and copy subtrees.
class ArtifactDataBlock extends ArtifactBlock {
  /// Creates an [ArtifactDataBlock].
  const ArtifactDataBlock({required this.json, super.id});

  /// The payload — any JSON value (map, list, scalar, or null).
  final Object? json;

  @override
  String get type => 'data';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    'json': json,
  };

  @override
  ArtifactDataBlock withId(String? id) => ArtifactDataBlock(json: json, id: id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactDataBlock &&
          id == other.id &&
          const DeepCollectionEquality().equals(json, other.json);

  @override
  int get hashCode =>
      Object.hash(type, id, const DeepCollectionEquality().hash(json));
}

/// Coerces a JSON scalar to display text.
///
/// The LLM boundary is loose by design (PRD Part 2 §2.1): a model that emits
/// `{"y": 42}` where a label belongs, or a bare number as a table cell, should
/// still publish. Structured values (maps/lists) return `''` — silently
/// flattening one into text would produce Dart's `{a: 1}` debug syntax in a
/// user-facing document, which reads like a bug.
String coerceArtifactText(Object? value) => switch (value) {
  final String s => s,
  final num n => '$n',
  final bool b => '$b',
  _ => '',
};

/// Coerces a JSON value to a double, returning [double.nan] when it is not a
/// number (including a numeric string the model quoted). Non-finite results are
/// rejected by the codec's semantic pass.
double coerceArtifactDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s.trim()) ?? double.nan,
  _ => double.nan,
};

/// Reads an optional text field: absent, non-scalar, or blank all collapse to
/// null so `if (x != null)` in `toJson` stays meaningful.
String? _optionalText(Object? value) {
  final text = coerceArtifactText(value);
  return text.isEmpty ? null : text;
}
