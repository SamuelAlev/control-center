import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Renders an [ArtifactTableBlock] as a tokenized data table.
///
/// Scrolls horizontally inside its own box rather than letting a wide table
/// widen the page — the surrounding surface must never scroll sideways.
///
/// Distinct from cc_markdown's table renderer, which draws tables parsed from
/// markdown source. This one takes typed data (columns with keys and alignment,
/// rows as values), which is what an agent produces when it has a result set
/// rather than prose.
///
/// Typed does NOT mean literal, though: a cell is a string an agent wrote, and
/// agents write `path/to/file.ts`, *emphasis* and **bold** into result sets the
/// same way they write them into prose. Cells are therefore parsed as INLINE
/// markdown ([CcParser.parseInline]) and drawn with the app's markdown
/// renderer, so a backtick is a code chip here exactly as it is in a markdown
/// table. Inline only, on purpose — a cell is not a block context, so a leading
/// `- ` stays a hyphen instead of becoming a list.
class ArtifactTable extends StatefulWidget {
  /// Creates an [ArtifactTable].
  const ArtifactTable({
    super.key,
    required this.columns,
    required this.rows,
    this.compact = false,
  });

  /// Column headers, in display order.
  final List<ArtifactColumn> columns;

  /// Row values, parallel to [columns]. A short row renders blank cells rather
  /// than throwing — a persisted artifact must always come back out.
  final List<List<String>> rows;

  /// Tightens padding and type.
  final bool compact;

  @override
  State<ArtifactTable> createState() => _ArtifactTableState();
}

class _ArtifactTableState extends State<ArtifactTable> {
  /// The parsed header labels, one inline run per column.
  late List<List<CcInlineNode>> _header;

  /// The parsed body cells, `[row][column]`, padded to the column count.
  late List<List<List<CcInlineNode>>> _cells;

  /// Per column: the longest plain-text cell, and whether any cell carries
  /// media. Both feed [_columnWidths]; see there for what they decide.
  late List<int> _maxLength;
  late List<bool> _hasMedia;

  /// Parsing is memoized against the block's data rather than redone per build:
  /// a table rebuilds on every theme change, hover and scroll tick, and the AST
  /// depends on none of that.
  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(ArtifactTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.columns, widget.columns) ||
        !_rowsEqual(oldWidget.rows, widget.rows)) {
      _parse();
    }
  }

  static bool _rowsEqual(List<List<String>> a, List<List<String>> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  void _parse() {
    const parser = CcParser();
    final count = widget.columns.length;
    _header = [for (final c in widget.columns) parser.parseInline(c.label)];
    _cells = [
      for (final row in widget.rows)
        [
          for (var c = 0; c < count; c++)
            parser.parseInline(c < row.length ? row[c] : ''),
        ],
    ];
    _maxLength = List<int>.filled(count, 0);
    _hasMedia = List<bool>.filled(count, false);
    for (var c = 0; c < count; c++) {
      _measure(_header[c], c);
      for (final row in _cells) {
        _measure(row[c], c);
      }
    }
  }

  void _measure(List<CcInlineNode> nodes, int column) {
    final metrics = _inlineMetrics(nodes);
    if (metrics.length > _maxLength[column]) {
      _maxLength[column] = metrics.length;
    }
    if (metrics.media) {
      _hasMedia[column] = true;
    }
  }

  /// Column length above which a column is treated as prose and left flexible
  /// rather than shrunk to its content. Matches cc_markdown's table budget so
  /// an artifact table and a markdown table of the same data size the same.
  static const int _narrowColumnCharBudget = 24;

  /// The floor a hugging column is held to, so a one-character column ("#") is
  /// still a comfortable target rather than a sliver.
  static const double _minCellWidth = 88;

  /// Per-column widths. Short, media-free columns hug their content (held to
  /// [_minCellWidth]); everything else falls through to the table's flexible
  /// default and shares out the remaining width.
  ///
  /// This replaced a per-row `Row` of `ConstrainedBox(minWidth, maxWidth)`
  /// cells, which had no shared geometry at all: each cell sized itself from
  /// its own text, so every row put its column boundaries somewhere different
  /// and the header lined up with nothing.
  ///
  /// Intrinsic sizing is withheld from a column carrying media because an
  /// image's width is not known until it loads, and a builder that sizes itself
  /// with a `LayoutBuilder` throws outright during the intrinsic measurement
  /// pass.
  Map<int, TableColumnWidth> _columnWidths() {
    final widths = <int, TableColumnWidth>{};
    for (var i = 0; i < widget.columns.length; i++) {
      if (!_hasMedia[i] && _maxLength[i] <= _narrowColumnCharBudget) {
        widths[i] = const MaxColumnWidth(
          FixedColumnWidth(_minCellWidth),
          IntrinsicColumnWidth(),
        );
      }
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = resolveDesignTokens(context);
    final compact = widget.compact;
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 10.0 : 12.0,
      vertical: compact ? 6.0 : 8.0,
    );

    final markdownStyle = appMarkdownStyle(context, compact: compact);
    final renderer = CcRenderer(
      style: markdownStyle,
      builders: chatMarkdownBuilders,
    );
    final renderContext = CcRenderContext(style: markdownStyle);

    final headerStyle = AppTextStyles.labelSmall(tokens).copyWith(
      color: tokens.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final cellStyle =
        (compact
                ? AppTextStyles.bodySmall(tokens)
                : AppTextStyles.bodyMedium(tokens))
            .copyWith(color: tokens.textPrimary, height: 1.35);

    Widget cell(List<CcInlineNode> nodes, int column, TextStyle style) {
      final align = switch (widget.columns[column].align) {
        ArtifactColumnAlign.center => TextAlign.center,
        ArtifactColumnAlign.right => TextAlign.right,
        ArtifactColumnAlign.left || null => TextAlign.left,
      };
      return Padding(
        padding: padding,
        // `Align` places the text BLOCK; `textAlign` places the lines within
        // it. A wrapped cell needs both, or a right-aligned column reads as
        // left-aligned the moment a value is long enough to wrap.
        child: Align(
          alignment: switch (align) {
            TextAlign.center => Alignment.center,
            TextAlign.right => AlignmentDirectional.centerEnd,
            _ => AlignmentDirectional.centerStart,
          },
          child: DefaultTextStyle.merge(
            textAlign: align,
            child: renderer.renderInline(nodes, style, renderContext),
          ),
        ),
      );
    }

    final table = Table(
      columnWidths: _columnWidths(),
      // Rules run between rows only; the rounded outline below draws the
      // outside edge and the columns are separated by whitespace, not lines.
      border: TableBorder(
        horizontalInside: BorderSide(color: tokens.borderSecondary),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          decoration: BoxDecoration(color: tokens.bgSecondary),
          children: [
            for (var c = 0; c < widget.columns.length; c++)
              cell(_header[c], c, headerStyle),
          ],
        ),
        for (var r = 0; r < _cells.length; r++)
          TableRow(
            // Zebra striping so a long row stays trackable across a wide table
            // without relying on the reader's eye alone.
            decoration: r.isOdd
                ? BoxDecoration(color: tokens.bgSecondary)
                : null,
            children: [
              for (var c = 0; c < widget.columns.length; c++)
                cell(_cells[r][c], c, cellStyle),
            ],
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tight, so the table fills the box (its bands and stripes reach
            // both edges) and a wide table squeezes its flexible columns
            // instead of overflowing. The horizontal scroller is the escape
            // hatch below the legibility floor, where squeezing further would
            // shred every column.
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(320.0, double.infinity)
                : 900.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: width),
                child: table,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Plain-text length of an inline run, and whether it contains media (an image
/// or a custom inline that may size itself with a `LayoutBuilder`).
({int length, bool media}) _inlineMetrics(List<CcInlineNode> nodes) {
  var length = 0;
  var media = false;

  void walk(List<CcInlineNode> ns) {
    for (final node in ns) {
      switch (node) {
        case CcText(:final text):
          length += text.length;
        case CcInlineCode(:final code):
          length += code.length;
        case CcInlineHtml(:final raw):
          length += raw.length;
        case CcEmphasis(:final children):
          walk(children);
        case CcStrong(:final children):
          walk(children);
        case CcStrikethrough(:final children):
          walk(children);
        case CcLink(:final children):
          walk(children);
        case CcSoftBreak():
        case CcHardBreak():
          length += 1;
        case CcImage():
        case CcCustomInline():
          media = true;
        default:
          break;
      }
    }
  }

  walk(nodes);
  return (length: length, media: media);
}
