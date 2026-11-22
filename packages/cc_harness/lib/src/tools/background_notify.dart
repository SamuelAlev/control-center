/// `notify` on a background command: output lines that match a pattern are
/// delivered to the model while the command keeps running.
///
/// The lines are the command's output, so they are untrusted: a delivery puts
/// them inside the data envelope ([wakeDataEnvelope]), and only the framing
/// line around it is server text. Deliveries are bounded (lines per delivery,
/// characters per line, deliveries per command). The pattern is not a
/// regular expression: it is the small grammar of [NotifyPattern], whose
/// matcher is linear in the line's length, because matching runs on the
/// server's isolate and Dart's regular expressions have no step bound.
library;

import 'package:cc_harness/src/context/wake_data.dart';
import 'package:cc_harness/src/tools/notify_pattern.dart';

/// One delivery of matched lines, for the run's aside lane.
typedef BackgroundNotifyDelivery = ({String handle, String text});

/// Why [pattern] cannot be a `notify` pattern, or null when it can.
String? notifyPatternRefusal(String pattern) {
  if (pattern.isEmpty) {
    return 'notify is empty: give a pattern, or leave it out.';
  }
  if (pattern.length > BackgroundNotify.maxPatternChars) {
    return 'notify is ${pattern.length} characters; at most '
        '${BackgroundNotify.maxPatternChars} are allowed.';
  }
  return NotifyPattern.parse(pattern).refusal;
}

/// The matcher and outbox of one command's `notify`.
class BackgroundNotify {
  /// Creates the matcher for [pattern] (already checked with
  /// [notifyPatternRefusal]; a pattern it refuses throws an [ArgumentError]).
  BackgroundNotify(this.pattern)
    : _matcher =
          NotifyPattern.parse(pattern).pattern ??
          (throw ArgumentError.value(pattern, 'pattern', 'refused'));

  /// The longest pattern accepted.
  static const int maxPatternChars = 200;

  /// Each line is cut to this many characters before it is matched.
  static const int matchChars = 2000;

  /// Characters of a matched line a delivery carries.
  static const int lineChars = 300;

  /// Lines one delivery carries.
  static const int linesPerDelivery = 10;

  /// Deliveries one command makes before matching is switched off.
  static const int maxDeliveries = 30;

  /// The pattern, as the model wrote it.
  final String pattern;

  final NotifyPattern _matcher;
  final StringBuffer _carry = StringBuffer();
  bool _skipToNewline = false;
  final List<String> _pending = [];
  int _skipped = 0;
  int _deliveries = 0;
  bool _off = false;

  /// Deliveries made so far.
  int get deliveries => _deliveries;

  /// Whether matching was switched off.
  bool get off => _off;

  /// Whether a delivery is waiting.
  bool get hasPending => _pending.isNotEmpty;

  /// Feeds a chunk of output; returns whether a line matched, so a parked run
  /// can wake.
  bool add(String chunk) {
    if (_off) {
      return false;
    }
    var signalled = false;
    var start = 0;
    while (start <= chunk.length) {
      final nl = chunk.indexOf('\n', start);
      final piece = chunk.substring(start, nl < 0 ? chunk.length : nl);
      if (!_skipToNewline) {
        final room = matchChars - _carry.length;
        _carry.write(piece.length > room ? piece.substring(0, room) : piece);
        if (_carry.length >= matchChars && nl < 0) {
          // A line longer than the cut: match its first part now, ignore
          // the rest of it.
          signalled = _matchLine(_carry.toString()) || signalled;
          _carry.clear();
          _skipToNewline = true;
        }
      }
      if (nl < 0) {
        break;
      }
      if (!_skipToNewline) {
        signalled = _matchLine(_carry.toString()) || signalled;
      }
      _carry.clear();
      _skipToNewline = false;
      start = nl + 1;
      if (_off) {
        return true;
      }
    }
    return signalled;
  }

  /// Matches what is left of the last line, when the command ended without a
  /// final newline.
  bool flush() {
    if (_off || _skipToNewline || _carry.isEmpty) {
      return false;
    }
    final line = _carry.toString();
    _carry.clear();
    return _matchLine(line);
  }

  bool _matchLine(String raw) {
    final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
    if (line.trim().isEmpty) {
      return false;
    }
    if (!_matcher.hasMatch(line)) {
      return false;
    }
    if (_pending.length < linesPerDelivery) {
      _pending.add(
        line.length > lineChars ? '${line.substring(0, lineChars)}…' : line,
      );
    } else {
      _skipped++;
    }
    return true;
  }

  /// The next delivery for the command [handle], or null when nothing is
  /// waiting. [running] says whether the command still runs; [outputHandle]
  /// is where its whole output reads.
  String? takeDelivery({
    required String handle,
    required bool running,
    required String outputHandle,
  }) {
    if (!hasPending) {
      return null;
    }
    final lines = List.of(_pending);
    final skipped = _skipped;
    _pending.clear();
    _skipped = 0;
    final parts = <String>[];
    if (lines.isNotEmpty) {
      _deliveries++;
      final n = lines.length + skipped;
      parts
        ..add(
          '[Background command $handle: $n output line${n == 1 ? '' : 's'} '
          'matched notify${running ? '; it is still running' : ''}] '
          '$wakeDataRule',
        )
        ..add(
          wakeDataEnvelope(
            lines.map((l) => '[$handle] $l').join('\n'),
            nonce: newWakeDataNonce(),
          ),
        );
      if (skipped > 0) {
        parts.add(
          '$skipped more matching line${skipped == 1 ? ' is' : 's are'} not '
          'shown: read_output(handle: "$outputHandle")',
        );
      }
    }
    if (_deliveries >= maxDeliveries && !_off) {
      _off = true;
      parts.add(
        'Notify is now off for $handle after $maxDeliveries deliveries. The '
        'rest of its output: read_output(handle: "$outputHandle")',
      );
    }
    return parts.join('\n');
  }
}
