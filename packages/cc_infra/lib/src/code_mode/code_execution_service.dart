import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_mode_store_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_infra/src/code_mode/code_execution_metrics.dart';
import 'package:cc_infra/src/code_mode/code_execution_record.dart';
import 'package:cc_infra/src/code_mode/code_runner_slots.dart';
import 'package:cc_infra/src/code_mode/runner_json.dart';
import 'package:cc_infra/src/code_mode/script_lookups.dart';
import 'package:cc_infra/src/code_mode/script_model_calls.dart';
import 'package:cc_infra/src/code_mode/script_outcome_watch.dart';
import 'package:cc_infra/src/code_mode/script_past_calls.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// The tool a script asks a person a question with, on both surfaces. Its
/// calls count against [CodeModeLimits.maxQuestions] and their answers are
/// appended to the result.
const String kScriptQuestionToolName = 'ask_user';

/// Whether scripts of a workspace may be admitted yet: null once they may,
/// else why not, which the refused script is told (an owner must be able to
/// act on it). The service waits for it within the script's wall clock and
/// refuses `server_busy` past that; a reason refuses `audit_unavailable`.
typedef ScriptAdmission = Future<String?> Function(String workspaceId);

const String _sweepPending = '\u0000sweep pending';
const String _unchecked =
    'the code mode records of this workspace could not be checked, so the '
    'script was not run; the server log says why.';

/// Runs `repl` scripts for both surfaces: the harness loop and the MCP
/// endpoint call it through [CodeExecutionPort].
///
/// For each script it admits the call (one script per run, a server-wide cap
/// on runner processes shared fairly between workspaces), records it as
/// running, starts a runner through the [CodeSandboxPort], answers discovery
/// and `models.*` calls itself from the same catalog the gate enforces, sends
/// each tool call to the surface's own gate and records it when it settles,
/// buffers store writes and commits them only when the script completes,
/// shapes the result the model reads and finishes the record once.
///
/// Nested tool calls are started strictly in the order the script made them.
/// Read-tier calls with no effects share up to
/// [CodeModeLimits.maxInFlightCalls] slots; every other call (writes,
/// commands, anything that may ask a person, questions) runs one at a time.
/// A call never starts before an earlier one has started, so the surface sees
/// calls in sequence order and numbers its transcript rows exactly as the
/// audit rows are numbered.
///
/// What the server owner bounds: at most [serverProcessCap] scripts hold a
/// runner slot at once; a script waiting on a person gives its slot back
/// only while fewer than [parkedCap] runners are parked that way (and its
/// workspace holds fewer than [parkedShare] of them), so live runner
/// processes never exceed `serverProcessCap + parkedCap`; while a script
/// waits on a person it starts no tool call and no `models.*` batch, so
/// only slot holders start work on the server; one workspace holds at most
/// [workspaceShare] slots, one run with its subagents at most [treeShare],
/// and waiting scripts are admitted round-robin across workspaces; a
/// script's lookups are bounded in size, number and server time
/// ([CodeModeLimits.maxLookups]); every script's heap is at most [maxHeapBytes]; and at
/// most [CodeModeLimits.maxServerModelBatches] `models.*` batches started
/// by scripts run at once. No script of a workspace is admitted before the
/// constructor's `admission` lets that workspace in (the boot sweep of the
/// records a previous process left running).
class CodeExecutionService implements CodeExecutionPort {
  /// Creates the service.
  ///
  /// [serverProcessCap] is the most scripts running at once on this server
  /// (`--code-mode-max-processes`); it defaults to
  /// [CodeModeLimits.defaultServerProcessCap] for this machine's cores.
  /// [maxHeapBytes] is the owner's heap ceiling
  /// (`--code-mode-max-heap-mb`), defaulting to the workspace ceiling
  /// [CodeModeLimits.heap]; it clamps every script. [outcomeGrace] is how
  /// long past its wall clock a script's runner has to report how it ended
  /// before the host gives up on it. Without `embeddings`, `models.*` calls
  /// fail and say the embedding model is not installed. `admission`, when
  /// given, is asked before each admission (see [ScriptAdmission]).
  CodeExecutionService({
    required this._sandbox,
    required this._executions,
    required this._store,
    this._embeddings,
    int? serverProcessCap,
    int? maxHeapBytes,
    this._metrics,
    this._formatter = const ScriptResultFormatter(),
    this.outcomeGrace = const Duration(seconds: 15),
    this.lookupTimeBudget = const Duration(
      milliseconds: CodeModeLimits.maxLookupMs,
    ),
    WorkspaceLookupBuckets? lookupBuckets,
    ScriptAdmission? admission,
  }) : lookupBuckets = lookupBuckets ?? WorkspaceLookupBuckets(),
       _slots = CodeRunnerSlots(
         serverProcessCap ??
             CodeModeLimits.defaultServerProcessCap(
               Platform.numberOfProcessors,
             ),
       ),
       _admission = admission ?? _admitAll,
       maxHeapBytes = maxHeapBytes ?? CodeModeLimits.heap.ceiling {
    if (_slots.cap < 1) {
      throw ArgumentError.value(
        serverProcessCap,
        'serverProcessCap',
        'must be at least 1',
      );
    }
    if (!CodeModeLimits.heap.admits(this.maxHeapBytes)) {
      throw ArgumentError.value(
        maxHeapBytes,
        'maxHeapBytes',
        'must be between ${CodeModeLimits.heap.floor} and '
            '${CodeModeLimits.heap.ceiling}',
      );
    }
  }

  final CodeSandboxPort _sandbox;
  final CodeExecutionRepository _executions;
  final CodeModeStoreRepository _store;
  final EmbeddingPort? _embeddings;
  final CodeExecutionMetrics? _metrics;
  final ScriptResultFormatter _formatter;
  final CodeRunnerSlots _slots;
  final ScriptAdmission _admission;
  static Future<String?> _admitAll(String _) async => null;
  final CountingSemaphore _modelBatches = CountingSemaphore(
    CodeModeLimits.maxServerModelBatches,
  );
  final Set<String> _activeRuns = {};

  /// Execution ids taken by scripts in flight in this process. With the
  /// recorded ones, what an id must not collide with.
  final Set<String> _reservedIds = {};
  bool _disposed = false;

  /// The owner's heap ceiling, in bytes: no script gets a larger heap,
  /// whatever its workspace allows.
  final int maxHeapBytes;

  /// The server time one script's lookups may take together
  /// ([CodeModeLimits.maxLookupMs] unless a test sets it).
  final Duration lookupTimeBudget;

  /// The lookup time of each workspace's scripts together
  /// ([CodeModeLimits.workspaceLookupMs] unless a test sets it).
  final WorkspaceLookupBuckets lookupBuckets;

  /// How long past its wall clock (person waits excluded) a script's runner
  /// has to report how it ended. Past it the host kills the runner and ends
  /// the script as a sandbox error, so no runner can keep a slot, a run or
  /// a process entry forever.
  final Duration outcomeGrace;

  /// The most scripts running at once on this server.
  int get serverProcessCap => _slots.cap;

  /// The most runners kept alive while their scripts wait on a person
  /// without a slot: four times [serverProcessCap].
  int get parkedCap => _slots.parkedCap;

  /// The most of [parkedCap] one workspace's runners take at once, by the
  /// same rule as [workspaceShare].
  int get parkedShare => _slots.parkedShare;

  /// The most slots one workspace holds at once: the cap less a quarter of
  /// it (at least one), so other workspaces always find room; the whole cap
  /// when it is 1.
  int get workspaceShare => _slots.workspaceShare;

  /// Scripts holding a runner slot now.
  int get slotsInUse => _slots.used;

  /// Runners parked on a person without a slot now.
  int get parkedRunners => _slots.parked;

  /// The most slots one run and its subagents hold at once: half of
  /// [workspaceShare], at least one (`CodeExecutionRequest.runTree`).
  int get treeShare => _slots.treeShare;

  /// Slots [workspaceId]'s scripts hold now.
  int slotsHeldBy(String workspaceId) => _slots.heldBy(workspaceId);

  /// Runners of [workspaceId] parked now.
  int parkedRunnersOf(String workspaceId) => _slots.parkedBy(workspaceId);

  /// Runs with a script in flight now (admitted or waiting for a slot).
  int get activeRuns => _activeRuns.length;

  /// Whether scripts can run on this host, with a reason fit for a model
  /// and a run's record: the runner's own reason can name a host path, so
  /// it stays in the server log (and, path-free, on the status page).
  @override
  CodeRunnerAvailability get availability => switch (_sandbox.availability) {
    final CodeRunnerAvailable available => available,
    CodeRunnerUnavailable() => const CodeRunnerAvailability.unavailable(
      unavailableReason,
    ),
  };

  /// Why scripts cannot run, as a model and a run's record are told.
  static const String unavailableReason =
      'the script runner has not passed its self-test on this server (the '
      'server log says why)';

  /// For tests: called when the bound on a script's wait for its slot after
  /// a person answered runs out, before it is checked.
  @visibleForTesting
  void Function()? slotBackDue;

  /// For tests: the runner slots, to hold one or give it back.
  @visibleForTesting
  CodeRunnerSlots get slots => _slots;

  /// Kills every live runner. Called at shutdown, before the databases close.
  /// Scripts still running end as cancelled and are recorded as such where
  /// the database is still open.
  Future<void> dispose() async {
    _disposed = true;
    _slots.closeAll();
    await _sandbox.dispose();
  }

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => _Execution(this, request, callNested, cancel).run();
}

/// One script, from admission to its finished record.
class _Execution {
  _Execution(this._service, this._request, this._callNested, this._cancel)
    : _clock = Stopwatch()..start(),
      _slot = ScriptSlot(
        _service._slots,
        _request.workspaceId,
        // Keyed in the workspace: a tree is one run's, so one workspace's.
        '${_request.workspaceId}\u0000${_request.runTree ?? _request.runId}',
      ),
      _recorder = ExecutionRecorder(
        _service._executions,
        workspaceId: _request.workspaceId,
      ),
      _executionId = CodeExecution.idFor(
        runId: _request.runId,
        toolCallId: _boundedId(_request.parentToolCallId),
      ),
      _description = CodeExecution.boundDescription(_request.description),
      _limits = _clampHeap(
        _request.limits.clamp(
          timeoutMs: _request.timeoutMs,
          maxOutputTokens: _request.maxOutputTokens,
        ),
        _service.maxHeapBytes,
      );

  final CodeExecutionService _service;
  final CodeExecutionRequest _request;
  final ScriptNestedCall _callNested;
  final CancellationToken _cancel;
  final Stopwatch _clock;
  final ScriptSlot _slot;
  final ExecutionRecorder _recorder;
  late DateTime _startedAt;

  /// The execution's id: [CodeExecution.idFor] of the run and the `repl`
  /// call, or that with `#<n>` appended when the pair is already taken.
  String _executionId;
  final String _description;
  bool _reserved = false;

  /// The running record, once [CodeExecutionRepository.begin] wrote it.
  CodeExecution? _record;
  CodeModeLimits _limits;

  ScriptCatalog? _catalog;
  CodeSandboxSession? _session;
  final List<String> _notes = [];
  final List<ScriptOutputItem> _output = [];
  final List<String> _console = [];

  /// The last write of each key, in the order keys were first written.
  final Map<String, CodeModeStoreWrite> _storeWrites = {};
  bool _storeWritable = false;
  final List<ScriptCall> _calls = [];
  final Queue<ScriptCall> _queue = Queue();
  final Set<Future<void>> _inFlight = {};
  int _running = 0;
  bool _serialBusy = false;
  int _questions = 0;

  late final ScriptLookups _lookups = ScriptLookups(
    catalog: () => _catalog!,
    budget: _service.lookupTimeBudget,
    buckets: _service.lookupBuckets,
    workspaceId: _request.workspaceId,
    reply: _reply,
    reject: _reject,
  );
  late final ScriptModelCalls _models = ScriptModelCalls(
    embeddings: _service._embeddings,
    serverBatches: _service._modelBatches,
    scriptEnd: _scriptEnd.token,
    ended: () => _ended,
    mayStart: _mayStart,
    reply: _reply,
    reject: _reject,
  );
  late final ScriptPastCalls _past = ScriptPastCalls.of(
    _request,
    buckets: _service.lookupBuckets,
    ended: () => _ended,
    mayStart: _mayStart,
    reply: _reply,
    reject: _reject,
  );
  bool _ended = false;
  final CancellationTokenSource _scriptEnd = CancellationTokenSource();
  int _admissionWaitMs = 0;
  final Stopwatch _scriptClock = Stopwatch();

  // Person waits: the deadline hold and the time. The slot is [_slot]'s.
  int _waitDepth = 0;
  CodeSandboxDeadlineHold? _hold;
  final Stopwatch _personWait = Stopwatch();
  final List<Completer<void>> _resumeWaiters = [];

  /// Bounds the wait for a slot back after a person answered; why the
  /// script was stopped when the slot did not come back in time.
  Timer? _slotBack;
  String? _slotNotBack;

  /// The most bytes of a caller-supplied `repl` tool call id. It ends up in
  /// execution ids, call rows and transcript events.
  static const int maxParentToolCallIdBytes = 256;

  /// How many times a taken id is retried with the next suffix: only a
  /// record written between the suffix read and the insert can take one.
  static const int maxIdAttempts = 5;

  /// [id] made safe to name a refused call with in a log line or a result:
  /// one line with no control, separator or bidirectional character (the
  /// sanitiser every caller- or script-chosen text in a log line goes
  /// through), cut to [maxParentToolCallIdBytes].
  static String _boundedId(String id) {
    final cut = cutToUtf8Bytes(
      oneLineLabel(id, maxParentToolCallIdBytes),
      maxParentToolCallIdBytes,
    );
    return cut.isEmpty ? '?' : cut;
  }

  static CodeModeLimits _clampHeap(CodeModeLimits limits, int maxHeapBytes) =>
      limits.heapBytes <= maxHeapBytes
      ? limits
      : CodeModeLimits(
          wallClockMs: limits.wallClockMs,
          cpuMs: limits.cpuMs,
          heapBytes: maxHeapBytes,
          maxNestedCalls: limits.maxNestedCalls,
          maxInFlightCalls: limits.maxInFlightCalls,
          maxOutputTokens: limits.maxOutputTokens,
        );

  String get _runKey => '${_request.workspaceId}\u0000${_request.runId}';

  Future<CodeExecutionResult> run() async {
    // One script per run, checked before anything else is done for the call.
    if (!_service._activeRuns.add(_runKey)) {
      return _refuse(
        CodeExecutionErrorKind.runBusy,
        'another script of this run is still running. Scripts of one run '
        'run one at a time; call repl again when it has finished.',
      );
    }
    try {
      return await _run();
    } finally {
      _service._activeRuns.remove(_runKey);
      _slot.end();
      if (_reserved) {
        _service._reservedIds.remove(_executionId);
      }
    }
  }

  Future<CodeExecutionResult> _run() async {
    final parentId = _request.parentToolCallId;
    if (utf8Length(parentId) > maxParentToolCallIdBytes ||
        hasUnsafeCharacters(parentId)) {
      return _refuse(
        CodeExecutionErrorKind.invalidToolCallId,
        'the repl call id must be at most $maxParentToolCallIdBytes bytes '
        'with no control, separator or bidirectional characters.',
      );
    }
    final refusal = _admissionRefusal();
    if (refusal != null) {
      return _refuse(refusal.$1, refusal.$2);
    }

    final wait = Stopwatch()..start();
    // The boot sweep of the workspace first, within the wall clock; on a
    // cancel the admission below refuses.
    final String? notReady;
    try {
      notReady =
          await Future.any([
            _service._admission(_request.workspaceId),
            _cancel.whenCancelled.then((_) => null),
          ]).timeout(
            Duration(milliseconds: _limits.wallClockMs),
            onTimeout: () => _sweepPending,
          );
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: the admission check failed', e, st);
      return _refuse(CodeExecutionErrorKind.auditUnavailable, _unchecked);
    }
    if (notReady == _sweepPending) {
      return _refuse(
        CodeExecutionErrorKind.serverBusy,
        'the server was still closing the records of scripts its previous '
        'process left running when the script\'s '
        '${_limits.wallClockMs ~/ 1000} s limit ran out.',
      );
    }
    if (notReady != null) {
      return _refuse(CodeExecutionErrorKind.auditUnavailable, notReady);
    }
    // A script that queues for a slot waits at most half its wall clock:
    // one admitted later would run on what the queue left of it and end
    // `deadline`, its own fault on the record, when the cause was the
    // server's (slots held by other runs). It is refused `server_busy`.
    final requestedMs = _limits.wallClockMs;
    final queueStart = wait.elapsedMilliseconds;
    final admitted = await _slot.admit(
      timeout: Duration(
        milliseconds: math.max(
          1,
          math.min(requestedMs - queueStart, requestedMs - requestedMs ~/ 2),
        ),
      ),
      cancel: _cancel,
    );
    _admissionWaitMs = wait.elapsedMilliseconds;
    final queuedMs = _admissionWaitMs - queueStart;
    if (admitted && (requestedMs - queuedMs) * 2 < requestedMs) {
      // Granted after the half, before the timer fired: the slot goes to
      // the next script now, not after this refusal is written.
      _slot.end();
      return _refuse(CodeExecutionErrorKind.serverBusy, _serverBusy(queuedMs));
    }
    if (!admitted) {
      if (_cancel.isCancelled) {
        return _refuse(
          CodeExecutionErrorKind.cancelled,
          'The script was cancelled while it waited for a runner.',
          status: CodeExecutionStatus.cancelled,
        );
      }
      if (_service._disposed) {
        return _refuse(
          CodeExecutionErrorKind.shutdown,
          'the server is shutting down.',
        );
      }
      return _refuse(CodeExecutionErrorKind.serverBusy, _serverBusy(queuedMs));
    }
    if (_admissionWaitMs > 0) {
      // The wait counts against the wall clock, down to the floor: an
      // admitted script always gets at least that. Refusing below it would
      // refuse every script whose wall clock is the floor (a `timeout` of a
      // second or less clamps to it) for the time its admission took,
      // claiming no runner was free when one was. A script that queued for
      // its slot has at least half its wall clock left here.
      final remaining = math.max(
        CodeModeLimits.wallClock.floor,
        _limits.wallClockMs - _admissionWaitMs,
      );
      _limits = CodeModeLimits(
        wallClockMs: remaining,
        cpuMs: _limits.cpuMs,
        heapBytes: _limits.heapBytes,
        maxNestedCalls: _limits.maxNestedCalls,
        maxInFlightCalls: _limits.maxInFlightCalls,
        maxOutputTokens: _limits.maxOutputTokens,
      );
    }
    final begun = await _begin();
    if (begun != null) {
      return begun;
    }
    return _admitted();
  }

  /// Records the admitted script as running under a free id. Returns the
  /// refusal when it cannot be recorded, so it does not run unaudited.
  Future<CodeExecutionResult?> _begin() async {
    final base = CodeExecution.idFor(
      runId: _request.runId,
      toolCallId: _request.parentToolCallId,
    );
    final int highest;
    try {
      highest = await _service._executions.highestIdSuffix(
        _request.workspaceId,
        runId: _request.runId,
        toolCallId: _request.parentToolCallId,
      );
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: reading execution ids failed', e, st);
      return _refuse(
        CodeExecutionErrorKind.auditUnavailable,
        'the script could not be recorded, so it was not run.',
      );
    }
    var n = highest + 1;
    for (var attempt = 0; attempt < maxIdAttempts; attempt++, n++) {
      String candidate() => n == 1 ? base : '$base#$n';
      while (!_service._reservedIds.add(candidate())) {
        n++;
      }
      _executionId = candidate();
      _reserved = true;
      _startedAt = DateTime.now().toUtc();
      final running = CodeExecution(
        id: _executionId,
        runId: _request.runId,
        toolCallId: _request.parentToolCallId,
        surface: _request.surface,
        startedAt: _startedAt,
        durationMs: 0,
        status: CodeExecutionStatus.running,
        sourceHash: sha256.convert(utf8.encode(_request.code)).toString(),
        sourceBytes: utf8Length(_request.code),
        limits: _limits,
        conversationId: _request.conversationId,
        agentId: _request.agentId,
        spaceId: _request.spaceId,
        description: _description,
      );
      try {
        await _recorder.begin(running, source: _request.code);
        _record = running;
        return null;
      } on CodeExecutionBeginRefused catch (e) {
        _service._reservedIds.remove(_executionId);
        _reserved = false;
        switch (e.reason) {
          case CodeExecutionBeginRefusal.noRun:
            return _refuse(
              CodeExecutionErrorKind.noRunLog,
              'this run keeps no run log, so a script could not be recorded '
              'and was not run.',
            );
          case CodeExecutionBeginRefusal.spaceGone:
            return _refuse(
              CodeExecutionErrorKind.spaceGone,
              "this run's space was deleted, so a script could not be "
              'recorded with it and was not run.',
            );
          case CodeExecutionBeginRefusal.idTaken:
            break;
        }
      } on Object catch (e, st) {
        _service._reservedIds.remove(_executionId);
        _reserved = false;
        CcInfraLog.error(
          'code mode: recording execution $_executionId failed',
          e,
          st,
        );
        return _refuse(
          CodeExecutionErrorKind.auditUnavailable,
          'the script could not be recorded, so it was not run.',
        );
      }
    }
    return _refuse(
      CodeExecutionErrorKind.executionId,
      'no free execution id was found for this repl call.',
    );
  }

  (String, String)? _admissionRefusal() {
    if (_service._disposed) {
      return (CodeExecutionErrorKind.shutdown, 'the server is shutting down.');
    }
    final availability = _service.availability;
    if (availability case CodeRunnerUnavailable(:final reason)) {
      return (
        CodeExecutionErrorKind.unavailable,
        'code mode is not available on this host: $reason',
      );
    }
    final bytes = utf8Length(_request.code);
    if (bytes > CodeModeLimits.maxSourceBytes) {
      return (
        CodeExecutionErrorKind.sourceTooLarge,
        'the script is $bytes bytes; the limit is '
            '${CodeModeLimits.maxSourceBytes ~/ 1024} KiB. Split the work into '
            'smaller scripts.',
      );
    }
    try {
      _catalog = ScriptCatalog(
        _request.tools,
        namespaceDescriptions: _request.namespaceDescriptions,
      );
    } on ArgumentError catch (e) {
      return (
        CodeExecutionErrorKind.catalog,
        'the tool catalog is invalid: ${e.message}',
      );
    }
    return null;
  }

  Future<CodeExecutionResult> _admitted() async {
    final snapshot = await _readStore();
    final CodeSandboxSession session;
    try {
      session = await _service._sandbox.start(
        CodeSandboxStart(
          code: _request.code,
          limits: _limits,
          catalog: _catalog!.allTools(),
          returnBudgetChars: _service._formatter.returnBudgetChars(
            _limits.maxOutputTokens,
          ),
          store: snapshot,
          storeWritable: _storeWritable,
        ),
        cancel: _cancel,
      );
    } on CodeSandboxStartException catch (e) {
      final cancelled = e.errorKind == CodeExecutionErrorKind.cancelled;
      return _finish(
        cancelled
            ? CodeExecutionStatus.cancelled
            : CodeExecutionStatus.sandboxError,
        errorKind: e.errorKind,
        detail: e.message,
      );
    }
    _session = session;
    _scriptClock.start();
    final cancelled = _cancel.whenCancelled.then((_) => session.cancel());
    final eventsDone = Completer<void>();
    session.events.listen(
      _onEvent,
      onDone: eventsDone.complete,
      onError: (Object _) {},
    );
    final outcome = await _outcomeOf(session);
    // The events close before the outcome completes; a session the host gave
    // up on may never close them.
    await eventsDone.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    unawaited(cancelled);
    await _endScript();
    // Stopped because no slot came back after a person answered: it did not
    // finish, and the calls it made stand as they are.
    final notBack = _slotNotBack;
    return _finish(
      notBack == null ? outcome.status : CodeExecutionStatus.timedOut,
      errorKind: notBack == null
          ? outcome.errorKind
          : CodeExecutionErrorKind.serverBusy,
      detail: notBack ?? outcome.detail,
      sandbox: outcome,
    );
  }

  /// [session]'s outcome, bounded by [watchOutcome].
  Future<CodeSandboxOutcome> _outcomeOf(CodeSandboxSession session) =>
      watchOutcome(
        session,
        remaining: _remainingScriptTime,
        personWaiting: () => _waitDepth > 0,
        overrunMs: _overrunMs,
        grace: _service.outcomeGrace,
        executionId: _executionId,
      );

  /// Milliseconds of script time past the wall clock (negative while time
  /// is left).
  int _overrunMs() =>
      _scriptClock.elapsedMilliseconds -
      _personWait.elapsedMilliseconds -
      _limits.wallClockMs;

  /// Why a script that queued [queuedMs] for a slot is refused.
  String _serverBusy(int queuedMs) {
    final limitMs = _request.limits
        .clamp(timeoutMs: _request.timeoutMs)
        .wallClockMs;
    return _busyText(
      'the script waited ${_seconds(queuedMs)} s for a script runner, and a '
      'script may wait at most half of its ${_seconds(limitMs)} s limit',
    );
  }

  /// [why] a script got no runner in time, with the caps that decide it.
  String _busyText(String why) {
    final slots = _service._slots;
    return '$why: this server runs at most ${slots.cap} '
        '${slots.cap == 1 ? 'script' : 'scripts'} at once '
        '(--code-mode-max-processes), at most ${slots.workspaceShare} of them '
        'for one workspace and ${slots.treeShare} for one run with its '
        'subagents.';
  }

  static String _seconds(int ms) =>
      (ms / 1000).toStringAsFixed(ms % 1000 == 0 ? 0 : 1);

  Future<Map<String, String>> _readStore() async {
    final conversationId = _request.conversationId;
    final agentId = _request.agentId;
    if (!_request.storeEnabled) {
      _storeWritable = false;
      if (_request.code.contains('store(') || _request.code.contains('load(')) {
        _notes.add(
          "store() is unavailable in this run: a subagent's scripts do not "
          "use its parent's values, so store() throws and load() returns "
          'nothing.',
        );
      }
      return const {};
    }
    if (conversationId == null ||
        conversationId.isEmpty ||
        agentId == null ||
        agentId.isEmpty) {
      _storeWritable = false;
      if (_request.code.contains('store(')) {
        // The runner's own refusal only names a zero size limit; say why.
        _notes.add(
          'store() is unavailable in this run: it has no conversation and '
          'agent to keep values under, so store() throws and load() returns '
          'nothing.',
        );
      }
      return const {};
    }
    try {
      final values = await _service._store.readAll(
        _request.workspaceId,
        conversationId: conversationId,
        agentId: agentId,
      );
      _storeWritable = !_request.readOnly;
      if (_request.readOnly && _request.code.contains('store(')) {
        _notes.add(ScriptPastCalls.readOnlyStore);
      }
      return values;
    } on Object catch (e, st) {
      CcInfraLog.error(
        'code mode: reading stored values for $_executionId failed',
        e,
        st,
      );
      _storeWritable = false;
      _notes.add(
        'Stored values could not be read, so load() returned nothing and '
        'store() was unavailable in this script.',
      );
      return const {};
    }
  }

  // -----------------------------------------------------------------------
  // Events

  void _onEvent(CodeSandboxEvent event) {
    switch (event) {
      case CodeSandboxCall(target: CodeSandboxCallTarget.tool):
        _onToolCall(event);
      case CodeSandboxCall(target: CodeSandboxCallTarget.host):
        unawaited(_onHostCall(event));
      case CodeSandboxOutput(:final item):
        _output.add(item);
        if (item is ScriptConsoleOutput) {
          _console.add('[${item.level.wire}] ${item.text}');
        }
      case CodeSandboxStoreWrite(:final key, :final valueJson):
        _onStoreWrite(CodeModeStoreWrite(key: key, valueJson: valueJson));
    }
  }

  void _reject(String id, String message, {String? status}) {
    _session?.reply(
      CodeSandboxReply(
        id: id,
        ok: false,
        payload: {'message': message, 'status': ?status},
      ),
    );
  }

  void _onStoreWrite(CodeModeStoreWrite write) {
    if (!_storeWritable) {
      // The runner was given a zero store budget; the host ends a runner
      // that sends a store frame anyway, so nothing can get here.
      return;
    }
    final problem = CodeModeStoreRules.checkWrite(write);
    if (problem != null) {
      _notes.add('Not saved: $problem');
      return;
    }
    // Only the last write of a key is committed, so only it is kept.
    _storeWrites
      ..remove(write.key)
      ..[write.key] = write;
  }

  void _onToolCall(CodeSandboxCall call) {
    final entry = _catalog!.find(call.name);
    if (entry == null) {
      _reject(
        call.id,
        'Unknown tool "${call.name}". Use searchTools(query) or ALL_TOOLS to '
        'find one.',
        status: NestedCallStatus.unknownTool.wire,
      );
      return;
    }
    if (_calls.length >= _limits.maxNestedCalls) {
      _reject(
        call.id,
        _past.callLimit(_limits.maxNestedCalls),
        status: kScriptLimitStatus,
      );
      return;
    }
    final argsJson = jsonEncode(call.arguments);
    final argsBytes = utf8Length(argsJson);
    if (argsBytes > CodeModeLimits.maxCallArgumentBytes) {
      _reject(
        call.id,
        'The arguments to ${entry.name} are $argsBytes bytes; a call takes at '
        'most ${CodeModeLimits.maxCallArgumentBytes ~/ 1024} KiB.',
        status: NestedCallStatus.invalidArgs.wire,
      );
      return;
    }
    final isQuestion = entry.name == kScriptQuestionToolName;
    if (isQuestion) {
      if (_questions >= CodeModeLimits.maxQuestions) {
        _reject(
          call.id,
          'This script has already asked ${CodeModeLimits.maxQuestions} '
          'questions, its limit, so this one was not shown. Ask it directly '
          'with ask_user instead.',
          status: kScriptLimitStatus,
        );
        return;
      }
      _questions++;
    }
    final sequence = _calls.length + 1;
    final record = ScriptCall(
      replyId: call.id,
      sequence: sequence,
      toolCallId: CodeExecutionCall.nestedToolCallId(
        _request.parentToolCallId,
        sequence,
      ),
      name: entry.name,
      arguments: call.arguments,
      argumentBytes: argsBytes,
      isQuestion: isQuestion,
      parallel:
          !isQuestion &&
          entry.tool.tier.name == 'read' &&
          entry.tool.effects.isEmpty,
      site: call.site,
    );
    _calls.add(record);
    _queue.add(record);
    _pump();
  }

  /// Starts queued calls in order while their lane has room. The head of the
  /// queue blocks everything behind it, so calls start in sequence order.
  /// Nothing starts once the session has ended (a runner killed for a
  /// violation may have asked for more before it was stopped), and nothing
  /// while the script is [_held].
  void _pump() {
    while (_queue.isNotEmpty && !_ended && !(_session?.ended ?? false)) {
      if (_held) {
        return;
      }
      final next = _queue.first;
      if (_running >= _limits.maxInFlightCalls) {
        return;
      }
      if (!next.parallel && _serialBusy) {
        return;
      }
      _queue.removeFirst();
      _running++;
      if (!next.parallel) {
        _serialBusy = true;
      }
      late final Future<void> done;
      done = _runCall(next).whenComplete(() {
        _running--;
        if (!next.parallel) {
          _serialBusy = false;
        }
        _inFlight.remove(done);
        _pump();
      });
      _inFlight.add(done);
    }
  }

  /// Whether the script may start nothing new: one of its calls waits on a
  /// person, it gave its slot up for that wait and has not got it back, or
  /// it was stopped for not getting it back in time (a slot granted after
  /// that starts nothing). What it sends meanwhile waits in [_queue] (a
  /// `models.*` batch in [_mayStart]); calls already running go on.
  bool get _held => _waitDepth > 0 || _slot.parked || _slotNotBack != null;

  /// Completes once the script is not [_held], or has ended.
  Future<void> _mayStart() async {
    while (!_ended && _held) {
      final ready = Completer<void>();
      _resumeWaiters.add(ready);
      await ready.future;
    }
  }

  /// Starts what was held, as far as nothing holds it any more.
  void _resume() {
    for (final waiter in _resumeWaiters) {
      waiter.complete();
    }
    _resumeWaiters.clear();
    _pump();
  }

  Duration _remainingScriptTime() {
    final used =
        _scriptClock.elapsedMilliseconds - _personWait.elapsedMilliseconds;
    return Duration(milliseconds: math.max(1, _limits.wallClockMs - used));
  }

  Future<void> _runCall(ScriptCall call) async {
    call.startOffsetMs = _clock.elapsedMilliseconds;
    final clock = Stopwatch()..start();
    // The call keeps no value: until the reply, only the value's JSON bytes
    // wait (at most [CodeModeLimits.maxNestedResultBytes]), not the decoded
    // value, which can take far more memory. No variable here holds the
    // outcome past this line.
    final (status, error, valueJson) = _settle(
      call,
      await _invoke(call, clock),
      clock,
    );
    // A script parked on a person holds no runner slot; it gets one back
    // before it sees the answer.
    await _slot.back;
    if (_ended) {
      return;
    }
    if (valueJson != null) {
      _session!.reply(CodeSandboxReply.json(call.replyId, valueJson));
    } else {
      _reject(
        call.replyId,
        error ?? '${call.name} did not complete.',
        status: status.wire,
      );
    }
  }

  /// Runs [call] through the surface and closes any wait its gate left
  /// open.
  Future<NestedCallOutcome> _invoke(ScriptCall call, Stopwatch clock) async {
    NestedCallOutcome outcome;
    try {
      outcome = await _callNested(
        NestedCallRequest(
          sequence: call.sequence,
          toolCallId: call.toolCallId,
          name: call.name,
          arguments: call.start(),
          origin: ScriptCallOrigin(
            parentToolCallId: _request.parentToolCallId,
            executionId: _executionId,
          ),
          deadline: _remainingScriptTime(),
          site: call.site,
          cancel: _scriptEnd.token,
          onPersonWait: (waiting) => _onPersonWait(call, waiting),
          onToolStarted: (decision) {
            call
              ..toolStarted = true
              ..toolStartedAfter = decision;
          },
        ),
      );
    } on Object catch (e, st) {
      // What the server threw can name a host path: it goes to the log.
      CcInfraLog.error('code mode: the call to ${call.name} failed', e, st);
      outcome = NestedCallOutcome(
        status: NestedCallStatus.failed,
        errorMessage: 'The call to ${call.name} failed on the server.',
        durationMs: clock.elapsedMilliseconds,
      );
    }
    while (call.waitDepth > 0) {
      _onPersonWait(call, false);
    }
    return outcome;
  }

  /// Checks [outcome]'s value, settles and records [call], and returns what
  /// its reply needs: the status, the error and, for a completed call, the
  /// value as UTF-8 JSON.
  (NestedCallStatus, String?, Uint8List?) _settle(
    ScriptCall call,
    NestedCallOutcome outcome,
    Stopwatch clock,
  ) {
    final (checked, encoded) = _checkValue(call, outcome);
    call
      ..durationMs = math.max(checked.durationMs, clock.elapsedMilliseconds)
      ..settle(checked);
    _recorder.append(_executionId, call);
    return (
      checked.status,
      checked.errorMessage,
      checked.status == NestedCallStatus.completed ? encoded : null,
    );
  }

  /// A completed outcome whose value the script cannot receive becomes a
  /// failure that says why. Also returns the value's UTF-8 JSON when it can
  /// be received. A tool's JSON text ([ScriptJsonText]) is decoded only
  /// inside this encode, so no decoded result outlives it; the depth is read
  /// from the encoded bytes.
  (NestedCallOutcome, Uint8List?) _checkValue(
    ScriptCall call,
    NestedCallOutcome outcome,
  ) {
    if (outcome.status != NestedCallStatus.completed) {
      return (outcome, null);
    }
    String? problem;
    var bytes = outcome.resultBytes;
    final text = tryJsonEncode(outcome.value);
    final encoded = text == null ? null : utf8.encode(text);
    if (encoded == null) {
      problem = 'The result of ${call.name} is not JSON.';
    } else {
      bytes = encoded.length;
      if (bytes > CodeModeLimits.maxNestedResultBytes) {
        problem =
            'The result of ${call.name} is $bytes bytes; a script receives at '
            'most ${CodeModeLimits.maxNestedResultBytes ~/ (1024 * 1024)} MiB. '
            'Narrow the request (a path, a pattern, a limit) and try again.';
      } else if (scanJsonFrame(encoded).depth > kRunnerMaxJsonDepth - 2) {
        problem =
            'The result of ${call.name} is nested more than '
            '${kRunnerMaxJsonDepth - 2} levels deep, which a script cannot '
            'receive.';
      }
    }
    if (problem == null) {
      return (
        outcome.resultBytes == bytes
            ? outcome
            : NestedCallOutcome(
                status: outcome.status,
                value: outcome.value,
                gateDecision: outcome.gateDecision,
                durationMs: outcome.durationMs,
                approvalWaitMs: outcome.approvalWaitMs,
                resultBytes: bytes,
              ),
        encoded,
      );
    }
    return (
      NestedCallOutcome(
        status: NestedCallStatus.failed,
        errorMessage: problem,
        gateDecision: outcome.gateDecision,
        durationMs: outcome.durationMs,
        approvalWaitMs: outcome.approvalWaitMs,
        resultBytes: bytes,
      ),
      null,
    );
  }

  // -----------------------------------------------------------------------
  // Waiting on a person

  void _onPersonWait(ScriptCall call, bool waiting) {
    if (waiting) {
      call.waitDepth++;
      if (_waitDepth++ == 0) {
        // The deadline holds while a person decides, and the slot goes to
        // the next script while the parked pool has room.
        _hold ??= _session?.holdDeadline();
        if (!_personWait.isRunning) {
          _personWait.start();
        }
        _slot.waitBegan();
      }
      return;
    }
    if (call.waitDepth == 0) {
      return;
    }
    call.waitDepth--;
    if (--_waitDepth == 0) {
      // The answer is in: the script's clock runs again at once, so the
      // time it takes to get a slot back is the script's, and a script
      // that cannot get one ends at its deadline.
      _hold?.release();
      _hold = null;
      _personWait.stop();
      _slot.waitEnded();
      _boundSlotBack();
      // What the script sent meanwhile starts once its slot is back (at
      // once when it kept it), never from inside this callback.
      unawaited(
        _slot.back.then((_) {
          _slotBack?.cancel();
          _resume();
        }),
      );
    }
  }

  /// The rule of admission on the way back from a person: a script that
  /// gave its slot up gets it back within half the time its clock had left
  /// at the answer, or it is stopped and ends `server_busy` (the cause is
  /// other scripts holding the slots, not the script). A slot that comes
  /// back in time changes nothing. Two exceptions: a script with less than
  /// twice the wall clock's floor left at the answer gets no bound (it ends
  /// at its own deadline, as before), and one already cancelled, or on a
  /// server shutting down, ends as that, not `server_busy`.
  void _boundSlotBack() {
    _slotBack?.cancel();
    final leftMs = _remainingScriptTime().inMilliseconds;
    if (!_slot.parked || leftMs < 2 * CodeModeLimits.wallClock.floor) {
      return;
    }
    final waited = Stopwatch()..start();
    _slotBack = Timer(Duration(milliseconds: leftMs - leftMs ~/ 2), () {
      _service.slotBackDue?.call();
      if (_ended ||
          !_slot.parked ||
          _waitDepth > 0 ||
          _cancel.isCancelled ||
          _service._disposed) {
        return;
      }
      _slotNotBack = _busyText(
        'the script waited ${_seconds(waited.elapsedMilliseconds)} s for a '
        'script runner after a person answered, and a script may wait at '
        'most half of the ${_seconds(leftMs)} s its limit had left then',
      );
      _session?.cancel();
    });
  }

  // -----------------------------------------------------------------------
  // Host calls

  Future<void> _onHostCall(CodeSandboxCall call) async {
    switch (call.name) {
      case 'searchTools' || 'describeTool' || 'describeNamespace':
        _lookups.answer(call);
      case 'models.embed' || 'models.rank' || 'models.classify':
        await _models.answer(call);
      case 'history' || 'outputs' || 'loadOutput' || 'keep':
        await _past.answer(call);
      default:
        _reject(call.id, 'Unknown host function "${call.name}".');
    }
  }

  void _reply(String id, Object? value) {
    if (!_ended) {
      _session?.reply(CodeSandboxReply.value(id, value));
    }
  }

  // -----------------------------------------------------------------------
  // The end

  /// Cancels every nested call still running and gives them
  /// [CodeModeLimits.nestedSettleGraceMs] to settle, so the record states how
  /// each one ended. Calls still queued never start.
  Future<void> _endScript() async {
    _ended = true;
    _slotBack?.cancel();
    _scriptEnd.cancel('The script ended.');
    _queue.clear();
    // The runner is gone: its slot or parked place goes back now, and calls
    // waiting to reply stop waiting for one.
    _slot.end();
    if (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList()).timeout(
        const Duration(milliseconds: CodeModeLimits.nestedSettleGraceMs),
        onTimeout: () => const [],
      );
    }
    _models.end();
    _resume();
    _hold?.release();
    _hold = null;
    _personWait.stop();
  }

  /// Ends a call refused before it was admitted. It did nothing, so it is
  /// not recorded: it is counted, and one line with its ids is logged.
  CodeExecutionResult _refuse(
    String errorKind,
    String detail, {
    CodeExecutionStatus status = CodeExecutionStatus.refused,
  }) {
    final outcome = CodeExecutionOutcome(
      status: status,
      durationMs: _clock.elapsedMilliseconds,
      detail: detail,
      source: _request.code,
    );
    final result = _service._formatter.format(
      outcome,
      budgetTokens: _limits.maxOutputTokens,
    );
    final execution = CodeExecution(
      id: CodeExecution.idFor(
        runId: _request.runId,
        toolCallId: _boundedId(_request.parentToolCallId),
      ),
      runId: _request.runId,
      toolCallId: _boundedId(_request.parentToolCallId),
      surface: _request.surface,
      startedAt: DateTime.now().toUtc(),
      durationMs: _clock.elapsedMilliseconds,
      status: status,
      sourceHash: sha256.convert(utf8.encode(_request.code)).toString(),
      sourceBytes: utf8Length(_request.code),
      limits: _limits,
      conversationId: _request.conversationId,
      agentId: _request.agentId,
      spaceId: _request.spaceId,
      description: _description,
      errorKind: _kindFor(status, errorKind),
    );
    CcInfraLog.info(
      'code mode: a repl call was refused before admission and not '
      'recorded (kind ${execution.errorKind}, workspace '
      '${_request.workspaceId}, run ${_request.runId}, call '
      '${execution.toolCallId}).',
    );
    _recordMetrics(execution, const [], result, admitted: false);
    return CodeExecutionResult(
      result: result,
      execution: execution,
      calls: const [],
    );
  }

  /// [kind] when it is in the vocabulary; otherwise the closest kind the
  /// host can vouch for. None for a completed script.
  static String? _kindFor(CodeExecutionStatus status, String? kind) {
    if (status == CodeExecutionStatus.completed) {
      return null;
    }
    if (CodeExecutionErrorKind.isKnown(kind)) {
      return kind;
    }
    return status == CodeExecutionStatus.failed
        ? CodeExecutionErrorKind.scriptError
        : CodeExecutionErrorKind.hostError;
  }

  /// Ends an admitted script: commits its store when it completed, shapes
  /// the result and finishes its running record exactly once.
  Future<CodeExecutionResult> _finish(
    CodeExecutionStatus status, {
    String? errorKind,
    String? detail,
    CodeSandboxOutcome? sandbox,
  }) async {
    // From here a call that settles is a late log line, so the result and
    // the record state the same rows.
    _recorder.stopAppends();
    final endedAtMs = _clock.elapsedMilliseconds;
    final calls = [
      for (final c in _calls) c.summary(_executionId, endedAtMs: endedAtMs),
    ];
    final questions = [for (final c in _calls) ?c.questionRecord];

    if (status == CodeExecutionStatus.completed) {
      await _commitStore();
    } else if (_storeWrites.isNotEmpty) {
      _notes.add(
        'Values passed to store() were not saved, because the script did not '
        'complete.',
      );
    }
    _notes.addAll(await _past.settle(status));

    CodeExecutionOutcome outcomeWith(List<String> notes) =>
        CodeExecutionOutcome(
          status: status,
          durationMs: _clock.elapsedMilliseconds,
          output: _output,
          returnValue: sandbox?.returnValue,
          error: sandbox?.error,
          calls: [
            for (final c in calls)
              ScriptCallSummary(name: c.toolName, status: c.status),
          ],
          questions: questions,
          detail: _past.withFix(detail, errorKind),
          source: _request.code,
          notes: notes,
        );
    final formatter = _service._formatter;
    var outcome = outcomeWith(_notes);
    final full = formatter.renderOutput(outcome);
    ToolOutputReference? reference;
    final sink = _request.fullOutputSink;
    if (sink != null &&
        formatter.exceedsBudget(
          full,
          formatter.outputBudget(outcome, _limits.maxOutputTokens),
        )) {
      try {
        reference = await sink(full);
      } on Object catch (e, st) {
        CcInfraLog.error(
          'code mode: storing the full output of $_executionId failed',
          e,
          st,
        );
      }
    }
    var result = formatter.format(
      outcome,
      budgetTokens: _limits.maxOutputTokens,
      fullOutput: reference,
    );

    final execution = _record!.ended(
      status: status,
      durationMs: _clock.elapsedMilliseconds,
      errorKind: _kindFor(status, errorKind),
      cpuMs: sandbox?.stats?.cpuMs,
      peakHeapBytes: sandbox?.stats?.peakHeapBytes,
      callCounts: NestedCallCounts.of(calls),
      questionCount: questions.length,
      outputBytes: utf8Length(full),
      outputTruncated: result.truncated,
      engineVersion: _session?.handshake.engine,
      lockdown: _session?.handshake.lockdown.toJson(),
    );
    final payload = CodeExecutionPayload.bounded(
      executionId: _executionId,
      source: _request.code,
      output: result.text,
      console: _console.join('\n'),
      errorName: sandbox?.error?.name,
    );
    final finished = await _recorder.finish(
      execution,
      payload: payload,
      calls: calls,
    );
    if (finished == CodeExecutionFinishResult.gone) {
      CcInfraLog.info(
        'code mode: the record of $_executionId was deleted with its run '
        'or space while the script ran.',
      );
    } else if (finished == null) {
      outcome = outcomeWith([
        ..._notes,
        'The audit record of this script could not be completed.',
      ]);
      result = formatter.format(
        outcome,
        budgetTokens: _limits.maxOutputTokens,
        fullOutput: reference,
      );
    }

    _recordMetrics(execution, calls, result, admitted: true);
    return CodeExecutionResult(
      result: result,
      execution: execution,
      calls: calls,
    );
  }

  Future<void> _commitStore() async {
    if (_storeWrites.isEmpty || !_storeWritable) {
      return;
    }
    try {
      await _service._store.commit(
        _request.workspaceId,
        conversationId: _request.conversationId!,
        agentId: _request.agentId!,
        writes: List.unmodifiable(_storeWrites.values),
      );
    } on Object catch (e, st) {
      CcInfraLog.warning(
        'code mode: stored values of $_executionId were not saved: $e',
      );
      if (e is! FormatException && e is! ArgumentError) {
        CcInfraLog.debug('$st');
      }
      _notes.add('Values passed to store() were not saved: ${_reason(e)}');
    }
  }

  /// What a script is told about values that were not saved: a bound it
  /// broke, never a server error's text (it can name a host path).
  static String _reason(Object e) => switch (e) {
    ArgumentError(:final message) => '$message',
    FormatException(:final message) => message,
    _ => 'the server could not save them.',
  };

  void _recordMetrics(
    CodeExecution execution,
    List<CodeExecutionCall> calls,
    ScriptResult result, {
    required bool admitted,
  }) {
    final metrics = _service._metrics;
    if (metrics == null) {
      return;
    }
    try {
      metrics.recordExecution(
        CodeExecutionSample(
          admitted: admitted,
          surface: execution.surface,
          status: execution.status,
          errorKind: execution.errorKind,
          durationMs: execution.durationMs,
          admissionWaitMs: _admissionWaitMs,
          personWaitMs: _personWait.elapsedMilliseconds,
          calls: execution.callCounts,
          questionCount: execution.questionCount,
          nestedResultBytes: calls.fold(0, (sum, c) => sum + c.resultBytes),
          outputBytes: execution.outputBytes,
          returnedChars: result.text.length,
          outputTruncated: result.truncated,
        ),
      );
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: a metrics listener threw', e, st);
    }
  }
}
