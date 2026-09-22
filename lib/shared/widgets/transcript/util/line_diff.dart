import 'dart:isolate';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Kind of a line in a computed diff.
enum DiffLineKind {
  /// Unchanged context line, present in both sides.
  context,

  /// Added line (present only in the new text).
  add,

  /// Removed line (present only in the old text).
  del,
}

/// A single rendered line of a unified diff.
class DiffLine {
  /// Creates a [DiffLine].
  const DiffLine(this.kind, this.text);

  /// Whether the line was added, removed, or unchanged.
  final DiffLineKind kind;

  /// The line text (without trailing newline).
  final String text;
}

/// Result of [computeLineDiff]: the rendered lines plus add/del counts.
class LineDiffResult {
  /// Creates a [LineDiffResult].
  const LineDiffResult(this.lines, this.additions, this.deletions);

  /// The diff lines in order.
  final List<DiffLine> lines;

  /// Number of added lines.
  final int additions;

  /// Number of removed lines.
  final int deletions;
}

/// Both sides shorter than this stay on the UI isolate. A 200-line file with
/// a third of its lines replaced is about 5ms; the same shape is about 7ms
/// at 400 lines, about 20ms at 800, and about 170ms at 3000.
const int _syncMaxShorterLines = 250;

/// Novel lines (text present on only one side) past which a long file is
/// deferred. A few real edits in a multi-thousand-line file stay under
/// 10ms and still diff inline. A rewrite crosses this and would drop the
/// frame, so it leaves the UI isolate.
///
/// A permutation of the same lines (a full reverse) has no novel lines and
/// still diffs inline. That case is expensive and rare; a rewrite, which
/// is the expensive edit an agent actually produces, is what this catches.
const int _asyncNovelLines = 200;

/// Synchronous diff time one frame will spend before later rows in that
/// build are deferred. One agent turn is a single list item, so every edit
/// in it diffs during that item's build.
const int _frameBudgetUs = 4000;

/// Shorter side at or above this, once [_frameBudgetUs] is spent, waits.
/// Smaller edits are cheap enough that a stack of them still fits a frame.
const int _budgetSpillLines = 40;

/// Remembered diffs. Twelve covers the edits on screen; the entries hold
/// the caller's strings (not copies) plus the line list the view paints.
const int _lineDiffCacheEntries = 12;

final List<_LineDiffCacheEntry> _lineDiffCache = <_LineDiffCacheEntry>[];

final Map<(String, String), Future<LineDiffResult>> _lineDiffInflight =
    <(String, String), Future<LineDiffResult>>{};

Duration? _lineDiffFrameStamp;
int _lineDiffFrameSpentUs = 0;

/// How many times the Myers diff itself ran on this isolate.
///
/// A helper isolate has its own copy, so a build that deferred a heavy diff
/// leaves this unchanged on the UI isolate.
@visibleForTesting
int debugLineDiffComputeCount = 0;

/// When true, [computeLineDiffAsync] diffs on this isolate after yielding.
///
/// Widget tests set this so they never spawn an isolate. Production leaves
/// it false; the web target also stays inline because `Isolate.run` is not
/// available there.
@visibleForTesting
bool debugLineDiffForceInline = false;

class _LineDiffCacheEntry {
  _LineDiffCacheEntry(this.oldText, this.newText, this.result);

  final String oldText;
  final String newText;
  final LineDiffResult result;
}

/// The cached diff for this pair, or null when one has not been computed.
LineDiffResult? peekLineDiff(String oldText, String newText) {
  for (var i = _lineDiffCache.length - 1; i >= 0; i--) {
    final entry = _lineDiffCache[i];
    if (identical(entry.oldText, oldText) &&
        identical(entry.newText, newText)) {
      return entry.result;
    }
  }
  for (var i = _lineDiffCache.length - 1; i >= 0; i--) {
    final entry = _lineDiffCache[i];
    if (entry.oldText.length != oldText.length ||
        entry.newText.length != newText.length) {
      continue;
    }
    if (entry.oldText == oldText && entry.newText == newText) {
      return entry.result;
    }
  }
  return null;
}

/// Whether [lineDiffForBuild] will refuse this pair on the current frame.
bool lineDiffDefers(String oldText, String newText) {
  _rollLineDiffFrame();
  return _lineDiffDefersNow(oldText, newText);
}

/// Diff for a build. Null means the caller paints a placeholder and awaits
/// [computeLineDiffAsync] — running it here would miss the frame.
LineDiffResult? lineDiffForBuild(String oldText, String newText) {
  // Roll even on a cache hit, so the first call of a new frame clears the
  // previous frame's budget before any miss consults it.
  _rollLineDiffFrame();
  final hit = peekLineDiff(oldText, newText);
  if (hit != null) {
    return hit;
  }
  if (_lineDiffDefersNow(oldText, newText)) {
    return null;
  }
  final watch = Stopwatch()..start();
  final result = computeLineDiff(oldText, newText);
  _lineDiffFrameSpentUs += watch.elapsedMicroseconds;
  return result;
}

/// Same diff as [computeLineDiff], off the UI isolate when the runtime has
/// one. Concurrent callers for the same pair share one computation.
Future<LineDiffResult> computeLineDiffAsync(String oldText, String newText) {
  final hit = peekLineDiff(oldText, newText);
  if (hit != null) {
    return Future<LineDiffResult>.value(hit);
  }
  final key = (oldText, newText);
  final pending = _lineDiffInflight[key];
  if (pending != null) {
    return pending;
  }
  final future = _lineDiffOffload(oldText, newText);
  _lineDiffInflight[key] = future;
  return future.whenComplete(() {
    _lineDiffInflight.remove(key);
  });
}

void _rollLineDiffFrame() {
  // Unit tests call the diff helpers before any binding exists. Without a
  // frame there is nothing to share a budget across, so each call starts
  // fresh. The novel-line deferral does not need the binding.
  final SchedulerBinding binding;
  try {
    binding = SchedulerBinding.instance;
  } on Object {
    _lineDiffFrameStamp = null;
    _lineDiffFrameSpentUs = 0;
    return;
  }
  final inFrame =
      binding.schedulerPhase == SchedulerPhase.persistentCallbacks ||
      binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
      binding.schedulerPhase == SchedulerPhase.transientCallbacks;
  final stamp = binding.currentFrameTimeStamp;
  if (!inFrame || stamp != _lineDiffFrameStamp) {
    _lineDiffFrameStamp = stamp;
    _lineDiffFrameSpentUs = 0;
  }
}

bool _lineDiffDefersNow(String oldText, String newText) {
  if (debugLineDiffForceInline) {
    return false;
  }
  final oldLines = _lineCount(oldText);
  final newLines = _lineCount(newText);
  final shorter = oldLines < newLines ? oldLines : newLines;
  if (shorter < _syncMaxShorterLines) {
    return _lineDiffFrameSpentUs >= _frameBudgetUs &&
        shorter >= _budgetSpillLines;
  }
  if (_novelLineCount(oldText, newText, _asyncNovelLines) >= _asyncNovelLines) {
    return true;
  }
  return _lineDiffFrameSpentUs >= _frameBudgetUs;
}

int _lineCount(String text) {
  if (text.isEmpty) {
    return 0;
  }
  var count = 1;
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      count++;
    }
  }
  if (text.codeUnitAt(text.length - 1) == 0x0A) {
    count--;
  }
  return count;
}

/// Lines of [text], dropping the empty segment a trailing newline produces,
/// matching [_LineEncoder].
List<String> _linesOf(String text) {
  if (text.isEmpty) {
    return const <String>[];
  }
  final segments = text.split('\n');
  if (segments.last.isEmpty) {
    segments.removeLast();
  }
  return segments;
}

/// How many lines appear on only one side, stopping at [cap].
int _novelLineCount(String oldText, String newText, int cap) {
  final oldLines = _linesOf(oldText);
  final knownOld = oldLines.toSet();
  var novel = 0;
  for (final line in _linesOf(newText)) {
    if (knownOld.contains(line)) {
      continue;
    }
    novel++;
    if (novel >= cap) {
      return novel;
    }
  }
  final knownNew = _linesOf(newText).toSet();
  for (final line in oldLines) {
    if (knownNew.contains(line)) {
      continue;
    }
    novel++;
    if (novel >= cap) {
      return novel;
    }
  }
  return novel;
}

void _rememberLineDiff(String oldText, String newText, LineDiffResult result) {
  _lineDiffCache.removeWhere((entry) {
    if (entry.oldText.length != oldText.length ||
        entry.newText.length != newText.length) {
      return false;
    }
    return (identical(entry.oldText, oldText) &&
            identical(entry.newText, newText)) ||
        (entry.oldText == oldText && entry.newText == newText);
  });
  if (_lineDiffCache.length >= _lineDiffCacheEntries) {
    _lineDiffCache.removeAt(0);
  }
  _lineDiffCache.add(_LineDiffCacheEntry(oldText, newText, result));
}

Future<LineDiffResult> _lineDiffOffload(String oldText, String newText) async {
  // Yield first on the inline path. An async function runs until its first
  // await, and a synchronous diff here would land back inside the build
  // that was trying to get off the frame.
  if (kIsWeb || debugLineDiffForceInline) {
    await Future<void>.delayed(Duration.zero);
    return computeLineDiff(oldText, newText);
  }
  try {
    final result = await Isolate.run(() => _computeLineDiff(oldText, newText));
    _rememberLineDiff(oldText, newText, result);
    return result;
  } on Object {
    return computeLineDiff(oldText, newText);
  }
}

/// Computes a line-level diff between [oldText] and [newText] using
/// `diff_match_patch` in line mode.
///
/// Each unique line is mapped to a single code unit so the character-level
/// Myers diff operates on whole lines; the result is decoded back into
/// [DiffLine]s. No semantic cleanup is applied (it would merge across the
/// synthetic line boundaries).
///
/// Repeated calls with the same text return the cached result. A build that
/// must not pay for a large rewrite uses [lineDiffForBuild] instead.
LineDiffResult computeLineDiff(String oldText, String newText) {
  final hit = peekLineDiff(oldText, newText);
  if (hit != null) {
    return hit;
  }
  final result = _computeLineDiff(oldText, newText);
  _rememberLineDiff(oldText, newText, result);
  return result;
}

/// The Myers diff itself, with no cache. A helper isolate can run it: it
/// touches no static cache, only [debugLineDiffComputeCount] on that isolate.
LineDiffResult _computeLineDiff(String oldText, String newText) {
  debugLineDiffComputeCount++;
  final encoder = _LineEncoder();
  final a = encoder.encode(oldText);
  final b = encoder.encode(newText);

  final dmp = DiffMatchPatch();
  final diffs = dmp.diff(a, b);

  final lines = <DiffLine>[];
  var additions = 0;
  var deletions = 0;

  for (final diff in diffs) {
    final decoded = encoder.decode(diff.text);
    switch (diff.operation) {
      case DIFF_EQUAL:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.context, l));
        }
      case DIFF_DELETE:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.del, l));
          deletions++;
        }
      case DIFF_INSERT:
        for (final l in decoded) {
          lines.add(DiffLine(DiffLineKind.add, l));
          additions++;
        }
    }
  }

  return LineDiffResult(lines, additions, deletions);
}

/// Maps unique lines to single code units and back, the standard
/// `diff_match_patch` line-mode encoding.
class _LineEncoder {
  final List<String> _lines = [];
  final Map<String, int> _index = {};

  String encode(String text) {
    if (text.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    // Preserve a trailing empty segment only when the text does not end in a
    // newline; otherwise the final '\n' yields a phantom empty line.
    final segments = text.split('\n');
    final count = (segments.isNotEmpty && segments.last.isEmpty)
        ? segments.length - 1
        : segments.length;
    for (var i = 0; i < count; i++) {
      final line = segments[i];
      var id = _index[line];
      if (id == null) {
        id = _lines.length;
        _lines.add(line);
        _index[line] = id;
      }
      buffer.writeCharCode(id);
    }
    return buffer.toString();
  }

  List<String> decode(String encoded) => [
    for (final unit in encoded.codeUnits) _lines[unit],
  ];
}
