import 'package:cc_syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/composer/composer_markdown.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/painting.dart';

/// Syntax colors for the fenced code blocks of a composer draft, one per
/// UTF-16 code unit, so the composer's text controller can paint a fence that
/// names its language (` ```tsx `) the way the sent message will read.
///
/// Same grammars and theme as every other code surface (the shared
/// [highlightCodeLines] seam). A fence in a grammar the UI isolate has
/// compiled, short enough for the frame budget, colors synchronously; any
/// other tokenizes off the UI thread and [onColorsReady] asks the host to
/// repaint when it lands. Until then the block keeps the colors of its last
/// result, line by line, so typing in a `tsx` fence does not flash plain on
/// every keystroke. One tokenize is in flight at a time: a burst of edits
/// queues only the latest text, not one worker round trip per key.
///
/// Draft text changes on every keystroke, so nothing here goes into the
/// shared highlight LRU (`cache: false`); it would only evict the transcript's
/// blocks.
class ComposerFenceHighlighter {
  /// Creates a [ComposerFenceHighlighter].
  ComposerFenceHighlighter({required this.onColorsReady});

  /// Called when a background tokenize lands with colors the last
  /// [colorsFor] did not have. The host repaints and calls [colorsFor] again.
  final void Function() onColorsReady;

  /// Bumped whenever a background result lands, so a host that memoizes
  /// [colorsFor] by draft text knows its memo is stale.
  int get revision => _revision;
  int _revision = 0;

  /// The last colored result per fence, by position in the draft.
  final Map<int, _Highlighted> _held = {};

  /// The tokenize in flight, and the latest request per fence waiting for it.
  _Request? _inFlight;
  final Map<int, _Request> _queued = {};

  bool _disposed = false;

  /// Per-code-unit token colors for [source], or null when no fence in
  /// [fences] has a color to give. A null entry inherits the base style.
  List<Color?>? colorsFor(
    String source,
    List<ComposerCodeFence> fences, {
    required bool dark,
  }) {
    List<Color?>? colors;
    for (var index = 0; index < fences.length; index++) {
      final fence = fences[index];
      final languageId = shikiLangForFence(fence.info);
      if (languageId == null || fence.bodyEnd <= fence.bodyStart) {
        continue;
      }
      final code = source.substring(fence.bodyStart, fence.bodyEnd);
      final lines = _linesFor(index, code, languageId, dark);
      if (lines == null) {
        continue;
      }
      _paint(
        colors ??= List<Color?>.filled(source.length, null),
        source,
        fence,
        lines,
      );
    }
    return colors;
  }

  /// Stops reporting results; a tokenize still in flight lands nowhere.
  void dispose() {
    _disposed = true;
    _queued.clear();
  }

  List<List<InlineSpan>>? _linesFor(
    int index,
    String code,
    String languageId,
    bool dark,
  ) {
    final held = _held[index];
    // A different language or theme has nothing worth keeping.
    final sameGrammar =
        held != null && held.languageId == languageId && held.dark == dark;
    // Checked first, so a keystroke outside this fence (prose, another
    // fence) costs it nothing: only the block being edited tokenizes again.
    if (sameGrammar && held.code == code) {
      return held.lines;
    }
    final lineCount = 1 + '\n'.allMatches(code).length;
    if (shouldHighlightSynchronously(
      languageId: languageId,
      lineCount: lineCount,
    )) {
      final lines = highlightCodeLines(
        code: code,
        languageId: languageId,
        dark: dark,
        cache: false,
      );
      _held[index] = (
        languageId: languageId,
        dark: dark,
        code: code,
        lines: lines,
      );
      return lines;
    }
    _request((index: index, code: code, languageId: languageId, dark: dark));
    // Stale colors from the previous text of this fence, mapped by line and
    // column: closer to right than plain while the fresh result is on its way.
    return sameGrammar ? held.lines : null;
  }

  void _request(_Request request) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      if (!_sameRequest(inFlight, request)) {
        _queued[request.index] = request;
      }
      return;
    }
    _queued.remove(request.index);
    _inFlight = request;
    highlightCodeLinesAsync(
      code: request.code,
      languageId: request.languageId,
      dark: request.dark,
      cache: false,
    ).then<void>(
      (lines) => _land(request, lines),
      // highlightCodeLinesAsync already degrades to plain; this only keeps
      // an unexpected throw from wedging the queue.
      onError: (Object _) => _land(request, null),
    );
  }

  void _land(_Request request, List<List<InlineSpan>>? lines) {
    _inFlight = null;
    if (_disposed) {
      return;
    }
    if (lines != null) {
      _held[request.index] = (
        languageId: request.languageId,
        dark: request.dark,
        code: request.code,
        lines: lines,
      );
      _revision++;
      onColorsReady();
    }
    if (_queued.isNotEmpty) {
      _request(_queued.values.first);
    }
  }

  static bool _sameRequest(_Request a, _Request b) =>
      a.index == b.index &&
      a.code == b.code &&
      a.languageId == b.languageId &&
      a.dark == b.dark;

  /// Writes each span's color over the fence body, line by line, clipped to
  /// the body's current lines (stale [lines] may be longer or shorter).
  static void _paint(
    List<Color?> colors,
    String source,
    ComposerCodeFence fence,
    List<List<InlineSpan>> lines,
  ) {
    var lineStart = fence.bodyStart;
    for (final line in lines) {
      if (lineStart > fence.bodyEnd) {
        break;
      }
      var lineEnd = source.indexOf('\n', lineStart);
      if (lineEnd < 0 || lineEnd > fence.bodyEnd) {
        lineEnd = fence.bodyEnd;
      }
      var offset = lineStart;
      for (final span in line) {
        if (span is! TextSpan) {
          continue;
        }
        final length = span.text?.length ?? 0;
        final color = span.style?.color;
        if (color != null) {
          final end = offset + length < lineEnd ? offset + length : lineEnd;
          for (var i = offset; i < end; i++) {
            colors[i] = color;
          }
        }
        offset += length;
        if (offset >= lineEnd) {
          break;
        }
      }
      lineStart = lineEnd + 1;
    }
  }
}

typedef _Highlighted = ({
  String languageId,
  bool dark,
  String code,
  List<List<InlineSpan>> lines,
});

typedef _Request = ({int index, String code, String languageId, bool dark});
