import 'package:flutter/widgets.dart';

/// Marks a subtree whose text selection is owned by a single ancestor
/// selection region (a `SelectionArea`/`SelectableRegion`).
///
/// When present, [CcMarkdown]/[CcStreamingMarkdown] render plain,
/// NON-selectable rich text and let the ancestor own selection — a long feed
/// pays for exactly ONE selection region instead of one per message, which is
/// the dominant scroll cost with per-bubble regions.
class CcSelectionScope extends InheritedWidget {
  /// Marks [child]'s subtree as living under an ancestor-owned region.
  const CcSelectionScope({required super.child, super.key});

  /// Whether an ancestor [CcSelectionScope] is present above [context].
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CcSelectionScope>() != null;

  @override
  bool updateShouldNotify(CcSelectionScope oldWidget) => false;
}
