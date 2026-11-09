part of 'agent_loop_runner.dart';

/// Executes ONE turn's tool calls and appends their results to the history.
///
/// Parallel-safe calls run as a bounded batch when no hook intercepts tools;
/// exclusive tools stay sequential. Results append in model call order whatever
/// the completion order, so timing cannot reorder the next cached request.
/// Deferred tools load their schema and run in the same step.
class _ToolStep {
  _ToolStep(this.s, this.output, {this.rewindRejection});

  final _RunState s;
  final _TurnOutput output;

  /// Set when the turn's `rewind` named an unknown checkpoint: the call is
  /// answered with this error instead of rewinding.
  final String? rewindRejection;

  AgentLoopConfig get config => s.config;
  List<_PendingTool> get pending => output.pending;

  Stream<AgentLoopEvent> execute() async* {
    final activatedByCall = s.catalog.activate(pending.map((t) => t.name));
    if (activatedByCall.isNotEmpty) {
      yield LoopToolsActivated(names: activatedByCall, trigger: 'direct_call');
    }
    final hooks = s.hooks;
    final batchingAllowed = hooks == null || !hooks.interceptsTools;
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
        await for (final event in _executeParallelBatch(
          batch,
          byName,
          s.ctx,
          limit: parallelLimit,
          timeout: config.tools.toolTimeout,
          completedReads: output.earlyResults,
        )) {
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
          requestedActivations.addAll(result.activateTools);
          final (block, notice) = await _observe(batch[k], result);
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
      final result = await _runSequential(t);
      if (hooks != null) {
        // Report-only: the tool has ALREADY run, so a throwing observer must
        // not turn a completed call into a dead run.
        final failure = await _guardExtension(
          'postToolUse hook',
          () => hooks.postToolUse(
            t.name,
            result.content,
            isError: result.isError,
          ),
        );
        if (failure != null) {
          yield LoopNotice(failure);
        }
      }
      s.ledger.recordToolResult(t.name, isError: result.isError);
      requestedActivations.addAll(result.activateTools);
      yield LoopToolCallResult(
        toolName: t.name,
        toolUseId: t.id,
        result: result,
      );
      final (block, notice) = await _observe(t, result);
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

  /// Gates and runs one call outside a parallel batch.
  Future<HarnessToolResult> _runSequential(_PendingTool t) async {
    final tool = s.catalog.byName[t.name];
    final argsError = t.argsError;
    if (argsError != null) {
      // Refused before dispatch: running a tool with arguments we know are
      // wrong produces a failure that blames the tool.
      return HarnessToolResult.error(argsError);
    }
    if (t.name == 'checkpoint') {
      // Loop-handled: mark the clean boundary at the start of this turn.
      final label = (t.args['label'] as String?)?.trim();
      final key = (label == null || label.isEmpty) ? 'default' : label;
      s.checkpoints[key] = s.preTurnLength;
      return HarnessToolResult.success('Checkpoint "$key" set.');
    }
    if (t.name == 'rewind') {
      // Reached only when the rewind was refused (an accepted rewind drops
      // the whole turn before any tool runs).
      return HarnessToolResult.error(
        rewindRejection ?? 'rewind is handled by the loop.',
      );
    }
    if (tool == null) {
      // Deliberately does NOT enumerate a deferred catalogue: that list is
      // ~130 names, and reprinting it every time the model fat-fingers one is
      // the context cost deferral was meant to remove.
      return HarnessToolResult.error(
        s.catalog.deferredByName.isEmpty
            ? 'Unknown tool: ${t.name}. '
                  'Available tools: ${s.catalog.byName.keys.join(', ')}.'
            : 'Unknown tool: ${t.name}. Call `search_tools` to find the '
                  'right tool for what you are trying to do, or '
                  '`list_my_tools` to browse everything available.',
      );
    }
    final hooks = s.hooks;
    if (hooks != null && !await _preToolUseAllows(hooks, t.name, t.args)) {
      return HarnessToolResult.error('Denied by policy hook.');
    }
    if (_requiresApproval(tool)) {
      final approve = config.tools.approvalCallback;
      if (approve != null) {
        final decision = await approve(tool, t.args);
        // A denial carries the policy's own reason + remediation so the model
        // can replan instead of guessing who denied it and why.
        return decision.allowed
            ? _run(tool, t)
            : HarnessToolResult.error(decision.deniedMessage);
      }
      if (!config.tools.autoApprove) {
        // Fail closed: a privileged tool must never run without an approver.
        return HarnessToolResult.error(
          'Denied: "${tool.name}" requires approval but no approver is '
          'configured for this run.',
        );
      }
    }
    return _run(tool, t);
  }

  Future<HarnessToolResult> _run(HarnessTool tool, _PendingTool t) =>
      _safeExecute(
        tool,
        t.args,
        s.ctx,
        toolCallId: t.id,
        timeout: config.tools.toolTimeout,
      );

  /// Shapes [result] into its model-facing block (observation ingest, image
  /// budget, activation references). The notice reports an output the store
  /// failed to retain.
  Future<(HarnessToolResultBlock, LoopNotice?)> _observe(
    _PendingTool call,
    HarnessToolResult result,
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

Stream<({int index, bool started, HarnessToolResult? result})>
_executeParallelBatch(
  List<_PendingTool> calls,
  Map<String, HarnessTool> tools,
  HarnessToolContext context, {
  required int limit,
  Duration? timeout,
  Map<String, HarnessToolResult> completedReads = const {},
}) {
  final stopped = CancellationTokenSource();
  final token = CancellationToken.any([
    context.cancel ?? CancellationToken.none,
    stopped.token,
  ]);
  final childContext = context.withCancel(token);
  final events =
      StreamController<
        ({int index, bool started, HarnessToolResult? result})
      >();
  var next = 0;
  var active = 0;
  var finished = 0;
  var closed = false;
  late void Function() pump;

  Future<void> execute(int index) async {
    final call = calls[index];
    final result = await _safeExecute(
      tools[call.name]!,
      call.args,
      childContext,
      toolCallId: call.id,
      timeout: timeout,
    );
    active--;
    finished++;
    if (closed) {
      return;
    }
    events.add((index: index, started: true, result: result));
    pump();
  }

  pump = () {
    if (closed) {
      return;
    }
    if (token.isCancelled) {
      while (next < calls.length) {
        events.add((
          index: next++,
          started: false,
          result: HarnessToolResult.error(
            'Cancelled before the tool could run.',
          ),
        ));
        finished++;
      }
    } else {
      while (active < limit && next < calls.length) {
        final index = next++;
        final alreadyCompleted = completedReads[calls[index].id];
        if (alreadyCompleted != null) {
          finished++;
          events.add((index: index, started: false, result: alreadyCompleted));
          continue;
        }
        active++;
        events.add((index: index, started: true, result: null));
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

/// Runs [tool], racing it against its deadline AND the run's cancellation.
///
/// Each call gets its OWN cancellation token, linked to the run's: when the
/// deadline passes, that token is cancelled so a cooperative tool (one that
/// watches `context.cancel` — bash, web fetch, subagents) actually stops its
/// work instead of running on after the loop stopped waiting. A tool that
/// ignores the token still cannot hold the turn: the kernel stops WAITING.
Future<HarnessToolResult> _safeExecute(
  HarnessTool tool,
  Map<String, dynamic> args,
  HarnessToolContext context, {
  String? toolCallId,
  Duration? timeout,
}) async {
  Timer? timer;
  final callCancel = CancellationTokenSource();
  final runCancel = context.cancel;
  final callToken = runCancel == null
      ? callCancel.token
      : CancellationToken.any([runCancel, callCancel.token]);
  try {
    final execution = tool.execute(
      args,
      context.withCancel(callToken).withToolCallId(toolCallId),
    );
    if (timeout == null && runCancel == null) {
      return await execution;
    }
    final guard = Completer<HarnessToolResult>();
    unawaited(
      execution.then(
        (r) => guard.isCompleted ? null : guard.complete(r),
        onError: (Object e) => guard.isCompleted
            ? null
            : guard.complete(
                HarnessToolResult.error('Tool "${tool.name}" failed: $e'),
              ),
      ),
    );
    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!guard.isCompleted) {
          callCancel.cancel('Tool "${tool.name}" exceeded its time limit.');
          guard.complete(
            HarnessToolResult.error(
              'Tool "${tool.name}" exceeded its ${timeout.inSeconds}s '
              'time limit and was abandoned. Its work was asked to stop but '
              'may still be running; do not assume it finished.',
            ),
          );
        }
      });
    }
    if (runCancel != null) {
      unawaited(
        runCancel.whenCancelled.then((_) {
          if (!guard.isCompleted) {
            guard.complete(
              HarnessToolResult.error('Tool "${tool.name}" was cancelled.'),
            );
          }
        }),
      );
    }
    return await guard.future;
  } on Object catch (e) {
    return HarnessToolResult.error('Tool "${tool.name}" failed: $e');
  } finally {
    timer?.cancel();
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
