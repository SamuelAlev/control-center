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

  bool _inFence = false;
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
    _detailsDepth = 0;
    _pendingBoundary = -1;
    _lastLineContinuable = false;
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
      _pendingBoundary = -1;
      _fenceMarker = trimmed[0];
      var n = 0;
      while (n < trimmed.length && trimmed[n] == _fenceMarker) {
        n++;
      }
      _fenceLen = n;
      _inFence = true;
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
    if (_pendingBoundary != -1) {
      final continuesConstruct =
          _lastLineContinuable &&
          (_indentOf(line) >= 2 || _listMarker.hasMatch(line));
      if (continuesConstruct) {
        _pendingBoundary = -1;
      } else {
        _boundary = _pendingBoundary;
        _pendingBoundary = -1;
      }
    }
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
