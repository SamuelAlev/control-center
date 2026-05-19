/// Kinds of sparse interactive children hosted by the unified diff sliver.
/// Code lines themselves are painted directly on the canvas and are NOT slots;
/// only the comparatively rare interactive rows are real widgets.
enum DiffSlotKind {
  /// Per-file header bar (filename, stats, viewed/collapse toggles).
  header,

  /// An "Show N lines" / "Show end of file" expand affordance.
  gap,

  /// An inline comment thread anchored below a code line.
  comment,

  /// An open comment composer anchored below a code line.
  composer,
}

/// One sparse child of the unified diff sliver, placed at an absolute offset in
/// the document's scroll space. Slots are kept sorted by [offset] so the sliver
/// can lay them out and garbage-collect them with the same contiguous-range
/// machinery it uses for a plain lazy list.
class DiffSlot {
  /// Creates a slot.
  const DiffSlot({
    required this.kind,
    required this.key,
    required this.fileIndex,
    required this.offset,
    required this.height,
    this.rawIndex = -1,
    this.anchorDisplayLine = -1,
  });

  /// What this slot renders.
  final DiffSlotKind kind;

  /// Stable identity (e.g. `hdr:<file>`, `gap:<file>:<raw>`, `thread:<id>`,
  /// `composer:<file>:<line>`) — drives child reuse + measurement caching.
  final String key;

  /// File this slot belongs to.
  final int fileIndex;

  /// Absolute top offset in the document's scroll space.
  final double offset;

  /// Slot height in logical pixels. Fixed for headers/gaps; for comments it is
  /// the document's reserved (measured-or-estimated) height.
  final double height;

  /// For [DiffSlotKind.gap]: the gap row's index into the file's structure.
  final int rawIndex;

  /// For comment/composer slots: the display line the block is anchored below.
  final int anchorDisplayLine;
}
