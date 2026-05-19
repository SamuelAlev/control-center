/// The incremental block-boundary scanner behind streaming rendering.
///
/// Append-only text is scanned line by line — only COMPLETE lines are ever
/// consumed, so [scanPos] always sits at a line start and each append costs
/// O(delta), never O(accumulated text). [boundary] is the last offset where
/// the text can be safely split into a sealed prefix and a volatile tail:
///
///   * never inside a fenced code block,
///   * never inside a `<details>` block,
///   * a blank line only *pends* a boundary — it becomes one when the next
///     non-blank complete line proves the previous construct cannot continue
///     (an indented continuation or list-marker line keeps a list open, so
///     loose lists no longer transiently mis-split).
///
/// Pure Dart — usable from tests and benchmarks without Flutter.
final class CcBlockBoundaryScanner {
  /// Offset scanned so far (always at a line start).
  int get scanPos => _scanPos;
  int _scanPos = 0;

  /// The last safe seal offset.
  int get boundary => _boundary;
  int _boundary = 0;

  /// Whether the scanner is currently INSIDE an unclosed fenced code block.
  ///
  /// While this is true the [boundary] cannot advance, so the volatile tail is
  /// the entire fence so far — which is what makes a long streamed code block
  /// quadratic unless the renderer special-cases it.
  bool get inFence => _inFence;
  bool _inFence = false;

  /// Offset of the line that OPENED the current fence, or -1 when not in one.
  /// Lets a renderer build the open code block directly instead of re-parsing
  /// the whole fence on every delta.
  int get fenceOpenOffset => _inFence ? _fenceOpenOffset : -1;
  int _fenceOpenOffset = -1;

  /// Offset just past the opening fence's info line (where the code starts).
  int get fenceBodyOffset => _inFence ? _fenceBodyOffset : -1;
  int _fenceBodyOffset = -1;

  /// The opening fence's info string (`dart`, `mermaid`, …), empty when none.
  String get fenceInfo => _inFence ? _fenceInfo : '';
  String _fenceInfo = '';

  String _fenceMarker = '';
  int _fenceLen = 0;
  int _detailsDepth = 0;

  /// Offset of a blank line awaiting confirmation, or -1.
  int _pendingBoundary = -1;

  /// Whether the last non-blank line looked like list/indented content whose
  /// construct could continue across a blank line.
  bool _lastLineContinuable = false;

  static final RegExp _listMarker = RegExp(r'^ {0,3}([-*+]|\d{1,9}[.)])[ \t]');
  static final RegExp _detailsOpen = RegExp(
    r'^ {0,3}<details(\s[^>]*)?>[ \t]*$',
    caseSensitive: false,
  );
  static final RegExp _detailsClose = RegExp(
    r'^ {0,3}</details>[ \t]*$',
    caseSensitive: false,
  );

  /// Continues scanning [text] from [scanPos]. Call after every append.
  void scan(String text) {
    var pos = _scanPos;
    while (true) {
      final nl = text.indexOf('\n', pos);
      if (nl == -1) {
        break;
      }
      _scanLine(text.substring(pos, nl), nl + 1);
      pos = nl + 1;
    }
    _scanPos = pos;
  }

  /// Resets all state (for a non-append rewrite).
  void reset() {
    _scanPos = 0;
    _boundary = 0;
    _inFence = false;
    _fenceOpenOffset = -1;
    _fenceBodyOffset = -1;
    _fenceInfo = '';
    _detailsDepth = 0;
    _pendingBoundary = -1;
    _lastLineContinuable = false;
  }

  /// Resolves a boundary pended by a blank line, now that [line] — the next
  /// non-blank line — shows whether the previous construct continues.
  void _confirmPendingBoundary(String line) {
    if (_pendingBoundary == -1) {
      return;
    }
    final continuesConstruct =
        _lastLineContinuable &&
        (_indentOf(line) >= 2 || _listMarker.hasMatch(line));
    if (!continuesConstruct) {
      _boundary = _pendingBoundary;
    }
    _pendingBoundary = -1;
  }

  void _scanLine(String line, int endOffset) {
    final trimmed = line.trimLeft();

    if (_inFence) {
      var n = 0;
      while (n < trimmed.length && trimmed[n] == _fenceMarker) {
        n++;
      }
      if (n >= _fenceLen && trimmed.substring(n).trim().isEmpty) {
        _inFence = false;
      }
      return;
    }

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      // A fence opener is a non-blank line like any other, so it CONFIRMS a
      // pending boundary rather than discarding it — subject to the same
      // continuation test, because an indented fence inside a list item does
      // continue that list. Discarding it meant the prose before a code block
      // could not seal until the fence CLOSED, so the volatile tail carried
      // that prose through a full re-parse on every delta of the code block.
      _confirmPendingBoundary(line);
      _fenceMarker = trimmed[0];
      var n = 0;
      while (n < trimmed.length && trimmed[n] == _fenceMarker) {
        n++;
      }
      _fenceLen = n;
      _inFence = true;
      _fenceOpenOffset = endOffset - line.length - 1;
      _fenceBodyOffset = endOffset;
      _fenceInfo = trimmed.substring(n).trim();
      _lastLineContinuable = false;
      return;
    }

    if (_detailsOpen.hasMatch(line)) {
      _pendingBoundary = -1;
      _detailsDepth++;
      _lastLineContinuable = false;
      return;
    }
    if (_detailsClose.hasMatch(line)) {
      if (_detailsDepth > 0) {
        _detailsDepth--;
      }
      _lastLineContinuable = false;
      return;
    }
    if (_detailsDepth > 0) {
      return;
    }

    if (trimmed.isEmpty) {
      // A blank line pends a boundary at the start of whatever follows it.
      _pendingBoundary = endOffset;
      return;
    }

    // A non-blank line: confirm or cancel the pending boundary.
    _confirmPendingBoundary(line);
    _lastLineContinuable = _listMarker.hasMatch(line) || _indentOf(line) >= 2;
  }

  static int _indentOf(String line) {
    var indent = 0;
    for (var i = 0; i < line.length; i++) {
      final unit = line.codeUnitAt(i);
      if (unit == 0x20) {
        indent++;
      } else if (unit == 0x09) {
        indent += 4;
      } else {
        break;
      }
    }
    return indent;
  }
}
