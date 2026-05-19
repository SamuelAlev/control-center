/// The block-level parser: a line-based state machine over a container stack
/// (blockquote / list item / details / footnote definition), with recursive
/// container content parsing.
///
/// Two-pass design: the block pass builds a lightweight raw tree (leaf text
/// unparsed) while collecting link-reference and footnote definitions; the
/// finalize pass then runs the inline parser over every leaf — so reference
/// links resolve regardless of definition position.
///
/// The parser never throws: anything malformed degrades to paragraph text,
/// and container nesting beyond [CcParseOptions.maxBlockDepth] falls through
/// to literal text.
library;

import 'package:cc_markdown/src/ast/document.dart';
import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/html_block_interpreter.dart';
import 'package:cc_markdown/src/parser/inline_parser.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';

// --- Raw (pre-inline) tree -------------------------------------------------

sealed class _Raw {
  const _Raw();
}

final class _RawParagraph extends _Raw {
  _RawParagraph(this.text);
  final String text;
}

final class _RawHeading extends _Raw {
  _RawHeading(this.level, this.text);
  final int level;
  final String text;
}

final class _RawQuote extends _Raw {
  _RawQuote(this.children);
  final List<_Raw> children;
}

final class _RawListItem {
  _RawListItem(this.children, this.checked);
  final List<_Raw> children;
  final bool? checked;
}

final class _RawList extends _Raw {
  _RawList({
    required this.ordered,
    required this.start,
    required this.tight,
    required this.items,
  });
  final bool ordered;
  final int start;
  final bool tight;
  final List<_RawListItem> items;
}

final class _RawTable extends _Raw {
  _RawTable({
    required this.header,
    required this.alignments,
    required this.rows,
  });
  final List<String> header;
  final List<CcTableAlign?> alignments;
  final List<List<String>> rows;
}

final class _RawDetails extends _Raw {
  _RawDetails({
    required this.summary,
    required this.children,
    required this.open,
  });
  final String summary;
  final List<_Raw> children;
  final bool open;
}

final class _RawFinished extends _Raw {
  _RawFinished(this.node);
  final CcBlockNode node;
}

// --- Patterns ---------------------------------------------------------------

final RegExp _atxPattern = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');
final RegExp _atxTrailing = RegExp(r'[ \t]+#+[ \t]*$');
final RegExp _thematicBreak = RegExp(
  r'^ {0,3}(?:(?:\* *){3,}|(?:- *){3,}|(?:_ *){3,})[ \t]*$',
);
final RegExp _fenceOpen = RegExp(r'^( {0,3})(`{3,}|~{3,})[ \t]*(.*)$');
final RegExp _blockquotePrefix = RegExp(r'^ {0,3}> ?');
final RegExp _listItemStart = RegExp(r'^( {0,3})([-*+]|\d{1,9}[.)])([ \t]+|$)');
final RegExp _taskMarker = RegExp(r'^\[([ xX])\][ \t]+');
final RegExp _setextUnderline = RegExp(r'^ {0,3}(=+|-+)[ \t]*$');
final RegExp _tableDelimiterRow = RegExp(
  r'^ {0,3}\|?[ \t]*:?-+:?[ \t]*(\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$',
);
final RegExp _footnoteDefStart = RegExp(r'^ {0,3}\[\^([^\s\]]+)\]:[ \t]*(.*)$');
final RegExp _linkRefDef = RegExp(
  r'''^ {0,3}\[([^\]]+)\]:[ \t]*<?([^\s>]+)>?(?:[ \t]+(?:"([^"]*)"|'([^']*)'|\(([^)]*)\)))?[ \t]*$''',
);
final RegExp _detailsOpen = RegExp(
  r'^ {0,3}<details(\s[^>]*)?>[ \t]*$',
  caseSensitive: false,
);
final RegExp _detailsOpenAttr = RegExp(r'\bopen\b', caseSensitive: false);
final RegExp _detailsClose = RegExp(
  r'^ {0,3}</details>[ \t]*$',
  caseSensitive: false,
);
final RegExp _summaryInline = RegExp(
  r'<summary(?:\s[^>]*)?>([\s\S]*?)</summary>',
  caseSensitive: false,
);
final RegExp _htmlCommentOpen = RegExp(r'^ {0,3}<!--');
final RegExp _htmlBlockOpen = RegExp(
  r'^ {0,3}</?(address|article|aside|blockquote|center|details|dialog|div|dl|dd|dt|fieldset|figcaption|figure|footer|form|h[1-6]|header|hr|li|main|menu|nav|ol|p|picture|pre|script|section|source|style|summary|table|tbody|td|tfoot|th|thead|tr|ul|video|iframe|img|sup|sub|kbd)\b',
  caseSensitive: false,
);

int _indentOf(String line) {
  var indent = 0;
  for (var i = 0; i < line.length; i++) {
    final unit = line.codeUnitAt(i);
    if (unit == 0x20) {
      indent++;
    } else if (unit == 0x09) {
      indent += 4 - (indent % 4);
    } else {
      break;
    }
  }
  return indent;
}

bool _isBlank(String line) => line.trim().isEmpty;

/// Whether [line] starts a construct that can interrupt an open paragraph.
bool _interruptsParagraph(String line, CcParseOptions options) {
  if (_atxPattern.hasMatch(line) ||
      _fenceOpen.hasMatch(line) ||
      _thematicBreak.hasMatch(line) ||
      _blockquotePrefix.hasMatch(line) ||
      (options.details && _detailsOpen.hasMatch(line))) {
    return true;
  }
  final item = _listItemStart.firstMatch(line);
  if (item != null) {
    final marker = item.group(2)!;
    final rest = line.substring(item.end);
    // Empty items can't interrupt; ordered lists only when starting at 1.
    if (rest.trim().isNotEmpty || item.group(3)!.isNotEmpty) {
      if (marker.length == 1 && !RegExp(r'\d').hasMatch(marker)) {
        return true;
      }
      final number = marker.substring(0, marker.length - 1);
      return number == '1';
    }
  }
  return false;
}

// --- Block parser -----------------------------------------------------------

/// Line-based block parser. One instance per document parse; reused
/// recursively for container content.
final class _BlockParser {
  _BlockParser({required this.options, this.plugins = CcPluginSet.empty});

  /// Parse feature toggles.
  final CcParseOptions options;

  /// Registered block plugins.
  final CcPluginSet plugins;

  /// Link-reference definitions collected during the block pass.
  final Map<String, CcLinkReference> linkRefs = {};

  /// Footnote definitions in source order (raw; finalized later).
  final List<(String label, List<_Raw> children)> rawFootnotes = [];

  /// Parses [lines] into a raw tree. [depth] guards container recursion.
  List<_Raw> parseRaw(List<String> lines, {int depth = 0}) {
    final out = <_Raw>[];
    final paragraph = StringBuffer();

    void closeParagraph() {
      if (paragraph.isNotEmpty) {
        out.add(_RawParagraph(paragraph.toString()));
        paragraph.clear();
      }
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];

      if (_isBlank(line)) {
        closeParagraph();
        i++;
        continue;
      }

      // Block plugins first (priority over core syntax).
      var pluginConsumed = false;
      for (final plugin in plugins.blockPlugins) {
        if (plugin.canParse(line, lines, i)) {
          final result = plugin.parse(lines, i);
          if (result != null && result.linesConsumed > 0) {
            closeParagraph();
            out.add(_RawFinished(result.node));
            i += result.linesConsumed;
            pluginConsumed = true;
            break;
          }
        }
      }
      if (pluginConsumed) {
        continue;
      }

      final indent = _indentOf(line);

      // Indented code (only when no paragraph is open).
      if (options.indentedCode && indent >= 4 && paragraph.isEmpty) {
        final code = <String>[];
        while (i < lines.length &&
            (_isBlank(lines[i]) || _indentOf(lines[i]) >= 4)) {
          code.add(_stripIndent(lines[i], 4));
          i++;
        }
        while (code.isNotEmpty && code.last.trim().isEmpty) {
          code.removeLast();
        }
        out.add(
          _RawFinished(CcCodeBlock(code: code.join('\n'), fenced: false)),
        );
        continue;
      }

      // Setext underline closes an open paragraph into a heading.
      if (options.setextHeadings && paragraph.isNotEmpty) {
        final setext = _setextUnderline.firstMatch(line);
        if (setext != null) {
          final level = setext.group(1)!.startsWith('=') ? 1 : 2;
          out.add(_RawHeading(level, paragraph.toString().trim()));
          paragraph.clear();
          i++;
          continue;
        }
      }

      // Fenced code.
      final fence = _fenceOpen.firstMatch(line);
      if (fence != null) {
        closeParagraph();
        i = _parseFence(lines, i, fence, out);
        continue;
      }

      // ATX heading.
      final atx = _atxPattern.firstMatch(line);
      if (atx != null) {
        closeParagraph();
        var content = atx.group(2) ?? '';
        content = content.replaceFirst(_atxTrailing, '').trim();
        out.add(_RawHeading(atx.group(1)!.length, content));
        i++;
        continue;
      }

      // Thematic break.
      if (_thematicBreak.hasMatch(line)) {
        closeParagraph();
        out.add(_RawFinished(const CcThematicBreak()));
        i++;
        continue;
      }

      // Details.
      if (options.details && _detailsOpen.hasMatch(line)) {
        closeParagraph();
        final consumed = _parseDetails(lines, i, out, depth);
        if (consumed > 0) {
          i += consumed;
          continue;
        }
      }

      // HTML comment block: swallow entirely (GitHub hides them, and a stray
      // comment must not glue neighboring paragraphs together).
      if (_htmlCommentOpen.hasMatch(line)) {
        closeParagraph();
        while (i < lines.length && !lines[i].contains('-->')) {
          i++;
        }
        i++; // the `-->` line
        continue;
      }

      // Blockquote.
      if (depth < options.maxBlockDepth && _blockquotePrefix.hasMatch(line)) {
        closeParagraph();
        i = _parseBlockquote(lines, i, out, depth);
        continue;
      }

      // Footnote definition.
      if (options.footnotes && paragraph.isEmpty) {
        final def = _footnoteDefStart.firstMatch(line);
        if (def != null) {
          i = _parseFootnoteDef(lines, i, def, depth);
          continue;
        }
      }

      // Link-reference definition (cannot interrupt a paragraph).
      if (paragraph.isEmpty) {
        final ref = _linkRefDef.firstMatch(line);
        if (ref != null) {
          final label = normalizeLinkLabel(ref.group(1)!);
          linkRefs.putIfAbsent(
            label,
            () => CcLinkReference(
              url: ref.group(2)!,
              title: ref.group(3) ?? ref.group(4) ?? ref.group(5),
            ),
          );
          i++;
          continue;
        }
      }

      // List.
      final item = _listItemStart.firstMatch(line);
      if (item != null &&
          depth < options.maxBlockDepth &&
          (paragraph.isEmpty || _interruptsParagraph(line, options))) {
        closeParagraph();
        i = _parseList(lines, i, out, depth);
        continue;
      }

      // GFM table.
      if (options.tables && paragraph.isEmpty && line.contains('|')) {
        final consumed = _tryParseTable(lines, i, out);
        if (consumed > 0) {
          i += consumed;
          continue;
        }
      }

      // Other HTML blocks: swallow to the next blank line, then interpret the
      // GitHub-bot subset (<table>, <details>, headings, …) into first-class
      // nodes — bot comments arrive as one huge single-line HTML chunk. When
      // nothing interpretable is found, keep the raw-block fallback.
      if (paragraph.isEmpty && _htmlBlockOpen.hasMatch(line)) {
        final raw = <String>[];
        while (i < lines.length && !_isBlank(lines[i])) {
          raw.add(lines[i]);
          i++;
        }
        final rawText = raw.join('\n');
        final interpreted = options.htmlBlocks
            ? interpretHtmlBlock(rawText)
            : null;
        if (interpreted != null) {
          for (final node in interpreted) {
            out.add(_RawFinished(node));
          }
        } else {
          out.add(_RawFinished(CcHtmlBlock(rawText)));
        }
        continue;
      }

      // Paragraph accumulation.
      if (paragraph.isNotEmpty) {
        paragraph.write('\n');
      }
      paragraph.write(
        line.trimRight().isEmpty ? '' : _stripIndent(line, indent.clamp(0, 3)),
      );
      i++;
    }
    closeParagraph();
    return out;
  }

  int _parseFence(
    List<String> lines,
    int start,
    RegExpMatch fence,
    List<_Raw> out,
  ) {
    final indent = fence.group(1)!.length;
    final marker = fence.group(2)!;
    final info = fence.group(3)!.trim();
    final language = info.isEmpty ? null : info.split(RegExp(r'\s+')).first;
    final markerChar = marker[0];
    final content = <String>[];
    var i = start + 1;
    var closed = false;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (_indentOf(line) < 4 &&
          trimmed.startsWith(markerChar * marker.length)) {
        final restStart = trimmed.replaceFirst(RegExp('^\\$markerChar+'), '');
        if (restStart.trim().isEmpty) {
          closed = true;
          i++;
          break;
        }
      }
      content.add(_stripIndent(line, indent));
      i++;
    }
    final code = content.join('\n');
    // A CLOSED mermaid fence becomes a diagram node; an open one stays code
    // (a half-streamed diagram would flicker through nonsense layouts), and so
    // does an empty one (nothing to draw).
    if (options.mermaid &&
        closed &&
        language != null &&
        language.toLowerCase() == 'mermaid' &&
        code.trim().isNotEmpty) {
      out.add(_RawFinished(CcMermaid(code)));
      return i;
    }
    out.add(
      _RawFinished(CcCodeBlock(code: code, language: language, closed: closed)),
    );
    return i;
  }

  int _parseBlockquote(
    List<String> lines,
    int start,
    List<_Raw> out,
    int depth,
  ) {
    final inner = <String>[];
    var i = start;
    var lastWasParagraphish = false;
    while (i < lines.length) {
      final line = lines[i];
      final match = _blockquotePrefix.firstMatch(line);
      if (match != null) {
        final content = line.substring(match.end);
        inner.add(content);
        lastWasParagraphish =
            content.trim().isNotEmpty &&
            !_interruptsParagraph(content, options);
        i++;
        continue;
      }
      // Lazy continuation: a non-blank line continues the quote's open
      // paragraph when it doesn't start a new construct itself.
      if (!_isBlank(line) &&
          lastWasParagraphish &&
          !_interruptsParagraph(line, options)) {
        inner.add(line);
        i++;
        continue;
      }
      break;
    }
    out.add(_RawQuote(parseRaw(inner, depth: depth + 1)));
    return i;
  }

  int _parseList(List<String> lines, int start, List<_Raw> out, int depth) {
    final firstMatch = _listItemStart.firstMatch(lines[start])!;
    final firstMarker = firstMatch.group(2)!;
    final ordered = RegExp(r'\d').hasMatch(firstMarker[0]);
    final bulletChar = ordered ? '' : firstMarker;
    final listStart = ordered
        ? int.tryParse(firstMarker.substring(0, firstMarker.length - 1)) ?? 1
        : 1;

    final items = <_RawListItem>[];
    var loose = false;
    var i = start;
    var blankBeforeNextItem = false;

    while (i < lines.length) {
      final line = lines[i];
      final match = _listItemStart.firstMatch(line);
      if (match == null) {
        break;
      }
      final marker = match.group(2)!;
      final markerIsOrdered = RegExp(r'\d').hasMatch(marker[0]);
      if (markerIsOrdered != ordered || (!ordered && marker != bulletChar)) {
        break;
      }
      if (blankBeforeNextItem) {
        loose = true;
      }

      final markerIndent = match.group(1)!.length;
      final spacesAfter = match.group(3)!.length;
      // Content column: >4 spaces after the marker = 1 (rest is code).
      final contentCol =
          markerIndent +
          marker.length +
          (spacesAfter == 0 || spacesAfter > 4 ? 1 : spacesAfter);

      var firstLine = match.end <= line.length ? line.substring(match.end) : '';
      bool? checked;
      if (options.taskLists) {
        final task = _taskMarker.firstMatch(firstLine);
        if (task != null) {
          checked = task.group(1)!.toLowerCase() == 'x';
          firstLine = firstLine.substring(task.end);
        }
      }

      final content = <String>[
        if (firstLine.isNotEmpty || checked != null) firstLine,
      ];
      i++;
      var pendingBlanks = 0;
      var lastNonBlank = firstLine;
      while (i < lines.length) {
        final next = lines[i];
        if (_isBlank(next)) {
          pendingBlanks++;
          i++;
          if (pendingBlanks >= 2) {
            break;
          }
          continue;
        }
        final nextIndent = _indentOf(next);
        if (nextIndent >= contentCol) {
          if (pendingBlanks > 0) {
            loose = true;
            for (var b = 0; b < pendingBlanks; b++) {
              content.add('');
            }
            pendingBlanks = 0;
          }
          final stripped = _stripIndent(next, contentCol);
          content.add(stripped);
          lastNonBlank = stripped;
          i++;
          continue;
        }
        // New sibling item?
        if (pendingBlanks == 0 &&
            lastNonBlank.trim().isNotEmpty &&
            _listItemStart.firstMatch(next) == null &&
            !_interruptsParagraph(next, options)) {
          // Lazy paragraph continuation.
          content.add(next);
          lastNonBlank = next;
          i++;
          continue;
        }
        break;
      }
      if (pendingBlanks > 0) {
        blankBeforeNextItem = true;
        // Step back so the outer loop can see a potential next item after
        // exactly one blank.
      } else {
        blankBeforeNextItem = false;
      }

      final children = parseRaw(content, depth: depth + 1);
      if (children.length > 1 &&
          children.whereType<_RawParagraph>().length > 1) {
        loose = true;
      }
      items.add(_RawListItem(children, checked));
    }

    out.add(
      _RawList(ordered: ordered, start: listStart, tight: !loose, items: items),
    );
    return i;
  }

  int _parseFootnoteDef(
    List<String> lines,
    int start,
    RegExpMatch def,
    int depth,
  ) {
    final label = def.group(1)!;
    final content = <String>[def.group(2) ?? ''];
    var i = start + 1;
    var pendingBlanks = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (_isBlank(line)) {
        pendingBlanks++;
        i++;
        if (pendingBlanks >= 2) {
          break;
        }
        continue;
      }
      final indent = _indentOf(line);
      if (indent >= 4) {
        for (var b = 0; b < pendingBlanks; b++) {
          content.add('');
        }
        pendingBlanks = 0;
        content.add(_stripIndent(line, 4));
        i++;
        continue;
      }
      if (pendingBlanks == 0 &&
          !_interruptsParagraph(line, options) &&
          _footnoteDefStart.firstMatch(line) == null &&
          _linkRefDef.firstMatch(line) == null) {
        content.add(line);
        i++;
        continue;
      }
      break;
    }
    rawFootnotes.add((label, parseRaw(content, depth: depth + 1)));
    return i - pendingBlanks.clamp(0, 1);
  }

  int _parseDetails(List<String> lines, int start, List<_Raw> out, int depth) {
    final openLine = lines[start];
    final open = _detailsOpenAttr.hasMatch(
      _detailsOpen.firstMatch(openLine)!.group(1) ?? '',
    );
    var nesting = 1;
    var i = start + 1;
    final body = <String>[];
    while (i < lines.length && nesting > 0) {
      final line = lines[i];
      if (_detailsOpen.hasMatch(line)) {
        nesting++;
      } else if (_detailsClose.hasMatch(line)) {
        nesting--;
        if (nesting == 0) {
          i++;
          break;
        }
      }
      body.add(line);
      i++;
    }
    if (nesting > 0) {
      // Unbalanced: not a details block — fall through to HTML tolerance by
      // reporting no consumption.
      return 0;
    }

    // Extract the (possibly multi-line) <summary>…</summary> from the body.
    var summary = '';
    var bodyText = body.join('\n');
    final summaryMatch = _summaryInline.firstMatch(bodyText);
    if (summaryMatch != null) {
      summary = summaryMatch.group(1)!.trim();
      bodyText = bodyText.replaceRange(
        summaryMatch.start,
        summaryMatch.end,
        '',
      );
    }
    final children = parseRaw(bodyText.split('\n'), depth: depth + 1);
    out.add(_RawDetails(summary: summary, children: children, open: open));
    return i - start;
  }

  /// GFM table at [start]. Returns lines consumed (0 = not a table).
  int _tryParseTable(List<String> lines, int start, List<_Raw> out) {
    if (start + 1 >= lines.length) {
      return 0;
    }
    final delimiter = lines[start + 1];
    if (!_tableDelimiterRow.hasMatch(delimiter)) {
      return 0;
    }
    final header = _splitTableRow(lines[start]);
    final aligns = _splitTableRow(delimiter).map((cell) {
      final c = cell.trim();
      final left = c.startsWith(':');
      final right = c.endsWith(':');
      if (left && right) {
        return CcTableAlign.center;
      }
      if (right) {
        return CcTableAlign.right;
      }
      if (left) {
        return CcTableAlign.left;
      }
      return null;
    }).toList();
    if (header.isEmpty || header.length != aligns.length) {
      return 0;
    }

    final rows = <List<String>>[];
    var i = start + 2;
    while (i < lines.length) {
      final line = lines[i];
      if (_isBlank(line) || _interruptsParagraph(line, options)) {
        break;
      }
      final cells = _splitTableRow(line);
      // Normalize to header width.
      if (cells.length > header.length) {
        cells.removeRange(header.length, cells.length);
      }
      while (cells.length < header.length) {
        cells.add('');
      }
      rows.add(cells);
      i++;
    }
    out.add(_RawTable(header: header, alignments: aligns, rows: rows));
    return i - start;
  }

  /// Splits a table row on unescaped pipes, honoring `\|` escapes and
  /// stripping optional leading/trailing pipes.
  static List<String> _splitTableRow(String line) {
    final cells = <String>[];
    final buf = StringBuffer();
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) {
      trimmed = trimmed.substring(1);
    }
    if (trimmed.endsWith('|') && !trimmed.endsWith(r'\|')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    for (var i = 0; i < trimmed.length; i++) {
      final unit = trimmed.codeUnitAt(i);
      if (unit == 0x5C /* \ */ &&
          i + 1 < trimmed.length &&
          trimmed.codeUnitAt(i + 1) == 0x7C /* | */ ) {
        buf.write('|');
        i++;
        continue;
      }
      if (unit == 0x7C) {
        cells.add(buf.toString().trim());
        buf.clear();
        continue;
      }
      buf.writeCharCode(unit);
    }
    cells.add(buf.toString().trim());
    return cells;
  }

  static String _stripIndent(String line, int columns) {
    var stripped = 0;
    var i = 0;
    while (i < line.length && stripped < columns) {
      final unit = line.codeUnitAt(i);
      if (unit == 0x20) {
        stripped++;
      } else if (unit == 0x09) {
        stripped += 4 - (stripped % 4);
      } else {
        break;
      }
      i++;
    }
    return line.substring(i);
  }
}

// --- Finalize (raw tree → AST via the inline parser) -------------------------

List<CcBlockNode> _finalizeRaw(List<_Raw> raw, CcInlineParser inlines) {
  final out = <CcBlockNode>[];
  for (final node in raw) {
    switch (node) {
      case _RawParagraph(:final text):
        final children = inlines.parse(text);
        if (children.isNotEmpty) {
          out.add(CcParagraph(children));
        }
      case _RawHeading(:final level, :final text):
        out.add(CcHeading(level: level, children: inlines.parse(text)));
      case _RawQuote(:final children):
        out.add(CcBlockquote(_finalizeRaw(children, inlines)));
      case _RawList(:final ordered, :final start, :final tight, :final items):
        out.add(
          CcList(
            ordered: ordered,
            start: start,
            tight: tight,
            items: [
              for (final item in items)
                CcListItem(
                  children: _finalizeRaw(item.children, inlines),
                  checked: item.checked,
                ),
            ],
          ),
        );
      case _RawTable(:final header, :final alignments, :final rows):
        out.add(
          CcTable(
            header: [
              for (final cell in header) CcTableCell(inlines.parse(cell)),
            ],
            alignments: alignments,
            rows: [
              for (final row in rows)
                [for (final cell in row) CcTableCell(inlines.parse(cell))],
            ],
          ),
        );
      case _RawDetails(:final summary, :final children, :final open):
        out.add(
          CcDetails(
            summary: inlines.parse(summary),
            children: _finalizeRaw(children, inlines),
            open: open,
          ),
        );
      case _RawFinished(:final node):
        out.add(node);
    }
  }
  return out;
}

/// Finalizes the collected raw footnote definitions in first-reference order.
///
/// [usedLabels] is the first-use order assigned by the resolver during inline
/// parsing; unreferenced definitions are dropped (GitHub behavior).
List<CcFootnoteDef> _finalizeFootnotes(
  List<(String, List<_Raw>)> rawFootnotes,
  List<String> usedLabels,
  CcInlineParser inlines,
) {
  final byLabel = <String, List<_Raw>>{};
  for (final (label, children) in rawFootnotes) {
    byLabel.putIfAbsent(label, () => children);
  }
  final out = <CcFootnoteDef>[];
  for (var i = 0; i < usedLabels.length; i++) {
    final children = byLabel[usedLabels[i]];
    if (children == null) {
      continue;
    }
    out.add(
      CcFootnoteDef(
        label: usedLabels[i],
        index: i + 1,
        children: _finalizeRaw(children, inlines),
      ),
    );
  }
  return out;
}

/// Labels of footnote definitions present in the raw collection.
Set<String> _footnoteLabels(List<(String, List<_Raw>)> rawFootnotes) => {
  for (final (label, _) in rawFootnotes) label,
};

/// Parses a whole markdown [source] into a [CcDocument]: block pass (raw
/// tree + link-ref/footnote collection), then the inline pass over every
/// leaf. This is the single parse entry point — `CcParser` wraps it.
CcDocument parseMarkdownDocument(
  String source, {
  CcParseOptions options = const CcParseOptions(),
  CcPluginSet plugins = CcPluginSet.empty,
}) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blockParser = _BlockParser(options: options, plugins: plugins);
  final raw = blockParser.parseRaw(lines);

  final defined = _footnoteLabels(blockParser.rawFootnotes);
  final usedLabels = <String>[];
  final inlines = CcInlineParser(
    options: options,
    plugins: plugins,
    linkRefs: blockParser.linkRefs,
    footnoteResolver: !options.footnotes
        ? null
        : (label) {
            if (!defined.contains(label)) {
              return -1;
            }
            var index = usedLabels.indexOf(label);
            if (index == -1) {
              usedLabels.add(label);
              index = usedLabels.length - 1;
            }
            return index + 1;
          },
  );

  final blocks = _finalizeRaw(raw, inlines);
  final footnotes = _finalizeFootnotes(
    blockParser.rawFootnotes,
    usedLabels,
    inlines,
  );
  return CcDocument(
    blocks: blocks,
    linkRefs: Map.unmodifiable(blockParser.linkRefs),
    footnotes: footnotes,
  );
}
