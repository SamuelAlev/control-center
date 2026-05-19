/// The inline (span-level) scanner: two CommonMark phases — a trigger-
/// dispatched scan producing a work list of finished nodes + delimiter runs,
/// then [processEmphasis] pairing.
///
/// Hot-loop discipline: `codeUnitAt` scanning, no 1-char string allocations,
/// plain-text accumulated by offset range and materialized once per flush.
library;

import 'package:cc_markdown/src/ast/document.dart';
import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/autolink_extension.dart';
import 'package:cc_markdown/src/parser/delimiter_stack.dart';
import 'package:cc_markdown/src/parser/emoji_shortcodes.dart';
import 'package:cc_markdown/src/parser/html_entities.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';

const int _backslash = 0x5C;
const int _backtick = 0x60;
const int _star = 0x2A;
const int _underscore = 0x5F;
const int _tilde = 0x7E;
const int _openBracket = 0x5B;
const int _closeBracket = 0x5D;
const int _bang = 0x21;
const int _lt = 0x3C;
const int _newline = 0x0A;
const int _space = 0x20;
const int _openParen = 0x28;
const int _closeParen = 0x29;
const int _amp = 0x26;
const int _quote = 0x22;
const int _apostrophe = 0x27;
const int _colon = 0x3A;
const int _zero = 0x30;
const int _nine = 0x39;
const int _lowerA = 0x61;
const int _lowerZ = 0x7A;
const int _plus = 0x2B;
const int _hyphen = 0x2D;

final RegExp _uriAutolink = RegExp(
  r'^<([A-Za-z][A-Za-z0-9+.\-]{1,31}:[^\s<>]*)>',
);
final RegExp _emailAutolink = RegExp(
  r"^<([A-Za-z0-9.!#$%&'*+/=?^_`{|}~\-]+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}"
  r'[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)*)>',
);
final RegExp _inlineHtmlTag = RegExp(
  r'^</?[A-Za-z][A-Za-z0-9\-]*(?:\s[^<>]*?)?/?>',
);
final RegExp _htmlComment = RegExp(r'^<!--[\s\S]*?-->');
final RegExp _anchorOpen = RegExp(r'^<a(\s[^<>]*)?>', caseSensitive: false);
final RegExp _anchorClose = RegExp(r'</a\s*>', caseSensitive: false);
final RegExp _hrefAttr = RegExp(
  r'''\bhref\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s<>]+))''',
  caseSensitive: false,
);
final RegExp _brTag = RegExp(r'^<br\s*/?>', caseSensitive: false);
final RegExp _footnoteLabel = RegExp(r'^\[\^([^\s\]]+)\]');

/// Resolves a footnote label to its 1-based render index, or -1 when the
/// label has no definition. Called only for syntactically valid refs; a
/// successful resolution registers first-use order.
typedef CcFootnoteResolver = int Function(String label);

class _Bracket {
  _Bracket({
    required this.itemIndex,
    required this.textPos,
    required this.image,
  });

  /// Index in the work list of the placeholder text item for `[` / `![`.
  final int itemIndex;

  /// Source position just after the bracket (start of the label text).
  final int textPos;

  final bool image;
  bool active = true;
}

/// The inline parser. One instance per document parse; [parse] is called per
/// leaf (paragraph, heading, table cell, …).
final class CcInlineParser {
  /// Creates a [CcInlineParser].
  CcInlineParser({
    required this.options,
    this.plugins = CcPluginSet.empty,
    this.linkRefs = const {},
    this.footnoteResolver,
  });

  /// Parse feature toggles.
  final CcParseOptions options;

  /// Current nesting depth of the inline pass (anchor unwrapping recurses).
  int _depth = 0;

  /// Registered inline plugins.
  final CcPluginSet plugins;

  /// Link-reference definitions collected by the block pass.
  final Map<String, CcLinkReference> linkRefs;

  /// Footnote resolution hook (null → footnote syntax is literal text).
  final CcFootnoteResolver? footnoteResolver;

  /// Parses [text] into finished inline nodes.
  List<CcInlineNode> parse(String text) {
    // Depth guard. The `<a href>` branch below re-enters `parse` on the anchor's
    // inner content, so `<a href=x>` repeated N times followed by one `</a>`
    // recursed N deep — a StackOverflowError (an `Error`, not an exception) in
    // an engine whose contract is "never throws", on input that arrives as
    // model output. Past the cap the text is emitted verbatim instead.
    if (_depth >= options.maxBlockDepth) {
      return text.isEmpty ? const [] : [CcText(text)];
    }
    _depth++;
    try {
      return _parse(text);
    } finally {
      _depth--;
    }
  }

  List<CcInlineNode> _parse(String text) {
    final items = <Object>[];
    final brackets = <_Bracket>[];
    var pos = 0;
    var textStart = 0;

    void flushText(int end) {
      if (end > textStart) {
        items.add(CcText(text.substring(textStart, end)));
      }
    }

    while (pos < text.length) {
      final unit = text.codeUnitAt(pos);

      // Plugins get first refusal on their trigger characters.
      final triggered = plugins.inlinePluginsFor(unit);
      if (triggered != null) {
        CcInlineParseResult? result;
        for (final plugin in triggered) {
          if (plugin.canParse(text, pos)) {
            result = plugin.parse(text, pos);
            if (result != null) {
              break;
            }
          }
        }
        if (result != null && result.consumed > 0) {
          flushText(pos);
          items.add(result.node);
          pos += result.consumed;
          textStart = pos;
          continue;
        }
      }

      switch (unit) {
        case _backslash:
          if (pos + 1 < text.length) {
            final next = text.codeUnitAt(pos + 1);
            if (next == _newline) {
              flushText(pos);
              items.add(const CcHardBreak());
              pos += 2;
              // Skip leading spaces of the next line.
              while (pos < text.length && text.codeUnitAt(pos) == _space) {
                pos++;
              }
              textStart = pos;
              continue;
            }
            if (ccIsPunctuation(next)) {
              flushText(pos);
              items.add(CcText(String.fromCharCode(next)));
              pos += 2;
              textStart = pos;
              continue;
            }
          }
          pos++;

        case _newline:
          // Trailing-space handling: 2+ spaces before \n = hard break.
          var spaceStart = pos;
          while (spaceStart > textStart &&
              text.codeUnitAt(spaceStart - 1) == _space) {
            spaceStart--;
          }
          flushText(spaceStart);
          items.add(
            pos - spaceStart >= 2 ? const CcHardBreak() : const CcSoftBreak(),
          );
          pos++;
          while (pos < text.length && text.codeUnitAt(pos) == _space) {
            pos++;
          }
          textStart = pos;

        case _backtick:
          final result = _parseCodeSpan(text, pos);
          if (result != null) {
            flushText(pos);
            items.add(result.$1);
            pos = result.$2;
            textStart = pos;
          } else {
            // Unmatched run: literal backticks.
            var end = pos;
            while (end < text.length && text.codeUnitAt(end) == _backtick) {
              end++;
            }
            pos = end;
          }

        case _star || _underscore || _tilde:
          var end = pos;
          while (end < text.length && text.codeUnitAt(end) == unit) {
            end++;
          }
          final count = end - pos;
          if (unit == _tilde && (!options.strikethrough || count != 2)) {
            pos = end;
            continue;
          }
          flushText(pos);
          items.add(
            classifyDelimiterRun(
              char: unit,
              count: count,
              before: pos > 0 ? text.codeUnitAt(pos - 1) : -1,
              after: end < text.length ? text.codeUnitAt(end) : -1,
            ),
          );
          pos = end;
          textStart = pos;

        case _openBracket:
          // Footnote reference?
          if (options.footnotes && footnoteResolver != null) {
            final m = _footnoteLabel.matchAsPrefix(text.substring(pos));
            if (m != null) {
              final label = m.group(1)!;
              final index = footnoteResolver!(label);
              if (index > 0) {
                flushText(pos);
                items.add(CcFootnoteRef(label: label, index: index));
                pos += m.group(0)!.length;
                textStart = pos;
                continue;
              }
            }
          }
          flushText(pos);
          items.add(const CcText('['));
          brackets.add(
            _Bracket(
              itemIndex: items.length - 1,
              textPos: pos + 1,
              image: false,
            ),
          );
          pos++;
          textStart = pos;

        case _bang:
          if (pos + 1 < text.length &&
              text.codeUnitAt(pos + 1) == _openBracket) {
            flushText(pos);
            items.add(const CcText('!['));
            brackets.add(
              _Bracket(
                itemIndex: items.length - 1,
                textPos: pos + 2,
                image: true,
              ),
            );
            pos += 2;
            textStart = pos;
          } else {
            pos++;
          }

        case _closeBracket:
          flushText(pos);
          textStart = pos;
          final closed = _tryCloseBracket(text, pos, items, brackets);
          if (closed != -1) {
            pos = closed;
            textStart = pos;
          } else {
            items.add(const CcText(']'));
            pos++;
            textStart = pos;
          }

        case _lt:
          final consumed = _parseAngle(text, pos, items);
          if (consumed > 0) {
            // _parseAngle flushed nothing itself — flush before its node.
            final node = items.removeLast();
            flushText(pos);
            items.add(node);
            pos += consumed;
            textStart = pos;
          } else {
            pos++;
          }

        case _colon:
          if (options.emoji) {
            final emoji = _parseEmojiShortcode(text, pos);
            if (emoji != null) {
              flushText(pos);
              items.add(CcText(emoji.$1));
              pos += emoji.$2;
              textStart = pos;
              continue;
            }
          }
          pos++;

        case _amp:
          final decoded = _parseEntity(text, pos);
          if (decoded != null) {
            flushText(pos);
            items.add(CcText(decoded.$1));
            pos += decoded.$2;
            textStart = pos;
          } else {
            pos++;
          }

        default:
          // Bare autolink extension (http/https/www).
          if (options.autolinkExtension &&
              (unit == 0x68 /* h */ || unit == 0x77 /* w */ )) {
            final match = tryParseBareAutolink(
              text,
              pos,
              pos > 0 ? text.codeUnitAt(pos - 1) : -1,
            );
            if (match != null) {
              flushText(pos);
              items.add(
                CcLink(
                  url: match.url,
                  children: [CcText(match.text)],
                  autolink: true,
                ),
              );
              pos += match.text.length;
              textStart = pos;
              continue;
            }
          }
          pos++;
      }
    }
    flushText(text.length);

    processEmphasis(items, 0);
    return flattenInlineItems(items);
  }

  /// Backtick code span: a run of N backticks closed by the next run of
  /// exactly N. Returns (node, new position) or null.
  (CcInlineCode, int)? _parseCodeSpan(String text, int start) {
    var openEnd = start;
    while (openEnd < text.length && text.codeUnitAt(openEnd) == _backtick) {
      openEnd++;
    }
    final runLength = openEnd - start;
    var scan = openEnd;
    while (scan < text.length) {
      if (text.codeUnitAt(scan) != _backtick) {
        scan++;
        continue;
      }
      var closeEnd = scan;
      while (closeEnd < text.length && text.codeUnitAt(closeEnd) == _backtick) {
        closeEnd++;
      }
      if (closeEnd - scan == runLength) {
        var content = text.substring(openEnd, scan).replaceAll('\n', ' ');
        // One-space trim rule: strip a single leading+trailing space when both
        // present and the content isn't all spaces.
        if (content.length >= 2 &&
            content.startsWith(' ') &&
            content.endsWith(' ') &&
            content.trim().isNotEmpty) {
          content = content.substring(1, content.length - 1);
        }
        return (CcInlineCode(content), closeEnd);
      }
      scan = closeEnd;
    }
    return null;
  }

  /// `<...>`: URI/email autolink, `<br>`, HTML comment, or tolerated inline
  /// HTML tag. Appends the produced node to [items] and returns consumed
  /// character count (0 = no match).
  int _parseAngle(String text, int pos, List<Object> items) {
    final rest = text.substring(pos);
    final uri = _uriAutolink.matchAsPrefix(rest);
    if (uri != null) {
      final url = uri.group(1)!;
      items.add(CcLink(url: url, children: [CcText(url)], autolink: true));
      return uri.group(0)!.length;
    }
    final email = _emailAutolink.matchAsPrefix(rest);
    if (email != null) {
      final addr = email.group(1)!;
      items.add(
        CcLink(url: 'mailto:$addr', children: [CcText(addr)], autolink: true),
      );
      return email.group(0)!.length;
    }
    final br = _brTag.matchAsPrefix(rest);
    if (br != null) {
      items.add(const CcHardBreak());
      return br.group(0)!.length;
    }
    final comment = _htmlComment.matchAsPrefix(rest);
    if (comment != null) {
      items.add(const CcText(''));
      return comment.group(0)!.length;
    }
    // HTML anchor with an href: parse into a real link (GitHub bodies —
    // Linear linkbacks, bot comments — carry `<a href>` routinely; the
    // generic tag tolerance below would strip it to plain text). Must be
    // checked before the tolerance, whose regex also matches `<a …>`.
    final anchor = _anchorOpen.matchAsPrefix(rest);
    if (anchor != null) {
      final close = _anchorClose.firstMatch(rest.substring(anchor.end));
      final href = _hrefAttr.firstMatch(anchor.group(1) ?? '');
      final url = href?.group(1) ?? href?.group(2) ?? href?.group(3) ?? '';
      if (close != null && url.isNotEmpty) {
        final inner = rest.substring(anchor.end, anchor.end + close.start);
        final children = parse(inner);
        items.add(
          CcLink(
            url: url,
            children: children.isEmpty ? [CcText(url)] : children,
          ),
        );
        return anchor.end + close.end;
      }
    }
    final tag = _inlineHtmlTag.matchAsPrefix(rest);
    if (tag != null) {
      items.add(CcInlineHtml(tag.group(0)!));
      return tag.group(0)!.length;
    }
    return 0;
  }

  /// `&name;` / `&#123;` / `&#x1F;` → (decoded, consumed) or null.
  (String, int)? _parseEntity(String text, int pos) =>
      decodeHtmlEntityAt(text, pos);

  /// `:shortcode:` → (emoji, consumed) or null.
  ///
  /// A colon is one of the commonest characters in prose (`Note:`, `12:30`,
  /// `http://`), so the scan bails on the first character outside gemoji's
  /// `[a-z0-9_+-]` alias grammar and never looks past the longest known name
  /// — the table is only consulted for a run that already closed. Nothing is
  /// allocated until then.
  ///
  /// Unknown names stay literal, which is how GitHub's custom image emoji
  /// (`:octocat:`) and any `a:b:c` text survive unchanged.
  (String, int)? _parseEmojiShortcode(String text, int start) {
    // Exclusive bound: the name may run to [kCcMaxEmojiShortcodeLength] and
    // the closing colon sits one past it.
    final maxEnd = start + kCcMaxEmojiShortcodeLength + 2;
    final limit = maxEnd < text.length ? maxEnd : text.length;
    for (var scan = start + 1; scan < limit; scan++) {
      final unit = text.codeUnitAt(scan);
      if (unit == _colon) {
        if (scan == start + 1) {
          return null; // `::`
        }
        final emoji = ccEmojiForShortcode(text.substring(start + 1, scan));
        return emoji == null ? null : (emoji, scan + 1 - start);
      }
      if (!_isShortcodeChar(unit)) {
        return null;
      }
    }
    return null;
  }

  /// gemoji's alias grammar — lowercase only, matching GitHub: `:Smile:` is
  /// not `:smile:` there either.
  static bool _isShortcodeChar(int unit) =>
      (unit >= _lowerA && unit <= _lowerZ) ||
      (unit >= _zero && unit <= _nine) ||
      unit == _underscore ||
      unit == _plus ||
      unit == _hyphen;

  /// Handles `]`: resolves the nearest bracket as an inline link/image,
  /// a reference link, or fails. Returns the new source position, or -1.
  int _tryCloseBracket(
    String text,
    int pos,
    List<Object> items,
    List<_Bracket> brackets,
  ) {
    if (brackets.isEmpty) {
      return -1;
    }
    final bracket = brackets.removeLast();
    if (!bracket.active) {
      return -1;
    }

    String? url;
    String? title;
    var end = -1;

    // Inline form: [label](dest "title")
    if (pos + 1 < text.length && text.codeUnitAt(pos + 1) == _openParen) {
      final parsed = _parseLinkSuffix(text, pos + 2);
      if (parsed != null) {
        url = parsed.$1;
        title = parsed.$2;
        end = parsed.$3;
      }
    }

    // Reference forms: [label][ref], [label][], [label]
    if (url == null) {
      String refLabel;
      var refEnd = pos + 1;
      if (pos + 1 < text.length && text.codeUnitAt(pos + 1) == _openBracket) {
        final close = text.indexOf(']', pos + 2);
        if (close != -1 && close - pos - 2 <= 999) {
          final explicit = text.substring(pos + 2, close);
          refLabel = explicit.isEmpty
              ? text.substring(bracket.textPos, pos)
              : explicit;
          refEnd = close + 1;
        } else {
          refLabel = text.substring(bracket.textPos, pos);
        }
      } else {
        refLabel = text.substring(bracket.textPos, pos);
      }
      final ref = linkRefs[normalizeLinkLabel(refLabel)];
      if (ref != null) {
        url = ref.url;
        title = ref.title;
        end = refEnd;
      }
    }

    if (url == null) {
      // Not a link: the bracket placeholder stays literal text.
      return -1;
    }

    // Children = everything after the bracket placeholder; pair emphasis
    // scoped to the label, then replace placeholder..end with one node.
    final labelItems = items.sublist(bracket.itemIndex + 1);
    items.removeRange(bracket.itemIndex, items.length);
    processEmphasis(labelItems, 0);
    final children = flattenInlineItems(labelItems);

    if (bracket.image) {
      items.add(CcImage(url: url, alt: _plainText(children), title: title));
    } else {
      items.add(CcLink(url: url, title: title, children: children));
      // Links cannot nest: deactivate enclosing link openers.
      for (final b in brackets) {
        if (!b.image) {
          b.active = false;
        }
      }
    }
    return end;
  }

  /// Parses `dest "title")` starting just after `(`. Returns
  /// (url, title, position after `)`).
  (String, String?, int)? _parseLinkSuffix(String text, int start) {
    var pos = start;
    while (pos < text.length && _isLinkWhitespace(text.codeUnitAt(pos))) {
      pos++;
    }
    if (pos >= text.length) {
      return null;
    }

    String url;
    if (text.codeUnitAt(pos) == _lt) {
      final close = text.indexOf('>', pos + 1);
      if (close == -1 || text.substring(pos + 1, close).contains('\n')) {
        return null;
      }
      url = text.substring(pos + 1, close);
      pos = close + 1;
    } else {
      final urlStart = pos;
      var depth = 0;
      while (pos < text.length) {
        final unit = text.codeUnitAt(pos);
        if (_isLinkWhitespace(unit)) {
          break;
        }
        if (unit == _openParen) {
          depth++;
        } else if (unit == _closeParen) {
          if (depth == 0) {
            break;
          }
          depth--;
        } else if (unit == _backslash && pos + 1 < text.length) {
          pos++;
        }
        pos++;
      }
      url = _unescape(text.substring(urlStart, pos));
      if (url.isEmpty) {
        return null;
      }
    }

    while (pos < text.length && _isLinkWhitespace(text.codeUnitAt(pos))) {
      pos++;
    }
    String? title;
    if (pos < text.length) {
      final unit = text.codeUnitAt(pos);
      if (unit == _quote || unit == _apostrophe || unit == _openParen) {
        final closeChar = unit == _openParen ? _closeParen : unit;
        var scan = pos + 1;
        while (scan < text.length && text.codeUnitAt(scan) != closeChar) {
          if (text.codeUnitAt(scan) == _backslash) {
            scan++;
          }
          scan++;
        }
        if (scan >= text.length) {
          return null;
        }
        title = _unescape(text.substring(pos + 1, scan));
        pos = scan + 1;
        while (pos < text.length && _isLinkWhitespace(text.codeUnitAt(pos))) {
          pos++;
        }
      }
    }
    if (pos >= text.length || text.codeUnitAt(pos) != _closeParen) {
      return null;
    }
    return (url, title, pos + 1);
  }

  static bool _isLinkWhitespace(int unit) =>
      unit == _space || unit == 0x09 || unit == _newline || unit == 0x0D;

  static String _unescape(String value) {
    if (!value.contains(r'\')) {
      return value;
    }
    final buf = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (unit == _backslash &&
          i + 1 < value.length &&
          ccIsPunctuation(value.codeUnitAt(i + 1))) {
        continue;
      }
      buf.writeCharCode(unit);
    }
    return buf.toString();
  }

  static String _plainText(List<CcInlineNode> nodes) {
    final buf = StringBuffer();
    void walk(List<CcInlineNode> list) {
      for (final node in list) {
        switch (node) {
          case CcText(:final text):
            buf.write(text);
          case CcInlineCode(:final code):
            buf.write(code);
          case CcEmphasis(:final children) ||
              CcStrong(:final children) ||
              CcStrikethrough(:final children) ||
              CcLink(:final children):
            walk(children);
          case CcImage(:final alt):
            buf.write(alt);
          case CcSoftBreak() || CcHardBreak():
            buf.write(' ');
          case CcFootnoteRef() || CcInlineHtml() || CcCustomInline():
            break;
        }
      }
    }

    walk(nodes);
    return buf.toString();
  }
}

/// Normalizes a link-reference label: case-folded, interior whitespace
/// collapsed, trimmed.
String normalizeLinkLabel(String label) =>
    label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
