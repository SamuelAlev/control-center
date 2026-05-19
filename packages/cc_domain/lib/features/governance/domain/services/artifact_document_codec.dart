import 'dart:convert';

import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:collection/collection.dart';

/// An ordered list of typed blocks — the whole artifact model.
///
/// Persisted as the JSON envelope in a `WorkProductRevision.content` text
/// column, which is why the format carries a version tag: the WorkProducts
/// subsystem already stores plain markdown revisions written by
/// `save_work_product_revision`, so a reader must be able to tell a block
/// document from prose without a schema migration. Anything that is not a
/// `blocks@1` envelope is simply not an artifact document.
class ArtifactDocument {
  /// Creates an [ArtifactDocument].
  const ArtifactDocument({required this.blocks});

  /// Reads an envelope tolerantly — junk blocks are dropped, diagnostics
  /// discarded.
  ///
  /// This is the RENDER path: content already accepted and persisted must never
  /// throw on the way back out (a revision written by an older build, or one an
  /// operator hand-edited, still has to display). Use
  /// [ArtifactDocumentCodec.decodeStrict] at a typed boundary where a caller
  /// deserves violations, and [ArtifactDocumentCodec.decodeLoose] where the
  /// diagnostics are fed back to an agent.
  factory ArtifactDocument.fromEnvelopeJson(Map<String, dynamic> json) =>
      ArtifactDocumentCodec.decodeLoose(json).document;

  /// The envelope's `format` tag. Bump only for a breaking block-schema change;
  /// additive kinds do not need a new version (an old client drops a kind it
  /// cannot decode, which is exactly the tolerant behaviour we want).
  static const String formatVersion = 'blocks@1';

  /// The blocks, in render order.
  final List<ArtifactBlock> blocks;

  /// Whether this document carries nothing renderable.
  bool get isEmpty => blocks.isEmpty;

  /// Encodes the document to its persisted envelope.
  Map<String, dynamic> toEnvelopeJson() => {
    'format': formatVersion,
    'blocks': [for (final b in blocks) b.toJson()],
  };

  /// Encodes the document to the JSON string stored in a revision's `content`.
  String toEnvelopeJsonString() => jsonEncode(toEnvelopeJson());

  /// Parses a revision's stored `content`, or null when it is not a block
  /// envelope (plain-markdown revisions from `save_work_product_revision`
  /// legitimately are not).
  static ArtifactDocument? tryParseContent(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    if (decoded['format'] != formatVersion || decoded['blocks'] is! List) {
      return null;
    }
    return ArtifactDocument.fromEnvelopeJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactDocument &&
          const ListEquality<ArtifactBlock>().equals(blocks, other.blocks);

  @override
  int get hashCode => const ListEquality<ArtifactBlock>().hash(blocks);
}

/// Thrown by [ArtifactDocumentCodec.decodeStrict] when a document is malformed.
///
/// Extends [ValidationException] so the typed RPC boundary maps it to a
/// validation error (not a 500) with the violation paths intact in the message.
class ArtifactFormatException extends ValidationException {
  /// Creates an [ArtifactFormatException] from its [violations].
  ArtifactFormatException(this.violations)
    : super(
        'The artifact document is not valid:\n'
        '${violations.map((v) => '- $v').join('\n')}',
      );

  /// One entry per problem, each carrying its block path
  /// (`blocks[2].chart: series is empty`).
  final List<String> violations;
}

/// The outcome of a loose decode: what survived, plus what did not and why.
///
/// `errors` name blocks that were DROPPED; `warnings` name blocks that were
/// KEPT but will render degraded (an unsupported mermaid dialect falls back to
/// a code block, a pie chart ignores extra series). Both are echoed to the
/// calling agent so it can fix the next revision — a silent drop is how an
/// operator ends up staring at a document with a hole in it.
typedef ArtifactDecodeResult = ({
  ArtifactDocument document,
  List<String> errors,
  List<String> warnings,
});

/// Decodes, validates, and stamps artifact block documents.
///
/// Two validation modes on purpose, because the two callers have opposite
/// failure preferences:
///
///  * [decodeStrict] — the typed RPC boundary. A malformed document is a
///    programming error; reject the whole thing with violations so it cannot be
///    persisted half-understood.
///  * [decodeLoose] — the LLM boundary. A slightly-off tool call is normal, and
///    refusing the entire document costs the agent a whole turn to rediscover
///    what it already computed. Coerce what can be coerced, drop the individual
///    blocks that cannot, and report per-block error paths in the tool result.
///
/// Both run the same structural parse ([ArtifactBlock.fromJson]) followed by
/// the same semantic/renderability pass ([validateBlock]) — the modes differ
/// only in what they do with the findings.
class ArtifactDocumentCodec {
  const ArtifactDocumentCodec._();

  /// Decodes a `blocks@1` envelope, throwing [ArtifactFormatException] listing
  /// every violation. Warnings do not fail a strict decode (a degraded render
  /// is still a render).
  static ArtifactDocument decodeStrict(Map<String, dynamic> json) {
    final format = json['format'];
    if (format != null && format != ArtifactDocument.formatVersion) {
      throw ArtifactFormatException([
        'format: expected "${ArtifactDocument.formatVersion}", got "$format"',
      ]);
    }
    final raw = json['blocks'];
    if (raw is! List) {
      throw ArtifactFormatException(['blocks: expected a list of blocks']);
    }
    final blocks = <ArtifactBlock>[];
    final violations = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is! Map) {
        violations.add('blocks[$i]: expected an object');
        continue;
      }
      final ArtifactBlock block;
      try {
        block = ArtifactBlock.fromJson(entry.cast<String, dynamic>());
      } on Object catch (e) {
        violations.add('blocks[$i]: ${_reason(e)}');
        continue;
      }
      final (errors: errors, warnings: _) = validateBlock(block, index: i);
      if (errors.isNotEmpty) {
        violations.addAll(errors);
        continue;
      }
      blocks.add(block);
    }
    if (violations.isNotEmpty) {
      throw ArtifactFormatException(violations);
    }
    if (blocks.isEmpty) {
      throw ArtifactFormatException(['blocks: the document has no blocks']);
    }
    return ArtifactDocument(blocks: blocks);
  }

  /// Decodes blocks tolerantly, dropping the individual blocks that cannot be
  /// salvaged and reporting each one's error path.
  ///
  /// Accepts either a bare block list (what an MCP `blocks` argument carries) or
  /// a full envelope map, so the same entry point serves the tool boundary and
  /// the render path.
  static ArtifactDecodeResult decodeLoose(Object? json) {
    final errors = <String>[];
    final warnings = <String>[];

    Object? raw = json;
    if (json is Map) {
      final format = json['format'];
      if (format != null && format != ArtifactDocument.formatVersion) {
        // Kept as a warning, not an error: an unknown tag most likely means a
        // newer writer, and dropping every block we CAN read helps nobody.
        warnings.add(
          'format: unrecognized "$format" — read as '
          '"${ArtifactDocument.formatVersion}"',
        );
      }
      raw = json['blocks'];
    }
    if (raw is! List) {
      return (
        document: const ArtifactDocument(blocks: []),
        errors: ['blocks: expected a list of blocks, got ${_typeName(raw)}'],
        warnings: warnings,
      );
    }

    final blocks = <ArtifactBlock>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is! Map) {
        errors.add('blocks[$i]: expected an object, got ${_typeName(entry)}');
        continue;
      }
      final ArtifactBlock block;
      try {
        block = ArtifactBlock.fromJson(entry.cast<String, dynamic>());
      } on Object catch (e) {
        errors.add('blocks[$i]: ${_reason(e)}');
        continue;
      }
      final result = validateBlock(block, index: i);
      warnings.addAll(result.warnings);
      if (result.errors.isNotEmpty) {
        errors.addAll(result.errors);
        continue;
      }
      blocks.add(block);
    }
    return (
      document: ArtifactDocument(blocks: blocks),
      errors: errors,
      warnings: warnings,
    );
  }

  /// The semantic / renderability pass over one already-parsed [block].
  ///
  /// Structure is not enough: a chart with an empty series parses perfectly and
  /// draws nothing, and a mermaid dialect the app cannot lay out silently
  /// becomes a code block. Errors mean "this block cannot be rendered as its
  /// kind"; warnings mean "it renders, but not the way the author expects".
  static ({List<String> errors, List<String> warnings}) validateBlock(
    ArtifactBlock block, {
    required int index,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    String at(String message) => 'blocks[$index].${block.type}: $message';

    switch (block) {
      case ArtifactMarkdownBlock(:final text):
        if (text.trim().isEmpty) {
          errors.add(at('text is empty'));
        }

      case ArtifactTableBlock(:final columns, :final rows):
        if (columns.isEmpty) {
          errors.add(at('columns is empty'));
        }
        if (rows.isEmpty) {
          errors.add(at('rows is empty'));
        }
        if (columns.any((c) => c.key.isEmpty)) {
          errors.add(at('every column needs a key or a label'));
        }
        for (var r = 0; r < rows.length && columns.isNotEmpty; r++) {
          if (rows[r].length != columns.length) {
            // Renderable (the table pads/truncates), but almost always a
            // mistake worth telling the author about.
            warnings.add(
              at(
                'row $r has ${rows[r].length} cells for ${columns.length} '
                'columns',
              ),
            );
          }
        }

      case ArtifactChartBlock(:final chartKind, :final series):
        if (series.isEmpty) {
          errors.add(at('series is empty'));
        }
        for (var s = 0; s < series.length; s++) {
          if (series[s].points.isEmpty) {
            errors.add(at('series[$s] "${series[s].label}" has no points'));
            continue;
          }
          for (var p = 0; p < series[s].points.length; p++) {
            if (!series[s].points[p].y.isFinite) {
              errors.add(at('series[$s].points[$p].y is not a finite number'));
            }
          }
          if (series.length > 1 && series[s].label.isEmpty) {
            warnings.add(
              at(
                'series[$s] has no label, so the legend cannot '
                'distinguish it by anything but colour',
              ),
            );
          }
        }
        if (chartKind == ArtifactChartKind.pie && series.length > 1) {
          warnings.add(
            at(
              'a pie chart draws the first series only; '
              '${series.length - 1} more will be ignored',
            ),
          );
        }

      case ArtifactMermaidBlock(:final source):
        if (source.trim().isEmpty) {
          errors.add(at('source is empty'));
          break;
        }
        final dialect = artifactMermaidDialect(source);
        if (dialect == null || !renderableMermaidDialects.contains(dialect)) {
          // A warning, never a rejection: the renderer degrades an unknown
          // dialect to a plain code block, so the content still reaches the
          // reader. Rejecting would throw away a diagram the author wrote.
          warnings.add(
            at(
              'the app cannot draw '
              '"${dialect ?? 'this diagram type'}" — it will render as a code '
              'block. Drawable: ${renderableMermaidDialects.join(', ')}',
            ),
          );
        }

      case ArtifactCodeBlock(:final code, :final lineStart):
        if (code.trim().isEmpty) {
          errors.add(at('code is empty'));
        }
        if (lineStart != null && lineStart < 1) {
          errors.add(at('lineStart must be 1 or greater'));
        }

      case ArtifactDataBlock(json: final payload):
        if (payload == null) {
          errors.add(at('json is missing'));
          break;
        }
        try {
          jsonEncode(payload);
        } on Object {
          errors.add(at('json is not JSON-encodable'));
        }
    }
    return (errors: errors, warnings: warnings);
  }

  /// Stamps stable short ids on [blocks], preserving ids already present.
  ///
  /// Ids are how a revision's blocks stay identifiable across revisions (a
  /// comment anchor, a "this block changed" affordance, a per-block copy
  /// action). [reserved] carries the ids used by earlier revisions of the same
  /// work product so a fresh block never inherits a retired block's id — an id
  /// must mean the same block for the artifact's whole history, or the history
  /// lies.
  static List<ArtifactBlock> assignBlockIds(
    List<ArtifactBlock> blocks, {
    Set<String> reserved = const {},
  }) {
    final used = <String>{...reserved};
    final out = <ArtifactBlock>[];
    var next = 1;
    for (final block in blocks) {
      final existing = block.id;
      if (existing != null && existing.isNotEmpty && used.add(existing)) {
        out.add(block);
        continue;
      }
      while (!used.add('b$next')) {
        next++;
      }
      out.add(block.withId('b$next'));
      next++;
    }
    return out;
  }

  /// Every non-null block id in [blocks] — the [assignBlockIds] `reserved` set
  /// for the next revision.
  static Set<String> blockIdsOf(List<ArtifactBlock> blocks) => {
    for (final b in blocks)
      if (b.id != null && b.id!.isNotEmpty) b.id!,
  };

  static String _reason(Object error) =>
      error is FormatException ? error.message : '$error';

  static String _typeName(Object? value) => switch (value) {
    null => 'null',
    final List _ => 'a list',
    final Map _ => 'an object',
    final String _ => 'a string',
    final num _ => 'a number',
    final bool _ => 'a boolean',
    _ => 'an unsupported value',
  };
}

/// The mermaid dialect keywords the app can actually draw.
///
/// Duplicated here on purpose. cc_domain is dependency-light by contract (no
/// Flutter, no cc_markdown), but "will this render?" is a question the server
/// must answer at publish time — before any renderer exists — so the artifact
/// codec can warn the agent in the same tool call instead of the operator
/// discovering a code block where a diagram should be.
///
/// The authority is `parseMermaid`'s dialect switch in
/// `packages/cc_markdown/lib/src/mermaid/parse/mermaid_parser.dart`; keep this
/// set in step with it when a new dialect parser lands. Being stale is a
/// warning-quality mistake in both directions (a warning that need not have
/// fired, or a missing warning), never a rejection or a render failure.
const Set<String> renderableMermaidDialects = {
  'flowchart',
  'flowchart-elk',
  'graph',
  'statediagram',
  'statediagram-v2',
  'classdiagram',
  'classdiagram-v2',
  'erdiagram',
  'sequencediagram',
  'pie',
  'timeline',
};

final RegExp _mermaidInitDirective = RegExp(r'%%\{.*?\}%%');
final RegExp _mermaidFrontMatterFence = RegExp(r'^\s*---\s*$');

/// Extracts the lower-cased dialect keyword from mermaid [source], or null when
/// the source carries no header at all.
///
/// Mirrors the header handling in cc_markdown's `preprocessMermaid`: YAML front
/// matter, `%%{init: …}%%` directives, `%%` comments, and blank lines are
/// skipped, then the first word of the first real line is the dialect (with a
/// trailing `:` removed, as `sequenceDiagram:` is written both ways).
String? artifactMermaidDialect(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  var start = 0;
  while (start < lines.length && lines[start].trim().isEmpty) {
    start++;
  }
  // Front matter: `---` … `---` at the very top, ignored except by mermaid's
  // own title handling.
  if (start < lines.length && _mermaidFrontMatterFence.hasMatch(lines[start])) {
    var end = start + 1;
    while (end < lines.length &&
        !_mermaidFrontMatterFence.hasMatch(lines[end])) {
      end++;
    }
    if (end < lines.length) {
      start = end + 1;
    }
  }
  for (var i = start; i < lines.length; i++) {
    var line = lines[i].replaceAll(_mermaidInitDirective, '');
    final comment = line.indexOf('%%');
    if (comment >= 0) {
      line = line.substring(0, comment);
    }
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final space = trimmed.indexOf(RegExp(r'\s'));
    final keyword = space < 0 ? trimmed : trimmed.substring(0, space);
    final dialect = keyword.toLowerCase().replaceAll(':', '');
    return dialect.isEmpty ? null : dialect;
  }
  return null;
}
