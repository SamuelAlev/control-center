import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/render/node_builder.dart';
import 'package:cc_markdown/src/render/render_context.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlwaysBuild extends CcNodeBuilder {
  const _AlwaysBuild();
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      const SizedBox.shrink();
}

class _ParagraphBuilder extends CcNodeBuilder {
  const _ParagraphBuilder();
  @override
  bool canBuild(CcNode node) => node is CcParagraph && node.children.isNotEmpty;
  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) =>
      const SizedBox.shrink();
}

/// A custom block/inline pair for the override + custom-node paths.
class _MyCustomBlock extends CcCustomBlock {
  const _MyCustomBlock();
  @override
  String get nodeType => 'my_block';
}

class _MyCustomInline extends CcCustomInline {
  const _MyCustomInline();
  @override
  String get nodeType => 'my_inline';
}

void main() {
  group('CcNodeBuilder', () {
    test('canBuild defaults to true (fall-through only when a subclass opts '
        'out)', () {
      const builder = _AlwaysBuild();
      expect(builder.canBuild(const CcText('x')), isTrue);
    });
  });

  group('CcBuilderRegistry', () {
    test('empty registry has no entries and resolves to null', () {
      final reg = CcBuilderRegistry.empty;
      expect(reg.builderFor('paragraph'), isNull);
      expect(reg.entries, isEmpty);
    });

    test('builderFor resolves a registered nodeType', () {
      const builder = _AlwaysBuild();
      final reg = CcBuilderRegistry({'paragraph': builder});
      expect(reg.builderFor('paragraph'), same(builder));
      expect(reg.builderFor('heading'), isNull);
    });

    test('entries exposes every registered entry', () {
      const a = _AlwaysBuild();
      const b = _AlwaysBuild();
      final reg = CcBuilderRegistry({'paragraph': a, 'heading': b});
      expect(reg.entries.map((e) => e.key).toList()..sort(), [
        'heading',
        'paragraph',
      ]);
    });

    test('withOverrides layers new builders on top (and wins ties)', () {
      const a = _AlwaysBuild();
      const b = _AlwaysBuild();
      final reg = CcBuilderRegistry({'paragraph': a});
      final reg2 = reg.withOverrides({'heading': b});
      // Original is untouched (identity-stable / immutable).
      expect(reg.builderFor('heading'), isNull);
      // The new registry carries both, with overrides winning ties.
      expect(reg2.builderFor('paragraph'), same(a));
      expect(reg2.builderFor('heading'), same(b));
      // New identity — distinct from the original.
      expect(identical(reg, reg2), isFalse);
    });

    test(
      'canBuild fall-through: a selective builder claims only some nodes',
      () {
        const builder = _ParagraphBuilder();
        final reg = CcBuilderRegistry({'paragraph': builder});
        expect(
          reg
              .builderFor('paragraph')!
              .canBuild(const CcParagraph([CcText('x')])),
          isTrue,
        );
        // An empty paragraph falls through to the default renderer.
        expect(
          reg.builderFor('paragraph')!.canBuild(const CcParagraph([])),
          isFalse,
        );
      },
    );
  });

  group('custom node types', () {
    test('CcCustomBlock and CcCustomInline expose their nodeType', () {
      expect(const _MyCustomBlock().nodeType, 'my_block');
      expect(const _MyCustomInline().nodeType, 'my_inline');
    });
  });
}
