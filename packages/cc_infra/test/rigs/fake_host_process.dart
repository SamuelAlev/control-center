// The three controllers are the fake child's pipes; `finish` closes them and
// the lint cannot follow that across the callbacks that call it.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/rigs/host_ffmpeg.dart';

/// A scripted child process.
///
/// The seam that makes the ADB and ffmpeg paths testable without either
/// binary: both go through [HostProcessSpawn], and this is what a test hands
/// back. Deliberately narrow — feed it stdout, complete its exit code, read
/// what was written to its stdin.
class FakeHostProcess implements HostProcess {
  /// Creates a [FakeHostProcess] recording the argv it was started with.
  FakeHostProcess({required this.executable, required this.args}) {
    _stdin.stream.listen(stdinBytes.add, onDone: () {
      stdinClosed = true;
      onStdinClosed?.call();
    });
  }

  /// Called when the caller closes stdin. Scripts a child that exits on EOF,
  /// which is what ffmpeg does and what the segment loop relies on.
  void Function()? onStdinClosed;

  /// The binary the caller asked for.
  final String executable;

  /// The argv the caller passed.
  final List<String> args;

  /// Everything written to the child's stdin.
  final BytesBuilder stdinBytes = BytesBuilder(copy: false);

  /// Whether the caller closed stdin.
  bool stdinClosed = false;

  /// Whether [kill] was called.
  bool killed = false;

  final StreamController<List<int>> _stdin = StreamController<List<int>>();
  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final StreamController<List<int>> _stderr = StreamController<List<int>>();
  final Completer<int> _exit = Completer<int>();

  @override
  StreamSink<List<int>> get stdin => _stdin.sink;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    // A killed child's pipes close and its exit code arrives; a fake that
    // leaves them open would let a leak in the code under test look fine.
    finish(exitCode: -15);
    return true;
  }

  /// Emits [bytes] on the child's stdout.
  void emit(List<int> bytes) {
    if (!_stdout.isClosed) {
      _stdout.add(bytes);
    }
  }

  /// Emits [text] on the child's stderr.
  void emitError(String text) {
    if (!_stderr.isClosed) {
      _stderr.add(utf8.encode(text));
    }
  }

  /// Closes the child's pipes and completes its exit code. Idempotent.
  void finish({int exitCode = 0}) {
    if (!_stdout.isClosed) {
      unawaited(_stdout.close());
    }
    if (!_stderr.isClosed) {
      unawaited(_stderr.close());
    }
    if (!_exit.isCompleted) {
      _exit.complete(exitCode);
    }
  }

  /// Answers a buffered command in one go: write [stdout]/[stderr] and exit.
  void complete({int exitCode = 0, String stdout = '', String stderr = ''}) {
    if (stdout.isNotEmpty) {
      emit(utf8.encode(stdout));
    }
    if (stderr.isNotEmpty) {
      emitError(stderr);
    }
    finish(exitCode: exitCode);
  }
}

/// A [HostProcessSpawn] that records every start and lets a test script it.
class FakeSpawner {
  /// Creates a [FakeSpawner]. [onStart] is called with each new process, which
  /// it may answer immediately (a buffered command) or hold open (a stream).
  FakeSpawner(this.onStart);

  /// Called for each spawned process.
  final void Function(FakeHostProcess process) onStart;

  /// Every process started, in order.
  final List<FakeHostProcess> started = [];

  /// The spawn function to hand to the code under test.
  Future<HostProcess> call(String executable, List<String> args) async {
    final process = FakeHostProcess(executable: executable, args: args);
    started.add(process);
    onStart(process);
    return process;
  }

  /// The processes started for [binary] (matched on the executable path).
  Iterable<FakeHostProcess> forBinary(String binary) =>
      started.where((p) => p.executable == binary);
}
