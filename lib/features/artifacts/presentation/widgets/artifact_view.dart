import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_chart.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_table.dart';
import 'package:control_center/shared/widgets/artifacts/json_tree_view.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/markdown/mermaid_block.dart';
import 'package:flutter/widgets.dart';

/// Renders an [ArtifactDocument] — an ordered list of typed blocks — natively.
///
/// One component per block kind, dispatched by a pattern switch. This is the
/// same shape `TranscriptFlow` uses for agent turns and it is why the schema is
/// a sealed hierarchy: adding a kind breaks the switch until it is handled,
/// rather than silently rendering a hole where the operator expected a chart.
///
/// Deliberately no HTML. Every kind maps to a widget the app already draws
/// (markdown, native mermaid, syntax-highlighted code) or a small new one
/// (table, chart, JSON tree), so an artifact is themable, selectable,
/// accessible and identical on desktop, web and phone.
class ArtifactView extends StatelessWidget {
  /// Creates an [ArtifactView].
  const ArtifactView({super.key, required this.document, this.compact = false});

  /// The blocks to render, in order.
  final ArtifactDocument document;

  /// Tightens spacing and type for dense surfaces (the conversation bubble).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (document.isEmpty) {
      return const SizedBox.shrink();
    }
    final gap = compact ? 10.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < document.blocks.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          ArtifactBlockView(block: document.blocks[i], compact: compact),
        ],
      ],
    );
  }
}

/// One artifact block. Public so a caller can render a single block (e.g. a
/// preview that shows only the first one).
class ArtifactBlockView extends StatelessWidget {
  /// Creates an [ArtifactBlockView].
  const ArtifactBlockView({
    super.key,
    required this.block,
    this.compact = false,
  });

  /// The block to render.
  final ArtifactBlock block;

  /// Tightens spacing and type.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      ArtifactMarkdownBlock(:final text) => CcMarkdown(
        data: text,
        style: appMarkdownStyle(context, compact: compact),
        plugins: chatMarkdownPlugins,
        builders: chatMarkdownBuilders,
      ),
      ArtifactTableBlock(:final columns, :final rows) => ArtifactTable(
        columns: columns,
        rows: rows,
        compact: compact,
      ),
      final ArtifactChartBlock chart => ArtifactChart(
        block: chart,
        height: compact ? 180 : 220,
      ),
      // The same figure a ```mermaid``` fence renders as: fit-to-width first,
      // then horizontal scroll past the legibility floor, plus view-source and
      // the pan/zoom viewer. A local frame here would have to re-earn all of
      // that and the earlier one didn't — it handed the diagram unbounded
      // width, which defeats the fit and cuts a wide diagram off.
      ArtifactMermaidBlock(:final source) => AppMermaidFigure(source: source),
      ArtifactCodeBlock(:final code, :final language, :final title) =>
        _CodeFrame(code: code, language: language, title: title),
      ArtifactDataBlock(:final json) => _DataFrame(value: json),
    };
  }
}

/// A code block with app-side syntax highlighting, matching every other code
/// surface in the app.
class _CodeFrame extends StatelessWidget {
  const _CodeFrame({
    required this.code,
    required this.language,
    required this.title,
  });

  final String code;
  final String? language;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(
            title!,
            style: AppTextStyles.labelSmall(
              tokens,
            ).copyWith(color: tokens.textTertiary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
        ],
        buildSharedCodeBlock(context, code, language),
      ],
    );
  }
}

/// Arbitrary JSON as a collapsible tree.
class _DataFrame extends StatelessWidget {
  const _DataFrame({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: JsonTreeView(value: value),
        ),
      ),
    );
  }
}
