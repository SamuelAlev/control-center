/// How the diff viewer renders code lines that are wider than the viewport.
enum DiffOverflowMode {
  /// Long lines soft-wrap to multiple visual rows; the line-number gutter stays
  /// pinned and only the code content wraps. No horizontal scrolling.
  wrap,

  /// Long lines stay on a single row; the code content scrolls horizontally
  /// while the line-number gutter stays pinned.
  scroll;

  /// Parses a persisted enum name (e.g. `'wrap'`), defaulting to [wrap].
  static DiffOverflowMode fromName(String? name) {
    return switch (name) {
      'scroll' => DiffOverflowMode.scroll,
      'wrap' => DiffOverflowMode.wrap,
      _ => DiffOverflowMode.wrap,
    };
  }
}
