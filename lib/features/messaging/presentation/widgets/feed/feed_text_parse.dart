part of 'feed_text_measure.dart';

/// Splits [source] into blocks, starting no new block once [charBudget]
/// characters have been consumed.
_ParseResult _parseBlocks(String source, int charBudget) {
  final lines = _LineReader(source);
  final blocks = <_Block>[];
  final paragraph = <String>[];
  _ListBlock? list;
  var blankSinceList = false;
  // Characters of over-long lines cut at the budget: read past, never laid
  // out, so they count as unmeasured for the extrapolation.
  var dropped = 0;

  /// [line] cut to what is left of the budget.
  String withinBudget(String line) {
    final keep = math.max(0, charBudget - lines.consumed);
    if (line.length <= keep) {
      return line;
    }
    dropped += line.length - keep;
    return line.substring(0, keep);
  }

  void flushParagraph() {
    if (paragraph.isNotEmpty) {
      blocks.add(_Paragraph(paragraph.join('\n')));
      paragraph.clear();
    }
  }

  void closeList() {
    list = null;
    blankSinceList = false;
  }

  while (lines.hasNext) {
    if (lines.consumed >= charBudget) {
      break;
    }
    final line = lines.peek();
    if (line.trim().isEmpty) {
      lines.skip();
      flushParagraph();
      if (list != null) {
        blankSinceList = true;
      }
      continue;
    }

    final fence = _fenceOpen.firstMatch(line);
    if (fence != null) {
      flushParagraph();
      closeList();
      lines.skip();
      final marker = fence[1]!;
      final labeled = (fence[2] ?? '').trim().isNotEmpty;
      var count = 0;
      var chars = 0;
      while (lines.hasNext) {
        final body = lines.next();
        final trimmed = body.trimLeft();
        if (trimmed.startsWith(marker) &&
            trimmed.replaceAll(marker[0], '').trim().isEmpty) {
          break;
        }
        count++;
        chars += body.length + 1;
      }
      blocks.add(
        _Code(lineCount: math.max(1, count), chars: chars, labeled: labeled),
      );
      continue;
    }

    final heading = _heading.firstMatch(line);
    if (heading != null) {
      flushParagraph();
      closeList();
      lines.skip();
      blocks.add(_Heading(heading[1]!.length, heading[2] ?? ''));
      continue;
    }

    if (_rule.hasMatch(line)) {
      flushParagraph();
      closeList();
      lines.skip();
      blocks.add(const _Rule());
      continue;
    }

    final quote = _quote.firstMatch(line);
    if (quote != null) {
      flushParagraph();
      closeList();
      final inner = StringBuffer(quote[1] ?? '');
      lines.skip();
      while (lines.hasNext) {
        final next = _quote.firstMatch(lines.peek());
        if (next == null) {
          break;
        }
        inner
          ..write('\n')
          ..write(next[1] ?? '');
        lines.skip();
      }
      final nested = _parseBlocks(
        inner.toString(),
        math.max(1, charBudget - lines.consumed),
      );
      dropped += inner.length - nested.consumedChars;
      blocks.add(_Quote(nested.blocks));
      continue;
    }

    final item = _listItem.firstMatch(line);
    if (item != null) {
      flushParagraph();
      final depth = math.min(4, _indentWidth(item[1]!) ~/ 2);
      final text = withinBudget(item[2] ?? '');
      final current = list;
      if (current == null) {
        final created = _ListBlock([_ListItem(depth, text)]);
        list = created;
        blocks.add(created);
      } else {
        if (blankSinceList) {
          current.tight = false;
        }
        current.items.add(_ListItem(depth, text));
      }
      blankSinceList = false;
      lines.skip();
      continue;
    }

    final current = list;
    if (current != null) {
      // An indented line continues the open item (after a blank line too); an
      // unindented one continues it only lazily, with no blank in between.
      final indented = _indentWidth(line) >= 2;
      if (indented || !blankSinceList) {
        if (blankSinceList) {
          current.tight = false;
        }
        final last = current.items.last;
        final text = withinBudget(line.trim());
        last.text = last.text.isEmpty ? text : '${last.text}\n$text';
        blankSinceList = false;
        lines.skip();
        continue;
      }
      closeList();
    }

    final trimmed = line.trim();
    if (paragraph.isEmpty && trimmed.startsWith('|') && trimmed.length > 1) {
      final rows = <List<String>>[];
      while (lines.hasNext) {
        final row = lines.peek().trim();
        if (!row.startsWith('|')) {
          break;
        }
        lines.skip();
        final cells = _tableCells(row);
        if (cells.every(_tableSeparatorCell.hasMatch)) {
          continue;
        }
        rows.add(cells);
      }
      blocks.add(_Table(rows));
      continue;
    }

    paragraph.add(withinBudget(line));
    lines.skip();
  }
  flushParagraph();
  return _ParseResult(
    blocks,
    math.max(0, math.min(lines.consumed, source.length) - dropped),
  );
}

/// The cells of a `| a | b |` table row.
List<String> _tableCells(String row) {
  var body = row;
  if (body.startsWith('|')) {
    body = body.substring(1);
  }
  if (body.endsWith('|')) {
    body = body.substring(0, body.length - 1);
  }
  return [for (final cell in body.split('|')) cell.trim()];
}

/// Leading whitespace width, a tab counting as four columns.
int _indentWidth(String text) {
  var width = 0;
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit == 0x20) {
      width++;
    } else if (unit == 0x09) {
      width += 4;
    } else {
      break;
    }
  }
  return width;
}

/// Forward-only line cursor over a string, without splitting it up front.
class _LineReader {
  _LineReader(this._source);

  final String _source;
  int _pos = 0;
  String? _peeked;
  int _peekEnd = 0;

  /// Characters consumed so far, newlines included.
  int get consumed => _pos;

  bool get hasNext => _pos < _source.length;

  String peek() {
    final cached = _peeked;
    if (cached != null) {
      return cached;
    }
    var end = _source.indexOf('\n', _pos);
    if (end < 0) {
      end = _source.length;
    }
    final line = _source.substring(_pos, end);
    _peeked = line;
    _peekEnd = end;
    return line;
  }

  String next() {
    final line = peek();
    skip();
    return line;
  }

  void skip() {
    peek();
    _pos = _peekEnd + 1;
    _peeked = null;
  }
}
