/// Provider-aware frame shapes for the vision compaction renderer.
///
/// A [VisionShape] captures the geometry one model line reads back best: the
/// pixel font, the per-character cell advance (which adds letter-spacing /
/// leading beyond the 8x8 glyph), the square frame edge, and provider billing
/// hints. [resolveShape] maps a model id to its eval-validated shape, matching
/// case-insensitively (first match wins) and falling back to the Anthropic
/// shape for unknown models. Ported from oh-my-pi's `snapcompact` shape table.
library;

/// One eval-validated frame shape: font, cell pitch, ink, and frame size.
///
/// The embedded font is always 8x8 ([fontWidth]/[fontHeight]); [cellWidth] and
/// [cellHeight] are the per-character advance in pixels. A cell larger than the
/// glyph adds letter-spacing (wider [cellWidth]) and leading (taller
/// [cellHeight]), which the legibility benches showed helps models read code /
/// search output. The ink is always monochrome (`bw`): **black glyphs on a
/// white background**.
class VisionShape {
  /// Creates a [VisionShape]. All fields are required and describe the frame
  /// geometry plus the target provider's per-frame billing estimate.
  const VisionShape({
    required this.code,
    required this.fontWidth,
    required this.fontHeight,
    required this.cellWidth,
    required this.cellHeight,
    required this.stopwordDim,
    required this.columns,
    required this.frameSize,
    required this.frameTokenEstimate,
    required this.imageDetail,
  });

  /// Research name of the variant (e.g. `11on16-bw`, `8on22-bw`, `8on16-bw`).
  final String code;

  /// Glyph width in pixels (always 8 — the embedded font's natural cell).
  final int fontWidth;

  /// Glyph height in pixels (always 8 — the embedded font's natural cell).
  final int fontHeight;

  /// Per-character horizontal advance in pixels. Larger than [fontWidth] adds
  /// letter-spacing; the frame holds `frameSize ~/ cellWidth` columns.
  final int cellWidth;

  /// Per-row vertical advance in pixels. Larger than [fontHeight] adds leading;
  /// the frame holds `frameSize ~/ cellHeight` rows.
  final int cellHeight;

  /// Whether high-frequency stopwords should be drawn in dim ink. Always
  /// `false` for the bundled monochrome shapes (reserved for parity with the
  /// upstream `-dim` variants).
  final bool stopwordDim;

  /// Layout column count. Always `1` (row-major grid) for the bundled shapes.
  final int columns;

  /// Square frame edge in pixels (the rendered PNG is [frameSize] x
  /// [frameSize]).
  final int frameSize;

  /// Per-frame billed-token estimate for the shape's target provider, used by
  /// callers for context budgeting.
  final int frameTokenEstimate;

  /// Resolution hint forwarded to the provider when attaching the frame
  /// (e.g. `original` for OpenAI patch billing). Empty when none applies.
  final String imageDetail;

  /// Characters per row at this shape's [cellWidth] within [frameSize].
  int get columnsPerFrame => frameSize ~/ cellWidth;

  /// Text rows per frame at this shape's [cellHeight] within [frameSize].
  int get rowsPerFrame => frameSize ~/ cellHeight;

  /// Nominal characters that fit one frame (`columnsPerFrame * rowsPerFrame`).
  int get capacity => columnsPerFrame * rowsPerFrame;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionShape &&
          code == other.code &&
          fontWidth == other.fontWidth &&
          fontHeight == other.fontHeight &&
          cellWidth == other.cellWidth &&
          cellHeight == other.cellHeight &&
          stopwordDim == other.stopwordDim &&
          columns == other.columns &&
          frameSize == other.frameSize &&
          frameTokenEstimate == other.frameTokenEstimate &&
          imageDetail == other.imageDetail;

  @override
  int get hashCode => Object.hash(
        code,
        fontWidth,
        fontHeight,
        cellWidth,
        cellHeight,
        stopwordDim,
        columns,
        frameSize,
        frameTokenEstimate,
        imageDetail,
      );
}

/// Builds the Anthropic `11on16-bw` shape at [frameSize] (default 1568).
VisionShape _anthropicShape({int frameSize = 1568}) => VisionShape(
      code: '11on16-bw',
      fontWidth: 8,
      fontHeight: 8,
      cellWidth: 11,
      cellHeight: 16,
      stopwordDim: false,
      columns: 1,
      frameSize: frameSize,
      frameTokenEstimate: 3290,
      imageDetail: '',
    );

/// Builds the Google/OpenAI `8on22-bw` shape at [frameSize].
VisionShape _wideLeadingShape({
  required int frameSize,
  required int frameTokenEstimate,
  required String imageDetail,
}) =>
    VisionShape(
      code: '8on22-bw',
      fontWidth: 8,
      fontHeight: 8,
      cellWidth: 8,
      cellHeight: 22,
      stopwordDim: false,
      columns: 1,
      frameSize: frameSize,
      frameTokenEstimate: frameTokenEstimate,
      imageDetail: imageDetail,
    );

/// Builds the `8on16-bw` shape (used for kimi/glm) at [frameSize].
VisionShape _denseShape({int frameSize = 1568}) => VisionShape(
      code: '8on16-bw',
      fontWidth: 8,
      fontHeight: 8,
      cellWidth: 8,
      cellHeight: 16,
      stopwordDim: false,
      columns: 1,
      frameSize: frameSize,
      frameTokenEstimate: 3290,
      imageDetail: '',
    );

/// One model-pattern → shape rule. The first matching [pattern] (tested
/// case-insensitively against the model id) wins.
class _ShapeRule {
  const _ShapeRule(this.pattern, this.build);

  /// Case-insensitive pattern tested against the model id.
  final RegExp pattern;

  /// Builds the [VisionShape] for a match.
  final VisionShape Function() build;
}

/// Ordered model-pattern rules. First match wins; unmatched ids fall back to
/// the Anthropic shape (see [resolveShape]).
final List<_ShapeRule> _shapeRules = <_ShapeRule>[
  // Opus 4.7+ and Fable/Mythos read high-res natively (1932px frame, same
  // bill, a third fewer frames).
  _ShapeRule(
    RegExp(r'claude.*(fable|mythos)', caseSensitive: false),
    () => _anthropicShape(frameSize: 1932),
  ),
  _ShapeRule(
    RegExp(r'claude-?opus-?4[.-][7-9]', caseSensitive: false),
    () => _anthropicShape(frameSize: 1932),
  ),
  // Older Claude lines downscale past 1568px — keep the safe size.
  _ShapeRule(
    RegExp('claude', caseSensitive: false),
    _anthropicShape,
  ),
  // Gemini 3.x bills a fixed budget per image regardless of pixels: a larger
  // 2048px frame packs more chars at the same bill.
  _ShapeRule(
    RegExp('gemini', caseSensitive: false),
    () => _wideLeadingShape(
      frameSize: 2048,
      frameTokenEstimate: 1120,
      imageDetail: '',
    ),
  ),
  // OpenAI patch billing is area-proportional; 1568 is already optimal.
  _ShapeRule(
    RegExp('gpt|codex', caseSensitive: false),
    () => _wideLeadingShape(
      frameSize: 1568,
      frameTokenEstimate: 2881,
      imageDetail: 'original',
    ),
  ),
  // kimi / glm read the denser 8on16-bw cell best.
  _ShapeRule(RegExp('kimi', caseSensitive: false), _denseShape),
  _ShapeRule(RegExp('glm', caseSensitive: false), _denseShape),
];

/// Resolves the eval-validated [VisionShape] for [modelId].
///
/// Matching is case-insensitive and first-match-wins over the shape rules
/// (Claude/Fable/Opus → `11on16-bw`, Gemini/GPT/Codex → `8on22-bw`, kimi/glm →
/// `8on16-bw`). An unknown model id falls back to the Anthropic `11on16-bw`
/// shape at the standard 1568px frame.
VisionShape resolveShape(String modelId) {
  for (final rule in _shapeRules) {
    if (rule.pattern.hasMatch(modelId)) {
      return rule.build();
    }
  }
  return _anthropicShape();
}
