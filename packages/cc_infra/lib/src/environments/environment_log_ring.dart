import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/util/command_redaction.dart';

final RegExp _terminalControl = RegExp(
  '\x1B\\][^\x07\x1B]*(?:\x07|\x1B\\\\)|\x1B\\[[0-9;?]*[ -/]*[@-~]|\x1B[@-_]',
);

/// What a terminal would show for [raw]: the last state of a line rewritten
/// with `\r`, without colour or cursor codes. Not redacted.
String terminalVisibleLine(String raw) {
  final trimmed = raw.replaceFirst(RegExp(r'\r+$'), '');
  // A progress bar rewrites its line with `\r`. Only the last state is news.
  final visible = trimmed.substring(trimmed.lastIndexOf('\r') + 1);
  return visible.replaceAll(_terminalControl, '');
}

/// The most recent output of one process, in memory and on disk.
///
/// Takes raw PTY bytes and keeps redacted plain lines: colour and cursor codes
/// belong to the terminal tab, which reads the bytes itself. Up to [maxBytes]
/// stay in memory. The file at [path] is rotated to `<path>.1` at the same
/// size, so disk holds between one and two times [maxBytes].
class EnvironmentLogRing {
  /// Creates an [EnvironmentLogRing].
  EnvironmentLogRing({
    required this.path,
    this.maxBytes = 2 * 1024 * 1024,
    this.flushInterval = const Duration(milliseconds: 250),
    this.maxLineChars = 64 * 1024,
  }) {
    _decoder = const Utf8Decoder(
      allowMalformed: true,
    ).startChunkedConversion(StringConversionSink.fromStringSink(_pending));
  }

  /// The log file.
  final String path;

  /// The ring's size.
  final int maxBytes;

  /// Minimum gap between disk writes.
  final Duration flushInterval;

  /// A line this long is cut, so output with no newline can't grow forever.
  final int maxLineChars;

  final StringBuffer _pending = StringBuffer();
  late final ByteConversionSink _decoder;
  final ListQueue<String> _memory = ListQueue();
  int _memoryChars = 0;
  final StringBuffer _unwritten = StringBuffer();
  Timer? _flushTimer;
  Future<void> _writes = Future.value();
  int _fileBytes = 0;
  final StreamController<String> _lines = StreamController.broadcast(
    sync: true,
  );

  /// New lines as they complete.
  Stream<String> get lines => _lines.stream;

  /// Loads what earlier runs left on disk.
  Future<void> load() async {
    final current = File(path);
    await current.parent.create(recursive: true);
    for (final file in [File('$path.1'), current]) {
      if (file.existsSync()) {
        for (final line in const LineSplitter().convert(
          await file.readAsString(
            encoding: const Utf8Codec(allowMalformed: true),
          ),
        )) {
          _remember(line);
        }
      }
    }
    _fileBytes = current.existsSync() ? current.lengthSync() : 0;
  }

  /// Takes a chunk of output.
  void addBytes(List<int> bytes) {
    _decoder.add(bytes);
    final text = _pending.toString();
    final end = text.lastIndexOf('\n');
    if (end >= 0) {
      _pending
        ..clear()
        ..write(text.substring(end + 1));
      text.substring(0, end).split('\n').forEach(_emit);
    } else if (text.length > maxLineChars) {
      _pending.clear();
      _emit(text);
    }
  }

  /// Ends a line left open when a process exits.
  void finishLine() {
    final text = _pending.toString();
    _pending.clear();
    if (text.isNotEmpty) {
      _emit(text);
    }
  }

  /// The last [count] lines.
  List<String> tail(int count) {
    final skip = _memory.length > count ? _memory.length - count : 0;
    return _memory.skip(skip).toList(growable: false);
  }

  /// Writes everything so far to disk.
  Future<void> flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_unwritten.isEmpty) {
      return _writes;
    }
    final text = _unwritten.toString();
    _unwritten.clear();
    return _writes = _writes.then((_) => _append(text));
  }

  /// Flushes and stops.
  Future<void> close() async {
    finishLine();
    await flush();
    await _lines.close();
  }

  void _emit(String raw) {
    final line = redactSecrets(terminalVisibleLine(raw));
    _remember(line);
    _unwritten.writeln(line);
    _flushTimer ??= Timer(flushInterval, () => unawaited(flush()));
    if (!_lines.isClosed) {
      _lines.add(line);
    }
  }

  void _remember(String line) {
    _memory.addLast(line);
    _memoryChars += line.length + 1;
    while (_memoryChars > maxBytes && _memory.length > 1) {
      _memoryChars -= _memory.removeFirst().length + 1;
    }
  }

  Future<void> _append(String text) async {
    try {
      final bytes = utf8.encode(text);
      await File(path).writeAsBytes(bytes, mode: FileMode.append);
      _fileBytes += bytes.length;
      if (_fileBytes >= maxBytes) {
        await File(path).rename('$path.1');
        _fileBytes = 0;
      }
    } on FileSystemException catch (e) {
      // The state directory goes away with the environment. Logs are not
      // worth failing a process over.
      CcInfraLog.warning('environment log write failed for $path: $e');
    }
  }
}
