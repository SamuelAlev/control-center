part of 'agent_loop_runner.dart';

/// What the gate did with one call.
class _Gated {
  const _Gated(
    this.result,
    this.status, {
    this.gate,
    this.personWait = Duration.zero,
    this.notice,
    this.nested = _NestedRecord.none,
    this.stillRunning,
  });

  /// The result the model (or the calling script) receives.
  final HarnessToolResult result;

  /// How the call ended.
  final ToolReentryStatus status;

  /// What the gate decided; null when the call ended before it decided.
  final ToolGateRecord? gate;

  /// Time spent waiting on a person (approval, or a tool that waits on one).
  final Duration personWait;

  /// A failure of the post-tool hook, reported rather than fatal.
  final String? notice;

  /// The calls this call made through its reentry.
  final _NestedRecord nested;

  /// The tool's execution, when the call was given up on while it ran.
  final Future<HarnessToolResult>? stillRunning;
}

/// Starts and stops the clocks that must not count a person's wait: the
/// call's own deadline, the calling tool's deadline and the caller's own
/// clock, and measures the wait.
///
/// One per call. Every wait the call has (its approval, the whole execution of
/// a tool that waits on a person, and the waits the tool reports through
/// `HarnessToolContext.personWait`) goes through [begin] and [end]. Waits
/// nest: the clocks stop on the first and run again on the last, and the
/// caller hears only those two moments. [settle] ends whatever a tool left
/// open and ignores anything reported after it.
class _PersonWaits {
  _PersonWaits([this._parent, this._listener]);

  final _PausableDeadline? _parent;
  final PersonWaitListener? _listener;
  final Stopwatch _clock = Stopwatch();
  _PausableDeadline? _own;
  var _depth = 0;
  var _settled = false;

  /// The time spent waiting on a person so far.
  Duration get elapsed => _clock.elapsed;

  /// Pauses [own], the call's own deadline, through the waits that follow.
  /// The deadline is armed after any wait that is open now, and that wait is
  /// one this call's deadline was never meant to bound.
  void attach(_PausableDeadline? own) => _own = own;

  void begin() {
    if (_settled || _depth++ > 0) {
      return;
    }
    _clock.start();
    _own?.pause();
    _parent?.pause();
    _tell(true);
  }

  void end() {
    if (_settled || _depth == 0 || --_depth > 0) {
      return;
    }
    _clock.stop();
    _own?.resume();
    _parent?.resume();
    _tell(false);
  }

  /// What the call's tool reports through its context.
  void report(bool waiting) => waiting ? begin() : end();

  /// Ends any wait still open: the call has settled, whichever way.
  void settle() {
    if (_settled) {
      return;
    }
    if (_depth > 0) {
      _depth = 1;
      end();
    }
    _settled = true;
    _own = null;
  }

  void _tell(bool waiting) {
    final listener = _listener;
    if (listener == null) {
      return;
    }
    try {
      listener(waiting);
    } on Object {
      // The caller's bookkeeping must not break the call it observes.
    }
  }
}

/// The approval callback's own report of a person being asked, relayed into
/// the call's [_PersonWaits]: at most one wait open at a time, and [close]
/// ends one the callback left open (it threw, or the call stopped waiting
/// before the answer) and ignores anything reported afterwards.
class _CallbackWait {
  _CallbackWait(this._waits);

  final _PersonWaits _waits;
  var _open = false;
  var _closed = false;

  void report(bool waiting) {
    if (_closed || waiting == _open) {
      return;
    }
    _open = waiting;
    waiting ? _waits.begin() : _waits.end();
  }

  void close() {
    report(false);
    _closed = true;
  }
}

/// THE gate: the one path every tool call takes, whether the model issued it
/// or a tool made it through its [ToolReentry].
///
/// In order: argument validation, the loop-handled tools (model calls only),
/// surface lookup, the pre-tool hook, [_requiresApproval] and the approval
/// callback, [_execute] under the deadline and cancellation, the post-tool
/// hook and the completion-contract ledger. There is no second policy path.
class _ToolGate {
  _ToolGate(this.s);

  final _RunState s;

  AgentLoopConfig get config => s.config;

  /// Gates and runs one call.
  ///
  /// [parentToolUseId] is null for a model-issued call, which then gets a
  /// reentry whose events go to [emitNested]. A nested call gets none, and
  /// races its hook and approval waits against [context]'s cancellation so a
  /// cancelled parent settles it at once.
  Future<_Gated> run({
    required String name,
    required Map<String, dynamic> args,
    required String toolCallId,
    required HarnessToolContext context,
    String? argsError,
    String? parentToolUseId,
    Duration? timeout,
    String? rewindRejection,
    void Function(AgentLoopEvent event)? emitNested,
    _PersonWaits? waits,
    void Function(ToolGateVerdict verdict)? onToolStarted,
  }) async {
    final nested = parentToolUseId != null;
    final token = context.cancel ?? CancellationToken.none;
    final personWaits = waits ?? _PersonWaits();
    _Gated cancelled([ToolGateRecord? gate]) => _Gated(
      HarnessToolResult.error(
        'Tool "$name" was cancelled.',
      ).withOutcome(ToolOutcome.cancelled),
      ToolReentryStatus.cancelled,
      gate: gate,
      personWait: personWaits.elapsed,
    );
    // A nested call stops waiting the moment its parent, its caller or the
    // run cancels. A direct call keeps today's semantics: its hook and
    // approval are awaited, and cancellation is noticed by the execution.
    Future<T?> wait<T>(Future<T> future) =>
        nested ? raceCancellation(future, token) : future;

    if (argsError != null) {
      // Refused before dispatch: running a tool with arguments we know are
      // wrong produces a failure that blames the tool.
      return _finish(
        name,
        _Gated(
          HarnessToolResult.error(argsError),
          ToolReentryStatus.invalidArgs,
        ),
      );
    }
    if (!nested && name == 'checkpoint') {
      // Loop-handled: mark the clean boundary at the start of this turn.
      final label = (args['label'] as String?)?.trim();
      final key = (label == null || label.isEmpty) ? 'default' : label;
      s.checkpoints[key] = s.preTurnLength;
      return _finish(
        name,
        _Gated(
          HarnessToolResult.success('Checkpoint "$key" set.'),
          ToolReentryStatus.completed,
          gate: const ToolGateRecord(ToolGateVerdict.allowed),
        ),
      );
    }
    if (!nested &&
        name == compactToolName &&
        s.catalog.byName.containsKey(compactToolName)) {
      // Loop-handled: the next turn boundary compacts with this focus.
      if (s.compactor == null || s.config.compaction.contextWindow == null) {
        return _finish(
          name,
          _Gated(
            HarnessToolResult.error(
              'Compaction is not available in this run: it has no compactor '
              'or no context window.',
            ),
            ToolReentryStatus.failed,
            gate: const ToolGateRecord(ToolGateVerdict.allowed),
          ),
        );
      }
      final raw = args['focus'];
      var focus = raw is String ? raw.trim() : '';
      final cut = focus.length > maxCompactFocusChars;
      if (cut) {
        focus = focus.substring(0, maxCompactFocusChars);
      }
      s
        ..compactRequested = true
        ..pendingCompactFocus = focus.isEmpty ? null : focus;
      return _finish(
        name,
        _Gated(
          HarnessToolResult.success(
            'Compaction will run before the next model call'
            '${focus.isEmpty ? '' : ', with your focus'}'
            '${cut ? ' (cut to $maxCompactFocusChars characters)' : ''}. '
            'Older turns are folded into a summary; the newest stay verbatim.',
          ),
          ToolReentryStatus.completed,
          gate: const ToolGateRecord(ToolGateVerdict.allowed),
        ),
      );
    }
    if (!nested && name == 'rewind') {
      // Reached only when the rewind was refused (an accepted rewind drops
      // the whole turn before any tool runs).
      return _finish(
        name,
        _Gated(
          HarnessToolResult.error(
            rewindRejection ?? 'rewind is handled by the loop.',
          ),
          ToolReentryStatus.failed,
          gate: const ToolGateRecord(ToolGateVerdict.allowed),
        ),
      );
    }
    final tool = nested ? s.catalog.callable[name] : s.catalog.byName[name];
    if (tool == null) {
      return _finish(
        name,
        _Gated(
          HarnessToolResult.error(_unknownToolMessage(name, nested: nested)),
          ToolReentryStatus.unknownTool,
        ),
      );
    }
    // A script may call the tool but not with every argument (one that
    // assigns, starts or messages another agent run): refused here, before
    // the hook and the approval step, so the call raises no card.
    final argumentRefusal = nested ? tool.scriptArgumentRefusal(args) : null;
    if (argumentRefusal != null) {
      return _finish(
        name,
        _Gated(
          HarnessToolResult.error(
            argumentRefusal,
          ).withOutcome(ToolOutcome.denied),
          ToolReentryStatus.denied,
          gate: ToolGateRecord(ToolGateVerdict.denied, reason: argumentRefusal),
        ),
      );
    }
    // A nested call the host refuses outright (a script's call too long for
    // the audit to hold whole): before the owner's pre-tool hook is handed
    // its arguments and before any card. A direct call is never asked.
    final refuse = nested ? config.tools.nestedCallRefusal : null;
    String? refusal;
    try {
      refusal = refuse?.call(tool, args);
    } on Object catch (e) {
      // Fail closed, as for an approver that cannot answer.
      refusal = 'the approval check failed ($e)';
    }
    if (refusal != null) {
      final message = ToolGateDecision.deny(reason: refusal).deniedMessage;
      return _finish(
        name,
        _Gated(
          HarnessToolResult.error(message).withOutcome(ToolOutcome.denied),
          ToolReentryStatus.denied,
          gate: ToolGateRecord(ToolGateVerdict.denied, reason: message),
        ),
      );
    }
    final hooks = s.hooks;
    if (hooks != null) {
      final allowed = await wait(_preToolUseAllows(hooks, name, args));
      if (allowed == null) {
        return _finish(name, cancelled());
      }
      if (!allowed) {
        const reason = 'Denied by policy hook.';
        return _finish(
          name,
          const _Gated(
            HarnessToolResult(
              content: reason,
              isError: true,
              outcome: ToolOutcome.denied,
            ),
            ToolReentryStatus.denied,
            gate: ToolGateRecord(ToolGateVerdict.denied, reason: reason),
          ),
        );
      }
    }
    var gate = const ToolGateRecord(ToolGateVerdict.allowed);
    if (_requiresApproval(tool)) {
      final approve = config.tools.approvalCallback;
      if (approve != null) {
        final origin = ToolCallOrigin(
          toolCallId: toolCallId,
          parentToolUseId: parentToolUseId,
        );
        // Only the time a person is asked is a wait: the callback says when
        // it asks, and a policy that answers on its own stops no clock.
        final asking = _CallbackWait(personWaits);
        ToolGateDecision? decision;
        try {
          decision = await wait(
            approve(
              ToolApprovalRequest(
                tool: tool,
                args: args,
                origin: origin,
                withdrawn: token,
                onPersonWait: asking.report,
              ),
            ),
          );
        } on Object catch (e) {
          if (!nested) {
            // A direct call keeps today's contract: a throwing approver is
            // the host's failure and ends the run as one.
            rethrow;
          }
          // Fail closed: an approver that cannot answer is not permission.
          decision = ToolGateDecision.deny(
            reason: 'the approval check failed ($e)',
          );
        } finally {
          asking.close();
        }
        if (decision == null) {
          return _finish(name, cancelled());
        }
        if (!decision.allowed) {
          // A denial carries the policy's own reason + remediation so the
          // model can replan instead of guessing who denied it and why.
          final message = decision.deniedMessage;
          return _finish(
            name,
            _Gated(
              HarnessToolResult.error(message).withOutcome(ToolOutcome.denied),
              ToolReentryStatus.denied,
              gate: ToolGateRecord(ToolGateVerdict.denied, reason: message),
              personWait: personWaits.elapsed,
            ),
          );
        }
        gate = ToolGateRecord(
          decision.askedPerson
              ? ToolGateVerdict.approved
              : ToolGateVerdict.allowed,
        );
      } else if (!config.tools.autoApprove) {
        // Fail closed: a privileged tool must never run without an approver.
        final message =
            'Denied: "${tool.name}" requires approval but no approver is '
            'configured for this run.';
        return _finish(
          name,
          _Gated(
            HarnessToolResult.error(message).withOutcome(ToolOutcome.denied),
            ToolReentryStatus.denied,
            gate: ToolGateRecord(ToolGateVerdict.denied, reason: message),
          ),
        );
      }
    }
    if (nested && token.isCancelled) {
      // Decided, but the caller stopped waiting meanwhile: never start it.
      return _finish(name, cancelled(gate));
    }
    // Past here the call's outcome is the tool's: say so, with the verdict
    // it passed, before it starts.
    onToolStarted?.call(gate.verdict);
    // A tool whose execution IS a person's wait: the caller's clock and the
    // calling tool's deadline stop for all of it. Its own deadline keeps
    // running as the backstop for a question nobody answers.
    if (nested && tool.waitsOnPerson) {
      personWaits.begin();
    }
    final _Exec exec;
    try {
      exec = await _execute(
        tool,
        args,
        context.withParentToolCallId(parentToolUseId),
        toolCallId: toolCallId,
        timeout: timeout,
        waits: personWaits,
        reentryFor: emitNested == null
            ? null
            : (callToken, deadline) => _LoopReentry(
                s,
                parentToolUseId: toolCallId,
                parentToken: callToken,
                parentDeadline: deadline,
                emit: emitNested,
              ),
      );
    } finally {
      personWaits.settle();
    }
    // A tool that guards itself decides after this gate let it through: its
    // decision is the call's, so a script's record and result say what a
    // person approved or what refused the call, not the plain allow above.
    final guarded = switch (exec.result.guardVerdict) {
      final verdict?
          when gate.verdict == ToolGateVerdict.allowed &&
              tool.selfGuards &&
              (exec.status == ToolReentryStatus.completed ||
                  exec.status == ToolReentryStatus.failed) =>
        verdict,
      _ => null,
    };
    return _finish(
      name,
      _Gated(
        exec.result,
        guarded == ToolGateVerdict.denied
            ? ToolReentryStatus.denied
            : exec.status,
        gate: switch (guarded) {
          null => gate,
          ToolGateVerdict.denied => ToolGateRecord(
            guarded,
            reason: exec.result.content,
          ),
          _ => ToolGateRecord(guarded),
        },
        personWait: personWaits.elapsed,
        nested: exec.nested,
        stillRunning: exec.stillRunning,
      ),
    );
  }

  /// The post-tool hook and the contract ledger, run for every call the gate
  /// settles. The hook is report-only: the tool has ALREADY run (or been
  /// refused), so a throwing observer must not turn the call into a dead run.
  Future<_Gated> _finish(String name, _Gated gated) async {
    final hooks = s.hooks;
    String? notice;
    if (hooks != null) {
      notice = await _guardExtension(
        'postToolUse hook',
        () => hooks.postToolUse(
          name,
          gated.result.content,
          isError: gated.result.isError,
        ),
      );
    }
    s.ledger.recordToolResult(name, isError: gated.result.isError);
    return notice == null
        ? gated
        : _Gated(
            gated.result,
            gated.status,
            gate: gated.gate,
            personWait: gated.personWait,
            notice: notice,
            nested: gated.nested,
            stillRunning: gated.stillRunning,
          );
  }

  String _unknownToolMessage(String name, {required bool nested}) {
    final catalog = s.catalog;
    if (nested) {
      if (catalog.admitted.containsKey(name) ||
          harnessControlToolNames.contains(name)) {
        return '"$name" cannot be called from a script. Call it directly.';
      }
      return 'Unknown tool: $name. It is not on this run\'s tool surface.';
    }
    if (catalog.scriptOnlyByName.containsKey(name)) {
      // Script-only: callable, but never as a direct call. No schema loads.
      return '"$name" is callable only from a script. Call it from `repl` as '
          '`await tools["$name"](args)`.';
    }
    // Deliberately does NOT enumerate a deferred catalogue: that list is ~130
    // names, and reprinting it every time the model fat-fingers one is the
    // context cost deferral was meant to remove.
    if (catalog.deferredByName.isEmpty) {
      return 'Unknown tool: $name. '
          'Available tools: ${catalog.byName.keys.join(', ')}.';
    }
    // Only the ways this run has: a discovery tool it was not given (a run
    // with `repl` has no `list_my_tools`) is never named.
    final ways = [
      if (catalog.byName.containsKey('search_tools'))
        'call `search_tools` to find the right tool for what you are doing',
      if (catalog.byName.containsKey('list_my_tools'))
        'call `list_my_tools` to browse everything available',
      if (catalog.byName.containsKey('repl') &&
          catalog.scriptOnlyByName.isNotEmpty &&
          !catalog.scriptsWithdrawn)
        'look it up from a `repl` script with `searchTools(query)`',
    ];
    return ways.isEmpty
        ? 'Unknown tool: $name. It is not on this run\'s tool surface.'
        : 'Unknown tool: $name. To find one, ${ways.join(', or ')}.';
  }
}
