import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:path/path.dart' as p;

/// Captured image/metadata output and bounded decoder diagnostics.
class MediaProcessOutput {
  /// Creates a completed media-process result.
  const MediaProcessOutput({required this.bytes, required this.diagnostics});

  /// Binary stdout, bounded by the caller's expected output size.
  final Uint8List bytes;

  /// Decoder stderr without terminal colors or inherited logging settings.
  final String diagnostics;
}

/// Owns all subprocesses for one render, including its deadline and cancellation.
class MediaRenderProcess {
  /// Starts a single deadline covering probing, decoding and encoding.
  MediaRenderProcess({
    required Duration timeout,
    Iterable<Future<void>?> abandoned = const [],
  }) {
    _timer = Timer(
      timeout,
      () => _interrupt(
        TimeoutException('Media rendering exceeded its time limit.', timeout),
      ),
    );
    for (final signal in abandoned) {
      if (signal != null) {
        unawaited(
          signal.then(
            (_) => _interrupt(
              const CancelledException('Media rendering was cancelled.'),
            ),
          ),
        );
      }
    }
  }

  final Set<Process> _children = {};
  final Completer<Never> _interrupted = Completer<Never>();
  late final Timer _timer;
  Object? _failure;
  bool _closed = false;

  /// Returns promptly on abandonment, including while waiting for a render slot.
  Future<T> guard<T>(Future<T> work) => Future.any([work, _interrupted.future]);

  /// Refuses additional work after cancellation or disposal.
  void checkActive() {
    final failure = _failure;
    if (failure != null) {
      throw failure;
    }
    if (_closed) {
      throw const CancelledException('Media rendering was cancelled.');
    }
  }

  void _interrupt(Object failure) {
    if (_closed || _failure != null) {
      return;
    }
    _failure = failure;
    for (final child in _children) {
      child.kill(ProcessSignal.sigkill);
    }
    _interrupted.completeError(failure);
  }

  /// Runs one managed executable with no inherited PATH or loader overrides.
  Future<MediaProcessOutput> run({
    required String executable,
    required List<String> arguments,
    required int maxOutputBytes,
    Uint8List? input,
  }) async {
    checkActive();
    if (!p.isAbsolute(executable)) {
      throw const MediaRenderException(
        'Media executables must have absolute managed paths.',
      );
    }
    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
      includeParentEnvironment: false,
      environment: {
        'PATH': '',
        'LANG': 'C',
        'LC_ALL': 'C',
        'AV_LOG_FORCE_NOCOLOR': '1',
        if (Platform.isWindows)
          for (final entry in Platform.environment.entries)
            if (entry.key.toLowerCase() == 'systemroot') entry.key: entry.value,
      },
    );
    _children.add(process);
    if (_closed || _failure != null) {
      process.kill(ProcessSignal.sigkill);
    }
    Object? inputError;
    Future<void> writeInput() async {
      try {
        if (input != null) {
          await process.stdin.addStream(Stream.value(input));
        }
        await process.stdin.close();
      } on Object catch (error) {
        inputError = error;
      }
    }

    final written = writeInput();
    try {
      final output = await Future.wait([
        _collect(process.stdout, limit: maxOutputBytes),
        _collectDiagnostics(process.stderr),
      ]);
      final exitCode = await process.exitCode;
      await written;
      checkActive();
      final diagnostics = utf8.decode(output[1], allowMalformed: true).trim();
      if (exitCode != 0) {
        final detail = diagnostics.isEmpty
            ? 'exit code $exitCode'
            : diagnostics;
        throw MediaRenderException('${p.basename(executable)} failed: $detail');
      }
      if (inputError != null) {
        throw MediaRenderException(
          'Unable to send the rendered page to the image encoder: $inputError',
        );
      }
      return MediaProcessOutput(bytes: output[0], diagnostics: diagnostics);
    } finally {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
      _children.remove(process);
    }
  }

  Future<Uint8List> _collect(
    Stream<List<int>> stream, {
    required int limit,
  }) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      final remaining = limit - bytes.length;
      if (chunk.length <= remaining) {
        bytes.add(chunk);
      } else {
        _interrupt(
          const MediaRenderException(
            'Rendered media exceeds the image size limit. Request a smaller max_dimension.',
          ),
        );
      }
    }
    return bytes.takeBytes();
  }

  Future<Uint8List> _collectDiagnostics(Stream<List<int>> stream) async {
    const limit = 64 * 1024;
    final chunks = Queue<List<int>>();
    var length = 0;
    await for (final chunk in stream) {
      chunks.add(chunk);
      length += chunk.length;
      while (length > limit) {
        final first = chunks.removeFirst();
        final excess = length - limit;
        if (first.length <= excess) {
          length -= first.length;
        } else {
          chunks.addFirst(
            first is Uint8List
                ? Uint8List.sublistView(first, excess)
                : first.sublist(excess),
          );
          length = limit;
        }
      }
    }
    final bytes = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// Stops remaining children and prevents late cancellation from affecting reuse.
  void dispose() {
    _closed = true;
    _timer.cancel();
    for (final child in _children) {
      child.kill(ProcessSignal.sigkill);
    }
  }
}
