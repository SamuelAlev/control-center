/// Text normalization for the vision compaction bitmap renderer.
///
/// The pixel font only carries printable ASCII (`0x20`–`0x7E`), so every
/// character that reaches the renderer must first be folded to that single-cell
/// alphabet. [normalizeForBitmap] strips ANSI escapes, collapses whitespace
/// (newline-bearing runs become the [newlineGlyph] sentinel so line structure
/// survives), folds common Unicode punctuation/symbols to ASCII, replaces other
/// non-ASCII graphic characters with `?`, and drops control characters — while
/// letting the zero-width [dimOn]/[dimOff] ink toggles pass through untouched so
/// downstream rendering can dim tool-output spans.
library;

/// Sentinel marking a hard line break. The renderer treats this as "advance to
/// the next row" rather than drawing a glyph. Chosen as `█` (U+2588) so it is
/// visually distinct in serialized text and never collides with real content
/// after folding (it is preserved verbatim by [normalizeForBitmap]).
const String newlineGlyph = '█';

/// Zero-width "dim ink on" toggle (ASCII Shift-Out, `0x0E`). Spans between
/// [dimOn] and [dimOff] render in mid-gray instead of black. Not drawn as a
/// glyph and not counted as a visible cell.
const String dimOn = '';

/// Zero-width "dim ink off" toggle (ASCII Shift-In, `0x0F`); closes a [dimOn]
/// span. Not drawn as a glyph and not counted as a visible cell.
const String dimOff = '';

/// Punctuation and symbol folds applied before the `?` fallback: smart quotes,
/// dashes, ellipses, bullets, and arrows that have no plain-ASCII equivalent
/// otherwise. Keyed by the single source code unit.
const Map<String, String> _charFold = <String, String>{
  // Quotation marks and primes.
  '‘': "'",
  '’': "'",
  '‚': "'",
  '‛': "'",
  '“': '"',
  '”': '"',
  '„': '"',
  '′': "'",
  '″': '"',
  '‹': '<',
  '›': '>',
  // Dashes and hyphens.
  '‐': '-',
  '‑': '-',
  '‒': '-',
  '–': '-',
  '—': '-',
  '―': '-',
  '−': '-',
  // Dot leaders and ellipses.
  '․': '.',
  '‥': '..',
  '…': '...',
  '⋯': '...',
  // Bullets.
  '•': '*',
  '‣': '*',
  '⁃': '-',
  '∙': '*',
  '●': '*',
  '■': '*',
  '▪': '*',
  // Arrows.
  '←': '<-',
  '↑': '^',
  '→': '->',
  '↓': 'v',
  '↔': '<->',
  '⇐': '<=',
  '⇒': '=>',
  '⇔': '<=>',
  // Check marks and crosses.
  '✓': 'v',
  '✔': 'v',
  '✗': 'x',
  '✘': 'x',
  // Non-breaking space folds to a plain space.
  ' ': ' ',
};

/// Matches ANSI/VT escape sequences (CSI, OSC, and bare escapes).
final RegExp _ansiEscape = RegExp(
  r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~]|\][^\x07\x1B]*(?:\x07|\x1B\\))',
);

/// Leading or trailing spaces / newline glyphs carry no information on a frame.
final RegExp _edgeRuns = RegExp('^[ $newlineGlyph]+|[ $newlineGlyph]+\$');

/// Folds [text] to the printable single-cell ASCII the pixel font can render.
///
/// Steps, in order:
/// 1. Strip ANSI escape sequences.
/// 2. Collapse each maximal whitespace run: a run containing a line break
///    becomes one [newlineGlyph]; any other whitespace run becomes a single
///    space.
/// 3. For every remaining character: printable ASCII passes through; the
///    [dimOn]/[dimOff]/[newlineGlyph] sentinels pass through; characters in
///    [_charFold] are replaced by their ASCII fold; other non-ASCII graphic
///    characters become `?`; control characters are dropped.
/// 4. Trim leading/trailing spaces and newline glyphs.
String normalizeForBitmap(String text) {
  final stripped = text.contains('')
      ? text.replaceAll(_ansiEscape, '')
      : text;
  final collapsed = _collapseWhitespace(stripped);

  final buffer = StringBuffer();
  for (final rune in collapsed.runes) {
    final ch = String.fromCharCode(rune);
    if (rune >= 0x20 && rune < 0x7f) {
      buffer.write(ch);
      continue;
    }
    if (ch == dimOn || ch == dimOff || ch == newlineGlyph) {
      buffer.write(ch);
      continue;
    }
    final fold = _charFold[ch];
    if (fold != null) {
      buffer.write(fold);
      continue;
    }
    if (rune >= 0x2500 && rune <= 0x257f) {
      // Box drawing: keep table skeletons legible.
      if (rune == 0x2502 || rune == 0x2503) {
        buffer.write('|');
      } else if (rune == 0x2500 || rune == 0x2501) {
        buffer.write('-');
      } else {
        buffer.write('+');
      }
      continue;
    }
    if (_isControl(rune)) {
      // Drop control / format characters outright (no cell).
      continue;
    }
    // Any other graphic character the font cannot draw.
    buffer.write('?');
  }
  return buffer.toString().replaceAll(_edgeRuns, '');
}

/// Collapses whitespace runs: newline-bearing runs to [newlineGlyph], other
/// whitespace runs to a single space. Sentinels and non-whitespace pass through.
String _collapseWhitespace(String text) {
  final buffer = StringBuffer();
  var inRun = false;
  var runHasBreak = false;
  for (final rune in text.runes) {
    if (_isWhitespace(rune)) {
      inRun = true;
      if (rune == 0x0a ||
          rune == 0x0d ||
          rune == 0x2028 ||
          rune == 0x2029) {
        runHasBreak = true;
      }
      continue;
    }
    if (inRun) {
      buffer.write(runHasBreak ? newlineGlyph : ' ');
      inRun = false;
      runHasBreak = false;
    }
    buffer.writeCharCode(rune);
  }
  if (inRun) {
    buffer.write(runHasBreak ? newlineGlyph : ' ');
  }
  return buffer.toString();
}

/// Whether [rune] is ASCII/Unicode whitespace the collapse pass folds. The
/// no-break space (`0xA0`) is intentionally excluded so it folds to a space via
/// [_charFold] like any other punctuation.
bool _isWhitespace(int rune) {
  switch (rune) {
    case 0x09: // tab
    case 0x0a: // line feed
    case 0x0b: // vertical tab
    case 0x0c: // form feed
    case 0x0d: // carriage return
    case 0x20: // space
    case 0x2028: // line separator
    case 0x2029: // paragraph separator
      return true;
    default:
      return false;
  }
}

/// Whether [rune] is a control or zero-width format character that should be
/// dropped. The [dimOn]/[dimOff] sentinels (`0x0E`/`0x0F`) are handled by the
/// caller before this check, so they are never dropped here.
bool _isControl(int rune) {
  if (rune < 0x20) {
    return true;
  }
  if (rune >= 0x7f && rune <= 0x9f) {
    return true;
  }
  // Zero-width / BOM / directional formatting marks.
  if (rune == 0x200b ||
      rune == 0x200c ||
      rune == 0x200d ||
      rune == 0x200e ||
      rune == 0x200f ||
      rune == 0xfeff) {
    return true;
  }
  return false;
}

/// Strips stray [dimOn]/[dimOff] toggles from raw content so it cannot forge a
/// dim span that bleeds into surrounding serialized text.
String stripDimMarkers(String text) =>
    text.replaceAll(dimOn, '').replaceAll(dimOff, '');
