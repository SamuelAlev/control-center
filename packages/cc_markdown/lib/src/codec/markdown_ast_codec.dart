/// Codec between the typed [CcDocument] AST and a primitive `Map`/`List`/`String`
/// form, so a parsed document can cross an isolate / Web Worker boundary (which
/// only transfers primitives) and be reconstructed on the other side.
///
/// This is Flutter-free by construction (it touches only the pure AST types),
/// so it compiles into the `dart compile js` Web Worker together with the
/// parser. The `nodeType` string on every node is the encode discriminator;
/// decode is an exhaustive switch on it.
///
/// Open [CcCustomBlock]/[CcCustomInline] plugin nodes are intentionally NOT
/// supported: encoding one throws [UnsupportedError]. Callers offload only
/// plugin-free (GitHub-flavored) documents and treat a throw as "don't cache,
/// fall back to the synchronous parse" — so a plugin node can never be silently
/// dropped or mis-rendered.
library;

import 'package:cc_markdown/src/ast/document.dart';
import 'package:cc_markdown/src/ast/nodes.dart';

/// Encodes a parsed [doc] into a primitive map (JSON-shaped: only `String`,
/// `int`, `bool`, `null`, `List` and `Map<String, dynamic>`).
Map<String, dynamic> encodeCcDocument(CcDocument doc) => <String, dynamic>{
  'blocks': [for (final b in doc.blocks) _encodeBlock(b)],
  'linkRefs': {
    for (final e in doc.linkRefs.entries)
      e.key: <String, dynamic>{'url': e.value.url, 'title': e.value.title},
  },
  'footnotes': [for (final f in doc.footnotes) _encodeBlock(f)],
};

/// Reconstructs a [CcDocument] from [map] produced by [encodeCcDocument].
CcDocument decodeCcDocument(Map<String, dynamic> map) => CcDocument(
  blocks: [
    for (final b in map['blocks'] as List)
      _decodeBlock(b as Map<String, dynamic>),
  ],
  linkRefs: {
    for (final e in (map['linkRefs'] as Map).entries)
      e.key as String: CcLinkReference(
        url: (e.value as Map)['url'] as String,
        title: (e.value as Map)['title'] as String?,
      ),
  },
  footnotes: [
    for (final f in map['footnotes'] as List)
      _decodeBlock(f as Map<String, dynamic>) as CcFootnoteDef,
  ],
);

// ─── Inline ──────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _encodeInlines(List<CcInlineNode> nodes) => [
  for (final n in nodes) _encodeInline(n),
];

List<CcInlineNode> _decodeInlines(List<dynamic> list) => [
  for (final n in list) _decodeInline(n as Map<String, dynamic>),
];

/// Table cells stay a bare inline list for the common span-1 case; a
/// spanning cell wraps into `{'s': span, 'c': inlines}`.
Object _encodeTableCell(CcTableCell cell) => cell.span == 1
    ? _encodeInlines(cell.children)
    : {'s': cell.span, 'c': _encodeInlines(cell.children)};

CcTableCell _decodeTableCell(Object encoded) => encoded is Map
    ? CcTableCell(
        _decodeInlines(encoded['c'] as List),
        span: encoded['s'] as int,
      )
    : CcTableCell(_decodeInlines(encoded as List));

Map<String, dynamic> _encodeInline(CcInlineNode n) {
  switch (n) {
    case CcText():
      return {'t': n.nodeType, 'text': n.text};
    case CcSoftBreak():
      return {'t': n.nodeType};
    case CcHardBreak():
      return {'t': n.nodeType};
    case CcEmphasis():
      return {'t': n.nodeType, 'children': _encodeInlines(n.children)};
    case CcStrong():
      return {'t': n.nodeType, 'children': _encodeInlines(n.children)};
    case CcStrikethrough():
      return {'t': n.nodeType, 'children': _encodeInlines(n.children)};
    case CcInlineCode():
      return {'t': n.nodeType, 'code': n.code};
    case CcLink():
      return {
        't': n.nodeType,
        'url': n.url,
        'title': n.title,
        'autolink': n.autolink,
        'children': _encodeInlines(n.children),
      };
    case CcImage():
      return {'t': n.nodeType, 'url': n.url, 'alt': n.alt, 'title': n.title};
    case CcFootnoteRef():
      return {'t': n.nodeType, 'label': n.label, 'index': n.index};
    case CcInlineHtml():
      return {'t': n.nodeType, 'raw': n.raw};
    case CcCustomInline():
      throw UnsupportedError(
        'Cannot encode custom inline node "${n.nodeType}" — offload only '
        'plugin-free documents.',
      );
  }
}

CcInlineNode _decodeInline(Map<String, dynamic> m) {
  final children = m['children'];
  switch (m['t'] as String) {
    case 'text':
      return CcText(m['text'] as String);
    case 'soft_break':
      return const CcSoftBreak();
    case 'hard_break':
      return const CcHardBreak();
    case 'emphasis':
      return CcEmphasis(_decodeInlines(children as List));
    case 'strong':
      return CcStrong(_decodeInlines(children as List));
    case 'strikethrough':
      return CcStrikethrough(_decodeInlines(children as List));
    case 'inline_code':
      return CcInlineCode(m['code'] as String);
    case 'link':
      return CcLink(
        url: m['url'] as String,
        title: m['title'] as String?,
        autolink: m['autolink'] as bool,
        children: _decodeInlines(children as List),
      );
    case 'image':
      return CcImage(
        url: m['url'] as String,
        alt: m['alt'] as String,
        title: m['title'] as String?,
      );
    case 'footnote_ref':
      return CcFootnoteRef(
        label: m['label'] as String,
        index: m['index'] as int,
      );
    case 'inline_html':
      return CcInlineHtml(m['raw'] as String);
    default:
      throw UnsupportedError('Unknown inline nodeType "${m['t']}".');
  }
}

// ─── Block ─────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _encodeBlocks(List<CcBlockNode> nodes) => [
  for (final n in nodes) _encodeBlock(n),
];

List<CcBlockNode> _decodeBlocks(List<dynamic> list) => [
  for (final n in list) _decodeBlock(n as Map<String, dynamic>),
];

Map<String, dynamic> _encodeBlock(CcBlockNode n) {
  switch (n) {
    case CcParagraph():
      return {'t': n.nodeType, 'children': _encodeInlines(n.children)};
    case CcHeading():
      return {
        't': n.nodeType,
        'level': n.level,
        'children': _encodeInlines(n.children),
      };
    case CcCodeBlock():
      return {
        't': n.nodeType,
        'code': n.code,
        'language': n.language,
        'fenced': n.fenced,
        'closed': n.closed,
      };
    case CcMermaid():
      return {'t': n.nodeType, 'source': n.source};
    case CcBlockquote():
      return {'t': n.nodeType, 'children': _encodeBlocks(n.children)};
    case CcList():
      return {
        't': n.nodeType,
        'ordered': n.ordered,
        'start': n.start,
        'tight': n.tight,
        'items': [
          for (final it in n.items)
            <String, dynamic>{
              'checked': it.checked,
              'children': _encodeBlocks(it.children),
            },
        ],
      };
    case CcTable():
      return {
        't': n.nodeType,
        'header': [for (final c in n.header) _encodeTableCell(c)],
        'alignments': [for (final a in n.alignments) a?.index],
        'rows': [
          for (final row in n.rows) [for (final c in row) _encodeTableCell(c)],
        ],
      };
    case CcThematicBreak():
      return {'t': n.nodeType};
    case CcHtmlBlock():
      return {'t': n.nodeType, 'raw': n.raw};
    case CcDetails():
      return {
        't': n.nodeType,
        'open': n.open,
        'summary': _encodeInlines(n.summary),
        'children': _encodeBlocks(n.children),
      };
    case CcFootnoteDef():
      return {
        't': n.nodeType,
        'label': n.label,
        'index': n.index,
        'children': _encodeBlocks(n.children),
      };
    case CcCustomBlock():
      throw UnsupportedError(
        'Cannot encode custom block node "${n.nodeType}" — offload only '
        'plugin-free documents.',
      );
  }
}

CcBlockNode _decodeBlock(Map<String, dynamic> m) {
  switch (m['t'] as String) {
    case 'paragraph':
      return CcParagraph(_decodeInlines(m['children'] as List));
    case 'heading':
      return CcHeading(
        level: m['level'] as int,
        children: _decodeInlines(m['children'] as List),
      );
    case 'code_block':
      return CcCodeBlock(
        code: m['code'] as String,
        language: m['language'] as String?,
        fenced: m['fenced'] as bool,
        closed: m['closed'] as bool,
      );
    case 'mermaid':
      return CcMermaid(m['source'] as String);
    case 'blockquote':
      return CcBlockquote(_decodeBlocks(m['children'] as List));
    case 'list':
      return CcList(
        ordered: m['ordered'] as bool,
        start: m['start'] as int,
        tight: m['tight'] as bool,
        items: [
          for (final it in m['items'] as List)
            CcListItem(
              checked: (it as Map)['checked'] as bool?,
              children: _decodeBlocks(it['children'] as List),
            ),
        ],
      );
    case 'table':
      return CcTable(
        header: [
          for (final c in m['header'] as List) _decodeTableCell(c as Object),
        ],
        alignments: [
          for (final a in m['alignments'] as List)
            a == null ? null : CcTableAlign.values[a as int],
        ],
        rows: [
          for (final row in m['rows'] as List)
            [for (final c in row as List) _decodeTableCell(c as Object)],
        ],
      );
    case 'thematic_break':
      return const CcThematicBreak();
    case 'html_block':
      return CcHtmlBlock(m['raw'] as String);
    case 'details':
      return CcDetails(
        open: m['open'] as bool,
        summary: _decodeInlines(m['summary'] as List),
        children: _decodeBlocks(m['children'] as List),
      );
    case 'footnote_def':
      return CcFootnoteDef(
        label: m['label'] as String,
        index: m['index'] as int,
        children: _decodeBlocks(m['children'] as List),
      );
    default:
      throw UnsupportedError('Unknown block nodeType "${m['t']}".');
  }
}
