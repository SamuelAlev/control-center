import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/pr_review/presentation/utils/markdown_preview_diff.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:flutter/widgets.dart';

/// AST node type for a rich-diff addition or deletion span.
const String kMarkdownDiffInlineNodeType = 'markdown_diff_inline';

/// Preview-only plugin set: GitHub GFM plus the rich-diff sentinels.
final CcPluginSet markdownPreviewDiffPlugins = CcPluginSet(const [
  MarkdownDiffInlinePlugin(),
]);

/// Preview-only builders: GitHub register plus the rich-diff washes.
///
/// Identity-stable (process-global final) so the parse cache and streaming
/// memo treat every preview the same.
final CcBuilderRegistry markdownPreviewDiffBuilders = githubMarkdownBuilders
    .withOverrides(const {
      kMarkdownDiffInlineNodeType: MarkdownDiffInlineBuilder(),
      'paragraph': MarkdownDiffBlockBuilder(),
      'heading': MarkdownDiffBlockBuilder(),
    });

/// Claims `{U+E000}a…{U+E001}` / `{U+E000}d…{U+E001}` at parse time.
final class MarkdownDiffInlinePlugin extends CcInlinePlugin {
  /// Creates a [MarkdownDiffInlinePlugin].
  const MarkdownDiffInlinePlugin();

  static const CcParser _inner = CcParser();

  @override
  String get id => 'markdown_diff';

  @override
  int get priority => 20;

  @override
  String get triggerCharacters => String.fromCharCode(kMarkdownDiffTriggerUnit);

  @override
  bool canParse(String text, int index) {
    if (index + 1 >= text.length) {
      return false;
    }
    if (text.codeUnitAt(index) != kMarkdownDiffTriggerUnit) {
      return false;
    }
    final tag = text.codeUnitAt(index + 1);
    return tag == 0x61 || tag == 0x64; // a | d
  }

  @override
  CcInlineParseResult? parse(String text, int startIndex) {
    if (!canParse(text, startIndex)) {
      return null;
    }
    final added = text.codeUnitAt(startIndex + 1) == 0x61;
    final close = text.indexOf(kMarkdownDiffClose, startIndex + 2);
    if (close < 0) {
      return null;
    }
    final inner = text.substring(startIndex + 2, close);
    final children = inner.isEmpty
        ? const <CcInlineNode>[]
        : _inner.parseInline(inner);
    return CcInlineParseResult(
      MarkdownDiffInline(added: added, children: children),
      close + kMarkdownDiffClose.length - startIndex,
    );
  }
}

/// One addition or deletion span produced by [MarkdownDiffInlinePlugin].
final class MarkdownDiffInline extends CcCustomInline {
  /// Creates a [MarkdownDiffInline].
  const MarkdownDiffInline({required this.added, required this.children});

  /// True for an insertion, false for a deletion.
  final bool added;

  /// Inner inlines (the original markdown, re-parsed).
  final List<CcInlineNode> children;

  @override
  String get nodeType => kMarkdownDiffInlineNodeType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownDiffInline &&
          added == other.added &&
          ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, added, Object.hashAll(children));
}

/// Paints an inline addition/deletion as a wrapping [TextSpan] wash.
final class MarkdownDiffInlineBuilder extends CcNodeBuilder {
  /// Creates a [MarkdownDiffInlineBuilder].
  const MarkdownDiffInlineBuilder();

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    final diff = node as MarkdownDiffInline;
    return context.renderInlines!(diff.children, style.paragraph);
  }

  @override
  InlineSpan? buildSpan(
    CcNode node,
    TextStyle? base,
    CcMarkdownStyle style,
    CcRenderContext context,
    BuildContext buildContext,
  ) {
    final diff = node as MarkdownDiffInline;
    final children =
        context.renderInlineSpans?.call(diff.children, base) ?? const [];
    if (MarkdownDiffWashScope.maybeOf(buildContext) != null) {
      // The enclosing block already carries the wash; don't double-paint.
      return TextSpan(children: children);
    }
    final colors = DiffColors.of(buildContext);
    return TextSpan(
      style: TextStyle(
        backgroundColor: diff.added
            ? colors.additionWordBg
            : colors.deletionWordBg,
      ),
      children: children,
    );
  }
}

/// Full-width wash for a paragraph or heading whose content is entirely an
/// addition or entirely a deletion — GitHub's block-level rich-diff treatment.
final class MarkdownDiffBlockBuilder extends CcNodeBuilder {
  /// Creates a [MarkdownDiffBlockBuilder].
  const MarkdownDiffBlockBuilder();

  @override
  bool canBuild(CcNode node) => _uniformDiffKind(node) != null;

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    final added = _uniformDiffKind(node)!;
    final (children, textStyle) = switch (node) {
      CcParagraph(:final children) => (children, style.paragraph),
      CcHeading(:final children, :final level) => (
        children,
        style.headingStyle(level) ?? style.paragraph,
      ),
      _ => (const <CcInlineNode>[], style.paragraph),
    };
    return MarkdownDiffBlockWash(
      added: added,
      startBleed: context.listLevel > 0
          ? style.listIndent * context.listLevel
          : 0,
      child: context.renderInlines!(children, textStyle),
    );
  }
}

bool? _uniformDiffKind(CcNode node) {
  final children = switch (node) {
    CcParagraph(:final children) => children,
    CcHeading(:final children) => children,
    _ => null,
  };
  if (children == null || children.isEmpty) {
    return null;
  }
  bool? added;
  var saw = false;
  for (final child in children) {
    if (child is CcSoftBreak || child is CcHardBreak) {
      continue;
    }
    if (child is! MarkdownDiffInline) {
      return null;
    }
    if (added != null && child.added != added) {
      return null;
    }
    added = child.added;
    saw = true;
  }
  return saw ? added : null;
}

/// Marks a subtree as already carrying a block-level add/delete wash.
class MarkdownDiffWashScope extends InheritedWidget {
  /// Creates a [MarkdownDiffWashScope].
  const MarkdownDiffWashScope({
    super.key,
    required this.added,
    required super.child,
  });

  /// Whether the enclosing wash is an addition.
  final bool added;

  /// The nearest wash, or null when the inline sits in mixed prose.
  static MarkdownDiffWashScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MarkdownDiffWashScope>();

  @override
  bool updateShouldNotify(MarkdownDiffWashScope oldWidget) =>
      added != oldWidget.added;
}

/// GitHub-style block wash: full-width tint plus a start-edge accent.
class MarkdownDiffBlockWash extends StatelessWidget {
  /// Creates a [MarkdownDiffBlockWash].
  const MarkdownDiffBlockWash({
    super.key,
    required this.added,
    required this.child,
    this.startBleed = 0,
  });

  /// Whether this block is an addition.
  final bool added;

  /// The rendered original block.
  final Widget child;

  /// Extra width pulled toward the start edge so a list-item wash covers the
  /// marker column, matching GitHub's full-row rich diff.
  final double startBleed;

  @override
  Widget build(BuildContext context) {
    final colors = DiffColors.of(context);
    final bg = added ? colors.additionBg : colors.deletionBg;
    final accent = added ? colors.additionAccent : colors.deletionAccent;
    final painted = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8 + startBleed, 4, 8, 4),
        child: child,
      ),
    );
    final washed = startBleed <= 0
        ? painted
        : LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth + startBleed;
              return OverflowBox(
                alignment: AlignmentDirectional.centerEnd,
                minWidth: width,
                maxWidth: width,
                child: painted,
              );
            },
          );
    return MarkdownDiffWashScope(added: added, child: washed);
  }
}
