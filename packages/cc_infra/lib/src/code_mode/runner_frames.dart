import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';

// What the host reads from a runner, below the protocol: lines, the bytes it
// keeps of a stream, the checks on an image a runner claims to have made,
// the size a stored value is charged at, and the wall-clock deadline.

/// The bytes a stored [value] is charged against the store caps: its compact
/// JSON as Dart encodes it, which is what the host sends the runner and the
/// measure the runner applies to every value it stores. One measure for the
/// values loaded at the start and every value a script writes, so the two
/// sides never disagree about what is stored, whatever spacing the saved text
/// has.
int storedValueBytes(Object? value) => utf8Length(jsonEncode(value));

/// Why an image output is refused, or null when it is accepted: a media
/// type other than [CodeModeLimits.imageMediaTypes], data that is not
/// standard base64, more than [CodeModeLimits.maxImageBytes] decoded, or
/// bytes that do not start the way the media type says.
String? imageProblem(String mediaType, String data) {
  if (!CodeModeLimits.imageMediaTypes.contains(mediaType)) {
    return 'claims the unsupported type "${oneLineLabel(mediaType, 40)}"';
  }
  // Four base64 characters per three bytes, plus padding.
  if (data.length > (CodeModeLimits.maxImageBytes + 2) ~/ 3 * 4) {
    return 'is over ${CodeModeLimits.maxImageBytes ~/ (1024 * 1024)} MiB';
  }
  final Uint8List bytes;
  try {
    bytes = base64.decode(data);
  } on FormatException {
    return 'is not valid base64';
  }
  if (bytes.length > CodeModeLimits.maxImageBytes) {
    return 'is over ${CodeModeLimits.maxImageBytes ~/ (1024 * 1024)} MiB';
  }
  bool startsWith(List<int> magic, [int at = 0]) {
    if (bytes.length < at + magic.length) {
      return false;
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[at + i] != magic[i]) {
        return false;
      }
    }
    return true;
  }

  final matches = switch (mediaType) {
    'image/png' => startsWith(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]),
    'image/jpeg' => startsWith(const [0xFF, 0xD8, 0xFF]),
    'image/gif' =>
      startsWith(ascii.encode('GIF87a')) || startsWith(ascii.encode('GIF89a')),
    _ =>
      startsWith(ascii.encode('RIFF')) && startsWith(ascii.encode('WEBP'), 8),
  };
  return matches ? null : 'is not the $mediaType it claims to be';
}

/// The lines of a script as call sites name them, for checking the `at` of a
/// runner's `call` frame (cc_codemode README, "Call sites"): split at `\n`,
/// `\r\n` and a lone `\r`, as QuickJS counts lines and the runner maps them,
/// and measured in UTF-16 code units.
class ScriptLines {
  /// The lines of the script `code`, split on first use.
  ScriptLines(String code) : _code = code;

  final String _code;
  List<String>? _lines;

  /// The site a frame's `at` value names. Throws [FormatException] when it
  /// is not two integers naming the first code unit of a character on one of
  /// the script's lines (`null` included): a runner that keeps its protocol
  /// never writes that. A frame without `at` has no site; that is not this
  /// function's to decide.
  ScriptCallSite siteOf(Object? at) {
    if (at is! List || at.length != 2) {
      throw const FormatException('at is not [line, column]');
    }
    final [line, column] = at;
    if (line is! int || column is! int) {
      throw const FormatException('at is not two integers');
    }
    final lines = _lines ??= const LineSplitter().convert(_code);
    if (line < 1 || line > lines.length) {
      throw FormatException('at names line $line of ${lines.length}');
    }
    final text = lines[line - 1];
    if (column < 1 || column > text.length) {
      throw FormatException(
        'at names column $column of a line of ${text.length}',
      );
    }
    if (column > 1 &&
        _isLowSurrogate(text.codeUnitAt(column - 1)) &&
        _isHighSurrogate(text.codeUnitAt(column - 2))) {
      throw const FormatException('at names the middle of a character');
    }
    if (line > ScriptCallSite.maxPosition ||
        column > ScriptCallSite.maxPosition) {
      throw const FormatException('at is past the largest position');
    }
    return ScriptCallSite(line, column);
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}

/// One hold on a [PausableDeadline]; releasing it twice releases once.
class PausableDeadlineHold implements CodeSandboxDeadlineHold {
  /// Holds [_deadline] until [release].
  PausableDeadlineHold(this._deadline);

  final PausableDeadline _deadline;
  bool _released = false;

  @override
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _deadline.release();
  }
}

/// A wall-clock budget that stops counting while held. Holds nest.
class PausableDeadline {
  /// Creates a deadline of [budget]; it starts counting at [start].
  PausableDeadline(this.budget);

  /// The time it counts down.
  final Duration budget;

  /// Called once, when the budget runs out.
  late void Function() onExpire;
  final Stopwatch _running = Stopwatch();
  final Stopwatch _held = Stopwatch();
  int _holds = 0;
  bool _started = false;
  bool _stopped = false;
  Timer? _timer;

  /// Milliseconds it spent held.
  int get heldMs => _held.elapsedMilliseconds;

  /// Starts counting, unless held.
  void start() {
    if (_started || _stopped) {
      return;
    }
    _started = true;
    if (_holds == 0) {
      _running.start();
      _arm();
    } else {
      _held.start();
    }
  }

  void _arm() {
    _timer?.cancel();
    final left = budget - _running.elapsed;
    if (left <= Duration.zero) {
      _fire();
      return;
    }
    _timer = Timer(left, _arm);
  }

  void _fire() {
    if (_stopped) {
      return;
    }
    stop();
    onExpire();
  }

  /// Stops counting until the matching [release].
  void hold() {
    if (_stopped) {
      return;
    }
    if (_holds++ == 0 && _started) {
      _timer?.cancel();
      _running.stop();
      _held.start();
    }
  }

  /// Ends one [hold]; counting resumes when none is left.
  void release() {
    if (_stopped || _holds == 0) {
      return;
    }
    if (--_holds == 0 && _started) {
      _held.stop();
      _running.start();
      _arm();
    }
  }

  /// Stops for good; it never fires afterwards.
  void stop() {
    _stopped = true;
    _timer?.cancel();
    _running.stop();
    _held.stop();
  }
}

/// Splits a byte stream into newline-terminated frames without ever holding
/// more than [maxBytes] of an unterminated line.
class RunnerFrameSplitter {
  /// Calls [onFrame] per line, or [onOversize] once and then nothing.
  RunnerFrameSplitter(
    this.maxBytes, {
    required this.onFrame,
    required this.onOversize,
  });

  /// The longest line.
  final int maxBytes;

  /// Called with each complete line, without its newline.
  final void Function(Uint8List frame) onFrame;

  /// Called once a line passes [maxBytes].
  final void Function() onOversize;
  final BytesBuilder _partial = BytesBuilder();
  bool _failed = false;

  /// Adds the next bytes of the stream.
  void add(List<int> chunk) {
    if (_failed) {
      return;
    }
    var start = 0;
    while (start <= chunk.length) {
      final newline = chunk.indexOf(10, start);
      final end = newline < 0 ? chunk.length : newline;
      if (_partial.length + (end - start) > maxBytes) {
        _failed = true;
        _partial.clear();
        onOversize();
        return;
      }
      if (end > start) {
        _partial.add(
          chunk is Uint8List
              ? Uint8List.sublistView(chunk, start, end)
              : chunk.sublist(start, end),
        );
      }
      if (newline < 0) {
        return;
      }
      onFrame(_partial.takeBytes());
      if (_failed) {
        return;
      }
      start = newline + 1;
    }
  }
}

/// Keeps the last [limit] bytes of a stream.
class BoundedCapture {
  /// Keeps at most [limit] bytes.
  BoundedCapture(this.limit);

  /// The most bytes kept.
  final int limit;
  final Queue<List<int>> _chunks = Queue();
  int _length = 0;

  /// Adds the next bytes of the stream.
  void add(List<int> chunk) {
    _chunks.add(chunk);
    _length += chunk.length;
    while (_length > limit && _chunks.isNotEmpty) {
      final first = _chunks.removeFirst();
      final excess = _length - limit;
      if (first.length <= excess) {
        _length -= first.length;
      } else {
        _chunks.addFirst(first.sublist(excess));
        _length = limit;
      }
    }
  }

  /// What is kept, oldest first.
  Uint8List bytes() {
    final out = BytesBuilder(copy: false);
    for (final c in _chunks) {
      out.add(c);
    }
    return out.takeBytes();
  }
}
