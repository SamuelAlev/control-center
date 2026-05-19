/// Interprets the tolerated raw-HTML block subset that GitHub bot comments
/// emit — `<table>`, `<details>`/`<summary>`, headings, lists, `<pre>`,
/// `<blockquote>` and inline formatting — into first-class AST nodes, so a
/// coverage-report table renders as a real [CcTable] instead of tag-stripped
/// text soup.
///
/// Deliberately NOT a browser. A tolerant single-pass tokenizer builds a
/// small element tree (implicit `</td>`/`</tr>`/`</li>` closes, unquoted
/// attribute values, entity decoding, depth caps), then a converter maps the
/// known vocabulary onto existing nodes. Unrecognized elements are
/// transparent (their content survives); script/style-class content is
/// dropped; a chunk that yields no blocks at all returns null so the caller
/// keeps the raw [CcHtmlBlock] fallback. Never throws.
library;

import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/html_entities.dart';

/// Interpretation cap: beyond this the chunk stays a raw [CcHtmlBlock].
const int _maxInput = 1 << 20;

/// Element-tree depth cap; deeper open tags become transparent (children
/// attach to the capped ancestor) so conversion recursion stays bounded.
const int _maxTreeDepth = 64;

/// Inline conversion recursion cap; deeper content degrades to plain text.
const int _maxInlineDepth = 16;

/// Widest a single `colspan` is allowed to pad.
const int _maxColspan = 16;

// Anchor-free patterns — matched with `matchAsPrefix(raw, index)` so an 80KB
// single-line bot table is scanned without per-tag substring copies.
final RegExp _openTag = RegExp(
  r'<([a-zA-Z][a-zA-Z0-9-]*)((?:[^<>\x22\x27]|\x22[^\x22]*\x22|\x27[^\x27]*\x27)*?)(/?)>',
);
final RegExp _closeTag = RegExp(r'</([a-zA-Z][a-zA-Z0-9-]*)\s*>');
final RegExp _doctypeOrPi = RegExp(r'<[!?][^>]*>');
final RegExp _attr = RegExp(
  r'([a-zA-Z_:][a-zA-Z0-9_:.\-]*)\s*(?:=\s*(?:\x22([^\x22]*)\x22|\x27([^\x27]*)\x27|([^\s\x22\x27<>`]+)))?',
);
final RegExp _whitespaceRun = RegExp(r'[ \t\r\n\f]+');
final RegExp _codeLanguageClass = RegExp(r'language-([\w+#.\-]+)');

/// Void elements: never pushed onto the open stack.
const Set<String> _voidTags = {
  'area',
  'base',
  'br',
  'col',
  'embed',
  'hr',
  'img',
  'input',
  'link',
  'meta',
  'source',
  'track',
  'wbr',
};

/// Opening the key implicitly closes any open element in the value set first
/// (sloppy bot HTML: `<tr><td>a<td>b</tr>`).
const Map<String, Set<String>> _implicitlyCloses = {
  'li': {'li'},
  'td': {'td', 'th'},
  'th': {'td', 'th'},
  'tr': {'tr', 'td', 'th'},
  'thead': {'tr', 'td', 'th'},
  'tbody': {'tr', 'td', 'th', 'thead'},
  'tfoot': {'tr', 'td', 'th', 'thead', 'tbody'},
  'dt': {'dt', 'dd'},
  'dd': {'dt', 'dd'},
  'p': {'p'},
};

/// Elements whose entire content is dropped (rendering their text would be
/// worse than nothing).
const Set<String> _droppedTags = {
  'audio',
  'button',
  'canvas',
  'col',
  'colgroup',
  'embed',
  'head',
  'iframe',
  'input',
  'link',
  'meta',
  'noscript',
  'object',
  'option',
  'script',
  'select',
  'source',
  'style',
  'svg',
  'template',
  'textarea',
  'title',
  'track',
  'video',
};

/// Elements converted (or recursed into) at block level; anything else in
/// block position is inline content accumulated into an implicit paragraph.
const Set<String> _blockTags = {
  'address',
  'article',
  'aside',
  'blockquote',
  'caption',
  'center',
  'details',
  'dd',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hr',
  'li',
  'main',
  'menu',
  'nav',
  'ol',
  'p',
  'pre',
  'section',
  'summary',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'ul',
};

/// Attempts to interpret a tolerated raw-HTML chunk into first-class block
/// nodes. Returns null when nothing interpretable was found — the caller
/// keeps the [CcHtmlBlock] fallback.
List<CcBlockNode>? interpretHtmlBlock(String raw) {
  if (raw.length > _maxInput || !raw.contains('<')) {
    return null;
  }
  final root = _Element('#root');
  _buildTree(raw, root);
  final blocks = _blocksOf(root.children, 0);
  return blocks.isEmpty ? null : blocks;
}

// --- Element tree ------------------------------------------------------------

final class _Element {
  _Element(this.name, [Map<String, String>? attrs]) : attrs = attrs ?? const {};

  final String name;
  final Map<String, String> attrs;

  /// `_Element | String` (text already entity-decoded).
  final List<Object> children = [];
}

void _buildTree(String raw, _Element root) {
  final stack = <_Element>[root];
  final text = StringBuffer();
  var i = 0;

  void flushText() {
    if (text.isEmpty) {
      return;
    }
    stack.last.children.add(decodeHtmlEntities(text.toString()));
    text.clear();
  }

  while (i < raw.length) {
    final lt = raw.indexOf('<', i);
    if (lt == -1) {
      text.write(raw.substring(i));
      break;
    }
    text.write(raw.substring(i, lt));

    if (raw.startsWith('<!--', lt)) {
      flushText();
      final end = raw.indexOf('-->', lt + 4);
      i = end == -1 ? raw.length : end + 3;
      continue;
    }
    final close = _closeTag.matchAsPrefix(raw, lt);
    if (close != null) {
      flushText();
      final name = close.group(1)!.toLowerCase();
      for (var j = stack.length - 1; j >= 1; j--) {
        if (stack[j].name == name) {
          stack.removeRange(j, stack.length);
          break;
        }
      }
      i = close.end;
      continue;
    }
    final open = _openTag.matchAsPrefix(raw, lt);
    if (open != null) {
      flushText();
      final name = open.group(1)!.toLowerCase();
      final selfClosing = open.group(3) == '/' || _voidTags.contains(name);
      final closes = _implicitlyCloses[name];
      if (closes != null) {
        while (stack.length > 1 && closes.contains(stack.last.name)) {
          stack.removeLast();
        }
      }
      final element = _Element(name, _parseAttrs(open.group(2) ?? ''));
      stack.last.children.add(element);
      if (!selfClosing && stack.length < _maxTreeDepth) {
        stack.add(element);
      }
      i = open.end;
      continue;
    }
    final skip = _doctypeOrPi.matchAsPrefix(raw, lt);
    if (skip != null) {
      flushText();
      i = skip.end;
      continue;
    }
    // Literal `<`.
    text.write('<');
    i = lt + 1;
  }
  flushText();
}

Map<String, String> _parseAttrs(String source) {
  if (source.trim().isEmpty) {
    return const {};
  }
  final attrs = <String, String>{};
  for (final m in _attr.allMatches(source)) {
    final value = m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
    attrs.putIfAbsent(
      m.group(1)!.toLowerCase(),
      () => decodeHtmlEntities(value),
    );
  }
  return attrs;
}

// --- Block conversion ---------------------------------------------------------

List<CcBlockNode> _blocksOf(List<Object> children, int depth) {
  if (depth > _maxTreeDepth) {
    return const [];
  }
  final out = <CcBlockNode>[];
  final inline = <CcInlineNode>[];

  void flushParagraph() {
    _trimInline(inline);
    if (inline.isNotEmpty) {
      out.add(CcParagraph(List.of(inline)));
      inline.clear();
    }
  }

  for (final child in children) {
    if (child is String) {
      _appendText(inline, child);
      continue;
    }
    final element = child as _Element;
    if (_droppedTags.contains(element.name)) {
      continue;
    }
    if (!_blockTags.contains(element.name)) {
      _appendInline(inline, element, 0);
      continue;
    }
    flushParagraph();
    switch (element.name) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final content = _inlinesOf(element.children);
        if (content.isNotEmpty) {
          out.add(
            CcHeading(
              level: element.name.codeUnitAt(1) - 0x30,
              children: content,
            ),
          );
        }
      case 'hr':
        out.add(const CcThematicBreak());
      case 'pre':
        out.add(_codeBlockOf(element));
      case 'blockquote':
        final inner = _blocksOf(element.children, depth + 1);
        if (inner.isNotEmpty) {
          out.add(CcBlockquote(inner));
        }
      case 'ul' || 'ol' || 'menu':
        final list = _listOf(element, depth);
        if (list != null) {
          out.add(list);
        }
      case 'table':
        final table = _tableOf(element);
        if (table != null) {
          out.add(table);
        }
      case 'details':
        out.add(_detailsOf(element, depth));
      case 'p':
        if (element.children.any(
          (c) => c is _Element && _blockTags.contains(c.name),
        )) {
          out.addAll(_blocksOf(element.children, depth + 1));
        } else {
          final content = _inlinesOf(element.children);
          if (content.isNotEmpty) {
            out.add(CcParagraph(content));
          }
        }
      default:
        // div/center/section/… and stray table/list internals: transparent.
        out.addAll(_blocksOf(element.children, depth + 1));
    }
  }
  flushParagraph();
  return out;
}

CcDetails _detailsOf(_Element element, int depth) {
  _Element? summary;
  final rest = <Object>[];
  for (final child in element.children) {
    if (summary == null && child is _Element && child.name == 'summary') {
      summary = child;
    } else {
      rest.add(child);
    }
  }
  return CcDetails(
    summary: summary == null ? const [] : _inlinesOf(summary.children),
    children: _blocksOf(rest, depth + 1),
    open: element.attrs.containsKey('open'),
  );
}

CcList? _listOf(_Element element, int depth) {
  final items = <CcListItem>[];
  for (final child in element.children) {
    if (child is _Element && child.name == 'li') {
      items.add(CcListItem(children: _blocksOf(child.children, depth + 1)));
    }
  }
  if (items.isEmpty) {
    return null;
  }
  return CcList(
    ordered: element.name == 'ol',
    start: int.tryParse(element.attrs['start'] ?? '') ?? 1,
    items: items,
  );
}

CcCodeBlock _codeBlockOf(_Element element) {
  String? language;
  var body = element.children;
  if (body.length == 1) {
    final only = body.first;
    if (only is _Element && only.name == 'code') {
      language = _codeLanguageClass
          .firstMatch(only.attrs['class'] ?? '')
          ?.group(1);
      body = only.children;
    }
  }
  var code = _rawTextOf(body);
  // `<pre>` conventionally starts content on the line after the tag.
  if (code.startsWith('\n')) {
    code = code.substring(1);
  }
  if (code.endsWith('\n')) {
    code = code.substring(0, code.length - 1);
  }
  return CcCodeBlock(code: code, language: language);
}

CcTable? _tableOf(_Element element) {
  final headerRows = <_Element>[];
  final bodyRows = <_Element>[];
  void collect(_Element parent, {required bool head}) {
    for (final child in parent.children) {
      if (child is! _Element) {
        continue;
      }
      switch (child.name) {
        case 'tr':
          (head ? headerRows : bodyRows).add(child);
        case 'thead':
          collect(child, head: true);
        case 'tbody' || 'tfoot':
          collect(child, head: false);
      }
    }
  }

  collect(element, head: false);
  // A headerless `<table><tr>…` promotes its first row: [CcTable] has no
  // headerless form and a styled first row beats a phantom empty band.
  if (headerRows.isEmpty && bodyRows.isNotEmpty) {
    headerRows.add(bodyRows.removeAt(0));
  }
  if (headerRows.isEmpty && bodyRows.isEmpty) {
    return null;
  }
  // Multi-row <thead>: first row is the header, the rest join the body.
  final headerRow = headerRows.isNotEmpty ? headerRows.first : null;
  final extraBody = [...headerRows.skip(1), ...bodyRows];

  (List<CcTableCell>, List<CcTableAlign?>) cellsOf(_Element tr) {
    final cells = <CcTableCell>[];
    final aligns = <CcTableAlign?>[];
    for (final child in tr.children) {
      if (child is! _Element || (child.name != 'td' && child.name != 'th')) {
        continue;
      }
      final span = (int.tryParse(child.attrs['colspan'] ?? '') ?? 1).clamp(
        1,
        _maxColspan,
      );
      cells.add(CcTableCell(_inlinesOf(child.children), span: span));
      aligns.add(switch (child.attrs['align']?.toLowerCase()) {
        'center' => CcTableAlign.center,
        'right' => CcTableAlign.right,
        'left' => CcTableAlign.left,
        _ => null,
      });
      for (var s = 1; s < span; s++) {
        cells.add(const CcTableCell([]));
        aligns.add(null);
      }
    }
    return (cells, aligns);
  }

  final (header, headerAligns) = headerRow != null
      ? cellsOf(headerRow)
      : (const <CcTableCell>[], const <CcTableAlign?>[]);
  final rows = <List<CcTableCell>>[];
  final rowAligns = <List<CcTableAlign?>>[];
  for (final tr in extraBody) {
    final (cells, aligns) = cellsOf(tr);
    if (cells.isNotEmpty) {
      rows.add(cells);
      rowAligns.add(aligns);
    }
  }
  if (header.isEmpty && rows.isEmpty) {
    return null;
  }

  var width = header.length;
  for (final row in rows) {
    if (row.length > width) {
      width = row.length;
    }
  }
  // Column alignment: header cell first, else the first aligned body cell.
  final alignments = List<CcTableAlign?>.generate(width, (i) {
    if (i < headerAligns.length && headerAligns[i] != null) {
      return headerAligns[i];
    }
    for (final aligns in rowAligns) {
      if (i < aligns.length && aligns[i] != null) {
        return aligns[i];
      }
    }
    return null;
  });
  List<CcTableCell> pad(List<CcTableCell> row) => [
    ...row,
    for (var i = row.length; i < width; i++) const CcTableCell([]),
  ];
  return CcTable(
    header: pad(header),
    alignments: alignments,
    rows: [for (final row in rows) pad(row)],
  );
}

// --- Inline conversion --------------------------------------------------------

List<CcInlineNode> _inlinesOf(List<Object> children) {
  final out = <CcInlineNode>[];
  for (final child in children) {
    if (child is String) {
      _appendText(out, child);
    } else {
      _appendInline(out, child as _Element, 0);
    }
  }
  _trimInline(out);
  return out;
}

void _appendText(List<CcInlineNode> out, String text) {
  var collapsed = text.replaceAll(_whitespaceRun, ' ');
  if (out.isEmpty || out.last is CcHardBreak) {
    collapsed = collapsed.trimLeft();
  } else if (collapsed.startsWith(' ')) {
    final last = out.last;
    if (last is CcText && last.text.endsWith(' ')) {
      collapsed = collapsed.trimLeft();
      if (collapsed.isEmpty) {
        return;
      }
    }
  }
  if (collapsed.isEmpty) {
    return;
  }
  out.add(CcText(collapsed));
}

void _appendInline(List<CcInlineNode> out, _Element element, int depth) {
  if (_droppedTags.contains(element.name)) {
    return;
  }
  if (depth > _maxInlineDepth) {
    _appendText(out, _rawTextOf(element.children));
    return;
  }

  List<CcInlineNode> childInlines() {
    final children = <CcInlineNode>[];
    for (final child in element.children) {
      if (child is String) {
        _appendText(children, child);
      } else {
        _appendInline(children, child as _Element, depth + 1);
      }
    }
    return children;
  }

  switch (element.name) {
    case 'br':
      out.add(const CcHardBreak());
    case 'em' || 'i' || 'cite' || 'var' || 'dfn':
      final children = childInlines();
      if (children.isNotEmpty) {
        out.add(CcEmphasis(children));
      }
    case 'strong' || 'b':
      final children = childInlines();
      if (children.isNotEmpty) {
        out.add(CcStrong(children));
      }
    case 'del' || 's' || 'strike':
      final children = childInlines();
      if (children.isNotEmpty) {
        out.add(CcStrikethrough(children));
      }
    case 'code' || 'tt' || 'kbd' || 'samp':
      final code = _rawTextOf(
        element.children,
      ).replaceAll(_whitespaceRun, ' ').trim();
      if (code.isNotEmpty) {
        out.add(CcInlineCode(code));
      }
    case 'a':
      final href = element.attrs['href'] ?? '';
      final children = childInlines();
      if (href.isEmpty) {
        out.addAll(children);
      } else {
        out.add(
          CcLink(
            url: href,
            title: element.attrs['title'],
            children: children.isEmpty ? [CcText(href)] : children,
          ),
        );
      }
    case 'img':
      final src = element.attrs['src'] ?? '';
      final alt = element.attrs['alt'] ?? '';
      if (src.isNotEmpty) {
        out.add(CcImage(url: src, alt: alt, title: element.attrs['title']));
      } else if (alt.isNotEmpty) {
        _appendText(out, alt);
      }
    default:
      // Misnested block content in inline position (a table inside a cell, a
      // list inside a summary) flattens — keep rows/items visually separated.
      if (_blockTags.contains(element.name)) {
        if ((element.name == 'tr' ||
                element.name == 'li' ||
                element.name == 'p') &&
            out.isNotEmpty &&
            out.last is! CcHardBreak) {
          out.add(const CcHardBreak());
        }
        if (element.name == 'li') {
          _appendText(out, '• ');
        }
      }
      // span/font/sub/sup/small/u/ins/abbr/…: transparent.
      for (final child in element.children) {
        if (child is String) {
          _appendText(out, child);
        } else {
          _appendInline(out, child as _Element, depth + 1);
        }
      }
  }
}

/// Trims leading/trailing whitespace and breaks off an inline run.
void _trimInline(List<CcInlineNode> out) {
  while (out.isNotEmpty) {
    final last = out.last;
    if (last is CcHardBreak) {
      out.removeLast();
      continue;
    }
    if (last is CcText) {
      final trimmed = last.text.trimRight();
      if (trimmed.isEmpty) {
        out.removeLast();
        continue;
      }
      if (trimmed != last.text) {
        out[out.length - 1] = CcText(trimmed);
      }
    }
    break;
  }
  while (out.isNotEmpty) {
    final first = out.first;
    if (first is CcHardBreak) {
      out.removeAt(0);
      continue;
    }
    if (first is CcText) {
      final trimmed = first.text.trimLeft();
      if (trimmed.isEmpty) {
        out.removeAt(0);
        continue;
      }
      if (trimmed != first.text) {
        out[0] = CcText(trimmed);
      }
    }
    break;
  }
}

/// Concatenated text content (whitespace preserved); `<br>` becomes `\n`.
String _rawTextOf(List<Object> children) {
  final buffer = StringBuffer();
  void walk(List<Object> nodes, int depth) {
    if (depth > _maxTreeDepth) {
      return;
    }
    for (final child in nodes) {
      if (child is String) {
        buffer.write(child);
      } else if (child is _Element) {
        if (child.name == 'br') {
          buffer.write('\n');
        } else if (!_droppedTags.contains(child.name)) {
          walk(child.children, depth + 1);
        }
      }
    }
  }

  walk(children, 0);
  return buffer.toString();
}
