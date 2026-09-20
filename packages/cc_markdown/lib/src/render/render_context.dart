import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/widgets.dart';

/// Signature of the fenced code-block renderer callback. [cache] is true for
/// settled content and false for a still-streaming volatile tail — thread it
/// to your syntax-highlight cache.
typedef CcCodeBuilder =
    Widget Function(String code, String? language, {required bool cache});

/// Signature of the image renderer callback. [alt] and [title] are passed
/// VERBATIM from the source (callers may encode sentinels in them).
typedef CcImageBuilder =
    Widget Function(String url, String? alt, String? title);

/// Sequential index source for interactive task-list checkboxes. Nested list
/// renders share one instance so indices match document order (and the
/// source-level [toggleMarkdownTaskListItem] scan).
final class CcTaskCheckboxCursor {
  int _next = 0;

  /// The next document-order task-list index.
  int take() => _next++;
}

/// Rendering state threaded through the builder tree.
@immutable
class CcRenderContext {
  /// Creates a [CcRenderContext].
  const CcRenderContext({
    required this.style,
    this.onTapLink,
    this.onTapImage,
    this.imageBuilder,
    this.codeBuilder,
    this.onTaskCheckboxChanged,
    this.taskCheckboxCursor,
    this.listLevel = 0,
    this.selectable = false,
    this.codeCache = true,
    this.footnotes = const [],
    this.renderBlocks,
    this.renderInlines,
    this.renderInlineSpans,
  });

  /// The active stylesheet.
  final CcMarkdownStyle style;

  /// Invoked when a link is tapped.
  final void Function(String url)? onTapLink;

  /// Invoked when an image is tapped (when no [imageBuilder] handles taps).
  final void Function(String url, String? alt, String? title)? onTapImage;

  /// Custom image renderer.
  final CcImageBuilder? imageBuilder;

  /// Custom fenced-code renderer.
  final CcCodeBuilder? codeBuilder;

  /// Invoked when a task-list checkbox is toggled. [index] is the
  /// document-order task item (matching [toggleMarkdownTaskListItem]).
  final void Function(int index, bool checked)? onTaskCheckboxChanged;

  /// Shared counter for [onTaskCheckboxChanged] indices. Nested lists keep
  /// the same instance via [copyWith].
  final CcTaskCheckboxCursor? taskCheckboxCursor;

  /// Current list nesting depth.
  final int listLevel;

  /// Whether this subtree renders inside a selection context.
  final bool selectable;

  /// Whether code blocks in this subtree may cache their highlight (false
  /// for the streaming volatile tail).
  final bool codeCache;

  /// Footnote definitions for the document being rendered.
  final List<CcFootnoteDef> footnotes;

  /// Renders nested blocks with this context (bound by the renderer; used by
  /// custom builders that recurse, e.g. a details builder).
  final Widget Function(List<CcBlockNode> blocks)? renderBlocks;

  /// Renders nested inlines with this context and an optional base style.
  final Widget Function(List<CcInlineNode> nodes, TextStyle? baseStyle)?
  renderInlines;

  /// Renders nested inlines as spans so a custom inline can wrap children
  /// inside a [TextSpan] (background highlights that wrap with the sentence).
  final List<InlineSpan> Function(
    List<CcInlineNode> nodes,
    TextStyle? baseStyle,
  )?
  renderInlineSpans;

  /// A copy with the given fields replaced.
  CcRenderContext copyWith({
    CcMarkdownStyle? style,
    void Function(String url)? onTapLink,
    void Function(String url, String? alt, String? title)? onTapImage,
    CcImageBuilder? imageBuilder,
    CcCodeBuilder? codeBuilder,
    void Function(int index, bool checked)? onTaskCheckboxChanged,
    CcTaskCheckboxCursor? taskCheckboxCursor,
    int? listLevel,
    bool? selectable,
    bool? codeCache,
    List<CcFootnoteDef>? footnotes,
    Widget Function(List<CcBlockNode>)? renderBlocks,
    Widget Function(List<CcInlineNode>, TextStyle?)? renderInlines,
    List<InlineSpan> Function(List<CcInlineNode>, TextStyle?)?
    renderInlineSpans,
  }) {
    return CcRenderContext(
      style: style ?? this.style,
      onTapLink: onTapLink ?? this.onTapLink,
      onTapImage: onTapImage ?? this.onTapImage,
      imageBuilder: imageBuilder ?? this.imageBuilder,
      codeBuilder: codeBuilder ?? this.codeBuilder,
      onTaskCheckboxChanged:
          onTaskCheckboxChanged ?? this.onTaskCheckboxChanged,
      taskCheckboxCursor: taskCheckboxCursor ?? this.taskCheckboxCursor,
      listLevel: listLevel ?? this.listLevel,
      selectable: selectable ?? this.selectable,
      codeCache: codeCache ?? this.codeCache,
      footnotes: footnotes ?? this.footnotes,
      renderBlocks: renderBlocks ?? this.renderBlocks,
      renderInlines: renderInlines ?? this.renderInlines,
      renderInlineSpans: renderInlineSpans ?? this.renderInlineSpans,
    );
  }
}
