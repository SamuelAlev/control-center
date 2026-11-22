part of 'agent_loop_runner.dart';

/// One call observed in a turn, for the checklist supervisor: a model-issued
/// call or a call one of them made through its reentry.
typedef _ObservedCall = ({String name, Map<String, dynamic> args});

/// Executes ONE turn's tool calls and appends their results to the history.
///
/// Parallel-safe calls run as a bounded batch when no hook intercepts tools;
/// exclusive tools stay sequential. Results append in model call order whatever
/// the completion order, so timing cannot reorder the next cached request.
/// Deferred tools load their schema and run in the same step.
///
/// Every model-issued call gets a [ToolReentry]; the calls it makes through it
/// stream their events between its start and result events.
class _ToolStep {
  _ToolStep(this.s, this.output, {this.rewindRejection});

  final _RunState s;
  final _TurnOutput output;

  /// Set when the turn's `rewind` named an unknown checkpoint: the call is
  /// answered with this error instead of rewinding.
  final String? rewindRejection;

  /// The turn's calls in model order, each followed by the calls it made
  /// through its reentry: what the checklist supervisor observes.
  final List<_ObservedCall> observedCalls = <_ObservedCall>[];

  AgentLoopConfig get config => s.config;
  List<_PendingTool> get pending => output.pending;

  Stream<AgentLoopEvent> execute() async* {
    final activatedByCall = s.catalog.activate(pending.map((t) => t.name));
    if (activatedByCall.isNotEmpty) {
      yield LoopToolsActivated(names: activatedByCall, trigger: 'direct_call');
    }
    final batchingAllowed = s.batchingAllowed;
    final resultBlocks = <HarnessToolResultBlock>[];
    // Deferred tools a RESULT asked for (a tool search loading its hits), so
    // the model can call one on its next turn rather than spending a round
    // trip asking for the schema it just read a description of.
    final requestedActivations = <String>[];
    final byName = s.catalog.byName;
    var pi = 0;
    while (pi < pending.length) {
      if (s.cancel.isCancelled) {
        // The assistant turn is already in history. Pair every requested
        // tool, including calls we never started, before finishing so a
        // resumed run can send a valid transcript back to the provider.
        for (final t in pending.skip(pi)) {
          resultBlocks.add(
            HarnessToolResultBlock(
              toolUseId: t.id,
              content: 'Cancelled before the tool could run.',
              isError: true,
            ),
          );
        }
        s.history.add(
          HarnessMessage.toolResults(
            resultBlocks,
            // Carried on the message that activated them, so a later fold or
            // a restart can still tell these tools are callable once the
            // reference blocks that carried them are gone.
            activatedToolNames: activatedByCall,
          ),
        );
        yield* s.finish(LoopDoneReason.cancelled);
        return;
      }
      if (batchingAllowed &&
          pending[pi].argsError == null &&
          _isParallelSafe(byName[pending[pi].name])) {
        // Gather the entire independent region. A free slot starts its next
        // call immediately rather than waiting for the slowest sibling.
        final parallelLimit = config.tools.maxParallelToolCalls < 1
            ? 1
            : config.tools.maxParallelToolCalls;
        final batch = <_PendingTool>[];
        while (pi < pending.length &&
            pending[pi].argsError == null &&
            _isParallelSafe(byName[pending[pi].name])) {
          batch.add(pending[pi]);
          pi++;
        }
        final results = List<HarnessToolResult?>.filled(batch.length, null);
        final nested = List<_NestedRecord>.filled(
          batch.length,
          _NestedRecord.none,
        );
        await for (final event in _executeParallelBatch(
          batch,
          byName,
          s.ctx,
          limit: parallelLimit,
          timeout: config.tools.toolTimeout,
          completedReads: output.earlyResults,
          reentryFor: s.reentryFor,
        )) {
          final nestedEvent = event.nested;
          if (nestedEvent != null) {
            yield nestedEvent;
            continue;
          }
          final call = batch[event.index];
          final result = event.result;
          if (result == null) {
            yield LoopToolCallStart(
              toolName: call.name,
              toolUseId: call.id,
              args: call.args,
            );
          } else {
            results[event.index] = result;
            nested[event.index] = event.record;
            s.ledger.recordToolResult(call.name, isError: result.isError);
            if (event.started) {
              yield LoopToolCallResult(
                toolName: call.name,
                toolUseId: call.id,
                result: result,
              );
            }
          }
        }
        // Completion events are immediate; history and activation remain in
        // model order so timing cannot reorder the next cached request.
        for (var k = 0; k < batch.length; k++) {
          final result = results[k]!;
          if (result.withdrawsScripts) {
            s.catalog.withdrawScripts();
          }
          requestedActivations.addAll(result.activateTools);
          observedCalls
            ..add((name: batch[k].name, args: batch[k].args))
            ..addAll(nested[k].calls);
          final (block, notice) = await _observe(
            batch[k],
            result,
            nested[k].digest,
          );
          if (notice != null) {
            yield notice;
          }
          resultBlocks.add(block);
        }
        continue;
      }
      final t = pending[pi];
      pi++;
      yield LoopToolCallStart(toolName: t.name, toolUseId: t.id, args: t.args);
      // The calls this one makes through its reentry stream through here
      // while it runs, so they land between its start and result events. The
      // channel closes when the gate settles, on every path.
      final nestedEvents = StreamController<AgentLoopEvent>();
      final settled = s.gate
          .run(
            name: t.name,
            args: t.args,
            argsError: t.argsError,
            toolCallId: t.id,
            context: s.ctx,
            timeout: config.tools.toolTimeout,
            rewindRejection: rewindRejection,
            emitNested: (event) {
              if (!nestedEvents.isClosed) {
                nestedEvents.add(event);
              }
            },
          )
          // Not chained on close()'s own future: it completes only once a
          // listener has taken the done event, and the call has settled.
          .whenComplete(() => unawaited(nestedEvents.close()));
      // A consumer that stops listening mid-call leaves this future
      // unawaited; its error must not surface as an unhandled one.
      unawaited(settled.then<void>((_) {}, onError: (Object _) {}));
      yield* nestedEvents.stream;
      final gated = await settled;
      if (gated.notice case final notice?) {
        yield LoopNotice(notice);
      }
      final result = gated.result;
      if (result.withdrawsScripts) {
        s.catalog.withdrawScripts();
      }
      requestedActivations.addAll(result.activateTools);
      yield LoopToolCallResult(
        toolName: t.name,
        toolUseId: t.id,
        result: result,
      );
      observedCalls
        ..add((name: t.name, args: t.args))
        ..addAll(gated.nested.calls);
      final (block, notice) = await _observe(t, result, gated.nested.digest);
      if (notice != null) {
        yield notice;
      }
      resultBlocks.add(block);
    }
    final activatedByRequest = s.catalog.activate(requestedActivations);
    if (activatedByRequest.isNotEmpty) {
      yield LoopToolsActivated(
        names: activatedByRequest,
        // Attributed to the tool that asked, so a search that activates
        // nothing is visibly a retrieval miss rather than silent noise.
        trigger: pending.map((t) => t.name).toSet().join(','),
      );
    }
    s.history.add(
      HarnessMessage.toolResults(
        resultBlocks,
        activatedToolNames: [...activatedByCall, ...activatedByRequest],
      ),
    );
  }

  /// Shapes [result] into its model-facing block (observation ingest, image
  /// budget, activation references, the record of its nested calls). The
  /// notice reports an output the store failed to retain.
  Future<(HarnessToolResultBlock, LoopNotice?)> _observe(
    _PendingTool call,
    HarnessToolResult result,
    List<HarnessNestedToolCall> nestedCalls,
  ) async {
    final observation = await s.observationIngest.ingest(
      toolName: call.name,
      args: call.args,
      result: result,
      context: s.ctx,
      toolUseId: call.id,
    );
    final failure = observation.storageFailure;
    return (
      HarnessToolResultBlock(
        toolUseId: call.id,
        content: observation.content,
        isError: result.isError,
        images: _budgetedImages(call.name, result),
        outputReference: observation.reference,
        toolReferences: s.catalog.referencesFor(call, result),
        nestedCalls: nestedCalls,
      ),
      failure == null
          ? null
          : LoopNotice('Original tool output was not retained: $failure'),
    );
  }
}

/// Whether [tool] must clear the approval gate before running. A tool is gated
/// when it is above read-tier OR declares any PRD 24 effect class (so a bridged
/// MCP tool that is mis-tiered `read` but really performs a prPublish/fileDelete
/// effect is still gated). Self-guarding tools (sandboxed `bash`) stay exempt:
/// they enforce their own finer-grained command policy in the runner.
bool _requiresApproval(HarnessTool tool) =>
    (tool.approvalTier != ToolApprovalTier.read ||
        tool.actionClasses.isNotEmpty) &&
    !tool.selfGuards;

/// Concurrent-safe with siblings: [HarnessTool.parallelSafe], no loop approval,
/// not loop-handled (checkpoint/rewind). Batch calls tools directly, so
/// anything [_requiresApproval] would gate stays sequential.
bool _isParallelSafe(HarnessTool? tool) =>
    tool != null &&
    tool.parallelSafe &&
    !_requiresApproval(tool) &&
    !harnessControlToolNames.contains(tool.name);

/// The images from [result] capped to the per-tool budget. Applied by the loop
/// rather than by each tool: a bridged MCP tool cannot know the transcript's
/// image economics, and images survive compaction.
List<HarnessImageBlock> _budgetedImages(
  String toolName,
  HarnessToolResult result,
) {
  if (result.images.isEmpty) {
    return const [];
  }
  return capToolImages(
    result.images,
    ToolOutputLimitTable.defaults.forTool(toolName),
  );
}

/// Whether the pre-tool gate allows the call. A THROWING gate denies:
/// fail-closed matches the rest of the approval machinery — a hook that cannot
/// answer is not permission.
Future<bool> _preToolUseAllows(
  AgentLoopHooks hooks,
  String name,
  Map<String, dynamic> args,
) async {
  try {
    return await hooks.preToolUse(name, args);
  } on Object {
    return false;
  }
}

/// Merges provider events with a bounded queue of explicitly safe reads.
/// Cancelling the subscription cancels both lanes. Failed attempts discard
/// their observations; a successful attempt reuses each result exactly once.
Stream<Object> _overlapReadOnlyTools(
  Stream<LlmEvent> source,
  Map<String, HarnessTool> tools,
  HarnessToolContext context, {
  required int limit,
  Duration? timeout,
}) {
  final stopped = CancellationTokenSource();
  final token = CancellationToken.any([
    context.cancel ?? CancellationToken.none,
    stopped.token,
  ]);
  final childContext = context.withCancel(token);
  final events = StreamController<Object>();
  final queued = <_PendingTool>[];
  final seen = <String>{};
  StreamSubscription<LlmEvent>? subscription;
  var next = 0;
  var active = 0;
  var sourceDone = false;
  var barrier = false;
  var closed = false;
  late void Function() pump;

  Future<void> execute(_PendingTool call) async {
    final result = await _safeExecute(
      tools[call.name]!,
      call.args,
      childContext,
      toolCallId: call.id,
      timeout: timeout,
    );
    active--;
    if (closed) {
      return;
    }
    events.add(
      LoopToolCallResult(
        toolName: call.name,
        toolUseId: call.id,
        result: result,
      ),
    );
    pump();
  }

  pump = () {
    if (closed) {
      return;
    }
    if (token.isCancelled) {
      next = queued.length;
    } else {
      while (active < limit && next < queued.length) {
        final call = queued[next++];
        active++;
        events.add(
          LoopToolCallStart(
            toolName: call.name,
            toolUseId: call.id,
            args: call.args,
          ),
        );
        unawaited(execute(call));
      }
    }
    if (sourceDone && active == 0 && next == queued.length) {
      closed = true;
      unawaited(events.close());
    }
  };
  events.onListen = () {
    if (token.isCancelled) {
      sourceDone = true;
      pump();
      return;
    }
    subscription = source.listen(
      (event) {
        if (closed) {
          return;
        }
        events.add(event);
        if (event is LlmError) {
          barrier = true;
          stopped.cancel('The provider attempt failed.');
          pump();
        } else if (event is LlmToolUseDelta) {
          if (!seen.add(event.id)) {
            barrier = true;
            stopped.cancel('The provider repeated a tool-call id.');
            pump();
            return;
          }
          if (barrier) {
            return;
          }
          final call = _PendingTool.fromStream(
            event.id,
            event.name,
            event.argumentsJson,
          );
          final tool = tools[call.name];
          if (call.argsError != null ||
              tool == null ||
              !tool.speculativeReadSafe ||
              tool.approvalTier != ToolApprovalTier.read ||
              tool.selfGuards ||
              tool.actionClasses.isNotEmpty ||
              !_isParallelSafe(tool)) {
            barrier = true;
            return;
          }
          queued.add(call);
          pump();
        }
      },
      onError: (Object error, StackTrace stack) {
        stopped.cancel('The provider stream failed.');
        if (!closed) {
          events.addError(error, stack);
        }
      },
      onDone: () {
        sourceDone = true;
        pump();
      },
    );
    unawaited(
      token.whenCancelled.then((_) async {
        await subscription?.cancel();
        sourceDone = true;
        pump();
      }),
    );
  };
  events.onPause = () => subscription?.pause();
  events.onResume = () => subscription?.resume();
  events.onCancel = () async {
    closed = true;
    stopped.cancel('The provider attempt was abandoned.');
    await subscription?.cancel();
  };
  return events.stream;
}

/// One event of a parallel batch: a call started, a call settled (with the
/// record of its nested calls), or an event of a nested call made by one.
class _BatchEvent {
  const _BatchEvent(
    this.index, {
    this.started = false,
    this.result,
    this.nested,
    this.record = _NestedRecord.none,
  });

  final int index;
  final bool started;
  final HarnessToolResult? result;
  final AgentLoopEvent? nested;
  final _NestedRecord record;
}

Stream<_BatchEvent> _executeParallelBatch(
  List<_PendingTool> calls,
  Map<String, HarnessTool> tools,
  HarnessToolContext context, {
  required int limit,
  Duration? timeout,
  Map<String, HarnessToolResult> completedReads = const {},
  // Builds the reentry for a call (by id), whose nested events go to `emit`.
  _LoopReentry Function(
    String parentToolUseId,
    CancellationToken callToken,
    _PausableDeadline? deadline,
    void Function(AgentLoopEvent event) emit,
  )?
  reentryFor,
}) {
  final stopped = CancellationTokenSource();
  final token = CancellationToken.any([
    context.cancel ?? CancellationToken.none,
    stopped.token,
  ]);
  final childContext = context.withCancel(token);
  final events = StreamController<_BatchEvent>();
  var next = 0;
  var active = 0;
  var finished = 0;
  var closed = false;
  late void Function() pump;

  Future<void> execute(int index) async {
    final call = calls[index];
    final exec = await _execute(
      tools[call.name]!,
      call.args,
      childContext,
      toolCallId: call.id,
      timeout: timeout,
      reentryFor: reentryFor == null
          ? null
          : (callToken, deadline) =>
                reentryFor(call.id, callToken, deadline, (event) {
                  if (!closed) {
                    events.add(_BatchEvent(index, nested: event));
                  }
                }),
    );
    active--;
    finished++;
    if (closed) {
      return;
    }
    events.add(
      _BatchEvent(
        index,
        started: true,
        result: exec.result,
        record: exec.nested,
      ),
    );
    pump();
  }

  pump = () {
    if (closed) {
      return;
    }
    if (token.isCancelled) {
      while (next < calls.length) {
        events.add(
          _BatchEvent(
            next++,
            result: HarnessToolResult.error(
              'Cancelled before the tool could run.',
            ).withOutcome(ToolOutcome.cancelled),
          ),
        );
        finished++;
      }
    } else {
      while (active < limit && next < calls.length) {
        final index = next++;
        final alreadyCompleted = completedReads[calls[index].id];
        if (alreadyCompleted != null) {
          finished++;
          events.add(_BatchEvent(index, result: alreadyCompleted));
          continue;
        }
        active++;
        events.add(_BatchEvent(index, started: true));
        unawaited(execute(index));
      }
    }
    if (finished == calls.length) {
      closed = true;
      unawaited(events.close());
    }
  };
  events.onListen = pump;
  events.onCancel = () {
    closed = true;
    stopped.cancel('Tool result subscription closed.');
  };
  return events.stream;
}

/// How one execution ended.
class _Exec {
  const _Exec(
    this.result,
    this.status, [
    this.nested = _NestedRecord.none,
    this.stillRunning,
  ]);

  final HarnessToolResult result;
  final ToolReentryStatus status;
  final _NestedRecord nested;

  /// The tool's own execution, when the call settled at its deadline or its
  /// cancellation while that execution had not returned.
  final Future<HarnessToolResult>? stillRunning;
}

/// Runs [tool] and returns only its result: the lanes that never hand a
/// reentry out (the speculative overlap lane) need nothing else.
Future<HarnessToolResult> _safeExecute(
  HarnessTool tool,
  Map<String, dynamic> args,
  HarnessToolContext context, {
  String? toolCallId,
  Duration? timeout,
}) async => (await _execute(
  tool,
  args,
  context,
  toolCallId: toolCallId,
  timeout: timeout,
)).result;

/// Runs [tool], racing it against its deadline AND the run's cancellation.
///
/// Each call gets its OWN cancellation token, linked to the run's: when the
/// deadline passes, that token is cancelled so a cooperative tool (one that
/// watches `context.cancel` — bash, web fetch, subagents) actually stops its
/// work instead of running on after the loop stopped waiting. A tool that
/// ignores the token still cannot hold the turn: the kernel stops WAITING.
///
/// The deadline is pausable: it stops while [waits] has a person's wait open,
/// whether the tool reports it through its context's `personWait` or a call
/// it makes through its reentry is waiting. [reentryFor] builds that
/// [ToolReentry] from the call's token and deadline. The reentry closes and
/// any wait still open ends when the call settles, whichever way it settles.
Future<_Exec> _execute(
  HarnessTool tool,
  Map<String, dynamic> args,
  HarnessToolContext context, {
  String? toolCallId,
  Duration? timeout,
  _PersonWaits? waits,
  _LoopReentry Function(
    CancellationToken callToken,
    _PausableDeadline? deadline,
  )?
  reentryFor,
}) async {
  final personWaits = waits ?? _PersonWaits();
  final callCancel = CancellationTokenSource();
  final runCancel = context.cancel;
  final callToken = runCancel == null
      ? callCancel.token
      : CancellationToken.any([runCancel, callCancel.token]);
  final guard = Completer<_Exec>();
  // Assigned before the deadline or the cancellation can settle the call.
  late final Future<HarnessToolResult> execution;
  final deadline = timeout == null
      ? null
      : _PausableDeadline(timeout, () {
          if (!guard.isCompleted) {
            callCancel.cancel('Tool "${tool.name}" exceeded its time limit.');
            guard.complete(
              _Exec(
                HarnessToolResult.error(
                  'Tool "${tool.name}" exceeded its ${timeout.inSeconds}s '
                  'time limit and was abandoned. Its work was asked to stop '
                  'but may still be running; do not assume it finished.',
                ).withOutcome(ToolOutcome.timedOut),
                ToolReentryStatus.timedOut,
                _NestedRecord.none,
                execution,
              ),
            );
          }
        });
  personWaits.attach(deadline);
  final reentry = reentryFor?.call(callToken, deadline);
  _Exec settled(HarnessToolResult result) => _Exec(
    result,
    result.isError ? ToolReentryStatus.failed : ToolReentryStatus.completed,
  );
  try {
    execution = tool.execute(
      args,
      context
          .withCancel(callToken)
          .withToolCallId(toolCallId)
          .withReentry(reentry)
          .withPersonWait(personWaits.report),
    );
    final _Exec exec;
    if (timeout == null && runCancel == null) {
      exec = settled(await execution);
    } else {
      unawaited(
        execution.then(
          (r) => guard.isCompleted ? null : guard.complete(settled(r)),
          onError: (Object e) => guard.isCompleted
              ? null
              : guard.complete(
                  _Exec(
                    HarnessToolResult.error('Tool "${tool.name}" failed: $e'),
                    ToolReentryStatus.failed,
                  ),
                ),
        ),
      );
      deadline?.start();
      if (runCancel != null) {
        unawaited(
          runCancel.whenCancelled.then((_) {
            if (!guard.isCompleted) {
              guard.complete(
                _Exec(
                  HarnessToolResult.error(
                    'Tool "${tool.name}" was cancelled.',
                  ).withOutcome(ToolOutcome.cancelled),
                  ToolReentryStatus.cancelled,
                  _NestedRecord.none,
                  execution,
                ),
              );
            }
          }),
        );
      }
      exec = await guard.future;
    }
    return reentry == null
        ? exec
        : _Exec(exec.result, exec.status, reentry.record, exec.stillRunning);
  } on Object catch (e) {
    return _Exec(
      HarnessToolResult.error('Tool "${tool.name}" failed: $e'),
      ToolReentryStatus.failed,
      reentry?.record ?? _NestedRecord.none,
    );
  } finally {
    personWaits.settle();
    deadline?.dispose();
    reentry?.close();
  }
}

/// A tool call accumulated from the provider stream, awaiting execution.
class _PendingTool {
  _PendingTool(this.id, this.name, this.args, {this.argsError});

  /// Parses [argumentsJson] as a tool argument map. Malformed/truncated JSON
  /// must not become `{}` (that hides the parse failure as missing args);
  /// [argsError] carries the real reason.
  factory _PendingTool.fromStream(
    String id,
    String name,
    String argumentsJson,
  ) {
    final raw = argumentsJson.trim();
    if (raw.isEmpty) {
      // Genuinely no arguments — the common shape for a zero-arg tool.
      return _PendingTool(id, name, <String, dynamic>{});
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _PendingTool(id, name, decoded);
      }
      return _PendingTool(
        id,
        name,
        <String, dynamic>{},
        argsError:
            'Tool arguments must be a JSON object, got '
            '${decoded.runtimeType}: ${_excerpt(raw)}',
      );
    } on FormatException catch (e) {
      return _PendingTool(
        id,
        name,
        <String, dynamic>{},
        argsError:
            'Tool arguments were not valid JSON (${e.message}): '
            '${_excerpt(raw)}',
      );
    }
  }

  /// Enough of the payload to see the break, bounded so a runaway argument
  /// blob cannot itself become the context problem.
  static String _excerpt(String raw) =>
      raw.length <= 200 ? raw : '${raw.substring(0, 200)}…';

  final String id;
  final String name;
  final Map<String, dynamic> args;

  /// Non-null when [args] could not be parsed; the call must not run.
  final String? argsError;
}
