import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_harness/cancellation.dart';

/// What the runner reported about its own lockdown in its `ready` frame.
class CodeRunnerLockdown {
  /// Creates a report.
  const CodeRunnerLockdown({required this.level, this.details = const {}});

  /// Rebuilds from the frame's `lockdown` object. A missing level reads as
  /// `none`, so a malformed report is never mistaken for a full one.
  factory CodeRunnerLockdown.fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    return CodeRunnerLockdown(
      level: level is String && level.isNotEmpty ? level : 'none',
      details: Map.unmodifiable(json),
    );
  }

  /// The only level a script is sent to.
  static const String fullLevel = 'full';

  /// `full`, or anything less (`partial`, `none`).
  final String level;

  /// The whole report: the controls applied, per operating system. Stored on
  /// the execution row as-is.
  final Map<String, dynamic> details;

  /// Whether every control was applied.
  bool get isFull => level == fullLevel;

  /// The wire form.
  Map<String, dynamic> toJson() => {...details, 'level': level};
}

/// The runner's `ready` frame.
class CodeRunnerHandshake {
  /// Creates a handshake.
  const CodeRunnerHandshake({
    required this.protocol,
    required this.engine,
    required this.lockdown,
  });

  /// The protocol version the runner speaks.
  final int protocol;

  /// The engine and its version (`quickjs-ng 0.10.1`).
  final String engine;

  /// The lockdown it applied.
  final CodeRunnerLockdown lockdown;
}

/// Everything one runner needs before it runs a script: the `init` frame
/// plus the source for the `exec` frame.
class CodeSandboxStart {
  /// Creates a start request.
  const CodeSandboxStart({
    required this.code,
    required this.limits,
    required this.catalog,
    required this.returnBudgetChars,
    this.store = const {},
    this.storeWritable = true,
  });

  /// The script source, already checked against
  /// [CodeModeLimits.maxSourceBytes].
  final String code;

  /// The limits after workspace overrides and the model's clamp. The
  /// session enforces [CodeModeLimits.wallClockMs] itself.
  final CodeModeLimits limits;

  /// `ALL_TOOLS`: `[{ id, name, namespace, description }]`, from
  /// `ScriptCatalog.allTools`: the descriptions share a fixed total equally
  /// (cut with `…`), so the list's size is bounded whatever the catalog's.
  final List<Map<String, Object?>> catalog;

  /// How many characters of output the script's result keeps whole
  /// (`ScriptResultFormatter.returnBudgetChars` of the run's
  /// `max_output_tokens`): what `limits().returnBudgetChars` reads.
  final int returnBudgetChars;

  /// A snapshot of the stored values, key to JSON text, for `load()`.
  final Map<String, String> store;

  /// Whether `store()` may write. False when the run has no conversation or
  /// no agent to keep values under, or is read-only (whose scripts still
  /// read [store]): the runner is then given a zero store
  /// budget, so `store(key, value)` throws in the script at the call instead
  /// of the value being dropped silently after the script returns.
  final bool storeWritable;
}

/// Whom a runner `call` frame is for.
enum CodeSandboxCallTarget {
  /// A tool, through the gate: `tools.<id>(args)`.
  tool('tool'),

  /// The host itself: discovery (`searchTools`, `describeTool`,
  /// `describeNamespace`) and `models.*`. Answered from the catalog the gate
  /// uses, never by running a tool.
  host('host');

  const CodeSandboxCallTarget(this.wire);

  /// The frame's `target` value.
  final String wire;

  /// Parses [value], or returns null when it is not a known target.
  static CodeSandboxCallTarget? tryParse(String? value) {
    for (final t in values) {
      if (t.wire == value) {
        return t;
      }
    }
    return null;
  }
}

/// Something a running script did, in the order the runner reported it.
sealed class CodeSandboxEvent {
  const CodeSandboxEvent();
}

/// A `call { id, target, name, args, at? }` frame. The host answers each one
/// exactly once with [CodeSandboxSession.reply].
final class CodeSandboxCall extends CodeSandboxEvent {
  /// Creates a call event.
  const CodeSandboxCall({
    required this.id,
    required this.target,
    required this.name,
    required this.arguments,
    required this.site,
  });

  /// The runner's id for the call, echoed in the reply.
  final String id;

  /// Whom it is for.
  final CodeSandboxCallTarget target;

  /// For a tool call, the raw name or identifier the script used; for a host
  /// call, the host function (`searchTools`, `describeTool`,
  /// `describeNamespace`, `models.embed`, `models.rank`, `models.classify`).
  final String name;

  /// The argument object, already capped at
  /// [CodeModeLimits.maxCallArgumentBytes] by the session.
  final Map<String, dynamic> arguments;

  /// Where in the script the call was made, or null when the runner reported
  /// no position. Checked by the session against the script's own lines.
  ///
  /// A display hint from the process that runs model-written code: it goes
  /// to the call's record and transcript row only, never to the gate, an
  /// approval, an audit entry or a fingerprint.
  final ScriptCallSite? site;
}

/// An `output { kind, … }` frame.
final class CodeSandboxOutput extends CodeSandboxEvent {
  /// Creates an output event.
  const CodeSandboxOutput(this.item);

  /// The output.
  final ScriptOutputItem item;
}

/// A `store { key, value }` frame. Buffered by the host; committed only when
/// the script completes.
final class CodeSandboxStoreWrite extends CodeSandboxEvent {
  /// Creates a store event.
  const CodeSandboxStoreWrite({required this.key, this.valueJson});

  /// The key.
  final String key;

  /// The value as JSON text, or null for a delete.
  final String? valueJson;
}

/// The host's answer to a [CodeSandboxCall]: the `result { id, ok, payload }`
/// frame.
class CodeSandboxReply {
  /// Creates a reply.
  const CodeSandboxReply({required this.id, required this.ok, Object? payload})
    // A named parameter cannot be a private initializing formal.
    // ignore: prefer_initializing_formals
    : _payload = payload,
      payloadJson = null;

  /// A resolving reply carrying [value] (JSON-serialisable).
  const CodeSandboxReply.value(this.id, Object? value)
    : ok = true,
      _payload = value,
      payloadJson = null;

  /// A resolving reply whose value is already encoded: [json] is its UTF-8
  /// JSON, written into the frame as it is. A tool's result waits for its
  /// reply in this form, so a script waiting for its slot holds the bytes
  /// of its results, not their decoded values.
  const CodeSandboxReply.json(this.id, Uint8List json)
    : ok = true,
      _payload = null,
      payloadJson = json;

  /// A rejecting reply: the script's promise rejects with an `Error` whose
  /// message is [message].
  const CodeSandboxReply.error(this.id, String message)
    : ok = false,
      _payload = message,
      payloadJson = null;

  /// The call's id.
  final String id;

  /// Whether the script's promise resolves.
  final bool ok;

  final Object? _payload;

  /// The value as UTF-8 JSON, for a reply made with [CodeSandboxReply.json].
  final Uint8List? payloadJson;

  /// The value, or the error message when [ok] is false. For a reply made
  /// with [CodeSandboxReply.json] it is decoded from [payloadJson].
  Object? get payload {
    final json = payloadJson;
    return json == null ? _payload : jsonDecode(utf8.decode(json));
  }
}

/// The runner's own measurements from its `done` frame.
class CodeSandboxStats {
  /// Creates stats. Throws [ArgumentError] when a value is negative.
  CodeSandboxStats({
    required this.cpuMs,
    required this.peakHeapBytes,
    required this.calls,
    required this.outputBytes,
  }) {
    for (final (value, name) in [
      (cpuMs, 'cpuMs'),
      (peakHeapBytes, 'peakHeapBytes'),
      (calls, 'calls'),
      (outputBytes, 'outputBytes'),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
  }

  /// Interpreter CPU milliseconds.
  final int cpuMs;

  /// Peak interpreter heap in bytes.
  final int peakHeapBytes;

  /// Call frames the script sent.
  final int calls;

  /// Output the script produced, in bytes.
  final int outputBytes;
}

/// How a runner process ended.
class CodeSandboxOutcome {
  /// Creates an outcome. Throws [ArgumentError] for
  /// [CodeExecutionStatus.refused], which only the host decides, and for
  /// [CodeExecutionStatus.running], which is no way to end.
  CodeSandboxOutcome({
    required this.status,
    this.returnValue,
    this.error,
    this.stats,
    this.errorKind,
    this.detail,
  }) {
    if (status == CodeExecutionStatus.refused ||
        status == CodeExecutionStatus.running) {
      throw ArgumentError.value(
        status,
        'status',
        'a runner never refuses, and an outcome is how it ended',
      );
    }
  }

  /// How it ended: from the `done` frame, or from the host's reason for
  /// killing it (deadline, cancel, protocol violation, crash).
  final CodeExecutionStatus status;

  /// The top-level return value, when the script completed with one.
  final ScriptTextOutput? returnValue;

  /// The uncaught error, when the script failed.
  final ScriptError? error;

  /// The runner's measurements, or null when it never sent `done`.
  final CodeSandboxStats? stats;

  /// Why it ended, from [CodeExecutionErrorKind.values] (`script_error`,
  /// `deadline`, `cpu`, `heap`, `output`, `protocol`, `frame_too_large`,
  /// `call_cap`, `exited`, …); null when it completed. Never the script's own
  /// error name, which is [ScriptError.name] on [error].
  final String? errorKind;

  /// A sentence for the model and the operator when the end was abnormal.
  final String? detail;
}

/// Pauses a session's wall-clock deadline while the script waits on a
/// person. Release it when the wait ends; releasing twice is a no-op.
abstract interface class CodeSandboxDeadlineHold {
  /// Ends the hold. The deadline resumes when no hold is left.
  void release();
}

/// One running script in one runner process.
abstract interface class CodeSandboxSession {
  /// The runner's `ready` frame. A session is only ever returned for a
  /// runner whose lockdown [CodeRunnerLockdown.isFull].
  CodeRunnerHandshake get handshake;

  /// Calls, output and store writes, in frame order. Single subscription;
  /// closes after the last frame, before [outcome] completes.
  Stream<CodeSandboxEvent> get events;

  /// Answers the [CodeSandboxCall] with [CodeSandboxReply.id]. A reply to a
  /// call that was already answered, or after the session ended, is ignored.
  void reply(CodeSandboxReply reply);

  /// Pauses the wall-clock deadline until the returned hold is released.
  /// Holds nest: the deadline runs again when the last one is released.
  CodeSandboxDeadlineHold holdDeadline();

  /// Asks the runner to stop (the `cancel` frame) and kills it
  /// [CodeModeLimits.cancelKillGraceMs] later if it has not exited. The
  /// outcome is then [CodeExecutionStatus.cancelled]. Idempotent.
  void cancel();

  /// Kills the runner at once because it stopped answering, and makes sure
  /// [outcome] completes shortly after even if the process never reports its
  /// exit: a [CodeExecutionStatus.sandboxError] with error kind
  /// `unresponsive`, unless the session had already ended. Idempotent.
  void terminate();

  /// Whether the script has ended: it finished, was cancelled or killed, or
  /// its runner broke the protocol. Nothing it asked for afterwards should
  /// start, and no reply reaches it.
  bool get ended;

  /// Completes once the runner process is gone, whatever ended it. Never
  /// completes with an error.
  Future<CodeSandboxOutcome> get outcome;
}

/// The runner could not be started, or did not lock itself down fully. The
/// host records the execution as [CodeExecutionStatus.sandboxError].
class CodeSandboxStartException implements Exception {
  /// Creates the exception.
  const CodeSandboxStartException(this.message, {this.errorKind = 'start'});

  /// What went wrong, for the operator.
  final String message;

  /// A short machine-readable kind (`start`, `lockdown`, `protocol`).
  final String errorKind;

  @override
  String toString() => 'CodeSandboxStartException($errorKind: $message)';
}

/// What the execution service needs from the sandboxed runner, independent of
/// how frames travel (newline-delimited JSON on stdio, plan section 6).
///
/// One [start] is one process running one script. The implementation spawns,
/// checks the handshake, sends `init` and `exec`, enforces the frame and call
/// caps and the wall-clock deadline, and kills the process on expiry, cancel
/// or a protocol violation.
abstract interface class CodeSandboxPort {
  /// The boot self-test's result. [CodeRunnerAvailability.unavailable] until
  /// [selfTest] has run.
  CodeRunnerAvailability get availability;

  /// Runs the runner's `--self-test`, which attempts every forbidden action
  /// from native code and expects each to fail, and records the result in
  /// [availability]. Never throws.
  Future<CodeRunnerAvailability> selfTest();

  /// Starts one runner for [request].
  ///
  /// Throws [CodeSandboxStartException] when the process cannot be started,
  /// sends a malformed `ready`, or reports a lockdown below full (the process
  /// is killed before it sees the script). [cancel] firing before the
  /// handshake completes kills the process and throws the same exception.
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  });

  /// Kills every live runner. Called at shutdown, before the databases
  /// close.
  Future<void> dispose();
}
